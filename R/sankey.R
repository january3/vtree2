#' @importFrom purrr map_int
.node_levels <- function(col, val, levels) {

  vapply(seq_along(col),
         \(i) {
           if(col[i] %in% names(levels)) {
             match(val[i], levels[[col[i]]])
           } else {
             NA_integer_
           }
         }, integer(1))

}

#' @importFrom dplyr desc join_by left_join slice arrange
#' @importFrom cli cli_warn
layout_sankey <- function(vtree, dir="lr",
                          lwidth=.4, lheight=NA,
                           varspace=NULL,
                           varsize=NULL,
                           show_root=TRUE) {

  totn <- attr(vtree, "N") #

  if(is.na(lwidth)) {
    lwidth <- .4
  }

  nodes <- as_tibble(vtree) |>
   #select(all_of(c("path", "parent_id",
   #                "level", "node_col", "node_val", "n"))) |>
    mutate(node_level = .node_levels(
                                     .data[["node_col"]],
                                     .data[["node_val"]],
                                     levels(vtree))) |>
    mutate(order = 1:n()) |>
    arrange(.data[["node_level"]]) |>
    mutate(fooord = 1:n()) |>
    mutate(parent_fooord =
            .data[["fooord"]][match(.data[["parent_id"]], .data[["node_id"]])]) |>
    arrange(.data[["node_level"]], .data[["parent_fooord"]]) |>
    mutate(fooord = 1:n()) |>
    mutate(parent_fooord =
            .data[["fooord"]][match(.data[["parent_id"]], .data[["node_id"]])]) |>
    arrange(.data[["node_level"]], .data[["parent_fooord"]]) |>
    slice(n():1) |>
    group_by(.data[["level"]]) |>
    mutate(offset = cumsum(lag(.data[["n"]], default=0))) |>
    mutate(y = (.data[["offset"]] + .data[["n"]]/2) / totn) |>
    mutate(height = .data[["n"]] / totn) |>
    ungroup() |>
    mutate(po = 1:n()) |> # plotting order
    arrange(.data[["order"]])

  # this rather complicated bit is cutting off empty space to the left and
  # right of the nodes.
  # The empty space is equal to (1 - lwidth)/2 on each
  # side, so each of the levels on the edge (left and right) occupy only
  # lwidth + (1-lwidth)/2 of the space, while the (nlevs - 2) levels in
  # between occupy full width (1). A complicated formula emerges which can
  # then be simplified a lot.

  nlevs <- max(nodes$level) + 1
  fct <- 1 / (nlevs + lwidth - 1)

  nodes <- nodes |>
    mutate(x = fct * (.data[["level"]] + .5)) |>
    mutate(width = fct * lwidth) |>
    mutate(full_w = fct) |>
    mutate(full_h = .data[["height"]]) |>
    mutate(x = .data[["x"]] - fct * (1 - lwidth) / 2)

  #print(nodes |> select(path, width, full_w, x, y), n=100)

  layout <- mutate(vtree,
                  shape = "rectangle",
                  x = nodes$x,
                  y = nodes$y,
                  width = nodes$width,
                  height = nodes$height,
                  full_w = nodes$full_w,
                  full_h = nodes$full_h)

  edges <- activate(layout, "edges") |> as_tibble() |>
           mutate(ord = 1:n())
  nsel <- select(nodes, any_of(c("node_col", "node_val", "order", "po", "x",
                                 "height", "width", "level", "node_level")))

  edges <- left_join(edges, nsel, by=join_by("from" == "order")) |>
           left_join(nsel, by=join_by("to" == "order"),
                     suffix=c(".from", ".to"))

  if(!"height" %in% colnames(edges)) {
    if("n" %in% colnames(edges)) {
      edges$height <- edges[["n"]]/totn
    } else {
      edges$height <- edges[["height.to"]]
    }
  }

  edges <- edges |>
    mutate(x1 = .data[["x.from"]] + .data[["width.from"]]/2,
           x2 = .data[["x.to"]] - .data[["width.to"]]/2) |>
    group_by(.data[["level.from"]]) |>
    arrange(.data[["po.from"]], .data[["po.to"]]) |>
    mutate(y1 = cumsum(lag(.data[["height"]], default=0)) +
           .data[["height"]] / 2) |>
    ungroup() |>
    group_by(.data[["level.to"]]) |>
    arrange(.data[["po.to"]], .data[["po.from"]]) |>
    mutate(y2 = cumsum(lag(.data[["height"]], default=0)) +
           .data[["height"]] / 2) |>
    ungroup() |>
    arrange(.data[["ord"]])

  layout <- layout |>
    mutate(x1 = edges$x1,
           x2 = edges$x2,
           y1 = edges$y1,
           y2 = edges$y2,
           height = edges$height,
           width = NA, .edges=TRUE)

  layout
}



