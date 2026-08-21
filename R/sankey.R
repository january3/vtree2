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

  if(!"fill" %in% nodecols(vtree)) {
    cli_warn(c(x = "Argument `vtree` for Sankey layout does not have a fill column",
      i = "For correct display, please add a coloring first with `add_palette()`"))
  }

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

  edges <- activate(layout, "edges") |> as_tibble()
  nsel <- select(nodes, any_of(c("order", "path", "x", "y", "fill",
                                 "height", "width", "level", "node_level")))

  edges <- left_join(edges, nsel, by=join_by("from" == "order")) |>
           left_join(nsel, by=join_by("to" == "order"),
                     suffix=c(".from", ".to")) |>
           mutate(x1 = .data[["x.from"]] + .data[["width.from"]]/2,
                  x2 = .data[["x.to"]] - .data[["width.to"]]/2,
                  y1 = .data[["y.from"]] - .data[["height.from"]]/2,
                  y2 = .data[["y.to"]]) |>
           mutate(order = 1:n()) |>
           group_by(.data[["path.from"]]) |>
           arrange(desc(.data[["to"]])) |>
           mutate(dy = cumsum(lag(.data[["height.to"]], default=0)) +
                       .data[["height.to"]] / 2) |>
           ungroup() |>
           mutate(y1 = .data[["y1"]] + .data[["dy"]]) |>
           mutate(height = .data[["height.to"]]) |>
           arrange(.data[["order"]])

  layout <- layout |>
    mutate(x1 = edges$x1,
           x2 = edges$x2,
           y1 = edges$y1,
           y2 = edges$y2,
           height = edges$height,
           width = edges$width.from, .edges=TRUE)

  if("fill" %in% nodecols(layout)) {
    layout <- layout |>
      mutate(fill.from = edges$fill.from,
             fill.to = edges$fill.to, .edges=TRUE)
  } else {
    layout <- layout |>
      mutate(fill.from = NA_character_,
             fill.to = NA_character_, .edges=TRUE)
  }


  layout
}

bezier <- function(p0, p1, p2, p3, n = 30) {
  t <- seq(0, 1, length.out = n)

  (1 - t)^3 %o% p0 +
    3 * (1 - t)^2 * t %o% p1 +
    3 * (1 - t) * t^2 %o% p2 +
    t^3 %o% p3
}

sankey_poly <- function(x1, x2,
                        y1a, y1b,
                        y2a, y2b,
                        n = 30,
                        curvature = 0.5) {

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

  rbind(top, bottom)
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

.get_sankey_polygon <- function(x1, y1, x2, y2, height,
                                name, fill1, fill2, alpha=.8) {

  h <- height/2
  p <- sankey_poly(x1 = x1, x2 = x2,
                  y1a = y1 - h, y1b = y1 + h,
                  y2a = y2 - h, y2b = y2 + h)
# following looks like crap
#  p <- sankey_ribbon(x1, y1, x2, y2, height)

  c1 <- adjustcolor(fill1, alpha.f = alpha)
  c2 <- adjustcolor(fill2, alpha.f = alpha)

  fill <- linearGradient(colours = c(c1, c2),
                         x1 = 0, x2 = 1,
                         y1 = y1, y2 = y2)

  polygonGrob(x = p[,1],
              y = p[,2],
              name = name,
              gp = gpar(
                        fill=fill,
                        col="black"))
}

# create the arrows between the nodes
#' @importFrom grid polygonGrob linearGradient
#' @importFrom grDevices adjustcolor
.get_connectors <- function(edges) {
  edges <- edges[nrow(edges):1, ]

  ret <- lapply(1:nrow(edges), \(i) {
    .df <- edges[i, ]
    .get_sankey_polygon(.df$x1, .df$y1, .df$x2, .df$y2,
                        .df$height, 
                        paste0("con_", .df$from, "_", .df$to),
                        .df$fill.from, .df$fill.to)

               })

  if(!is.null(ret)) {
    ret <- gTree(gp = gpar(),
                   children = do.call(gList, ret),
                   name = "edges")
  }

  ret
}
