# flip a layout horizontally
.flip_horiz <- function(layout) {
    mutate(layout, x = 1 - .data[["x"]]) |>
    mutate(x1 = 1 - .data[["x1"]],
           x2 = 1 - .data[["x2"]], .edges=TRUE)
}

# flip a layout vertically
.flip_vert <- function(layout) {
    mutate(layout, y = 1 - .data[["y"]]) |>
    mutate(y1 = 1 - .data[["y1"]],
           y2 = 1 - .data[["y2"]], .edges=TRUE)
}

# transpose a layout
.transpose <- function(layout) {
    mutate(layout, yy = .data[["y"]],
           y = .data[["x"]], x = .data[["yy"]]) |>
    mutate(yy = .data[["width"]],
           width = .data[["height"]],
           height = .data[["yy"]]) |>
    mutate(yy = .data[["full_w"]],
           full_w = .data[["full_h"]],
           full_h = .data[["yy"]]) |>
    mutate(yy = .data[["y1"]], y1 = .data[["x1"]],
           x1 = .data[["yy"]],
           yy = .data[["y2"]], y2 = .data[["x2"]],
           x2 = .data[["yy"]], .edges=TRUE)
}

# scale the layout. I know I am supposed to use the viewport for that, but
# right now this is better for debugging.
.scale <- function(layout, x0, y0, sx, sy) {

  mutate(layout,
         x = x0 + sx * .data[["x"]],
         y = y0 + sy * .data[["y"]],
         width = sx * .data[["width"]],
         height = sy * .data[["height"]]) |>
  mutate(x1 = x0 + sx * .data[["x1"]],
         x2 = x0 + sx * .data[["x2"]],
         y1 = y0 + sy * .data[["y1"]],
         y2 = y0 + sy * .data[["y2"]],
         .edges=TRUE)
}

# for each node, calculate the number of leafs and store in nleafs
.calc_nleafs <- function(vtree) {
  rt <- which(as_tibble(vtree)$node_id == 1)

  vtree |>
    mutate(nleafs = map_bfs_back_int(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        if(nrow(path) == 0) {
          return(1L)
        } else {
          if(sum(unlist(path$result)) == 0) {
            return(1L)
          }
          return(sum(unlist(path$result)))
        }
    })) |>
    group_by(.data[["parent_id"]]) |>
    mutate(offset = lag(cumsum(.data[["nleafs"]]), default = 0)) |>
    ungroup() |>
    mutate(offset_tot = map_bfs_int(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        .N()$offset[node] + sum(.N()$offset[path$node])
    }))
}