bezier_ribbon <- function(p0, p1, p2, p3, width, n = 100) {

  t <- seq(0, 1, length.out = n)

  # Bézier center line
  p <-
    (1 - t)^3 %o% p0 +
    3 * (1 - t)^2 * t %o% p1 +
    3 * (1 - t) * t^2 %o% p2 +
    t^3 %o% p3

  # derivative
  dp <-
    3 * (1 - t)^2 %o% (p1 - p0) +
    6 * (1 - t) * t %o% (p2 - p1) +
    3 * t^2 %o% (p3 - p2)

  # unit normals
  len <- sqrt(rowSums(dp^2))

  normal <- cbind(
    -dp[, 2] / len,
     dp[, 1] / len
  )

  upper <- p + width / 2 * normal
  lower <- p - width / 2 * normal

  rbind(
    upper,
    lower[nrow(lower):1, ]
  )
}

sankey_ribbon_foo <- function(x1, y1, x2, y2, height) {

  dx <- (x2 - x1)/2
  p0 <- c(x1, y1)
  p1 <- c(x1 + dx, y1)
  p2 <- c(x2 - dx, y2)
  p3 <- c(x2, y2)

  bezier_ribbon(p0, p1, p2, p3, height/200)
}

sankey_ribbon <- function(x1, y1, x2, y2, height, n=100) {

  x1 <- .55
  y1 <- .583333333
  x2 <- .78333333333
  y2 <- .25
  height <- .166666666666
  n <- 10

  message("x1: ", x1, " y1: ", y1, " x2: ", x2, " y2: ", y2, " height: ", height)
  xx <- seq(-pi/2, pi/2, length.out=n)
  yy <- (sin(xx) + 1)/2
  xx <- (xx + pi/2)/pi
  xx <- x1 + xx * (x2 - x1)
  yy <- y1 + yy * (y2 - y1)

  normals <- cbind(-diff(yy), diff(xx))
  normals <- normals / sqrt(rowSums(normals^2)) * height/2# normalize
  #segments(xx[-n], yy[-n], xx[-n] + normals[,1], yy[-n] + normals[,2])

  xx_mid <- xx[-length(xx)] + (xx[-1] - xx[-length(xx)])/2
  yy_mid <- yy[-length(yy)] + (yy[-1] - yy[-length(yy)])/2
  #points(xx_mid, yy_mid, col="blue")
  #segments(xx_mid, yy_mid, xx_mid + normals[,1], yy_mid + normals[,2],
  #         col="red")
  mid <- cbind(xx_mid, yy_mid)

  upper <- mid + normals * (height / 2)
  upper <- rbind(upper, c(x2, y2 + height / 2))
  lower <- mid - normals * (height / 2)
  lower <- rbind(lower, c(x2, y2 - height / 2))

  ret <- rbind(upper, mid[nrow(mid):1,])# lower[nrow(lower):1, ])
  #plot(ret, xlim=c(.5, 1), ylim=c(.2, .8))
  #points(upper, col="red")
  #points(xx, yy, col="green")
  #points(xx_mid - diff(yy), yy_mid + diff(xx), col="orange")
  ret

}

bezier <- function(p0, p1, p2, p3, n = 30) {
  t <- seq(0, 1, length.out = n)

  (1 - t)^3 %o% p0 +
    3 * (1 - t)^2 * t %o% p1 +
    3 * (1 - t) * t^2 %o% p2 +
    t^3 %o% p3
}

