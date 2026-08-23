# the proportional layout
layout_by_freq <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           show_root=TRUE) {

  layout <- .calc_offsets_from_sizes(vtree, .var="n")
  nodes <- as_tibble(layout)

  totn <- get_n(vtree)

  if(!show_root) {
    totn <- sum(nodes$n[nodes$level == 1])
  }

  if(is.na(lwidth)) {
    lwidth <- .65
  }

  layout <- .apply_varspace(layout, varspace, varsize, lwidth)

  layout <- layout |>
    mutate(height = .data[["n"]] / totn) |>
    mutate(full_h = .data[["height"]]) |>
    mutate(y = 1 - .data[["offset_tot"]] / totn -
           .data[["height"]] / 2) |>
    mutate(shape = "rectangle")

  if(!show_root) {
    layout <- .hide_root(layout)
  }

  nodes <- as_tibble(layout)
  layout <- .add_edge_positions(layout, horiz=TRUE)

  layout
}

# the regular layout
layout_regular <- function(vtree,
                           dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           flushed=NA,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_offsets_from_sizes(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + sr
  #totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totleafs <- nodes$size[nodes$node_id == 1]
  if(is.na(lheight)) {
    lheight <- .8 / totleafs
  } else {
    lheight <- lheight / totleafs
  }

  if(is.na(lwidth)) {
    lwidth <- .35
  }

  # calculate the x positions and label widths
  layout <- .apply_varspace(layout, varspace, varsize, lwidth)

  layout <- layout |>
    mutate(height = lheight) |>
    mutate(full_h = 1 / totleafs) |>
    mutate(y = 1 - .data[["offset_tot"]] / totleafs) |>
    mutate(shape = "roundrectangle")

  if(!is.na(flushed))  {
    if(flushed == "left") {
      layout <- mutate(layout, y = .data[["y"]] - lheight/2)
    } else if(flushed == "right") {
      layout <- mutate(layout, y = .data[["y"]] -
                       .data[["size"]] / totleafs + lheight/2)
    }
  } else {
    layout <- mutate(layout, y = .data[["y"]] - .data[["size"]] / 2 / totleafs)
  }

  if(!show_root) {
    layout <- .hide_root(layout)
  }

  layout <- .add_edge_positions(layout)
  layout
}

# the tight layout
layout_tight <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_offsets_from_sizes(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + sr
  totleafs <- nodes$size[nodes$node_id == 1]

  if(is.na(lheight)) {
    lheight <- .9
  }

  if(is.na(lwidth)) { lwidth <- .35 }

  layout <- .calc_full_hw_from_label(layout, dir)
  layout <- .calc_offsets_from_sizes(layout, .var = "full_h")
  layout <- .calc_xpos_from_fullw(layout)
  # calculate the x positions and label widths
  #layout <- .apply_varspace(layout, varspace, varsize, lwidth)

  layout <- layout |>
    mutate(width = .data[["full_w"]] * lwidth) |>
    mutate(height = .data[["full_h"]] * lheight) |>
    mutate(y = 1 - .data[["offset_tot"]]) |>
    mutate(y = .data[["y"]] - .data[["size"]]/2) |>
    mutate(shape = "roundrectangle")


  if(!show_root) {
    layout <- .hide_root(layout)
  }

  layout <- .add_edge_positions(layout)
  layout
}

layout_flushed_left <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           show_root=TRUE) {

  layout_regular(vtree, dir, lwidth, lheight,
                           varspace,
                           varsize,
                           flushed = "left",
                           show_root)

}


layout_flushed_right <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           show_root=TRUE) {

  layout_regular(vtree, dir, lwidth, lheight,
                           varspace,
                           varsize,
                           flushed = "right",
                           show_root)

}

.ensure_layout_cols <- function(layout) {

  ensure_node_cols(layout, c("x", "y", "width", "height"))
  ensure_edge_cols(layout, c("x1", "y1", "x2", "y2"))

  if(!"full_w" %in% nodecols(layout)) {
    layout <- mutate(layout, full_w = .data[["width"]])
  }

  if(!"full_h" %in% nodecols(layout)) {
    layout <- mutate(layout, full_h = .data[["height"]])
  }

  if(!"shape" %in% nodecols(layout)) {
    layout <- mutate(layout, shape = "roundrectangle")
  }

  if(!"height" %in% edgecols(layout)) {
    layout <- mutate(layout, height = NA, .edges=TRUE)
  }

  if(!"width" %in% edgecols(layout)) {
    layout <- mutate(layout, width = NA, .edges=TRUE)
  }

  layout
}

