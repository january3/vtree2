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
    fmt <- quo(ifelse(.data[["node_val"]] == "",
               sprintf("%d\n(%.0f%%)", .data[["n"]], .data[["freq"]] * 100),
               sprintf("%s\n%d (%.0f%%)",
         .data[["node_val"]],
         .data[["n"]], .data[["freq"]] * 100)))
    fmt_na = quo(ifelse(!is.na(.data[["node_val"]]) & .data[["node_val"]] == "",
                        sprintf("%d", .data[["n"]]),
                        sprintf("%s\n%d", .data[["node_val"]], .data[["n"]]))
                       )
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
    mutate(label = ifelse(.data[["node_id"]] == 1 & !is.na(root_label),
                root_label, .data[["label"]]))

  vtree <- as_vtree(vtree)
  vtree
}


.add_level_labels <- function(vtree, top = FALSE) {

  nn <- names(vtree)
  nodes <- as_tibble(vtree)

  # we reuse the node_key which is bound to the color
  # we pick the last fill/color combination, because that is usually the
  # strongest color
  keys <- purrr::map_chr(nn, \(x) {
    nodes |> filter(.data[["node_col"]] == x) |>
      dplyr::last() |> pull("node_key")
  })

  y <- ifelse(top, -.1, 1.1)
  lnn <- length(nn)
  dx <- 1/(lnn + 1)

  df <- data.frame(
        label = nn,
        keys = keys,
        x = seq(0, 1, by=dx)[-c(1, lnn + 2)] + dx/2,
        y = y
        )

  geom_label(data = df,
             aes(x = .data[["x"]], y = .data[["y"]],
                 label = .data[["label"]],
                 fill = .data[["keys"]],
                 color = .data[["keys"]]),
             size = 9,
             inherit.aes = FALSE)
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
                  fill = .data[["node_key"]]),
              color = "black") +
    geom_text(aes(color = .data[["node_key"]]),
                  size = lfontsize) +
    fill_scale +
    color_scale
}




# just the nodes, no resizing according to frequency
#' @importFrom ggplot2 arrow coord_flip
plot_regular <- function(layout, fill_scale, color_scale,
                         lfontsize = NA) {


  nodes <- as_tibble(layout)
  edges <- activate(layout, "edges") |> as_tibble()

  p <- nodes |> ggplot(aes(x = .data[["x"]],
                      y = .data[["y"]],
                      label = .data[["label"]])) +
    geom_segment(data = edges,
                 aes(x = .data[["x1"]],
                     y = .data[["y1"]],
                     xend = .data[["x2"]],
                     yend = .data[["y2"]]),
                 arrow = arrow(angle = 15, type = "closed"),
                 inherit.aes = FALSE) +
    geom_rrect(aes(xmin = .data[["x"]] - .data[["width"]]/2,
                   xmax = .data[["x"]] + .data[["width"]]/2,
                   ymin = .data[["y"]] - .data[["height"]]/2,
                   ymax = .data[["y"]] + .data[["height"]]/2,
                   fill = .data[["node_key"]]),
               color = "black", radius = .4) +
    geom_text(aes(color = .data[["node_key"]]),
              size = lfontsize) +
    # reverse y axis
    fill_scale +
    color_scale

  p
}

# we check that the layout is correct and has the required columns
# for some columns, we make sure that there are no NAs
normalize_layout <- function(layout) {

  nodes <- as_tibble(layout)
  edges <- activate(layout, "edges") |> as_tibble()

  req_cols <- c("x", "y", "width", "height", "color", "fill", "label")

  if(!all(req_cols %in% colnames(nodes))) {
    missing <- setdiff(req_cols, colnames(nodes))
    cli_abort(c(x = "layout is missing required columns: {missing}"))
  }

  # for color and fill: make sure it is character; if fill missing, put
  # "white"; if color missing, put "black"
  layout <- layout |>
    mutate(fill = as.character(.data[["fill"]]),
           color = as.character(.data[["color"]])) |>
    mutate(fill = ifelse(is.na(.data[["fill"]]), "white", .data[["fill"]]),
           color = ifelse(is.na(.data[["color"]]), "black", .data[["color"]]))

  # make sure label is character; if missing, fill in the node_val
  layout <- layout |>
    mutate(label = as.character(.data[["label"]])) |>
    mutate(label = ifelse(is.na(.data[["label"]]),
                          "NA", .data[["label"]]))

  # if full_w or full_h are missing, replace them with width/height
  if(!"full_w" %in% colnames(nodes)) {
    layout <- layout |>
      mutate(full_w = .data[["width"]])
  }

  if(!"full_h" %in% colnames(nodes)) {
    layout <- layout |>
      mutate(full_h = .data[["height"]])
  }

  # check edges; required are x1, x2, y1, y2
  req_cols_edges <- c("x1", "x2", "y1", "y2")
  if(!all(req_cols_edges %in% colnames(edges))) {
    missing <- setdiff(req_cols_edges, colnames(edges))
    cli_abort(c(x =
      "layout edges are missing required columns: {missing}"))
  }

  layout
}

