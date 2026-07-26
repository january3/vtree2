# ok, a better plotting approach with grobs.
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

.adapt_fontsize_single <- function(grob, width, height, mar) {

  mins <- 5
  maxs <- 150
  while(maxs - mins > 1) {
    fs <- (maxs + mins)/2
    grob <- .set_fontsize(list(grob), fs)[[1]]
    lw <- convertWidth(grobWidth(grob), "npc", valueOnly = TRUE)
    lh <-  convertHeight(grobHeight(grob), "npc", valueOnly = TRUE)

    if(lw > mar * width || lh > mar * height) {
      maxs <- fs  
    } else {
      mins <- fs
    }

  }

  # .set_fontsize works with lists
  grob <- .set_fontsize(list(grob), floor(mins))
  grob[[1]]
}

# adapt the font size of each grob separately
#' @importFrom grid convertWidth grobWidth
#' @importFrom grid convertHeight grobHeight
adapt_fontsize <- function(grobs, widths, heights,
                           padding = .2) {
  .mar <- 1 - padding

  grobs <- map(seq_along(grobs), \(i)
               .adapt_fontsize_single(grobs[[i]],
                                      widths[[i]],
                                      heights[[i]],
                                      .mar))
  return(grobs)
}

find_fontsize <- function(labels, widths, heights) {

  l <- strsplit(labels, "\n")
  maxh <- min(heights/sapply(l, length))
  maxw <- min(sapply(l, \(x) widths/max(nchar(x))))

  # we want to find a font size that will roughly give us a char w of maxw
  # and a line height of maxs.
  teststr <- "WM\u00C1\u00C2\u00C4\u00C5\u00C9\u00CA\u00CB\u00CD\u00CE\u00CF\u00D3\u00D4\u00D6\u00DA\u00DB\u00DCgjpqy"
  teststr <- paste(rep(teststr, 3), collapse="\n")

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
    } else {
      mins <- fs
    }
  }
  
  mins <- floor(mins)
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

.get_node_rects <- function(nodes, rgrob) {

  map(1:nrow(nodes), \(i) {
    if(rgrob == "roundrectGrob") {
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
    } else {
    rectGrob(x = nodes$x[i],
      y = nodes$y[i],
      name = paste0("node_", nodes$ID[i]),
      width = nodes$width[i],
      height = nodes$height[i],
      gp = gpar(
               lwd = 2,
               col = "black",
               fill = nodes$fill[i]))
    }
  })
}

.get_arrows <- function(edges, arr_length=.025) {

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

  # the rgrob param chooses between rectangle and roundrect
  rects <- .get_node_rects(nodes, x$params$rgrob)
  rects <- gTree(gp = gpar(),
                 children = do.call(gList, rects),
                 name = "nodes")

  # labels - this is the main reason why I used grid: I want the labels to
  # automatically fit inside of the node rectangles
  fs <- 12
  if(x$param$autofontsize == "fixed") {
    fs <- find_fontsize(nodes$label, .9 * nodes$width, .9 * nodes$height)
  }

  labels <- .get_labels(nodes, fs = fs) 

  # adaptive means: each label gets its own font size
  if(x$param$autofontsize == "adaptive") {
    labels <- adapt_fontsize(labels, nodes$width, nodes$height,
                         padding = .4)
  }

  labels <- gTree(gp = gpar(),
                  children = do.call(gList, labels),
                  name = "labels")


  arrows <- .get_arrows(edges)

  # margin labels with the variable names
  cnodes <- distinct(nodes, .data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1)
  if(x$params$dir %in% c("bt", "tb")) {
    message("margin[2]=",x$margin[2])
    fs <- find_fontsize(cnodes$node_col, x$margin[2], .9 * cnodes$full_h[1])
  } else {
    fs <- find_fontsize(cnodes$node_col, .9 * cnodes$full_w[1], .9 * x$margin[1])
  }
  clabs <- .get_clabs(cnodes, dir=x$params$dir, mar=x$margin, fs = fs)

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
  grid.newpage()
  grid.draw(x)
}

.flip_horiz <- function(layout) {
    mutate(layout, x = 1 - .data[["x"]]) |>
    mutate(x1 = 1 - .data[["x1"]],
           x2 = 1 - .data[["x2"]], .edges=TRUE)
}

.flip_vert <- function(layout) {
    mutate(layout, y = 1 - .data[["y"]]) |>
    mutate(y1 = 1 - .data[["y1"]],
           y2 = 1 - .data[["y2"]], .edges=TRUE)
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
plot_grob <- function(vtree,
                      proportional = FALSE,
                      lwidth = NA, lheight = NA,
                      autofontsize = NA,
                      dir = "lr") {
  dir <- match.arg(dir, c("lr", "rl", "bt", "tb"))

  if(proportional) {
    layout <- grob_layout_by_freq(vtree, dir, lwidth=lwidth, lheight=lheight)
    rgrob <- "rectGrob"
    if(is.na(autofontsize)) {
      autofontsize = "adaptive"
    }
  } else {
    layout <- grob_layout_regular(vtree, dir, lwidth=lwidth, lheight=lheight)
    rgrob <- "roundrectGrob"
    if(is.na(autofontsize)) {
      autofontsize = "fixed"
    }
  }

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
    layout <- .flip_horiz(layout)
  }

  if(dir == "tb") {
    layout <- .flip_vert(layout)
  }

  layout <- .scale(layout, margins[2], margins[1],
                  1 - (margins[2] + margins[4]),
                 1 - (margins[1] + margins[3]))

  gTree(
        params = list(
          dir = dir,
          rgrob = rgrob,
          autofontsize = autofontsize,
          proportional = proportional),
        layout = layout,
        margin = margins,
        name = "vtree",
        children = gList(),
        cl = "vtree_plot",
        gp = gpar()
        )
}