.calc_offsets <- function(vtree) {
  rt <- which(as_tibble(vtree)$node_id == 1)

  vtree |>
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

legend_layout <- function(layout, dir="lr", show_root=TRUE) {




}

layout_by_freq <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_offsets(vtree)
  nodes <- as_tibble(layout)

  nlevel <- max(nodes$level) + sr
  totn <- attr(vtree, "N") #
  if(!show_root) {
    totn <- sum(nodes$n[nodes$level == 1])
  }

  if(is.na(lwidth)) {
    lwidth <- .65 / nlevel
    full_w <- 1 / nlevel
  } else {
    lwidth <- lwidth / nlevel
    full_w <- 1 / nlevel
  }

  layout <- layout |>
    mutate(width = lwidth, height = .data[["n"]] / totn) |>
    mutate(full_w = full_w, full_h = .data[["height"]]) |>
    mutate(x = (.data[["level"]] + .5 - 1 + sr)/ nlevel) |>
    mutate(y = 1 - .data[["offset_tot"]] / totn -
           .data[["height"]] / 2) |>
    mutate(shape = "rectangle")

  if(!show_root) {
    layout <- layout |>
      mutate(x = ifelse(.data[["level"]] == 0, NA, .data[["x"]]),
             y = ifelse(.data[["level"]] == 0, NA, .data[["y"]]))
  }


  nodes <- as_tibble(layout)

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]],
           x2 = nodes$x[.data[["to"]]] - nodes$width[.data[["to"]]]/2,
           y1 = nodes$y[.data[["to"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)

  layout
}


layout_regular <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_nleafs(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + sr
  #totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totleafs <- nodes$nleafs[nodes$node_id == 1]
  if(is.na(lheight)) {
    lheight <- .8 / totleafs
    full_h <- 1 / totleafs
  } else {
    lheight <- lheight / totleafs
    full_h <- 1 / totleafs
  }

  if(is.na(lwidth)) {
    lwidth <- .35 / nlevel
    full_w <- 1 / nlevel
  } else {
    lwidth <- lwidth / nlevel
    full_w <- 1 / nlevel
  }

  layout <- layout |>
    mutate(width = lwidth, height = lheight) |>
    mutate(full_w = full_w, full_h = .data[["height"]]) |>
    mutate(x = (.data[["level"]] + .5 - 1 + sr)/ nlevel) |>
    mutate(y = 1 - .data[["offset_tot"]] / totleafs -
               .data[["nleafs"]] / 2 / totleafs) |>
    mutate(shape = "roundrectangle")


  if(!show_root) {
    layout <- layout |>
      mutate(x = ifelse(.data[["level"]] == 0, NA, .data[["x"]]),
             y = ifelse(.data[["level"]] == 0, NA, .data[["y"]]))
  }

  nodes <- as_tibble(layout)

  if(dir %in% c("tb", "bt")) {
    dx <- lheight
  } else {
    dx <- lwidth
  }
  dx <- lwidth

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]] + dx/2,
           x2 = nodes$x[.data[["to"]]] - dx/2,
           y1 = nodes$y[.data[["from"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)


   layout
}

layout_flushed <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_nleafs(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + sr
  #totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totleafs <- nodes$nleafs[nodes$node_id == 1]
  if(is.na(lheight)) {
    lheight <- .8 / totleafs
    full_h <- 1 / totleafs
  } else {
    lheight <- lheight / totleafs
    full_h <- 1 / totleafs
  }

  if(is.na(lwidth)) {
    lwidth <- .35 / nlevel
    full_w <- 1 / nlevel
  } else {
    lwidth <- lwidth / nlevel
    full_w <- 1 / nlevel
  }

  layout <- layout |>
    mutate(width = lwidth, height = lheight) |>
    mutate(full_w = full_w, full_h = .data[["height"]]) |>
    mutate(x = (.data[["level"]] + .5 - 1 + sr)/ nlevel) |>
    mutate(y = 1 - .data[["offset_tot"]] / totleafs - lheight / 2) |>
    mutate(shape = "roundrectangle")

  nodes <- as_tibble(layout)

  if(dir %in% c("tb", "bt")) {
    dx <- lheight
  } else {
    dx <- lwidth
  }
  dx <- lwidth

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]] + dx/2,
           x2 = nodes$x[.data[["to"]]] - dx/2,
           y1 = nodes$y[.data[["from"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)


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
#'  height, and the nodes are evenly spaced along the y-axis.
#' - "proportional" - a layout in which the height of each node is proportional
#' to the number of observations in that node, and the nodes are spaced along
#' the y-axis according to their cumulative frequencies.
#'
#' @section Custom layouts:
#'
#' You can also provide a custom layout function. The function should take a
#' the following arguments: vtree, dir, lwidth, lheight, show_root. It
#' should return a vtree object with following additional columns in the
#' nodes data frame:
#'
#' - x, y: the coordinates of the center of the node
#' - width, height: the width and height of the node
#' - full_w, full_h: the width and height of the node including the margins
#'
#' In addition, it can have the "shape" column which specifies the shape of
#' the node to use. It can be "rectangle" or "roundrectangle". If not
#' specified, the default is "roundrectangle".
#'
#' In the edge data frame, the following additional columns should be added:
#' - x1, y1: the coordinates of the start of the edge
#' - x2, y2: the coordinates of the end of the edge
#'
#' @param vtree A vtree object
#' @param layout The layout type, either "regular" or "proportional"
#' @param layout_func A custom layout function.
#' @param dir The direction of the layout, either "lr" (left to right), "rl"
#'            (right to left), "tb" (top to bottom), or "bt" (bottom to top)
#' @param lwidth,lheight The width and height of the nodes, as the fraction
#'        of the available space. If NA, a sensible preset is chosen.
#' @param show_root Whether to show the root node in the layout.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' layout(vt, layout = "regular", dir = "lr") |> tibble::as_tibble()
#' @return an object of class vtree with additional columns in the nodes
#'         and edges data frames
#' @export
layout <- function(vtree,
                   layout = c("regular", "proportional",
                              "flushed", "precomputed"),
                   layout_func = NULL,
                   dir="lr",
                   lwidth=NA, lheight=NA,
                   show_root=TRUE) {


  if(!is.null(layout_func)) {
    layout <- "custom"
  } else {
    layout <- match.arg(layout)
  }

  if(layout == "precomputed") {
    cli::cli_inform(c(i = paste("layout is 'precomputed',",
                      "assuming that the vtree already has a layout")))
    return(vtree)
  }

  if(layout == "regular") {
    layout_func <- layout_regular
  } else if(layout == "proportional") {
    layout_func <- layout_by_freq
  } else if(layout == "flushed") {
    layout_func <- layout_flushed
  }

  if(is.null(layout_func)) {
    cli_abort(c(x = "layout_func must be provided for custom layout"))
  }

  layout <- layout_func(vtree, dir=dir,
                           lwidth=lwidth, lheight=lheight,
                           show_root=show_root)

  layout
}
