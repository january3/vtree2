.fit_margins <- function(layout, margins) {

  if(is.null(margins)) {
    return(layout)
  }

  layout <- .scale(layout,
                   margins$left,
                   margins$bottom,
                   1 - (margins$left + margins$right),
                   1 - (margins$bottom + margins$top))

  layout
}


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

  vtree <- vtree |>
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
    ungroup()

  nodes <- as_tibble(vtree)
  vtree |>
    mutate(offset_tot = map_bfs_int(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        nodes$offset[node] + sum(nodes$offset[path$node])
    }))
}

# calculate the offsets for proportional layout
.calc_offsets <- function(vtree) {
  rt <- which(as_tibble(vtree)$node_id == 1)

  vtree <- vtree |>
    group_by(.data[["parent"]]) |>
    mutate(offset = lag(cumsum(.data[["n"]]), default = 0)) |>
    ungroup()

  nodes <- as_tibble(vtree)

  vtree |>
    mutate(offset_tot = map_bfs_int(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        nodes$offset[node] + sum(nodes$offset[path$node])
    }))
}

# vertical legend arrangement
.legend_vertical <- function(legend, titles, maxpos, margins) {

  legend <- legend |>
    mutate(height = .data[["full_h"]] / maxpos) |>
    mutate(x = margins$left / 2) |>
    mutate(width = .8 * margins$left) |>
    mutate(y = .data[["y"]] - .data[["full_h"]] / 2 +
           (maxpos - .data[["pos"]] - 1.5) * .data[["height"]])

  titles <- titles |>
    mutate(height = 2 * .data[["full_h"]] / maxpos) |>
    mutate(x = margins$left / 2) |>
    mutate(width = .8 * margins$left) |>
    mutate(y = .data[["y"]] + maxpos * .data[["height"]]/4 -
           2*.data[["height"]]/3)

  list(levels=legend, titles=titles)
}

# horizontal legend arrangements
.legend_horizontal <- function(legend, titles, maxpos, margins) {
  legend <- legend |>
    mutate(x = .data[["x"]],
           y = margins$bottom -
             (.data[["pos"]] + 1) * margins$bottom / maxpos) |>
    mutate(height = .9 * margins$bottom / maxpos) |>
    mutate(width = .data[["width"]])

  maxy <- max(legend[["y"]])

  titles <- titles |>
    mutate(height = .9 * margins$bottom / maxpos) |>
    mutate(y = maxy + .data[["height"]] * 1.1) |>
    mutate(height = .data[["height"]] * 2)

  list(levels=legend, titles=titles)
}

# use the aliases associated with the layout to replace the labels in the
# legend titles.
.use_alias_col <- function(df, layout) {
  alias <- get_alias_attr(layout)
  if(is.null(alias)) {
    return(df)
  }

  alias <- alias$col

  df <- df |>
    mutate(label = map_chr(.data[["node_col"]],
                           \(col) alias[[col]] %||% col))
  df
}

# prepare a summary using the aliases
#' @importFrom purrr map_chr map2_chr
.layout_summary <- function(layout) {

  ret <- summary(layout)
  nodes <- as_tibble(layout)
  if(!
     (all(nodes[-1, ][["node_col"]] %in% ret[["node_col"]]) &&
      all(nodes[-1, ][["node_val"]] %in% ret[["node_val"]]))) {
    cli_abort(c(x="corrupted vtree object: summary and node table not compatible"))
  }

  c_alias <- get_alias_attr(layout, "col")

  if(!is.null(c_alias)) {
    ret[["col_alias"]] <- map_chr(ret[["node_col"]],
                                 \(col) c_alias[[col]] %||% col)
  } else {
    ret[["col_alias"]] <- ret[["node_col"]]
  }

  v_alias <- get_alias_attr(layout, "val")
  if(!is.null(v_alias)) {
    ret[["val_alias"]] <- map2_chr(ret[["node_col"]], ret[["node_val"]],
                                   \(col, val) if(is.na(val)) {
                                     v_alias[["NAs"]] %||% "NA"
                                   } else {
                                     v_alias[[col]][val] %||% val
                                   })
  } else {
    ret[["val_alias"]] <- ret[["node_val"]]
  }

  ret[["label"]] <- sprintf("%s: %d (%.0f%%)",
                            ret[["val_alias"]],
                            ret[["count"]],
                            ret[["freq"]] * 100)

  ret
}

