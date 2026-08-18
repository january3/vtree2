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

# for each node, calculate the size of the follow up nodes and the offsets
# size = variable .var
.calc_offsets_from_sizes <- function(vtree, .var) {
  rt <- which(as_tibble(vtree)$node_id == 1)

  nodes <- as_tibble(vtree)
  vtree <- vtree |>
    mutate(size = tidygraph::map_bfs_back_dbl(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        if(nrow(path) == 0) {
          return(nodes[[.var]][node])
        } else {
          if(sum(unlist(path$result)) == 0) {
            return(nodes[[.var]][node])
          }
          return(sum(unlist(path[["result"]])))
        }
    })) |>
    group_by(.data[["parent_id"]]) |>
    mutate(offset = lag(cumsum(.data[["size"]]), default = 0)) |>
    ungroup()

  nodes <- as_tibble(vtree)
  vtree |>
    mutate(offset_tot = tidygraph::map_bfs_dbl(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        nodes$offset[node] + sum(nodes$offset[path$node])
    }))
}

# calculate the offsets for proportional layout
.calc_offsets <- function(vtree, .var="n") {
  rt <- which(as_tibble(vtree)$node_id == 1)

  vtree <- vtree |>
    group_by(.data[["parent"]]) |>
    mutate(offset = lag(cumsum(.data[[.var]]), default = 0)) |>
    ungroup()

  nodes <- as_tibble(vtree)

  vtree |>
    mutate(offset_tot = tidygraph::map_bfs_dbl(
      root = rt,
      mode = "out",
      .f = \(node, path, ...) {
        nodes$offset[node] + sum(nodes$offset[path$node])
    }))
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

# calculate the x positions in a layout from the full_w widths
.calc_xpos_from_fullw <- function(layout) {

  foo <- layout |>
    as_tibble() |>
    group_by(.data[["level"]]) |>
    summarize(maxw = max(.data[["full_w"]]),
              node_col = first(.data[["node_col"]]))

  varspace <- set_names(foo[["maxw"]], foo[["node_col"]])

  xpos <- cumsum(lag(varspace, 1, default=0)) + varspace/2
  names(xpos) <- names(varspace)

  layout <- layout |>
    mutate(x = xpos[ .data[["node_col"]] ])

  layout
}

# calculate full_w / width relative to max number of chars in a label
.calc_fullw_from_charwidths <- function(layout) {

  ret <- layout |>
    group_by(.data[["level"]]) |>
    mutate(maxchr = max(.data[["full_w"]])) |>
    mutate(fracchr = .data[["maxchr"]] / n()) |>
    ungroup() |>
    mutate(full_w = .data[["full_w"]] / sum(.data[["fracchr"]])) |>
    select(-all_of(c("fracchr", "maxchr")))

  ret
}

# calculate full_h/height relative to the number of lines in the label
.calc_fullh_from_lineheight <- function(layout) {

  ret <- layout |>
    group_by(.data[["level"]]) |>
    mutate(totlines = sum(.data[["full_h"]])) |>
    ungroup() |>
    mutate(full_h = .data[["full_h"]] / max(.data[["totlines"]])) |>
    select(-all_of("totlines"))

  ret
}

.calc_full_hw_from_label <- function(layout, dir="lr",
                                     add_c = 1, add_l = 1) {

  if(dir %in% c("tb", "bt")) {
    layout <- layout |>
      mutate(full_h = chr_size(.data[["label"]]) + add_c) |>
      mutate(full_w = nlines(.data[["label"]]) + add_l)
  } else {
    layout <- layout |>
      mutate(full_w = chr_size(.data[["label"]]) + add_c) |>
      mutate(full_h = nlines(.data[["label"]]) + add_l)
  }

  layout <- layout |>
    .calc_fullw_from_charwidths() |>
    .calc_fullh_from_lineheight()

  layout
}
