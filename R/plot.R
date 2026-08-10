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
.normalize_vtree_for_plotting <- function(x, palettes, na_fill) {
  if(!inherits(x, "vtree")) {
    cli_abort(c(x = "normalize_vtree() requires a vtree object"))
  }

  nodes <- as_tibble(x)

  if(! "fill" %in% colnames(nodes)) {
    x <- add_palette(x, palettes = palettes, na = na_fill)
  }

  if(! "color" %in% colnames(nodes)) {
    x <- mutate(x, color = contrast_color(.data[["fill"]]))
  }

  if(is.null(get_alias_attr(x))) {
    x <- add_aliases(x)
  }

  if(! "label" %in% colnames(nodes)) {
    x <- add_labels(x)
  }

  if(! "shape" %in% colnames(nodes)) {
    x <- mutate(x, shape = "roundrectangle")
  }

  # for color and fill: make sure it is character; if fill missing, put
  # "white"; if color missing, put "black"
  x <- x |>
    mutate(fill = as.character(.data[["fill"]]),
           color = as.character(.data[["color"]])) |>
    mutate(fill = ifelse(is.na(.data[["fill"]]), "white", .data[["fill"]]),
           color = ifelse(is.na(.data[["color"]]), "black", .data[["color"]]))

  # make sure label is character; if missing, fill in the node_val
  x <- x |>
    mutate(label = as.character(.data[["label"]])) |>
    mutate(label = ifelse(is.na(.data[["label"]]),
                          "NA", .data[["label"]]))

  x
}


# set some default margins depending on the presence of legends
# and plot direction
.normalize_margins <- function(margins, dir, legend) {
  # default margins
  ltin <- legend == "tiny"
  lful <- legend == "full"
  if(is.null(margins)) {
    if(dir %in% c("lr", "rl")) {
      margins <- margins %||% list(top = .01, right = .01,
                    bottom = .01 + .05 * ltin +
                      .15 * lful,
                    left = .01)
    } else {
      margins <- margins %||% list(top = .01, right = .01,
                    bottom = .01,
                    left = .01 + .15 * (lful || ltin))

    }
    return(margins)
  }

  if(length(margins) != 4 || !is.numeric(margins)) {
    die("margins should be a numeric vector with four elements, t-r-b-l")
  }

  if(!all(margins >= 0) || !all(margins <= 1)) {
    die("all margins must be values in the range [0,1]")
  }

  list(top = margins[1],
       right = margins[2],
       bottom = margins[3],
       left = margins[4])
}

.normalize_fontsizes <- function(fontsizes, layout) {

  # fields: nodes, var_labels, legend_labels
  nodes <- ifelse(layout == "proportional",
                       "adaptive", "fixed")

  ret <- list(nodes = nodes,
              var_labels = "fixed",
              legend_labels = "fixed")

  if(!is.null(fontsizes)) {
    ret <- purrr::imap(ret, \(val, nm) fontsizes[[nm]] %||% ret[[nm]])
  }

  ret

}

# figure out a direction from a precomputed layout
.get_dir <- function(layout) {

  if(!is.null(attr(layout, "dir"))) {
    return(attr(layout, "dir"))
  }

  nodes <- as_tibble(layout)

  # first, check if x is constant for a given node_col
  # then it is a horizontal layout, otherwise vertical
  vert <- TRUE
  if(all(tapply(nodes$x, nodes$node_col,
                \(x) length(unique(x))) == 1)) {
    vert <- FALSE
  } else if(all(tapply(nodes$y, nodes$node_col,
                \(x) length(unique(x))) == 1)) {
    vert <- TRUE
  } else {
    cli_abort(c(x = "cannot determine direction of precomputed layout"))
  }

  # if vert, check whether x are increasing or decreasing with node_col
  if(vert) {
    x_means <- tapply(nodes$x, nodes$node_col, mean)
    if(all(diff(x_means) > 0)) {
      return("bt")
    } else if(all(diff(x_means) < 0)) {
      return("tb")
    } else {
      cli_abort(c(x = "cannot determine direction of precomputed layout"))
    }
  } else {
    y_means <- tapply(nodes$y, nodes$node_col, mean)
    if(all(diff(y_means) > 0)) {
      return("lr")
    } else if(all(diff(y_means) < 0)) {
      return("rl")
    } else {
      cli_abort(c(x = "cannot determine direction of precomputed layout"))
    }
  }
}



# check whether vtree already has a layout. If so, return vtree
.normalize_layout <- function(vtree, layout_arg, lwidth, lheight, show_root, dir) {

  node_names <- igraph::vertex_attr_names(vtree)
  edge_names <- igraph::edge_attr_names(vtree)

  has_cols <- all(c("x", "y", "width", "height") %in% node_names) &&
              all(c("x1", "x2", "y1", "y2") %in% edge_names)

  if(inherits(vtree, "vtree_layout") || has_cols) {
    if(!is.na(lwidth) || !is.na(lheight)) {
      cli::cli_warn(
       c(i = "vtree already has a layout; ignoring lwidth and lheight"))
    }

    if(is.null(attr(vtree, "dir"))) {
      attr(vtree, "dir") <- .get_dir(vtree)
    }

    return(vtree)
  }

  layout <- add_layout(vtree, layout = layout_arg,
                   dir = dir,
                   lwidth=lwidth, lheight=lheight,
                   show_root = show_root)


  layout
}