# make sure that the vtree is ready for plotting. Fill in the missing
# color, label, fill etc. information.
normalize_vtree_for_plotting <- function(x, palettes, na_fill) {
  if(!inherits(x, "vtree")) {
    cli_abort(c(x = "normalize_vtree() requires a vtree object"))
  }

  nodes <- as_tibble(x)

  if(! "fill" %in% colnames(nodes)) {
    x <- add_palette(x, palettes = palettes, na_fill = na_fill)
  }

  if(! "color" %in% colnames(nodes)) {
    x <- x |> activate("nodes") |>
      mutate(color = contrast_color(.data[["fill"]]))
  }

  if(! "label" %in% colnames(nodes)) {
    x <- x |> add_labels()
  }

  if(! "shape" %in% colnames(nodes)) {
    x <- x |> activate("nodes") |>
      mutate(shape = "roundrectangle")
  }

  x
}

#' Plot a vtree
#'
#' Plots a vtree object using a variety of layouts.
#'
#' `plot.vtree()` plots a vtree object using a variety of layouts. The
#' default layout, "regular", simply shows the tree structure with all
#' nodes having the same size. The "proportional" layout shows the nodes
#' with sizes proportional to the number of observations in that node.
#'
#' Colors, fill colors, node labels and other details can be customized by
#' modifying the vtree object directly with the [vtree2::mutate.vtree()] function.
#' Otherwise, default colors and labels are filled in automatically.
#'
#' @section Colors:
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
#' instead for node labels. Here, there are several columns that can be
#' used to create a label:
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
#' See [vtree2::vtree()] for a list of all columns in the node data frame.
#'
#' Manipulating these columns is straightforward using the
#' [vtree2::mutate.vtree()] function (see below).
#'
#' For variables which are not associated with the nodes and additional
#' summary variables (ranges, medians, standard deviations and more), see
#' [vtree2::summary_vt()].
#'
#' @param x A vtree object
#' @param ... Arguments passed to `plot_vtree()`
#' @param lfontsize Font size for labels
#' @param lwidth Label width relative to available space
#' @param lheight Label height relative to available space
#' @param layout The layout type, either "regular", "flushed" or "proportional". If
#'        "proportional", then the height of each node is proportional to the number
#'        of observations in that node. See [vtree2::layout()] for details.
#'        If layout is NA, then it is assumed that the vtree already has a
#'        layout with all necessary columns and no layout is calculated.
#' @param layout_func Custom function to calculate layout (see
#'        [vtree2::layout()] for details).
#' @param show_root If TRUE (default), show the root node (total
#'        population).
#' @param var_labels If TRUE (default), add names of the variables to the
#'        plot.
#' @param dir direction of the tree. One of "lr" (left to right), "rl"
#'        (right to left), "tb" (top to bottom), "bt" (bottom to top).
#'        Default is "lr".
#' @param palettes A character vector with names of RColorBrewer palettes
#'                 to use for the variables. By default these are the
#'                 default arguments to the vtree_palette() function.
#' @param autofontsize If "adaptive", the font size is adjusted to fit the
#'        each node, which may result in nodes having different font sizes.
#'        If "fixed", all nodes have the same font size, adjusted to fit
#'        the smallest node. If NA (default), then "adaptive" is used for
#'        proportional plots (which often have very small nodes) and
#'        "fixed" for regular plots.
#' @param na_fill The color to use for NA values. Default is "white".
#' @param legend If TRUE, a legend is added to the plot. Default is FALSE.
#' @seealso [vtree2::mutate.vtree()] for modifying the node data frame, and
#' [vtree2::add_labels()] for adding labels to the nodes. For layout
#' details, see [vtree2::layout()].
#' @examples
#' vt <- vtree_from_freqtable(Titanic)
#'
#' # regular plot
#' plot(vt)
#'
#' # proportional plot
#' plot(vt, proportional = TRUE)
#'
#' # create custom labels as simple numbers with mutate()
#' library(dplyr)
#' vt |> mutate(label = as.character(1:n())) |> plot()
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
#' @return A grid::gTree object of class vtree_plot. `plot_ggplot()`
#' returns a ggplot2 object.
#' @importFrom grid gTree gpar gList
#' @export
plot.vtree <- function(x, ...) {
  plot_vtree(x, ...)
}

