# for each node, calculate the number of leafs and store in nleafs
.calc_nleafs <- function(vtree) {
  rt <- which(as_tibble(vtree)$ID == "root")

  vtree |> activate("nodes") |>
    mutate(nleafs = map_bfs_back_int(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        if(nrow(path) == 0) {
          return(1L)
        } else {
          return(sum(unlist(path$result)))
        }
    }))
}


#' Add labels to a plot
#'
#' Adds or modifies a column called `label` to the node data frame of a vtree object.
#' Labels are used by the [plot.vtree()] function to show as node labels.
#'
#' By default, `add_labels()` produces simple node labels containing the
#' associated variable value, number of cases and percentage within the
#' parent node.
#'
#' Formatting can be done with the `fmt`/`fmt_na` parameter, which is
#' an R expression. You can use sprintf, glue, paste or whichever
#' expressions you like to construct a label from the following variables:
#'
#'  * `freq`, the frequency for a node
#'  * `n`, number of samples of a node
#'  * `node_col`, name of the variable associated with a node
#'  * `node_name`, display name of the variable associated with a node
#'  * `node_val`, value of the variable associated with a node
#'  * `node_cv`, same as `paste0(node_col, ':', node_val)`
#'  * plus whatever new columns you have added to the vtree with mutate().
#'
#' (the difference between node_col and node_name is that you can set
#' node_name to whatever you like, while node_col must remain unchanged)
#
#'
#' @param vtree an object of class vtree
#' @param template One of the predefined formats; can be 'simple' or
#' 'long'. If 'custom', you must provide the `fmt` and `fmt_NA`
#' parameters.
#' @param mask If not NULL, then a logical vector is expected indicating
#' the nodes for which the labels will be modified.
#' @param fmt an R expression to format the valid value nodes. If not
#' NULL, replaces the format from the template.
#' @param fmt_na an R expression to format NA nodes. If not NULL,
#' replaces the format from the template.
#' @param root_label Label to be used for the root node. If NA, do not
#'                    modify the root label.
#' @return an object of class vtree with added labels
#' @importFrom rlang quo quo_is_null
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' # look at the labels
#' vt |> add_labels() |> pull(label)
#' vt |> add_labels() |> plot()
#'
#' vt |> add_labels(template = "long") |> plot()
#'
#' # add only labels to some nodes
#'
#' mask <- find_nodes(vt, freq > .30)
#' vt |> add_labels(mask = mask) |> plot()
#'
#' # customize the format
#' vt |>
#'   add_labels(fmt = sprintf("%d out of %d",
#'         n, round(n/freq)),
#'     fmt_na = "NA") |> plot()
#'
#' @export
add_labels <- function(vtree,
                       template = "simple",
                       mask = NULL,
                       fmt = NULL,
                       fmt_na = NULL,
                       root_label = NA) {

  template <- match.arg(template, c("simple", "long"))

  userfmt <- enquo(fmt)
  userfmt_na <- enquo(fmt_na)

  # this only looks complicated because we have to use .data
  if(template == "simple") {
    fmt <- quo(sprintf("%s\n%d (%.0f%%)",
         .data[["node_val"]],
         .data[["n"]], .data[["freq"]] * 100))
    fmt_na = quo(sprintf("%s\n%d", .data[["node_val"]],
                            .data[["n"]]))
  } else if(template == "long") {
    fmt <- quo(sprintf("%s: %s\nN = %d (%.0f%%)",
         .data[["node_name"]],
         .data[["node_val"]],
         .data[["n"]],
         .data[["freq"]] * 100))
    fmt_na = quo(sprintf("%s: %s\n%d", .data[["node_name"]],
                            .data[["node_val"]], .data[["n"]]))
  }

  if(!quo_is_null(userfmt)) {
    fmt <- userfmt
  }

  if(!quo_is_null(userfmt_na)) {
    fmt_na <- userfmt_na
  }

  if(quo_is_null(fmt) || quo_is_null(fmt_na)) {
    stop("fmt/fmt_na not defined")
  }

  nodes <- vtree |> activate("nodes") |> as_tibble()
  labels    <- eval_tidy(fmt, data = nodes)
  labels_na <- eval_tidy(fmt_na, data = nodes)

  if(is.null(mask)) {
    mask <- rep(TRUE, nrow(nodes))
  }

  is_vp <- attr(vtree, "vp") %||% TRUE

  # add label column if one is missing
  if(!"label" %in% colnames(nodes)) {
    vtree <- mutate(vtree, label = "")
  }


  vtree <- vtree |> activate("nodes") |>
    mutate(label = ifelse(mask,
           ifelse(is.na(.data[["node_val"]]) & is_vp,
                          labels_na,
                          labels),
                          .data[["label"]]
           )) |>
    mutate(label = ifelse(.data[["ID"]] == "root" & !is.na(root_label),
                root_label, .data[["label"]]))

  vtree <- as_vtree(vtree)
  vtree
}