sankey_poly <- function(x1, x2, y1, y2, size,
                        n = 30,
                        curvature = 0.5, vertical=FALSE) {

  if(vertical) {
    dy <- y2 - y1
    x1a <- x1 - size/2
    x1b <- x1 + size/2
    x2a <- x2 - size/2
    x2b <- x2 + size/2

    # upper boundary
    top <- bezier(
      c(x1a, y1),
      c(x1a, y1 + curvature * dy),
      c(x2a, y2 - curvature * dy),
      c(x2a, y2),
      n
    )

    # lower boundary, backwards
    bottom <- bezier(
      c(x2b, y2),
      c(x2b, y2 - curvature * dy),
      c(x1b, y1 + curvature * dy),
      c(x1b, y1),
      n
    )


  } else {

    y1a <- y1 - size/2
    y1b <- y1 + size/2
    y2a <- y2 - size/2
    y2b <- y2 + size/2

    dx <- x2 - x1

    # upper boundary
    top <- bezier(
      c(x1, y1a),
      c(x1 + curvature * dx, y1a),
      c(x2 - curvature * dx, y2a),
      c(x2, y2a),
      n
    )

    # lower boundary, backwards
    bottom <- bezier(
      c(x2, y2b),
      c(x2 - curvature * dx, y2b),
      c(x1 + curvature * dx, y1b),
      c(x1, y1b),
      n
    )
  }

  rbind(top, bottom)
}

.get_sankey_polygon <- function(x1, y1, x2, y2, size,
                                name, fill1, fill2, alpha=.8,
                                dir = "lr", col = "black") {

  vertical <- dir %in% c("tb", "bt")

  h <- size/2
  p <- sankey_poly(x1 = x1, x2 = x2,
                   y1 = y1, y2 = y2, size = size,
                  vertical = vertical)

# following looks like crap
#  p <- sankey_ribbon(x1, y1, x2, y2, size)

  c1 <- adjustcolor(fill1, alpha.f = alpha)
  c2 <- adjustcolor(fill2, alpha.f = alpha)

  if(vertical) {
    gx1 <- x1 ; gx2 <- x1
    gy1 <- 0 ; gy2 <- 1
  } else {
    gx1 <- 0 ; gx2 <- 1
    gy1 <- y1 ; gy2 <- y1
  }

  icol <- c(2, 1)

  if(dir %in% c("bt", "lr")) {
    icol <- rev(icol)
  }

  fill <- linearGradient(colours = c(c1, c2)[icol],
                         y1 = gy1, y2 = gy2,
                         x1 = gx1, x2 = gx2)

  polygonGrob(x = p[,1],
              y = p[,2],
              name = name,
              gp = gpar(
                        fill=fill,
                        col=col))
}

# create the arrows between the nodes
#' @importFrom grid polygonGrob linearGradient
#' @importFrom grDevices adjustcolor
.get_connectors <- function(layout, vertical=FALSE) {

  dir <- attr(layout, "dir")
  edges <- activate(layout, "edges") |> as_tibble()
  edges <- edges[nrow(edges):1, ]

  nodes <- as_tibble(layout)
  edges$fill.from <- nodes$fill[match(edges$from, nodes$node_id)]
  edges$fill.to <- nodes$fill[match(edges$to, nodes$node_id)]

  edges$fill.from[is.na(edges$fill.from)] <- "grey"
  edges$fill.to[is.na(edges$fill.to)] <- "grey"

  if(!"color" %in% colnames(edges)) {
    edges$color <- "black"
  }

  ret <- lapply(1:nrow(edges), \(i) {
    .df <- edges[i, ]
    .get_sankey_polygon(.df$x1, .df$y1, .df$x2, .df$y2,
                        ifelse(vertical, .df$width, .df$height),
                        paste0("con_", .df$from, "_", .df$to),
                        .df$fill.from, .df$fill.to,
                        dir=dir, col=.df$color %||% NA)

               })

  if(!is.null(ret)) {
    ret <- gTree(gp = gpar(),
                   children = do.call(gList, ret),
                   name = "edges")
  }

  ret
}


