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
    group_by(.data[["parent"]]) |>
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
    lwidth <- .35 / nlevel
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
           .data[["height"]] / 2)

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
               .data[["nleafs"]] / 2 / totleafs)


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
#' @param vtree A vtree object
#' @param layout The layout type, either "regular" or "proportional"
#' @param dir The direction of the layout, either "lr" (left to right), "rl"
#'            (right to left), "tb" (top to bottom), or "bt" (bottom to top)
#' @param lwidth,lheight The width and height of the nodes, as the fraction
#'        of the available space. If NA, a sensible preset is chosen.
#' @param show_root Whether to show the root node in the layout.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' layout(vt, layout = "regular", dir = "lr") |> as_tibble()
#' @export
layout <- function(vtree,
                   layout = c("regular", "proportional"),
                   dir="lr",
                   lwidth=NA, lheight=NA,
                   show_root=TRUE) {


  layout <- match.arg(layout)

  if(layout == "regular") {
    layout <- layout_regular(vtree, dir=dir,
                             lwidth=lwidth, lheight=lheight,
                             show_root=show_root)
  } else {
    layout <- layout_by_freq(vtree, dir=dir,
                             lwidth=lwidth, lheight=lheight,
                             show_root=show_root)
  }

  layout
}
