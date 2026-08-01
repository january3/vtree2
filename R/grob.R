# ok, a better plotting approach with grobs.
# calculate line width as a fraction of the device size
lwd_npc <- function(frac) {
  min(
    convertWidth(unit(frac, "npc"), "points", valueOnly = TRUE),
    convertHeight(unit(frac, "npc"), "points", valueOnly = TRUE)
  )
}

# get widths from a list of grobs
.get_widths <- function(grobs) {
    purrr::map_dbl(grobs, \(g)
      convertWidth(grobWidth(g), "npc", valueOnly = TRUE))
}

# get heights from a list of grobs
.get_heights <- function(grobs) {
    lhghs <- purrr::map_dbl(grobs, \(g)
      convertHeight(grobHeight(g), "npc", valueOnly = TRUE))
}

# for a list of grobs, set the fontsize to fs
.set_fontsize <- function(grobs, fs) {
    map(grobs, \(g) {
      g$gp$fontsize <- fs
      g })
}

# given a single grob, adapt the fontsize to fit a given w x h
.adapt_fontsize_single <- function(grob, width, height, size_fct = 1) {

  mins <- 5
  maxs <- 150
  while(maxs - mins > 1) {
    fs <- (maxs + mins)/2
    grob <- .set_fontsize(list(grob), fs)[[1]]
    lw <- convertWidth(grobWidth(grob), "npc", valueOnly = TRUE)
    lh <-  convertHeight(grobHeight(grob), "npc", valueOnly = TRUE)

    if(lw > size_fct * width || lh > size_fct * height) {
      maxs <- fs
    } else {
      mins <- fs
    }

  }

  mins
}

# adapt the font size of each grob separately
#' @importFrom grid convertWidth grobWidth
#' @importFrom grid convertHeight grobHeight
adapt_fontsize <- function(grobs, widths, heights,
                           padding = .2, ret_min = FALSE) {
  .size_fct <- 1 - padding

  if(length(widths) == 1L) {
    widths <- rep(widths, length(grobs))
  }

  if(length(heights) == 1L) {
    heights <- rep(heights, length(grobs))
  }

  ret <- map_dbl(seq_along(grobs), \(i)
               .adapt_fontsize_single(grobs[[i]],
                                      widths[[i]],
                                      heights[[i]],
                                      .size_fct))
  if(ret_min) {
    return(min(ret))
  } else {
    return(ret)
  }
}

fixed_fontsize <- function(grobs, widths, heights,
                            padding = .2) {
  adapt_fontsize(grobs, widths, heights, padding, ret_min = TRUE)
}

# sets a fontsize for a number of grobs
set_fontsize <- function(grobs, fs) {
  if(length(fs) == 1L) {
    fs <- rep(fs, length(grobs))
  }
  if(length(grobs) != length(fs)) {
    die("incorrect length of fontsize")
  }
  ret <- map(seq_along(grobs), \(i) {
                    l <- grobs[[i]]
                    l$gp$fontsize <- fs[i]
                    l
        })
  ret
}

adjust_linewidth <- function(x, path, lwd, nokids = FALSE) {
  path <- gPath(path)

  mutter <- getGrob(x, gPath = path)

  if(nokids) {
    mutter$gp$lwd <- lwd
  } else {
    kinder <- mutter$children

    kinder <- map(kinder, \(g) {
      g$gp$lwd <- lwd
      g
    })

    mutter <- setChildren(mutter, do.call(gList, kinder))
  }

  x <- setGrob(x, gPath = path, mutter)
  x
}

#' @importFrom grid getGrob setGrob setChildren gPath gList
adjust_fontsize <- function(x, path, font="fixed",
                            padding = .1,
                            widths, heights) {
  padding <- padding %||% .1
  path <- gPath(path)

  mutter <- getGrob(x, gPath = path)
  kinder <- mutter$children

  if(is.numeric(font)) {
    fs <- font
  } else if(font == "fixed") {
    fs <- fixed_fontsize(kinder, widths, heights,
                         padding = padding)
  } else if(font == "adaptive") {
    fs <- adapt_fontsize(kinder, widths, heights, padding = padding)
  } else {
    cli_abort(c(x = "Unsupported fontsize mode: {font}"))
  }

  kinder <- set_fontsize(kinder, fs)

  mutter <- setChildren(mutter, do.call(gList, kinder))

  x <- setGrob(x, gPath = path, mutter)
  x
}


#' Hook for vtree plots
#'
#' This function is called whenever a vtree_plot is plotted on a device.
#' It's purpose is to fit the
#' labels text into the allocated node space.
#'
#' @param x A vtree_plot object
#' @importFrom grid gTree gList setChildren makeContent
#' @importFrom grid gPath
#' @return A gTree object with the labels adjusted to fit into the allocated space.
#' @export
makeContent.vtree_plot <- function(x) {
  spec <- x$params$spec_fontsize

  for(i in seq_along(spec)) {
    s <- spec[[i]]
    x <- adjust_fontsize(x, s$path, font=s$fs,
                         padding = s$padding,
                         widths = s$widths,
                         heights = s$heights)
  }

  spec_lwd <- x$params$spec_lwd
  lwd <- lwd_npc(0.001 * x$params$lwd)
  for(i in seq_along(spec_lwd)) {
    s <- spec_lwd[[i]]
    x <- adjust_linewidth(x, s$path,
                          lwd = x$params$lwd, s$nokids %||% FALSE)
  }

  x
}

