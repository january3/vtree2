# ok, a better plotting approach with grobs.
# calculate line width as a fraction of the device size
lwd_npc <- function(frac) {
  min(
    convertWidth(unit(frac, "npc"), "points", valueOnly = TRUE),
    convertHeight(unit(frac, "npc"), "points", valueOnly = TRUE)
  )
}

# we want to have the same vertical and horizontal padding in terms of
# screen unit, but expressed as npc units. Since the screen might be
# rectangular and not square, the width padding and height padding might
# differ.
recalculate_padding <- function(df, p_frac) {

  #message("p_frac:", p_frac)
  # recalculate in terms of npc units by looking at the minimum
  # widths and minimum heights
  #message("max width: ", max(df$width))
  #message("max height: ", max(df$height))

  p_w <- p_frac * min(df$width)
  p_h <- p_frac * min(df$height)

  #message("p_w:", p_w, " p_h:", p_h)
  # convert the p_w and p_h to screen units

  pp_w <- convertWidth(unit(p_w, "npc"), "points", valueOnly = TRUE)
  pp_h <- convertHeight(unit(p_h, "npc"), "points", valueOnly = TRUE)

  #message("pp_w:", pp_w, " pp_h:", pp_h)
  ppmin <- min(pp_w, pp_h)

  p_w <- convertWidth(unit(ppmin, "points"), "npc", valueOnly = TRUE)
  p_h <- convertHeight(unit(ppmin, "points"), "npc", valueOnly = TRUE)
  #message("new p_w:", p_w, " new p_h:", p_h)

  return(list(w = p_w, h = p_h))
}

# depending on the option, returns a single textGrob or a richtext_grob
.mk_text <- function(x, y, label, name,
                     color, fs, richtext = FALSE) {
  if(richtext) {
    ret <- gridtext::richtext_grob(
           label,
           x = x, y = y,
           name = paste0("label_", name %||% "NA"),
           gp = gpar(col = color,
           fontsize = fs))
  } else {
    ret <- textGrob(x = x, y = y,
             label = label,
             name = paste0("label_", name %||% "NA"),
             gp = gpar(col = color,
             fontsize = fs))
  }
  ret
}

# given a single grob, adapt the fontsize to fit a given w x h
#' @importFrom grid convertWidth grobWidth
#' @importFrom grid convertHeight grobHeight
.adapt_fontsize_single_full <- function(grob, width, height,
                                        label, name, color,
                                        richtext = FALSE,
                                        p = list(w = 0.1 * width,
                                                 h = 0.1 * height)
                                        #size_fct = 1
                                        ) {

  #if(p$w > width) { p$w <- 0.2 * width }
  #if(p$h > height) { p$h <- 0.2 * height }

  mins <- 2.5
  maxs <- 150
  f <- \(x) format(x, digits=2)

  while(maxs - mins > 1) {
    fs <- (maxs + mins)/2

    grob <- .mk_text(.5, .5, label, name, color, fs, richtext = richtext)
    lw <- convertWidth(grobWidth(grob), "npc", valueOnly = TRUE)
    lh <-  convertHeight(grobHeight(grob), "npc", valueOnly = TRUE)

    #if(lw > size_fct * width || lh > size_fct * height) {
    if(lw > width - p$w || lh > height - p$h) {
      maxs <- fs
    } else {
      mins <- fs
    }

    #message("width: ", f(width - p$w), " lw: ", f(lw))
    #message("height: ", f(height - p$h), " lh: ", f(lh))
    #message("fs: ", f(fs), " maxs: ", f(maxs), " mins: ", f(mins))

  }
  #message("----------------------------------")

  mins
}

# adapt the font size of each grob separately
adapt_fontsize_df <- function(grobs, df,
                           padding = .2,
                           richtext = FALSE,
                           ret_min = FALSE) {
  #.size_fct <- 1 - padding

  ret <- map_dbl(seq_along(grobs), \(i)
               .adapt_fontsize_single_full(grobs[[i]],
                 width = df$width[[i]],
                 height = df$height[[i]],
                 label = df$label[[i]],
                 name = grobs[[i]]$name,
                 color = df$color[[i]],
                 richtext = richtext,
                 p = padding))
                 #.size_fct))

  if(ret_min) {
    return(min(ret))
  } else {
    return(ret)
  }
}

fixed_fontsize_df <- function(grobs, df, padding = .2, richtext = FALSE) {
  ret <- adapt_fontsize_df(grobs, df, padding,
                           richtext = richtext, ret_min = TRUE)
  ret
}

