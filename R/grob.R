# ok, a better plotting approach with grobs.

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

  grob$gp$fontsize <- floor(mins)
  grob
}

# adapt the font size of each grob separately
#' @importFrom grid convertWidth grobWidth
#' @importFrom grid convertHeight grobHeight
adapt_fontsize <- function(grobs, widths, heights,
                           padding = .2) {
  .size_fct <- 1 - padding

  grobs <- map(seq_along(grobs), \(i)
               .adapt_fontsize_single(grobs[[i]],
                                      widths[[i]],
                                      heights[[i]],
                                      .size_fct))
  return(grobs)
}

# given a vector of labels, figure out what fontsize fits them into the
# widths x heights. Note that this is approximate only
find_fontsize <- function(labels, widths, heights) {
  l <- strsplit(labels, "\n")
  maxh <- min(heights/sapply(l, length))
  maxw <- min(sapply(l, \(x) {
                       if(length(x) == 0) {
                         return(1)
                       }
                       min(widths/max(nchar(x)))
              }
  ))

  # we want to find a font size that will roughly give us a char w of maxw
  # and a line height of maxs.
  teststr <- paste0("WM\u00C1\u00C2\u00C4\u00C5\u00C9\u00CA",
                    "\u00CB\u00CD\u00CE\u00CF\u00D3\u00D4",
                    "\u00D6\u00DA\u00DB\u00DCgjpqy")
  teststr <- "WMjpqy()%"
  n <- nchar(teststr)
  teststr <- paste(rep(teststr, 3), collapse="\n")

  #n <- nchar(teststr)/3 - 2
  g <- textGrob(teststr, gp=gpar(fontsize=20))

  mins <- 2
  maxs <- 150

  while(maxs - mins > .1) {
    fs <- (maxs + mins)/2
    g$gp$fontsize <- fs
    w <- convertWidth(grobWidth(g), "npc", valueOnly = TRUE)
    h <- convertHeight(grobHeight(g), "npc", valueOnly = TRUE)

    if(w/n > maxw || h/3 > maxh) {
      maxs <- fs  
    } else {
      mins <- fs
    }
  }
  
  mins <- round(mins)
  mins
}

# create grobs for labels from the nodes data frame
#' @importFrom grid textGrob
.get_labels <- function(nodes, fs=9) {
  map(1:nrow(nodes), \(i) {
             textGrob(x = nodes$x[i],
                        y = nodes$y[i],
                        name = paste0("label_", nodes$node_key[i]),
                        label = nodes$label[i],
                        gp = gpar(
                        col = nodes$color[i],
                        fontsize = fs))
  })
}

#' @importFrom grid rectGrob roundrectGrob
#' @importFrom grid gpar unit
.get_grob <- function(grobname, x, y,
                      width, height,
                      name, col, fill) {
  if(grobname == "roundrectangle") {
    ret <- roundrectGrob(x = x, y = y,
      name = name,
      width = width,
      height = height,
      r = unit(.3, "snpc"),
      gp = gpar(
               lwd = 2,
               col = col,
               fill = fill))
  } else if(grobname == "rectangle") {
    ret <- rectGrob(x = x, y = y,
      name = name,
      width = width,
      height = height,
      gp = gpar(
               lwd = 2,
               col = col,
               fill = fill))
  } else {
    cli_abort(c(x = "Invalid value for grobname: {.val {grobname}}. Must be one of {.val {c('rectangle', 'roundrectangle')}}"))
  }

  ret
}

# create node grobs from the nodes data frame
#' @importFrom grid rectGrob roundrectGrob
.get_node_rects <- function(nodes) {
  nodes <- nodes |>
    filter(!is.na(.data[["x"]]) & !is.na(.data[["y"]]))

 #if(!is.na(rgrob)) {
 #  nodes <- mutate(nodes, grob = rgrob)
 #}

  if(any(is.na(nodes$shape))) {
    cli_abort(c(x = "NA values in the shape column"))
  }

  map(1:nrow(nodes), \(i) {
    .get_grob(grobname = nodes$shape[i],
              x = nodes$x[i],
              y = nodes$y[i],
              name = paste0("node_", nodes$node_key[i]),
              width = nodes$width[i],
              height = nodes$height[i],
              col = "black",
              fill = nodes$fill[i])
  })
}