# create grobs for labels from the nodes data frame
# returns a gTree with the labels
#' @importFrom grid textGrob
.get_labels <- function(nodes, fs=9, color = "black") {
  req_cols <- c("x", "y", "label")
  if(!all(req_cols %in% colnames(nodes))) {
    missing <- req_cols[!req_cols %in% colnames(nodes)]
    cli_abort(
     c(
     x = "Missing required columns in nodes data frame: {.val {missing}}"))
  }

  labels <- map(1:nrow(nodes), \(i) {
             textGrob(x = nodes$x[i], y = nodes$y[i],
                      label = nodes$label[i],
                      name = paste0("label_", nodes$node_key[i] %||% "NA"),
                      gp = gpar(col = nodes$color[i] %||% color,
                      fontsize = fs))
  })

  labels <- gTree(gp = gpar(),
                  children = do.call(gList, labels),
                  name = "text")
  labels
}

#' @importFrom grid rectGrob roundrectGrob
#' @importFrom grid gpar unit
.get_rect <- function(grobname, x, y,
                      width, height,
                      name, col, fill, lwd=1) {
  if(grobname == "roundrectangle") {
    ret <- roundrectGrob(x = x, y = y,
      name = name,
      width = width,
      height = height,
      r = unit(.15, "snpc"),
      gp = gpar(
               lwd = lwd,
               col = col,
               fill = fill))
  } else if(grobname == "rectangle") {
    ret <- rectGrob(x = x, y = y,
      name = name,
      width = width,
      height = height,
      gp = gpar(
               lwd = lwd,
               col = col,
               fill = fill))
  } else {
    cli_abort(c(x = "Invalid value for grobname: {.val {grobname}}. Must be one of {.val {c('rectangle', 'roundrectangle')}}"))
  }

  ret
}

# create node grobs from the nodes data frame
# returns a gTree with the rects
#' @importFrom grid rectGrob roundrectGrob
.get_node_rects <- function(nodes, lwd=1) {
  req_cols <- c("x", "y", "width", "height", "shape", "fill")

  if(!all(req_cols %in% colnames(nodes))) {
    missing <- req_cols[!req_cols %in% colnames(nodes)]
    cli_abort(
     c(
     x = "Missing required columns in nodes data frame: {.val {missing}}"))
  }

  nodes <- nodes |>
    filter(!is.na(.data[["x"]]) & !is.na(.data[["y"]])) |>
    filter(!is.na(.data[["shape"]]))

  if(nrow(nodes) < 1L) {
    return(NULL)
  }

 #if(!is.na(rgrob)) {
 #  nodes <- mutate(nodes, grob = rgrob)
 #}

  if(any(is.na(nodes$shape))) {
    cli_abort(c(x = "NA values in the shape column"))
  }

  rects <- map(1:nrow(nodes), \(i) {
    .get_rect(grobname = nodes$shape[i],
              x = nodes$x[i],
              y = nodes$y[i],
              name = paste0("node_", nodes$node_key[i] %||% "NA"),
              width = nodes$width[i],
              height = nodes$height[i],
              col = "black",
              fill = nodes$fill[i], lwd=lwd)
  })

  if(!is.null(rects)) {
    rects <- gTree(gp = gpar(),
                   children = do.call(gList, rects),
                   name = "rect")
  }

  rects
}

# create the arrows between the nodes
#' @importFrom grid segmentsGrob arrow
.get_arrows <- function(edges, arr_length=.025) {

  segmentsGrob(x0 = edges$x1, y0 = edges$y1,
               x1 = edges$x2, y1 = edges$y2,
               name = "edges",
               arrow = arrow(
                             length=unit(arr_length, "npc"),
                             angle=15,
                             type="closed"),

               gp=gpar(color = "black",
                       fill="black",
                       lwd = 2))
}

# given a data frame with the node positions, grob column, and label
# column, create a gTree with the node grobs and the labels.
.get_nodes <- function(nodes, fs = 9, lwd = 1, name = "nodes") {

  req_cols <- c("x", "y", "width", "height", "shape", "fill", "label")

  if(!all(req_cols %in% colnames(nodes))) {
    missing <- req_cols[!req_cols %in% colnames(nodes)]
    cli_abort(
     c(x = "Missing required columns in nodes data frame: {.val {missing}}"))
  }

  rects <- .get_node_rects(nodes, lwd = lwd)

  labels <- .get_labels(nodes, fs = fs)

  gTree(gp = gpar(),
        children = gList(rects=rects, labels=labels),
        name = name)
}