# create a layout for the legend.
layout_legend <- function(layout, margins) {

  dir <- attr(layout, "dir")

  #req_cols <- c("x", "y", "width", "height", "shape", "fill", "label"))
  cnms <- names(layout)

  pospar <- as_tibble(layout) |>
    filter(.data[["node_key"]] != "node_1") |>
    distinct(pick("node_col"), .keep_all = TRUE) |>
    select(all_of(c("node_col", "level", "x", "y", "width", "height", "full_w",
                    "full_h", "shape")))

  lvls <- levels(layout)
  pal <- attr(layout, "palette")

  if(is.null(pal)) {
    cli::cli_inform(c(i="palette attribute is NULL",
               "legend will be black and white"))
    pals_color <- NULL
    pals_fill <- NULL
    na_text <- "black"
    na_fill <- "white"
    pals_vt <- NULL
    pals_vf <- NULL
  } else {
    pals_color <- pal$color$scale %||% NULL
    pals_fill <- pal$fill$scale %||% NULL
    na_text <- pal$color$na %||% "black"
    na_fill <- pal$fill$na %||% "white"
    pals_vt <- pal$color$vars %||% NULL
    pals_vf <- pal$fill$vars %||% NULL
  }

  summaries <- .layout_summary(layout) |>
    group_by(.data[["node_col"]]) |>
    mutate(pos = 1:n()) |>
    ungroup() |>
    filter(.data[["count"]] != 0) |>
    mutate(fill = .get_vals(.data[["node_col"]],
                            .data[["node_val"]],
                            pals_fill, na_fill) %||% na_fill) |>
    mutate(color = .get_vals(.data[["node_col"]],
                             .data[["node_val"]],
                             pals_color, na_text) %||% na_text)


  legend <- merge(pospar, summaries, by = "node_col", all.y=TRUE) |>
      mutate(node_key = paste0("legend_", 1:n())) |>
      mutate(label_type = "var_level_label") |>
      filter(!is.na(.data[["x"]]))

  maxpos <- max(legend[["pos"]]) + 2

  titles <- legend |>
    group_by(.data[["node_col"]]) |>
    dplyr::slice(1) |>
    ungroup() |>
    mutate(node_key = paste0("legend_title_", 1:n())) |>
    mutate(label = .data[["col_alias"]]) |>
    mutate(label_type = "var_name_label") |>
    mutate(shape = NA)

  if(is.null(pals_vt) || is.null(pals_vf)) {
    titles$color <- "black"
    titles$fill <- "white"
  } else {
    titles$color <- pals_vt[ titles$node_col ]
    titles$fill  <- pals_vf[ titles$node_col ]
  }

  if(dir %in% c("tb", "bt")) {
    legend <- .legend_vertical(legend, titles, maxpos, margins)
  } else {
    legend <- .legend_horizontal(legend, titles, maxpos, margins)
  }

  legend
}

# just the variable titles
layout_legend_minimal <- function(layout, margins) {

  dir <- attr(layout, "dir")

  nodes <- as_tibble(layout) |>
    distinct(.data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1) |>
    mutate(node_key = paste0("legend_title_", 1:n())) |>
    mutate(label = .data[["node_col"]]) |>
    mutate(label_type = "var_name_label") |>
    mutate(shape = NA)

  if(is.null(attr(layout, "palette"))) {
    cli::cli_inform(c(i="palette attribute is NULL",
               "legend will be black and white"))
    pals_vt <- NULL
    pals_vf <- NULL
  } else {
    pals_vt <- attr(layout, "palette")$color$vars
    pals_vf <- attr(layout, "palette")$fill$vars
  }

  if(!is.null(pals_vf) & !is.null(pals_vt)) {
    nodes$color <- pals_vt[ nodes[["node_col"]] ]
    nodes$fill  <- pals_vf[ nodes[["node_col"]] ]
  } else {
    nodes$color <- "black"
    nodes$fill <- "white"
  }

  if(dir %in% c("bt", "tb")) {
    nodes$width <- margins$left
    nodes$height <- nodes$full_h[1]
    nodes$x <- margins$left / 2
  } else {
    nodes$width <- nodes$full_w[1]
    nodes$height <- margins$bottom
    nodes$y <- margins$bottom / 2
  }

  nodes <- .use_alias_col(nodes, layout)
  list(titles = nodes)
}

# the proportional layout
layout_by_freq <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_offsets(vtree)
  nodes <- as_tibble(layout)

  totn <- attr(vtree, "N") #

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

# calculate the x positions of the nodes based on the variable space, size
# and lwidth.
.apply_varspace <- function(layout, varspace, varsize, lwidth) {

  nlevel <- length(varspace)

  xpos <- cumsum(lag(varspace, 1, default=0)) + varspace/2
  names(xpos) <- names(varspace)

  layout <- layout |>
    mutate(full_w = varspace[.data[["node_col"]]],
           width = varspace[.data[["node_col"]]] *
                   varsize[.data[["node_col"]]] * lwidth) |>
    mutate(x = xpos[.data[["node_col"]]])

  layout
}

