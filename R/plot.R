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
    x <- add_palette(x, palettes = palettes, na_fill = na_fill)
  }

  if(! "color" %in% colnames(nodes)) {
    x <- mutate(x, color = contrast_color(.data[["fill"]]))
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

# checks and normalizes the var_labels parameter
.normalize_var_labels <- function(cnms, var_labels) {
  if(is.null(var_labels)) {
    return(NULL)
  }

  default <- set_names(cnms)

  if(is.logical(var_labels)) {
    if(var_labels) {
      var_labels <- default
    } else {
      var_labels <- NULL
    }
    return(var_labels)
  }

  if(!is.character(var_labels) || is.null(names(var_labels))) {
    cli_abort(c(x = "var_labels must be a logical or a named character vector"))
  }

  if(any(!names(var_labels) %in% default)) {
    incorrect <- names(var_labels)[!names(var_labels) %in% default]
    cli_abort(c(x = "incorrect var_labels - no such variable(s): {incorrect}"))
  }

  for(n in names(default)) {
    if(!n %in% names(var_labels)) {
      var_labels[n] <- default[n]
    }
  }

  var_labels
}

.normalize_margins <- function(margins, dir, var_labels, legend) {
  show_vl <- !is.null(var_labels)

  # default margins
  if(is.null(margins)) {
    if(dir %in% c("lr", "rl")) {
      margins <- margins %||% list(top = .01, right = .01,
                    bottom = .01 + .05 * show_vl +
                      .15 * legend,
                    left = .01)
    } else {
      margins <- margins %||% list(top = .01, right = .01,
                    bottom = .01, left = .01 + .08 * show_vl)

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

  nodes <- as_tibble(vtree)
  edges <- activate(vtree, "edges") |> as_tibble()

  has_cols <- all(c("x", "y", "width", "height") %in% colnames(nodes)) &&
              all(c("x1", "x2", "y1", "y2") %in% colnames(edges))

  if(inherits(vtree, "vtree_layout") || has_cols) {
    if(!is.na(lwidth) || !is.na(lheight)) {
      cli::cli_warn(
       c(i = "vtree already has a layout; ignoring lwidth and lheight"))
    } else {
      cli::cli_inform(c(i = "vtree already has a layout; using it as is"))
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
#' @param var_labels If TRUE (default), add names of the variables to the
#'        plot. Alternatively, it can be a named character vector where
#'        names are the variable names and values are the labels to be
#'        displayed for those variables. If FALSE or NULL,
#'        no variable labels are shown.
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
#' @param legend If TRUE, a legend is added to the plot. Default is FALSE.
#' @seealso [vtree2::mutate.vtree()] for modifying the node data frame, and
#' [vtree2::add_labels()] for adding labels to the nodes. For layout
#' details, see [vtree2::add_layout()].
#' @examples
#' vt <- vtree_from_freqtable(Titanic)
#'
#' # regular plot
#' plot(vt)
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
#' @export
plot.vtree <- function(x, ...) {
  plot_vtree(x, ...)
}

#' @rdname plot.vtree
#' @export
plot_vtree <- function(x,
                      layout = c("regular", "proportional", "flushed"),
                      palettes = c("Reds", "Blues", "Greens",
                                   "Oranges", "Purples"),
                      na_fill = "white",
                      show_root = TRUE,
                      var_labels = TRUE,
                      legend = FALSE,
                      margins = NULL,
                      fontsizes = NULL,
                      lwidth = NA, lheight = NA,
                      lwd = 1,
                      dir = "lr") {

  dir <- match.arg(dir, c("lr", "rl", "bt", "tb"))

  layout_arg <- match.arg(layout)
  var_labels <- .normalize_var_labels(names(x), var_labels)
  margins    <- .normalize_margins(margins, dir, var_labels, legend)
  fontsizes  <- .normalize_fontsizes(fontsizes, layout_arg)

  x <- .normalize_vtree_for_plotting(x, palettes, na_fill)

  layout <- .normalize_layout(x, layout_arg, lwidth, lheight, show_root, dir)

  dir <- attr(layout, "dir") %||% dir

  layout <- .fit_margins(layout, margins)
  layout <- normalize_layout(layout)

  if(legend) {
    legend <- layout_legend(layout, margins, var_labels)
  } else if(!is.null(var_labels)) {
    legend <- layout_legend_minimal(layout, margins, var_labels)
  } else {
    legend <- NULL
  }

  params <- list(
    mar = margins,
    dir = dir,
    fontsizes = fontsizes,
    lwd = lwd,
    legend = legend,
    layout_type = layout_arg)

  .make_children(params = params, layout = layout)
}