.calc_offsets <- function(vtree) {
  rt <- which(as_tibble(vtree)$ID == "root")

  vtree |>
    activate("nodes") |>
    group_by(.data[["parent"]]) |>
    mutate(offset = lag(cumsum(.data[["n"]]), default = 0)) |>
    ungroup() |>
    mutate(offset_tot = map_bfs_int(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        .N()$offset[node] + sum(.N()$offset[path$node])
    }))
}

layout_by_freq <- function(vtree, lwidth=NA) {

  layout <- .calc_offsets(vtree)

  nodes <- as_tibble(layout)

  maxl <- max(nodes$level)
  totn <- sum(nodes$n[nodes$level == 1])

  if(is.na(lwidth)) {
    lwidth <- .35 / maxl
  } else {
    lwidth <- lwidth / (2 * maxl)
  }

  layout <- layout |>
    mutate(x = .data[["level"]] / maxl) |>
    mutate(y = .data[["offset_tot"]] / totn +
           .data[["n"]] / (2 * totn)) |>
    mutate(width = 2 * lwidth, height = .data[["n"]] / totn)

  nodes <- as_tibble(layout)

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]],
           x2 = nodes$x[.data[["to"]]],
           y1 = nodes$y[.data[["to"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)

  layout
}

# plot by frequency
plot_by_freq <- function(layout, fill_scale, color_scale,
                         lfontsize = NA) {

  # calculate the local offsets for each descendant of each node
  nodes <- as_tibble(layout)
  edges <- activate(layout, "edges") |> as_tibble()

  nodes |> ggplot(aes(x = .data[["x"]], y = .data[["y"]],
                      height = .data[["height"]],
                      label = .data[["label"]])) +
    geom_segment(data = edges,
                 aes(x = .data[["x1"]],
                     y = .data[["y1"]],
                     xend = .data[["x2"]],
                     yend = .data[["y2"]]),
                 inherit.aes = FALSE) +
    geom_rect(aes(x = .data[["x"]],
                  y = .data[["y"]],
                  width = .data[["width"]],
                  height = .data[["height"]],
                  fill = .data[["ID"]]),
              color = "black") +
    geom_text(aes(color = .data[["ID"]]),
                  size = lfontsize) +
    fill_scale +
    color_scale +
    # reverse y axis
    scale_y_reverse()
}


layout_regular <- function(vtree, lwidth=NA, lheight=NA) {

  layout <- .calc_nleafs(vtree)

  nodes  <- as_tibble(layout)

  maxl <- max(nodes$level)
  totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totn <- sum(nodes$n[nodes$level == 1])

  if(is.na(lheight)) {
    lheight <- .8 / (2 * totleafs)
  } else {
    lheight <- lheight / (2 * totleafs)
  }

  if(is.na(lwidth)) {
    lwidth <- .35 / maxl
  } else {
    lwidth <- lwidth / (2 * maxl)
  }

  layout <- layout |>
    mutate(x = .data[["level"]] / maxl) |>
    group_by(.data[["level"]]) |>
    mutate(y = (cumsum(.data[["nleafs"]]) - .data[["nleafs"]] / 2)/
           totleafs) |>
    ungroup() |>
    mutate(xmin = .data[["x"]] - lwidth,
           xmax = .data[["x"]] + lwidth,
           ymin = .data[["y"]] - lheight,
           ymax = .data[["y"]] + lheight)

  nodes <- as_tibble(layout)

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]],
           x2 = nodes$x[.data[["to"]]] - lwidth,
           y1 = nodes$y[.data[["from"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)


   layout
}

# just the nodes, no resizing according to frequency
#' @importFrom ggplot2 arrow
plot_regular <- function(layout, fill_scale, color_scale,
                         lfontsize = NA) {


  nodes <- activate(layout, "nodes") |> as_tibble()
  edges <- activate(layout, "edges") |> as_tibble()

  nodes |> ggplot(aes(x = .data[["x"]],
                      y = .data[["y"]],
                      label = .data[["label"]])) +
    geom_segment(data = edges,
                 aes(x = .data[["x1"]],
                     y = .data[["y1"]],
                     xend = .data[["x2"]],
                     yend = .data[["y2"]]),
                 arrow = arrow(angle = 15, type = "closed"),
                 inherit.aes = FALSE) +
    geom_rrect(aes(xmin = .data[["xmin"]],
                   xmax = .data[["xmax"]],
                   ymin = .data[["ymin"]],
                   ymax = .data[["ymax"]],
                   fill = .data[["ID"]]),
               color = "black", radius = .4) +
    geom_text(aes(color = .data[["ID"]]),
              size = lfontsize) +
    # reverse y axis
    fill_scale +
    color_scale +
    scale_y_reverse()
}



#' Plot a vtree
#'
#' Plots a vtree object. By default, all nodes have the same size. If you
#' specify `proportional = TRUE`, then node size will be proportional to the
#' number of observations in that node.
#'
#' The returned value is a ggplot2 object, which can be further customized
#' using ggplot2 functions.
#'
#' @section Working with color palettes:
#'
#' By default, fill colors are assigned automatically based on the variable
#' level in the tree. Each node gets its own palette, and from
#' that palette fill colors are assigned to the levels of the variable by
#' their order of appearance or factor level in the data. The variables
#' with the lowest factor levels or appearing first will get the darkest
#' fill colors. NA values are colored white.
#'
#' If the vtree object contains, in the node data frame, a column called
#' "fill", then the fill colors will be taken from that column instead of being
#' assigned automatically.
#'
#' If the vtree object contains a column called "color", then the text
#' colors will be taken from that column. Otherwise, the either white or
#' black will be chosen depending on the fill color for each node. You can
#' easily create this column with the [vtree2::mutate.vtree()] function (see
#' examples below).
#'
#' @section Labels:
#'
#' Similarly, some default labels are created automatically. However, if
#' a `label` column is present in the nodes data frame, it will be used
#' instead for node labels. The node labels at present use
#' [ggplot2::geom_text()], so no additional markdown/HTML formatting can be
#' used. Here, there are several columns that can be used to create a
#' label:
#'
#'  * `freq`, the frequency for a node
#'  * `n`, number of samples of a node
#'  * `node_col`, name of the variable associated with a node
#'  * `node_name`, display name of the variable associated with a node
#'  * `node_val`, value of the variable associated with a node
#'  * `node_cv`, same as `paste0(node_col, ':', node_val)`
#'
#' (the difference between node_col and node_name is that you can set
#' node_name to whatever you like, while node_col must remain unchanged)
#'
#' Manipulating these columns is straightforward using the
#' [vtree2::mutate.vtree()] function (see below).
#'
#' For variables which are not associated with the nodes and additional
#' summary variables, see [vtree2::summary_vt()].
#'
#' @param x A vtree object
#' @param ... ignored
#' @param lfontsize Font size for labels
#' @param lwidth Label width relative to available space
#' @param lheight Label height relative to available space
#' @param palettes A character vector with names of RColorBrewer palettes
#'                 to use for the variables. By default these are the
#'                 default arguments to the vtree_palette() function.
#' @param na_fill The color to use for NA values. Default is "white".
#' @param proportional If TRUE, the node sizes are scaled by number of
#' observations. If FALSE, all nodes have the same size.
#' @param legend If TRUE, a legend is added to the plot. Default is FALSE.
#' @examples
#' vt <- vtree_from_freqtable(Titanic)
#'
#' # regular plot
#' plot(vt)
#'
#' # proportional
#' plot(vt, proportional = TRUE)
#'
#' # create custom labels as simple numbers with mutate()
#' library(dplyr)
#' vt |> mutate(label = 1:n()) |> plot()
#'
#' # a bit more complex example
#' vt |>
#'   mutate(label = paste0(node_col, " = ",
#'                         node_val, '\n',
#'          ifelse(is.na(node_val), '-',
#'              sprintf("%.0f%%", 100 * freq)))) |>
#'   plot()
#'
#' # some color manipulation
#' pal <- colorRampPalette(c("white", "steelblue"))(101)
#'
#' vt |>
#'   mutate(fill = pal[round(freq * 100) + 1]) |>
#'   plot()
#'
#' vt |>
#'   mutate(abs_freq = n / max(n)) |>
#'   mutate(fill = pal[round(abs_freq * 100) + 1]) |>
#'  plot()
#'
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_segment geom_rect
#' @importFrom ggplot2 scale_y_reverse coord_cartesian
#' @importFrom ggplot2 theme_void geom_text geom_label unit
#' @importFrom ggplot2 scale_fill_manual scale_color_manual theme
#' @export
plot.vtree <- function(x,
                       ...,
                       lfontsize = NA,
                       lwidth = .7,
                       lheight = .8,
                       palettes = c("Blues", "Greens", "Reds",
                                    "Oranges", "Purples"),
                       na_fill = "white",
                       proportional = FALSE,
                       legend = FALSE) {
  stopifnot(inherits(x, "vtree"))

  nodes <- x |> activate("nodes") |> as_tibble()
  if(! "fill" %in% colnames(nodes)) {
    x <- vtree_pal_assign(x, palettes = palettes, na_fill = na_fill)
  }

  if(! "color" %in% colnames(nodes)) {
    x <- x |> activate("nodes") |>
      mutate(color = contrast_color(.data[["fill"]]))
  }

  nodes <- x |> activate("nodes") |> as_tibble()

  fill_scale  <- scale_fill_manual(name = NULL,
                                   values  = set_names(nodes$fill,
                                                       nodes$ID))
  color_scale <- scale_color_manual(name = NULL,
                                    values = set_names(nodes$color,
                                                       nodes$ID))
  if(! "label" %in% colnames(nodes)) {
    x <- x |> add_labels()
  }

  if(proportional) {
    l <- layout_by_freq(x, lwidth = lwidth)
    p <- plot_by_freq(l, fill_scale, color_scale,
                      lfontsize = lfontsize)
  } else {
    l <- layout_regular(x, lwidth = lwidth, lheight = lheight)
    p <- plot_regular(l, fill_scale, color_scale,
                      lfontsize = lfontsize)
  }

  #p <- p + theme_void() +
  p <- p+  coord_cartesian(clip = "off") +
    theme(plot.margin = unit(rep(1, 4), "cm"))

  if(!legend) {
    p <- p + theme(legend.position = "none")
  }

  p

}



