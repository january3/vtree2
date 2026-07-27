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


layout_by_freq <- function(vtree, dir="lr", lwidth=NA, lheight=NA) {

  layout <- .calc_offsets(vtree)
  nodes <- as_tibble(layout)

  nlevel <- max(nodes$level) + 1
  totn <- attr(vtree, "N") #

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
    mutate(x = (.data[["level"]] + .5)/ nlevel) |>
    mutate(y = 1 - .data[["offset_tot"]] / totn -
           .data[["height"]] / 2)

  nodes <- as_tibble(layout)

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]],
           x2 = nodes$x[.data[["to"]]] - nodes$width[.data[["to"]]]/2,
           y1 = nodes$y[.data[["to"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)

  layout
}


layout_regular <- function(vtree, dir="lr", lwidth=NA, lheight=NA) {

  layout <- .calc_nleafs(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + 1
  #totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totleafs <- nodes$nleafs[nodes$node_id == 1]
  print(totleafs)

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

 #layout <- layout |>
 #  mutate(x = (.data[["level"]] + .5)/ nlevel) |>
 #  group_by(.data[["level"]]) |>
 #  mutate(y = (cumsum(.data[["nleafs"]]) - .data[["nleafs"]] / 2)/
 #         totleafs) |>
 #  ungroup() |>
 #  mutate(full_h = full_h, full_w = full_w) |>
 #  mutate(width = lwidth, height = lheight)

  layout <- layout |>
    mutate(width = lwidth, height = lheight) |>
    mutate(full_w = full_w, full_h = .data[["height"]]) |>
    mutate(x = (.data[["level"]] + .5)/ nlevel) |>
    mutate(y = 1 - .data[["offset_tot"]] / totleafs -
               .data[["nleafs"]] / 2 / totleafs)


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