#' Prepare a layout for plotting a vtree
#'
#' A layout function for vtree adds several columns to both the nodes and
#' edges data frame which specify the positions and sizes of the nodes and
#' edges in the plot.
#'
#' The builtin layouts are as follows:
#' - "regular" - a regular layout in which all nodes have the same width and
#'  height, and the nodes are evenly spaced along the y-axis;
#' - "flushed_left" and "flushed_right" are the same as "regular", but
#' flushed to one side (left or right in horizontal plots, and top / bottom
#' in the vertical plots);
#' - "proportional" - a layout in which the height of each node is proportional
#' to the number of observations in that node, and the nodes are spaced along
#' the y-axis according to their cumulative frequencies.
#'
#' @section Custom layouts:
#'
#' You can also provide a custom layout function. The function should take
#' a the following arguments: vtree, dir, lwidth, lheight, varspace,
#' varsize, show_root. It must return a vtree object with following
#' additional columns in the nodes data frame:
#'
#' - x, y: the coordinates of the center of the node
#' - width, height: the width and height of the node
#'
#' In addition, it can have the "shape" column which specifies the shape of
#' the node to use. It can be "rectangle" or "roundrectangle". If not
#' specified, the default is "roundrectangle".
#'
#' The function should be called from add_layout(), such that the layout is
#' transformed according to the dir argument and gets converted to the
#' vtree_layout class.
#'
#' In the edge data frame, the following additional columns should be added:
#' - x1, y1: the coordinates of the start of the edge
#' - x2, y2: the coordinates of the end of the edge
#'
#' @param vtree A vtree object
#' @param varspace named numerical vector with relative spaces for each
#'        variable. The names must include all variables present in the
#'        tree plus "root". Space describes the total amount of horizontal
#'        or vertical (for vertical layouts) space allocated to a variable.
#' @param varsize named numerical vector with relative sizes for each
#'        variable. The names must include all variables present in the
#'        tree plus "root". Size describes the actual horizontal or
#'        vertical (for vertical layouts) size of the nodes. It is
#'        cumulative with lwidth.
#' @param layout The layout type, "regular", "tight", "flushed_left",
#'        "flushed_right" or "proportional"
#' @param layout_func A custom layout function.
#' @param dir The direction of the layout, either "lr" (left to right), "rl"
#'            (right to left), "tb" (top to bottom), or "bt" (bottom to top)
#' @param lwidth,lheight The width and height of the nodes, as the fraction
#'        of the available space. If NA, a sensible preset is chosen.
#' @param show_root Whether to show the root node in the layout.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' add_layout(vt, layout = "regular", dir = "lr") |> tibble::as_tibble()
#' # the layout parameter from plot() is passed on to add_layout()
#' plot(vt, layout="proportional")
#' plot(vt, layout="flushed_right", dir="tb")
#' @return an object of class vtree with additional columns in the nodes
#'         and edges data frames
#' @export
add_layout <- function(vtree,
                   layout = c("regular", "proportional", "tight",
                              "flushed_left", "flushed_right", "sankey"),
                   layout_func = NULL,
                   dir="lr",
                   lwidth=NA, lheight=NA,
                   varspace = NULL,
                   varsize = NULL,
                   show_root=TRUE) {

  ensure_vtree(vtree)
  if(!is.null(layout_func)) {
    layout <- "custom"
  } else {
    layout <- match.arg(layout)
  }

  grobs <- extract_grobs(vtree)
  vtree <- remove_grobs(vtree)

  if(layout == "tight" && !"label" %in% nodecols(vtree)) {
    cli_abort(c(x=
        "tight layout requires labels.",
      i = "Use `add_labels()` to add labels to the vtree."))
  }

  varspace <- .normalize_varspace(varspace, vtree, show_root)
  varsize  <- .normalize_varsize(varsize, varspace, vtree)

  if(dir %in% c("tb", "bt")) {
    .t <- lwidth
    lwidth <- lheight
    lheight <- .t
  }

  layout_methods <- list(
    regular = layout_regular,
    proportional = layout_by_freq,
    tight = layout_tight,
    flushed_left = layout_flushed_left,
    flushed_right = layout_flushed_right,
    sankey = layout_sankey
  )

  if(is.null(layout_func)) {
    layout_func <- layout_methods[[layout]]
  }

  layout_arg  <- layout

  layout <- layout_func(vtree, dir=dir,
                           lwidth=lwidth, lheight=lheight,
                           varspace = varspace,
                           varsize = varsize,
                           show_root=show_root)
  layout <- .ensure_layout_cols(layout)

  if(dir == "rl") {
    layout <- .flip_horiz(layout)
  }

  if(dir %in% c("bt", "tb")) {
    layout <- .transpose(layout)
    layout <- .flip_horiz(layout)
  }

  if(dir == "tb") {
    layout <- .flip_vert(layout)
  }


  layout <- insert_grobs(layout, grobs)

  as_vtree_layout(layout, dir, show_root, layout_arg)
}

## not exported right now
## @rdname add_layout
## @export
as_vtree_layout <- function(layout, dir, show_root, layout_arg) {
  ensure_vtree(layout)
  layout <- set_dir(layout, dir)
  layout <- set_layout_arg(layout, layout_arg)
  layout <- set_show_root(layout, show_root)
  class(layout) <- c("vtree_layout", class(layout))

  layout
}