.normalize_dir <- function(dir, vtree) {
  dir_tree <- attr(vtree, "dir")

  if(!is.na(dir)) {
    if(!is.null(dir_tree) && dir != dir_tree) {
    cli_abort(
      c(x = "vtree has a precomputed layout with direction '{dir_tree}', but you specified dir = '{dir}'"))
    } else {
      return(dir)
    }
  }

  if(inherits(vtree, "vtree_layout") && !is.null(attr(vtree, "dir"))) {
    return(dir_tree)
  }

  "lr"
}

.normalize_legend <- function(legend) {

 if(is.logical(legend)) {
   if(legend) {
     return("full")
   } else {
     return("none")
   }
 }


 legend <- match.arg(legend, c("tiny", "none", "full"))
 return(legend)

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
#'  * `node_val`, value of the variable associated with a node
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
#' @param lwidth Label width relative to available space
#' @param lheight Label height relative to available space
#' @param layout The layout type, either "regular", "flushed" or "proportional". If
#'        "proportional", then the height of each node is proportional to the number
#'        of observations in that node. See [vtree2::add_layout()] for details.
#'        If layout is NA, then it is assumed that the vtree already has a
#'        layout with all necessary columns and no layout is calculated.
#' @param margins numerical vector: top/right/bottom/left margins in
#'        fraction of available space (from 0 to 1).
#' @param show_root If TRUE (default), show the root node (total
#'        population).
#' @param richtext If TRUE, use [gridtext::richtext_grob()] for node
#'        labels, which is much slower, but allows fine control over text
#'        formatting. Default is FALSE.
#' @param dir direction of the tree. One of "lr" (left to right), "rl"
#'        (right to left), "tb" (top to bottom), "bt" (bottom to top).
#'        Default is "lr".
#' @param palettes A character vector with names of RColorBrewer palettes
#'                 to use for the variables. By default these are the
#'                 default arguments to the vtree_palette() function.
#' @param fontsizes Manually select font sizes. A named list with following
#'        optional fields: `nodes`, `var_labels`, `legend_labels`. Each
#'        element can be either a number (font size), or either "fixed" or
#'        "adaptive"; "fixed" means that all objects within the group will
#'        have the same automatically adjusted font, and "adaptive" that
#'        each label will be fit separately.
#' @param lwd line width for use with plotting
#' @param na_fill The color to use for NA values. Default is "white".
#' @param legend If "tiny" (default), only minimal legend with variable
#'        names is shown. If FALSE or "none", no legend is shown. If TRUE or
#'        "full", a full legend with variable level summaries is shown.
#' @seealso [vtree2::mutate.vtree()] for modifying the node data frame, and
#' [vtree2::add_labels()] for adding labels to the nodes. For layout
#' details, see [vtree2::add_layout()].
#' @examples
#' vt <- vtree_from_freqtable(Titanic)
#'
#' # regular plot
#' plot(vt)
#'
#' # full legend
#' plot(vt, legend = "full")
#'
#' # proportional plot
#' plot(vt, layout = "proportional")
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
#' @return A grid::gTree object of class vtree_plot.
#' @importFrom grid gTree gpar gList
#' @family plotting
#' @export
plot.vtree <- function(x, ...) {
  plot_vtree(x, ...)
}

#' @rdname plot.vtree
#' @export
plot_vtree <- function(x,
                      layout = c("regular", "proportional",
                                 "flushed_left", "flushed_right"),
                      palettes = c("Reds", "Blues", "Greens",
                                   "Oranges", "Purples"),
                      na_fill = "white",
                      show_root = TRUE,
                      legend = "tiny",
                      margins = NULL,
                      fontsizes = NULL,
                      richtext = FALSE,
                      lwidth = NA, lheight = NA,
                      lwd = 1,
                      dir = NA) {

  dir <- .normalize_dir(dir, x)
  #dir <- match.arg(dir, c("lr", "rl", "bt", "tb"))

  layout_arg <- match.arg(layout)

  legend <- .normalize_legend(legend)
  margins    <- .normalize_margins(margins, dir, legend)
  fontsizes  <- .normalize_fontsizes(fontsizes, layout_arg)

  grobs <- extract_grobs(x)
  x <- remove_grobs(x)
  x <- .normalize_vtree_for_plotting(x, palettes, na_fill)

  layout <- .normalize_layout(x, layout_arg, lwidth, lheight, show_root, dir)


  layout <- .fit_margins(layout, margins)
  layout <- normalize_layout(layout)


  if(legend == "full") {
    legend <- layout_legend(layout, margins)
  } else if(legend == "tiny") {
    legend <- layout_legend_minimal(layout, margins)
  } else {
    legend <- NULL
  }

  params <- list(
    mar = margins,
    fontsizes = fontsizes,
    richtext = richtext,
    lwd = lwd,
    legend = legend,
    layout_type = layout_arg)

  #layout <- insert_grobs(layout, grobs)
  .make_children(params = params, layout = layout, grobs = grobs)
}