# the regular layout
layout_regular <- function(vtree, dir="lr",
                           lwidth=NA, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           flushed=NA,
                           show_root=TRUE) {

  sr <- as.integer(show_root)

  layout <- .calc_nleafs(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + sr
  #totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totleafs <- nodes$nleafs[nodes$node_id == 1]
  if(is.na(lheight)) {
    lheight <- .8 / totleafs
  } else {
    lheight <- lheight / totleafs
  }

  if(is.na(lwidth)) {
    lwidth <- .35
  }

  if(is.null(varspace)) {
    die("varspace is NULL")
  }

  if(nlevel != length(varspace)) {
    message(nlevel, "!=", length(varspace))
    die("nlevel" != length(varspace))
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
                       .data[["nleafs"]] / totleafs + lheight/2)
    }
  } else {
    layout <- mutate(layout, y = .data[["y"]] - .data[["nleafs"]] / 2 / totleafs)
  }

  if(!show_root) {
    layout <- layout |>
      mutate(x = ifelse(.data[["level"]] == 0, NA, .data[["x"]]),
             y = ifelse(.data[["level"]] == 0, NA, .data[["y"]]))
  }

  nodes <- as_tibble(layout)

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]],# + dx/2,
           x2 = nodes$x[.data[["to"]]] - nodes$width[.data[["to"]]]/2,
           y1 = nodes$y[.data[["from"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)


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


# calculate the actual sizes for the variables
.normalize_varsize <- function(varsize, varspace, layout) {
  vars <- unique(as_tibble(layout)$node_col)

  vars <- names(varspace)

  if(is.null(varsize)) {
    varsize <- rep(1, length(vars))
    names(varsize) <- vars
    return(varsize)
  }

  if(!all(vars %in% names(varsize))) {
    missing <- vars[ !vars %in% names(varsize) ]
    cli_abort(c(x="varsize lacks required names: {missing}"))
  }

  if(!is.numeric(varsize)) {
    die("varsize argument must be numeric")
  }

  varsize <- varsize[vars]

  if(!all(varsize <= 1)) {
    cli_abort(
      c(x = "varsize must be less than or equal to 1 for all variables",
        i = "varsize: {varsize}"))
  }

  varsize
}

.normalize_varspace <- function(varspace, layout, show_root) {
  vars <- unique(as_tibble(layout)$node_col)

  if(!show_root) {
    vars <- vars[ vars != "root" ]
  }

  if(is.null(varspace)) {
    varspace <- rep(1/length(vars), length(vars))
    names(varspace) <- vars
    return(varspace)
  }

  if(!all(vars %in% names(varspace))) {
    missing <- vars[ !vars %in% names(varspace) ]
    cli_abort(c(x="varspace lacks required names: {missing}"))
  }

  if(!is.numeric(varspace)) {
    die("varspace argument must be numeric")
  }

  varspace <- varspace[vars]
  varspace <- varspace / sum(varspace)

  varspace
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
#' @param layout The layout type, either "regular" or "proportional"
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
                   layout = c("regular", "proportional",
                              "flushed_left", "flushed_right"),
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

  varspace <- .normalize_varspace(varspace, vtree, show_root)
  varsize  <- .normalize_varsize(varsize, varspace, vtree)

  if(dir %in% c("tb", "bt")) {
    .t <- lwidth
    lwidth <- lheight
    lheight <- .t
  }

  if(layout == "regular") {
    layout_func <- layout_regular
  } else if(layout == "proportional") {
    layout_func <- layout_by_freq
  } else if(layout == "flushed_left") {
    layout_func <- layout_flushed_left
  } else if(layout == "flushed_right") {
    layout_func <- layout_flushed_right
  }

  if(is.null(layout_func)) {
    cli_abort(c(x = "layout_func must be provided for custom layout"))
  }

  layout <- layout_func(vtree, dir=dir,
                           lwidth=lwidth, lheight=lheight,
                           varspace = varspace,
                           varsize = varsize,
                           show_root=show_root)

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

  as_vtree_layout(layout, dir, show_root)
}

## not exported right now
## @rdname add_layout
## @export
as_vtree_layout <- function(layout, dir, show_root) {
  ensure_vtree(layout)
  attr(layout, "dir") <- dir
  attr(layout, "show_root") <- show_root
  class(layout) <- c("vtree_layout", class(layout))

  layout
}