#' @rdname plot.vtree
#' @export
plot_vtree <- function(x,
                      layout = "regular",
                      layout_func = NULL,
                      palettes = c("Blues", "Greens", "Reds",
                                   "Oranges", "Purples"),
                      na_fill = "white",
                      show_root = TRUE,
                      var_labels = TRUE,
                      lwidth = NA, lheight = NA,
                      autofontsize = NA,
                      dir = "lr") {

  dir <- match.arg(dir, c("lr", "rl", "bt", "tb"))

  layout_arg <- layout

  x <- normalize_vtree_for_plotting(x, palettes, na_fill)
  layout <- layout(x, layout = layout_arg,
                   layout_func = layout_func, dir = dir,
                   lwidth=lwidth, lheight=lheight,
                   show_root = show_root)

  if(is.na(autofontsize)) {
    if(layout_arg == "proportional") {
      autofontsize = "adaptive"
    } else {
      autofontsize = "fixed"
    }
  }

  margins <- c(.01 + .04 * var_labels, 0.01, .01, .01)
  if(dir == "rl") {
    layout <- .flip_horiz(layout)
  }

  if(dir %in% c("bt", "tb")) {
    margins <- c(0.01, .01 + .09 * var_labels, 0.01, 0.01)
    layout <- .transpose(layout)
    layout <- .flip_horiz(layout)
  }

  if(dir == "tb") {
    layout <- .flip_vert(layout)
  }

  layout <- .scale(layout, margins[2], margins[1],
                  1 - (margins[2] + margins[4]),
                 1 - (margins[1] + margins[3]))

  layout <- normalize_layout(layout)

  x <- gTree(
        params = list(
          dir = dir,
          autofontsize = autofontsize,
          layout_type = layout_arg),
        layout = layout,
        margin = margins,
        name = "vtree",
        children = gList(),
        cl = "vtree_plot",
        gp = gpar()
        )
  .make_children(x, fs = 9, var_labels = var_labels)
}

#' @rdname plot.vtree
#' @importFrom ggplot2 ggplot aes geom_segment geom_rect
#' @importFrom ggplot2 scale_x_reverse scale_y_reverse coord_cartesian
#' @importFrom ggplot2 theme_void geom_text geom_label unit
#' @importFrom ggplot2 scale_fill_manual scale_color_manual theme
#' @export
plot_ggplot <- function(x,
                       layout = "regular",
                       layout_func = NULL,
                       palettes = c("Blues", "Greens", "Reds",
                                    "Oranges", "Purples"),
                       na_fill = "white",
                       var_labels = TRUE,
                       lwidth = .7, lheight = .8,
                       dir = "lr",
                       lfontsize = NA,
                       legend = FALSE) {

  dir <- match.arg(dir, c("lr", "rl", "bt", "tb"))

  nodes <- as_tibble(x)
  if(! "fill" %in% colnames(nodes)) {
    x <- add_palette(x, palettes = palettes, na_fill = na_fill)
  }

  if(! "color" %in% colnames(nodes)) {
    x <- x |> activate("nodes") |>
      mutate(color = contrast_color(.data[["fill"]]))
  }

  nodes <- as_tibble(x)

  fill_scale  <- scale_fill_manual(name = NULL,
                                   values  = set_names(nodes$fill,
                                                       nodes$node_key))
  color_scale <- scale_color_manual(name = NULL,
                                    values = set_names(nodes$color,
                                                       nodes$node_key))
  if(! "label" %in% colnames(nodes)) {
    x <- x |> add_labels()
  }

  l <- layout(x, layout = layout,
              layout_func = layout_func,
              lwidth = lwidth)

  if(layout == "proportional") {
    p <- plot_by_freq(l, fill_scale, color_scale,
                      lfontsize = lfontsize)
  } else {
    p <- plot_regular(l, fill_scale, color_scale,
                      lfontsize = lfontsize)
  }

  # plot orientation
  if(dir == "rl") {
    p <- p + scale_x_reverse() + scale_y_reverse()
  } else if(dir == "lr") {
    p <- p + scale_y_reverse()
  } else if(dir == "tb") {
    p <- p + coord_flip() + scale_x_reverse()
  } else if(dir == "bt") {
    p <- p + coord_flip()
  }

  # add labels
  if(var_labels) {
    p <- p + .add_level_labels(x)
  }

  #p <- p + theme_void() +
  p <- p + #coord_cartesian(clip = "off") +
    theme(plot.margin = unit(rep(1, 4), "cm"))

  if(!legend) {
    p <- p + theme(legend.position = "none")
  }

  p
}