# here we create a new kind of tree - a Sankey tree. The levels of a
# variable are represented by just one node, but with multiple edges, and
# edges have a size (n), indicating how many samples from a parent node
# pass to the child node. So for example, if we had a node "Survived:No
# 122(38%)" attached to "Class:1st", then there will be an edge between
# "Class:1st" and "Survived:No" with a size of 122.
# Thus, a node may have multiple incoming edges and no single parent.
# this is not a plotting function, it returns an object of class both
# sankey_tree and vtree which allows to use add_labels and such.
# Note: we will need to handle the types carefully. Since sankey nodes have
# multiple parents, a "parent_id" column does not make sense. Therefore,
# vtree methods that rely on parent_id will not work. We might need to
# create add_labels generic and then add_labels.sankey_tree.

#' Create a Sankey tree from a vtree object
#'
#' Sankey trees can be used to visualize data without the conditional
#' frequencies that are used in a standard vtree.
#'
#' Unlike the using sankey layout for regular vtrees, this function does
#' not preserve the conditional frequencies of the vtree. The node
#' visualization shows the marginal frequencies of the variable levels -
#' that is, the overall frequencies of levels for each variable, equivalent
#' to the values produced in vtree plots with `legend=TRUE`.
#' @param vtree,x A vtree object.
#' @param ... Additional arguments passed to `plot_vtree()`.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Age, Survived)
#' sankey(vt) |> plot()
#' @return A sankey_tree object, which is also a vtree object.
#' `plot.sankey_tree()` can be used to plot the object and returns
#' a `grid::gTree` object.
#' @export
#' @importFrom dplyr cur_group_id
sankey <- function(vtree) {

  ensure_vtree(vtree)

  sep <- attr(vtree, "sep")
  vp <- attr(vtree, "vp")

  nd <- as_tibble(vtree) |>
    rename(oldid = .data[["node_id"]]) |>
    group_by(.data[["node_col"]], .data[["node_val"]]) |>
    mutate(node_id = cur_group_id()) |>
    ungroup() |>
    mutate(node_id = match(.data[["node_id"]], unique(.data[["node_id"]]))) |>
    rename(old_parent_id = .data[["parent_id"]]) |>
    mutate(parent_id = .data[["node_id"]][match(.data[["old_parent_id"]],
                                                .data[["oldid"]])]) |>
    mutate(node_key = paste0("node_", .data[["node_id"]]))

  eg <- nd |>
    filter(!is.na(.data[["parent_id"]])) |>
    select(from = .data[["parent_id"]], to = .data[["node_id"]],
           all_of("n")) |>
    group_by(.data[["from"]], .data[["to"]]) |>
    summarize(n = sum(.data[["n"]]), .groups = "drop")

  selcols <- c("node_id", "node_key", "node_col", "node_val", "level",
               "val_alias", "col_alias", "fill", "color", "grob")
  newnd <- nd |>
    group_by(.data[["node_col"]], .data[["node_val"]]) |>
    summarize(across(any_of(selcols), \(x) x[1]),
              n = sum(.data[["n"]]),
              .groups = "drop") |>
    arrange(.data[["node_id"]]) |>
    group_by(.data[["level"]]) |>
    mutate(tot_n = sum(.data[["n"]])) |>
    mutate(missing = sum(.data[["n"]][ is.na(.data[["node_val"]])])) |>
    mutate(denom = ifelse(vp, .data[["tot_n"]] - .data[["missing"]],
                              .data[["tot_n"]])) |>
    mutate(freq = .data[["n"]] / .data[["denom"]]) |>
    ungroup() |>
    mutate(parent_id = NA_integer_) |>
    mutate(path = NA_character_) |>
    mutate(path_l = NA_character_) |>
    mutate(parent = NA_character_)

  sankey <- tbl_graph(nodes = newnd, edges = eg,
                     directed = TRUE, node_key = "node_key") |>
            activate("nodes")

  class(sankey) <- c("sankey_tree", "vtree", class(sankey))
  for(a in c("vp", "levels", "cols", "N", "source_summary", "sep", "pruned",
             "palette", "alias", "grob")) {
    attr(sankey, a) <- attr(vtree, a)
  }

  sankey
}



#' @rdname sankey
#' @export
plot.sankey_tree <- function(x, ...) {
  ensure_vtree(x)
  plot_vtree(x, layout="sankey", ...)
}