# sets a fontsize for a number of grobs
set_fontsize_df <- function(df, fs, richtext=FALSE) {

  if(length(fs) == 1L) {
    fs <- rep(fs, nrow(df))
  }

  if(nrow(df) != length(fs)) {
    die("incorrect length of fontsize")
  }

  ret <- map(seq_len(nrow(df)), \(i)
    .mk_text(x=df$x[i], y=df$y[i], label=df$label[i],
             name=df$node_key[i], color=df$color[i],
             fs = fs[i], richtext = richtext)
  )

  ret
}

# set the line widths for a bunch of grobs in a path
set_linewidth <- function(x, path, lwd, nokids = FALSE) {
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

#   x <- adjust_fontsize_df(x, s$path, font=s$fs,
#                        padding = s$padding, df=s$df)

#' @importFrom grid getGrob setGrob setChildren gPath gList
adjust_fontsize_df <- function(x, spec) {
  path <- spec$path
  font <- spec$fs
  padding <- spec$padding %||% .1
  df <- spec$df
  richtext <- spec$richtext %||% FALSE

  padding <- padding %||% .1

  #message("adjust_fontsize_df padding:", padding)
  pad <- recalculate_padding(df, padding)

  path <- gPath(path)

  mutter <- getGrob(x, gPath = path)
  kinder <- mutter$children

  if(is.numeric(font)) {
    fs <- font
  } else if(font == "fixed") {
    fs <- fixed_fontsize_df(kinder, df,
                            richtext = richtext,
                            padding = pad)
  } else if(font == "adaptive") {
    fs <- adapt_fontsize_df(kinder, df,
                            richtext = richtext,
                            padding = pad)
  } else {
    cli_abort(c(x = "Unsupported fontsize mode: {font}"))
  }

  kinder <- set_fontsize_df(df, fs, richtext = richtext)

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
  spec <- x$params$spec

  for(i in seq_along(spec$fs)) {
    s <- spec$fs[[i]]
    x <- adjust_fontsize_df(x, s)
  }

  lwd <- lwd_npc(0.001 * x$params$lwd)
  for(i in seq_along(spec$lwd)) {
    s <- spec$lwd[[i]]
    x <- set_linewidth(x, s$path,
                          lwd = x$params$lwd, s$nokids %||% FALSE)
  }

  x
}

# create grobs for labels from the nodes data frame
# returns a gTree with the labels
#' @importFrom grid textGrob
.get_labels <- function(nodes, fs=9,
                        color = "black", richtext = FALSE) {

  req_cols <- c("x", "y", "label")
  ensure_colnames(nodes, req_cols)

  labels <- map(seq_len(nrow(nodes)), \(i) {
    .mk_text(nodes$x[i], nodes$y[i],
             label=nodes$label[i], name=nodes$node_key[i],
             color=nodes$color[i] %||% color, fs = fs,
             richtext = richtext)
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
  ensure_colnames(nodes, req_cols)

  nodes <- nodes |>
    filter(!is.na(.data[["x"]]) & !is.na(.data[["y"]])) |>
    filter(!is.na(.data[["shape"]]))

  if(nrow(nodes) < 1L) {
    return(NULL)
  }

  if(any(is.na(nodes$shape))) {
    cli_abort(c(x = "NA values in the shape column"))
  }

  rects <- map(seq_len(nrow(nodes)), \(i) {
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

.get_edges <- function(layout, vertical=FALSE, style = "arrows") {

  if(style == "arrows") {
    edges <- activate(layout, "edges") |> as_tibble()
    .get_arrows(edges)
  } else if(style == "sankey") {
    .get_connectors(layout, vertical = vertical)
  }
}

# given a data frame with the node positions, grob column, and label
# column, create a gTree with the node grobs and the labels.
.get_nodes <- function(nodes, fs = 9, lwd = 1,
                       name = "nodes", richtext = FALSE) {

  req_cols <- c("x", "y", "width", "height", "shape", "fill", "label")
  ensure_colnames(nodes, req_cols)

  rects <- .get_node_rects(nodes, lwd = lwd)

  labels <- .get_labels(nodes, fs = fs, richtext = richtext)

  gTree(gp = gpar(),
        children = gList(rects=rects, labels=labels),
        name = name)
}

.make_legend <- function(legend, params) {
  lwd       <- params$lwd
  fontsizes <- params$fontsizes
  richtext  <- params$richtext
  padding   <- params$padding %||% .2

  spec      <- list()
  spec$lwd <- list()
  spec$fs  <- list()
  kinder <- list()

  # levels for layout_legend when legend=TRUE
  if(!is.null(legend$levels)) {
    if(richtext) {
      legend$levels[["label"]] <- gsub("\n", "<br>", legend$levels[["label"]])
    }
    kinder <- list(.get_nodes(legend$levels, name="levels",
                              lwd = lwd, richtext = richtext))
    spec$fs$legend_levels <- list(path = c("legend", "levels", "text"),
                               df = legend$levels,
                               padding = padding,
                               fs = fontsizes$legend_labels,
                               richtext = richtext,
                               widths = legend$levels$width,
                               heights = legend$levels$height)
    spec$lwd$legend_levels <- list(path = c("legend", "levels", "rect"))
  }

  if(richtext) {
    legend$titles[["label"]] <- gsub("\n", "<br>", legend$titles[["label"]])
  }

  # titles when legend=TRUE or var_labels != FALSE
  kinder <- c(kinder,
              list(.get_nodes(legend$titles, name="titles",
                              lwd = lwd, richtext = richtext)))

  spec$fs$legend_titles <- list(path = c("legend", "titles", "text"),
                             df = legend$titles,
                             fs = fontsizes$var_labels,
                             richtext = richtext,
                             widths = legend$titles$width,
                             heights = legend$titles$height,
                             padding = padding)

  legend <- gTree(gp=gpar(), children = do.call(gList, kinder),
                  name = "legend")

  list(ret = legend, spec = spec)
}

# check whether grobs have unique names, and if not,
# assign unique names to them.
.make_unique_names <- function(grobs, names=NULL, prefix = "grob_") {
  grob_names <- map_chr(grobs, \(g) g$name)

  # no need to change names if they are already unique
  if(!any(duplicated(grob_names))) {
    return(grobs)
  }

  if(is.null(names)) {
    names <- 1:length(grobs)
  }

  names <- paste0(prefix, names)
  grobs <- map(seq_along(grobs), \(i) {
    g <- grobs[[i]]
    g$name <- names[i]
    g
  })

  grobs
}

# arrange label and graphics horizontally
.split_horizontal <- function(inner, gfirst, gfrac, gap) {

  gwidth <- gfrac * inner$width - gap/2
  lwidth <- (1 - gfrac) * inner$width - gap/2

  lheight <- gheight <- inner$height

  gx <- inner$x + gwidth / 2 
  lx <- inner$x + lwidth / 2

  if(gfirst) {
    lx <- lx + gwidth + gap
  } else {
    gx <- gx + lwidth + gap
  }

  gy <- ly <- inner$y + inner$height / 2

  list(
       graphics=list(x = gx, y = gy,
                     width = gwidth, height = gheight),
       label=list(x = lx, y = ly,
                     width = lwidth, height = lheight)
  )
}


# arrange the label and the graphics vertically
.split_vertical <- function(inner, gfirst, gfrac, gap) {

  gheight <- gfrac * inner$height - gap/2
  lheight <- (1-gfrac) * inner$height - gap/2

  gwidth <- lwidth <- inner$width

  gx <- lx <- inner$x + inner$width/2

  gy <- inner$y + gheight / 2
  ly <- inner$y + lheight / 2

  if(gfirst) {
    ly <- ly + gheight + gap
  } else {
    gy <- gy + lheight + gap
  }

  list(
       graphics=list(x = gx, y = gy,
                     width = gwidth, height = gheight),
       label=list(x = lx, y = ly,
                     width = lwidth, height = lheight)
  )
}

# process a row from the nodes, preparing the coordinates for the label and
# the graphics depending on the grob layout
.calc_grob_row <- function(nodes, grob, pad) {

  side <- grob$side
  frac <- grob$frac
  graphics_first <- side %in% c("l", "b")

  if(is.na(nodes$label) || nodes$label == "") { frac <- 1 }

  inner <- list(
    x0 = nodes$x - nodes$width/2 + pad$w,
    y0 = nodes$y - nodes$height/2 + pad$h,
    width = nodes$width - 2 * pad$w,
    height = nodes$height - 2 * pad$h
  )

  if(side %in% c("l", "r")) {
    .split_horizontal(inner, graphics_first, frac, gap=pad$w)
  } else {
    .split_vertical(inner, graphics_first, frac, gap=pad$h)
  }

}

#' @importFrom purrr map_dbl map_lgl map_int
.make_grobs <- function(nodes, grobs, params) {

  lwd       <- params$lwd
  fontsizes <- params$fontsizes
  richtext  <- params$richtext

  spec <- list()
  spec$fs  <- list()
  spec$lwd <- list()
  kinder <- list()

  # padding
  pad <- recalculate_padding(nodes, params$padding)
  pad$w <- pad$w/2
  pad$h <- pad$h/2

  rects <- .get_node_rects(nodes, lwd = lwd)

  gdata <- map(seq_len(nrow(nodes)), \(i) {
    .calc_grob_row(nodes[i, ], grobs[[i]], pad)
  })

  gnodes <- map_dfr(gdata, \(x) x$graphics)
 
  grobs <- map(seq_along(gnodes$x), \(i) {
                 g <- grobs[[i]]$grob
                 g$vp <- grid::viewport(x = gnodes$x[i],
                                        y = gnodes$y[i],
                                        width = gnodes$width[i],
                                        height = gnodes$height[i])
                 g})

  grobs <- .make_unique_names(grobs, names = nodes$node_key, prefix = "grob_")
  grobs <- gTree(gp = gpar(),
                 children = do.call(gList, grobs),
                 name = "plot_obj")

  # for labels, we need all the different meta-data like node_key and color
  # information
  nd2 <- map_dfr(gdata, \(x) x$label)

  nodes$x <- nd2$x
  nodes$y <- nd2$y
  nodes$width <- nd2$width
  nodes$height <- nd2$height

  labels <- .get_labels(nodes, fs = 9, richtext = richtext)
  spec$fs$plots <- list(path = c("plots", "text"),
                        df = nodes,
                        padding = 0,
                        richtext = richtext,
                        fs = "adaptive",
                        widths = nodes$width,
                        heights = nodes$height)

  ret <- gTree(gp = gpar(),
        children = gList(rects=rects, grobs = grobs, text=labels),
        name = "plots")

  list(ret = ret, spec = spec)
}

# little helper to dtrmine whether g is a grob
.has_graphics <- function(g) {
  if(is.null(g)) return(FALSE)
  if(length(g) == 1L && is.na(g)) return(FALSE)
  is.list(g) && !is.null(g$grob)
}

# create the grobs associated with the plot. This is the main function that
# actually creates the plot.
#' @importFrom grid gTree gpar gList setChildren
#' @importFrom purrr map_int map_lgl
.make_children <- function(params, layout, grobs=NULL) {
  x <- gTree(params = params,
             layout = layout,
             name = "vtree",
             children = gList(),
             cl = "vtree_plot",
             gp = gpar())

  legend    <- params$legend
  lwd       <- params$lwd
  fontsizes <- params$fontsizes
  #params$richtext <- params$richtext %||% TRUE
  richtext  <- params$richtext
  padding   <- params$padding %||% .1
  dir       <- attr(layout, "dir") %||% "lr"
  vertical  <- dir %in% c("tb", "bt")

  nodes <- as_tibble(layout)
  if(richtext) {
    nodes[["label"]] <- gsub("\n", "<br>", nodes[["label"]])
  }

  spec <- list()
  spec$lwd <- list()
  spec$fs  <- list()

  sel <- !is.na(nodes$x) & !is.na(nodes$y) &
    !is.na(nodes$width) & !is.na(nodes$height)

  # grobs are passed directly because they are so large
  grobs <- grobs[sel]

  # basic grobs: nodes and edges, always shown
  nodes <- nodes |> filter(sel)

  arrows   <- .get_edges(layout, vertical=vertical, style=params$edge_style)
  spec$lwd$edges <- list(path = c("edges"), nokids = TRUE)
  children <- list(arrows=arrows)

  if(!is.null(grobs)) {
    grobnodes <- map_lgl(grobs, .has_graphics)
    if(sum(grobnodes) > 0) {
      gn <- .make_grobs(nodes[grobnodes, ], grobs[grobnodes], params)
      children <- c(children, list(plots = gn$ret))

      nodes <- nodes |> filter(!grobnodes)
      spec$fs <- c(spec$fs, gn$spec$fs)
    }
  }


  if(nrow(nodes) > 0) {
    nodes_gt <- .get_nodes(nodes, fs = 9, lwd = lwd, richtext = richtext)
    children <- c(children, list(nodes=nodes_gt))

    # spec contains infor4mation necessary to adjust the font sizes
    spec$fs$labels <- list(path = c("nodes", "text"),
                        df = nodes,
                        richtext = richtext,
                        fs = fontsizes$nodes,
                        widths = nodes$width,
                        heights = nodes$height,
                        padding = padding)
    spec$lwd$nodes <- list(path = c("nodes", "rect"))
  }


  if(!is.null(legend)) {
    ll <- .make_legend(legend, params)
    spec$fs  <- c(spec$fs,  ll$spec$fs)
    spec$lwd <- c(spec$lwd, ll$spec$lwd)

    children <- c(children, list(legend = ll$ret))
  }

  children <- do.call(gList, children)

  x$params$spec <- spec
  setChildren(x, children)
}

#' @importFrom grid grid.newpage grid.draw
#' @family plotting
#' @export
print.vtree_plot <- function(x, ...) {
  grid.newpage()
  grid.draw(x)
}