.make_legend <- function(legend, params) {
  lwd       <- params$lwd
  fontsizes <- params$fontsizes

  spec      <- list()
  spec_lwd <- list()
  kinder <- list()

  # levels for layout_legend when legend=TRUE
  if(!is.null(legend$levels)) {
    kinder <- list(.get_nodes(legend$levels, name="levels", lwd = lwd))
    spec$legend_levels <- list(path = c("legend", "levels", "text"),
                               fs = fontsizes$legend_labels,
                               widths = legend$levels$width,
                               heights = legend$levels$height)
    spec_lwd$legend_levels <- list(path = c("legend", "levels", "rect"))
  }

  # titles when legend=TRUE or var_labels != FALSE
  kinder <- c(kinder,
              list(.get_nodes(legend$titles, name="titles", lwd = lwd)))

  spec$legend_titles <- list(path = c("legend", "titles", "text"),
                             fs = fontsizes$var_labels,
                             widths = legend$titles$width,
                             heights = legend$titles$height,
                             padding = .2)

  legend <- gTree(gp=gpar(), children = do.call(gList, kinder),
                  name = "legend")

  list(ret = legend, spec = spec, spec_lwd = spec_lwd)
}

.make_grobs <- function(nodes, params) {

  lwd       <- params$lwd
  fontsizes <- params$fontsizes

  spec <- list()
  spec_lwd <- list()
  kinder <- list()

  nodes <- nodes |> mutate(shape = "rectangle")
  rects <- .get_node_rects(nodes, lwd = lwd)

  gnodes <- nodes |>
    mutate(y = y - height/2 + height/20) |>
    mutate(height = 3/4 * height) |>
    mutate(width = 9/10 * width) |>
    mutate(y = y + height / 2)

  grobs <- map(seq_along(nodes$grob), \(i) {
                 g <- gnodes$grob[[i]]
                 g$vp <- grid::viewport(x = gnodes$x[i],
                                        y = gnodes$y[i],
                                        width = gnodes$width[i],
                                        height = gnodes$height[i])
                 g})
  grobs <- gTree(gp = gpar(),
                 children = do.call(gList, grobs),
                 name = "plot_obj")

  nodes$y <- nodes$y + nodes$height / 2
  nodes$y <- nodes$y + (- 1/4 + 1/7.5) * nodes$height
  nodes$height <- nodes$height / 8
  labels <- .get_labels(nodes, fs = 9)

  spec$plots <- list(path = c("plots", "text"),
                             fs = "adaptive",
                             widths = nodes$width,
                             heights = nodes$height)


# labels <- gTree(gp = gpar(),
#                 children = do.call(gList, labels),
#                 name = "text")
#
  ret <- gTree(gp = gpar(),
        children = gList(rects=rects, grobs = grobs, text=labels),
        name = "plots")


  list(ret = ret, spec = spec, spec_lwd = spec_lwd)
}

# create the grobs associated with the plot. This is the main function that
# actually creates the plot.
#' @importFrom grid gTree gpar gList setChildren
#' @importFrom purrr map_int map_lgl
.make_children <- function(params, layout) {
  x <- gTree(params = params,
             layout = layout,
             name = "vtree",
             children = gList(),
             cl = "vtree_plot",
             gp = gpar())

  legend    <- params$legend
  lwd       <- params$lwd
  fontsizes <- params$fontsizes

  spec <- list()
  spec_lwd <- list()

  # basic grobs: nodes and edges, always shown
  nodes <- as_tibble(layout)
  edges <- activate(layout, "edges") |> as_tibble()

  children <- list()

  if("grob" %in% colnames(nodes)) {
    grobnodes <- map_lgl(nodes[["grob"]],
                         \(g) {
                           print(length(g))
                           length(g) > 0L
                         })
    if(sum(grobnodes) > 0) {
      message("found ", sum(grobnodes), " grobnodes")
      gn <- .make_grobs(nodes[grobnodes, ], params)
      children <- c(children, list(plots = gn$ret))

      nodes <- nodes |> filter(!grobnodes)
      spec <- c(spec, gn$spec)
    }
  }

  nodes_gt <- .get_nodes(nodes, fs = 9, lwd = lwd)
  arrows   <- .get_arrows(edges)
  spec_lwd$edges <- list(path = c("edges"), nokids = TRUE)

  # spec contains information necessary to adjust the font sizes
  spec$labels <- list(path = c("nodes", "text"),
                      fs = fontsizes$nodes,
                      widths = nodes$width,
                      heights = nodes$height,
                      padding = .15)
  spec_lwd$nodes <- list(path = c("nodes", "rect"))

  # margin labels with the variable names
  children <- c(children, list(arrows=arrows, nodes=nodes_gt))

  if(!is.null(legend)) {
    ll <- .make_legend(legend, params)
    spec <- c(spec, ll$spec)
    spec_lwd <- c(spec, ll$spec_lwd)

    children <- c(children, list(legend = ll$ret))
  }

  children <- do.call(gList, children)

  x$params$spec_fontsize <- spec
  x$params$spec_lwd <- spec_lwd
  setChildren(x, children)
}




#' @importFrom grid grid.newpage grid.draw
#' @export
print.vtree_plot <- function(x, ...) {
  grid.newpage()
  grid.draw(x)
}