# create the arrows between the nodes
#' @importFrom grid segmentsGrob arrow
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

# get the labels of the variables
.get_clabs <- function(nodes, dir, margin, fs) {

  if(!"fill_class" %in% colnames(nodes)) {
    nodes$fill_class <- "black"
  }

  if(dir %in% c("rl", "lr")) {
    ret <- map(1:nrow(nodes), \(i) {
               textGrob(x = nodes$x[i],
                        y = margin[1]/2,
                        name = paste0("label_", nodes$node_key[i]),
                        label = nodes$node_col[i],
                        gp = gpar(
                        col = nodes$fill_class[i],
                        fontsize = fs))
    })
  } else {
    ret <- map(1:nrow(nodes), \(i) {
               textGrob(y = nodes$y[i],
                        x = margin[2]/2,
                        name = paste0("label_", nodes$node_key[i]),
                        label = nodes$node_col[i],
                        gp = gpar(
                        col = nodes$fill_class[i],
                        fontsize = fs))
    })
  }
  ret
}

#' Hook for vtree plots
#'
#' This function is called whenever a vtree_plot is plotted on a device.
#' It's purpose is to fit the
#' labels text into the allocated node space.
#'
#' @param x A vtree_plot object
#' @importFrom grid gTree gList setChildren makeContent
#' @return A gTree object with the labels adjusted to fit into the allocated space.
#' @export
makeContent.vtree_plot <- function(x) {

  labels <- x$children$labels$children
  nodes <- as_tibble(x$layout)

  if(x$param$autofontsize == "fixed") {
    fs <- find_fontsize(nodes$label, .9 * nodes$width, .9 * nodes$height)
    for(i in seq_along(x$children$labels$children)) {
      x$children$labels$children[[i]]$gp$fontsize <- fs
    }
  } else if(x$param$autofontsize == "adaptive") {
  # adaptive means: each label gets its own font size
    labels <- adapt_fontsize(labels, nodes$width, nodes$height,
                         padding = .4)
    x$children$labels <-
      setChildren(x$children$labels, do.call(gList, labels))
  }

  cnodes <- distinct(nodes, .data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1)

  if(x$params$dir %in% c("bt", "tb")) {
    fs <- find_fontsize(cnodes$node_col, x$margin[2], .9 * cnodes$full_h[1])
  } else {
    fs <- find_fontsize(cnodes$node_col, .9 * cnodes$full_w[1], .9 * x$margin[1])
  }
  for(i in seq_along(x$children$clabs$children)) {
    x$children$clabs$children[[i]]$gp$fontsize <- fs
  }

  x
}

# create the grobs associated with the plot. This is the main function that
# actually creates the plot.
#' @importFrom grid gTree gpar gList setChildren
.make_children <- function(x, fs=9, var_labels = TRUE) {

  layout <- x$layout

  nodes <- as_tibble(layout)
  edges <- activate(layout, "edges") |> as_tibble()

  # the rgrob param chooses between rectangle and roundrect
  rects <- .get_node_rects(nodes)
  rects <- gTree(gp = gpar(),
                 children = do.call(gList, rects),
                 name = "nodes")

  labels <- .get_labels(nodes, fs = fs) 
  labels <- gTree(gp = gpar(),
                  children = do.call(gList, labels),
                  name = "labels")

  arrows <- .get_arrows(edges)

  # margin labels with the variable names
  cnodes <- distinct(nodes, .data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1)

  if(var_labels) {
    clabs <- .get_clabs(cnodes, dir=x$params$dir,
                        margin=x$margin, fs = fs)

    clabs <- gTree(gp = gpar(),
                    children = do.call(gList, clabs),
                    name = "clabs")

    children <- gList(arrows=arrows, nodes=rects, labels=labels, clabs=clabs)
  } else {
    children <- gList(arrows=arrows, nodes=rects, labels=labels)
  }
  setChildren(x, children)
}




#' @importFrom grid grid.newpage grid.draw
#' @export
print.vtree_plot <- function(x, ...) {
  grid.newpage()
  grid.draw(x)
}
