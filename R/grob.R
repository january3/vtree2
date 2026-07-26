# ok, a better plotting approach with grobs.
grob_layout_by_freq <- function(vtree, dir="lr", lwidth=NA, lheight=NA) {

  layout <- .calc_offsets(vtree)
  nodes <- as_tibble(layout)

  nlevel <- max(nodes$level) + 1
  totn <- sum(nodes$n[nodes$level == 1])

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
    mutate(y = .data[["offset_tot"]] / totn +
           .data[["height"]] / 2)

  nodes <- as_tibble(layout)

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]] + nodes$width[.data[["from"]]]/2,
           x2 = nodes$x[.data[["to"]]] - nodes$width[.data[["to"]]]/2,
           y1 = nodes$y[.data[["to"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)

  layout
}


grob_layout_regular <- function(vtree, dir="lr", lwidth=NA, lheight=NA) {

  layout <- .calc_nleafs(vtree)
  nodes  <- as_tibble(layout)

  nlevel <- max(nodes$level) + 1
  totleafs <- sum(nodes$nleafs[nodes$level == 1])

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
    mutate(x = (.data[["level"]] + .5)/ nlevel) |>
    group_by(.data[["level"]]) |>
    mutate(y = (cumsum(.data[["nleafs"]]) - .data[["nleafs"]] / 2)/
           totleafs) |>
    ungroup() |>
    mutate(full_h = full_h, full_w = full_w) |>
    mutate(width = lwidth, height = lheight)

  nodes <- as_tibble(layout)

  if(dir %in% c("tb", "bt")) {
    dx <- lheight
  } else {
    dx <- lwidth
  }

  layout <- layout |>
    mutate(x1 = nodes$x[.data[["from"]]] + dx/2,
           x2 = nodes$x[.data[["to"]]] - dx/2,
           y1 = nodes$y[.data[["from"]]],
           y2 = nodes$y[.data[["to"]]],
           .edges = TRUE)


   layout
}

.get_widths <- function(grobs) {
    purrr::map_dbl(grobs, \(g) 
      convertWidth(grobWidth(g), "npc", valueOnly = TRUE))
}

.get_heights <- function(grobs) {
    lhghs <- purrr::map_dbl(grobs, \(g) 
      convertHeight(grobHeight(g), "npc", valueOnly = TRUE))
}

.set_fontsize <- function(grobs, fs) {
    map(grobs, \(g) {
      g$gp$fontsize <- fs
      g })
}

#' @importFrom grid convertWidth grobWidth
#' @importFrom grid convertHeight grobHeight
adapt_fontsize <- function(grobs, widths, heights) {
  fs <- grobs[[1]]$gp$fontsize

  print(sprintf("finding fontsize, starting from %d", fs))
  lwids <- purrr::map_dbl(grobs, \(g) 
    convertWidth(grobWidth(g), "npc", valueOnly = TRUE))

  lhghs <- purrr::map_dbl(grobs, \(g) 
    convertHeight(grobHeight(g), "npc", valueOnly = TRUE))

  mins <- 5
  maxs <- 50
  while(maxs - mins > 3) {
    fs <- (maxs + mins)/2
    grobs <- .set_fontsize(grobs, fs)
    lwids <- .get_widths(grobs)
    lhghs <- .get_heights(grobs)

    if(any(lwids > .9 * widths) || 
          any(lhghs > .9 * heights)) {
      maxs <- fs  
      print("too large")
    } else {
      print("too small")
      mins <- fs
    }

    message(fs, " mins=", mins, " maxs= ", maxs)
  }
  grobs <- .set_fontsize(grobs, mins)
  print(mins)

  return(grobs)
}

find_fontsize <- function(labels, widths, heights) {

  print(labels)
  print(widths)
  print(heights)
  l <- strsplit(labels, "\n")
  maxh <- min(heights/sapply(l, length))
  print(labels[which.min(sapply(l, length))])
  maxw <- min(sapply(l, \(x) widths/max(nchar(x))))
  print(labels[which.min(sapply(l, \(x) widths/max(nchar(x))))])

  # we want to find a font size that will roughly give us a char w of maxw
  # and a line height of maxs.
  teststr <- "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\nABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\nABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

  n <- nchar(teststr)/3 - 2
  g <- textGrob(teststr, gp=gpar(fontsize=20))

  mins <- 2
  maxs <- 150

  while(maxs - mins > 1) {
    fs <- (maxs + mins)/2
    g$gp$fontsize <- fs
    w <- convertWidth(grobWidth(g), "npc", valueOnly = TRUE)
    h <- convertHeight(grobHeight(g), "npc", valueOnly = TRUE)

    if(w/n > maxw || h > 3 * maxh) {
      maxs <- fs  
      print("too large")
    } else {
      print("too small")
      mins <- fs
    }

    message(fs, " mins=", mins, " maxs= ", maxs)
  }
  
  mins <- floor(mins)
  message("fontsize = ", mins)
  mins
}


.get_labels <- function(nodes, fs=9) {
  map(1:nrow(nodes), \(i) {
             textGrob(x = nodes$x[i],
                        y = nodes$y[i],
                        name = paste0("label_", nodes$ID[i]),
                        label = nodes$label[i],
                        gp = gpar(
                        col = nodes$color[i],
                        fontsize = fs))
  })
}

.get_node_rects <- function(nodes) {

  map(1:nrow(nodes), \(i) {
    roundrectGrob(x = nodes$x[i],
      y = nodes$y[i],
      name = paste0("node_", nodes$ID[i]),
      width = nodes$width[i],
      height = nodes$height[i],
      r = unit(.3, "snpc"),
      gp = gpar(
               lwd = 2,
               col = "black",
               fill = nodes$fill[i]))
  })
}

.get_arrows <- function(edges, arr_length=.01) {

  segmentsGrob(x0 = edges$x1, y0 = edges$y1,
               x1 = edges$x2, y1 = edges$y2,
               arrow = arrow(
                             length=unit(arr_length, "npc"),
                             angle=15,
                             type="closed"),

               gp=gpar(color = "black",
                       fill="black",
                       lwd = 2))
}

.get_clabs <- function(nodes, dir, margin, fs) {

  if(dir %in% c("rl", "lr")) {
    ret <- map(1:nrow(nodes), \(i) {
               textGrob(x = nodes$x[i],
                        y = margin[1]/2,
                        name = paste0("label_", nodes$ID[i]),
                        label = nodes$node_col[i],
                        gp = gpar(
                        col = nodes$fill_class[i],
                        fontsize = fs))
    })
  } else {
    ret <- map(1:nrow(nodes), \(i) {
               textGrob(y = nodes$y[i],
                        x = margin[2]/2,
                        name = paste0("label_", nodes$ID[i]),
                        label = nodes$node_col[i],
                        gp = gpar(
                        col = nodes$fill_class[i],
                        fontsize = fs))
    })
  }
  ret
}

#' @export
makeContent.vtree_plot <- function(x) {

  layout <- x$layout

  nodes <- as_tibble(layout)
  edges <- activate(layout, "edges") |> as_tibble()

  rects <- .get_node_rects(nodes)
  rects <- gTree(gp = gpar(),
                 children = do.call(gList, rects),
                 name = "nodes")

  fs <- find_fontsize(nodes$label, .9 * nodes$width, .9 * nodes$height)
  labels <- .get_labels(nodes, fs = fs) 

  labels <- gTree(gp = gpar(),
                  children = do.call(gList, labels),
                  name = "labels")

  arrows <- .get_arrows(edges)


  cnodes <- distinct(nodes, .data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1)
  if(x$dir %in% c("bt", "tb")) {
    message("margin[2]=",x$margin[2])
    fs <- find_fontsize(cnodes$node_col, x$margin[2], .9 * cnodes$full_h[1])
  } else {
    fs <- find_fontsize(cnodes$node_col, .9 * cnodes$full_w[1], .9 * x$margin[1])
  }
  clabs <- .get_clabs(cnodes, dir=x$dir, mar=x$margin, fs = fs)

  clabs <- gTree(gp = gpar(),
                  children = do.call(gList, clabs),
                  name = "clabs")


  obj <- gTree(gp = gpar(),
               name = "vtree",
               children = gList(rects, labels, arrows, clabs))

  children <- gList(obj)
  setChildren(x, children)
}

#' @export
print.vtree_plot <- function(x, ...) {

  
  print("printing")
  grid.newpage()
  grid.draw(x)

}

.flip_horiz <- function(layout) {
    mutate(layout, x = 1 - x) |>
    mutate(x1 = 1 - x1, x2 = 1 - x2, .edges=TRUE)
}

.flip_vert <- function(layout) {
    mutate(layout, y = 1 - y) |>
    mutate(y1 = 1 - y1, y2 = 1 - y2, .edges=TRUE)
}

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

#' @importFrom grid gTree gpar gList grid.newpage
#' @importFrom grid textGrob rectGrob roundrectGrob
#' @importFrom grid segmentsGrob arrow
#' @importFrom grid setChildren grid.draw makeContent
#' @export
plot_regular_grob <- function(vtree,
                              lwidth = NA, lheight = NA,
                              dir = "lr"
                              ) {
  dir <- match.arg(dir, c("lr", "rl", "bt", "tb"))

  #layout <- grob_layout_regular(vtree, dir, lwidth=lwidth, lheight=lheight)
  layout <- grob_layout_by_freq(vtree, dir, lwidth=lwidth, lheight=lheight)

  layout <- add_palette(layout) |>
      add_labels() |>
      mutate(color = contrast_color(.data[["fill"]])) |>
      .flip_vert()

  margins <- c(.05, 0.01, .02, .02)
  if(dir == "rl") {
    layout <- .flip_horiz(layout)
  }

  if(dir %in% c("bt", "tb")) {
    margins <- c(0.02, .1, 0.02, 0.02)
    layout <- .transpose(layout)
  }

  if(dir == "tb") {
    layout <- .flip_vert(layout)
  }

  layout <- .scale(layout, margins[2], margins[1],
                  1 - (margins[2] + margins[4]),
                 1 - (margins[1] + margins[3]))


  gTree(
        layout = layout,
        margin = margins,
        dir = dir,
        name = "vtree",
        children = gList(),
        cl = "vtree_plot",
        gp = gpar()
        )
}
