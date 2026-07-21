# for each node, calculate the number of leafs and store in nleafs
.calc_nleafs <- function(graph) {
  graph |> activate("nodes") |>
    mutate(nleafs = map_bfs_back_int(
      root = 1,
      mode = "out",
      .f = \(node, path, ...) {
        if(nrow(path) == 0) {
          return(1L)
        } else {
          return(sum(unlist(path$result)))
        }
    }))
}



add_labels <- function(vtree) {
  vtree <- vtree |> activate("nodes") |>
    mutate(.node_val = 
           ifelse(.data[["node_col"]] == "__ALL__", "All data", 
                  .data[["node_val"]])) |>
    mutate(label = ifelse(is.na(.data[[".node_val"]]),
           sprintf("%s: %s n=%d", .data[["node_col"]], 
                                  .data[[".node_val"]], .data[["n"]]),
           sprintf("%s: %s n=%d (%.1f%%)", 
                    .data[["node_col"]], 
                    .data[[".node_val"]], 
                    .data[["n"]], 
                    .data[["freq"]] * 100))
    ) |>
  select(-all_of(".node_val"))

  class(vtree) <- c("vtree", class(vtree))
  vtree
}


.calc_offsets <- function(vtree) {
  vtree |>
    activate("nodes") |>
    group_by(.data[["parent"]]) |>
    mutate(offset = lag(cumsum(.data[["n"]]), default = 0)) |>
    ungroup() |>
    mutate(offset_tot = map_bfs_int(
      root = 1,
      mode = "out",
      .f = \(node, path, ...) {
        .N()$offset[node] + sum(.N()$offset[path$node])
    }))
}

# plot by frequency
plot_by_freq <- function(graph, fill_scale, color_scale) {

  # calculate the local offsets for each descendant of each node
  .graph <- graph |>
    .calc_offsets() |>
    add_labels()

  nodes <- .graph |> 
    as_tibble() 

  maxl <- max(nodes$level)
  totn <- sum(nodes$n[nodes$level == 1])

  nodes <- nodes |>
    mutate(x = .data[["level"]] / maxl) |>
    mutate(y = .data[["offset_tot"]] / totn +
           .data[["n"]] / (2 * totn)) |>
    mutate(width = 0.8 / maxl, height = .data[["n"]] / totn)

  edges <- graph |> activate(edges) |> as_tibble() |>
    mutate(x1 = nodes$x[.data[["from"]]],
           x2 = nodes$x[.data[["to"]]],
           y1 = nodes$y[.data[["to"]]],
           y2 = nodes$y[.data[["to"]]])
  
  nodes |> ggplot(aes(x = .data[["x"]], y = .data[["y"]], 
                      height = .data[["height"]],
                      label = .data[["label"]])) +
    geom_segment(data = edges, 
                 aes(x = .data[["x1"]],
                     y = .data[["y1"]],
                     xend = .data[["x2"]],
                     yend = .data[["y2"]]), 
                 inherit.aes = FALSE) +
    geom_rect(aes(x = .data[["x"]],
                  y = .data[["y"]],
                  width = .data[["width"]],
                  height = .data[["height"]],
                  fill = .data[["node_cv"]]),
              color = "black") +
    geom_text(aes(color = .data[["node_cv"]])) +
    fill_scale +
    color_scale +
    # reverse y axis
    scale_y_reverse() +
    # remove clipping
    coord_cartesian(clip = "off")
  #+
  
  #theme_void()

}

# just the nodes, no resizing according to frequency
plot_regular <- function(graph, fill_scale, color_scale) {

  nodes <- graph |> activate(nodes) |> 
    .calc_nleafs() |>
    # calculate number of leafs per node
    add_labels() |>
    as_tibble()

  maxl <- max(nodes$level)
  totleafs <- sum(nodes$nleafs[nodes$level == 1])
  totn <- sum(nodes$n[nodes$level == 1])

  nodes <- nodes |>
    mutate(x = .data[["level"]] / maxl) |>
    group_by(.data[["level"]]) |>
    mutate(y = (cumsum(.data[["nleafs"]]) - .data[["nleafs"]] / 2)/
           totleafs) |>
    ungroup()

  edges <- graph |> activate(edges) |> as_tibble() |>
    mutate(x1 = nodes$x[.data[["from"]]],
           x2 = nodes$x[.data[["to"]]],
           y1 = nodes$y[.data[["from"]]],
           y2 = nodes$y[.data[["to"]]])

  nodes |> ggplot(aes(x = .data[["x"]],
                      y = .data[["y"]],
                      label = .data[["label"]])) +
    geom_segment(data = edges, 
                 aes(x = .data[["x1"]],
                     y = .data[["y1"]],
                     xend = .data[["x2"]],
                     yend = .data[["y2"]]), 
                 inherit.aes = FALSE) +
    geom_label(aes(fill = .data[["node_cv"]],
                   color = .data[["node_cv"]])) +
    # reverse y axis
    fill_scale +
    color_scale +
    scale_y_reverse() +
    # remove clipping
    coord_cartesian(clip = "off")
}

#' Get a contrasting color
#'
#' Get a contrasting color
#'
#' Returns a contrasting color (black or white) for a given color. This is
#' useful for ensuring that text is readable against a background color.
#' @param color A character vector with colors in any format accepted by R
#'              (e.g., "red", "#FF0000", etc.)
#' @return A character string representing the contrasting color
#' ("black" or "white")
#' @examples
#' contrast_color("red")    # returns "white"
#' @importFrom grDevices col2rgb
#' @export
contrast_color <- function(color) {
  # Convert the color to RGB
  rgb <- col2rgb(color)
  
  # Calculate the luminance using the formula
  luminance <- (0.299 * rgb[1, ] + 0.587 * rgb[2, ] + 0.114 * rgb[3, ]) / 255
  
  # Return black for light colors and white for dark colors
  ifelse(luminance > 0.5, "black", "white")
}

#' Get a color palette for a variable level
#'
#' Get a color palette for a variable level
#'
#' `vtree_palette` returns a color palette for a variable level in a vtree. 
#' The colors are chosen from the RColorBrewer package, and the palette is 
#' extended for variables with more than nine levels.
#'
#' `vtree_pal_assign` assigns fill colors to the nodes of a vtree based on the
#' variable levels. The fill colors are stored in a new column in the nodes
#' data frame called "fill".
#' @param vtree A vtree object
#' @param palettes The names of RColorBrewer palettes corresponding to the
#'                 subsequent columns in the vtree
#' @param na_fill fill color used for nodes associated with NA values
#' @return A character vector of colors for the levels of the variable
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom purrr map imap map2_chr map_chr map_dfr set_names
#' @export
vtree_palette <- function(vtree,
                          palettes = c("Blues", "Greens", "Reds", 
                                       "Oranges", "Purples")) {
  #family <- families[(level - 1L) %% length(families) + 1L]

  stopifnot(inherits(vtree, "vtree"))

  levs <- levels(vtree)
  levs <- map(levs, \(x) x[ !is.na(x)])

  palettes <- rep(palettes, length.out = length(levs))
  names(palettes) <- names(levs)

  ret <- imap(palettes, \(pal, var) {
    n <- length(levs[[var]])
    pal <- rev(.vtree_pal(n, pal_name = pal))
    names(pal) <- levs[[var]]
    pal
  })

  ret
}


#' @rdname vtree_palette
#' @export
vtree_pal_assign <- function(vtree, 
                             palettes = c("Blues", "Greens", "Reds", 
                                       "Oranges", "Purples"),
                             na_fill = "white") {

  stopifnot(inherits(vtree, "vtree"))

  pal <- vtree_palette(vtree, palettes = palettes)

  vtree <- vtree |> activate("nodes") |>
    mutate(fill = ifelse(is.na(.data[["node_val"]]),
                               na_fill,

                               map2_chr(.data[["node_val"]], 
                           .data[["node_col"]], \(val, var) {
      pal[[var]][as.character(val)] %||% na_fill
    })))

  as_vtree(vtree)
}

# @param n The number of levels in the variable
.vtree_pal <- function(n, pal_name = "Blues") {

  #family <- families[(level - 1L) %% length(families) + 1L]

  if (n == 0L) {
    return(character())
  }

  if (n == 1L) {
    # Equivalent to a medium/dark representative shade
    return(RColorBrewer::brewer.pal(3, pal_name)[2])
  }

  if (n <= 9L) {
    # brewer.pal() requires at least three colours
    pal <- RColorBrewer::brewer.pal(max(3L, n), pal_name)

    # For n = 2, retain the light and dark endpoints
    if (n == 2L) {
      return(pal[c(1L, 3L)])
    }

    return(pal)
  }

  # Extension for variables with more than nine levels
  grDevices::colorRampPalette(
    RColorBrewer::brewer.pal(9, pal_name),
    space = "Lab"
  )(n)
}

#' Plot a vtree
#'
#' Plot a vtree
#'
#' Plots a vtree object. By default, the plot is scaled by frequency, so
#' that the size of each node is proportional to the number of observations
#' in that node. If you prefer a regular plot, set `by_freq = FALSE`.
#'
#' The returned value is a ggplot2 object, which can be further customized
#' using ggplot2 functions.
#'
#' Working with color palettes
#'
#' By default, fill colors are assigned automatically based on the variable
#' level in the tree. Each node gets its own palette, and from
#' that palette fill colors are assigned to the levels of the variable by
#' their order of appearance or factor level in the data. The variables
#' with the lowest factor levels or appearing first will get the darkest
#' fill colors. NA values are colored white.
#' 
#' If the vtree object contains, in the node data frame, a column called
#' "fill", then the fill colors will be taken from that column instead of being
#' assigned automatically.
#'
#' If the vtree object contains a column called "color", then the text
#' colors will be taken from that column. Otherwise, the either white or
#' black will be chosen depending on the fill color for each node.
#' @param x A vtree object
#' @param ... ignored
#' @param palettes A character vector with names of RColorBrewer palettes
#'                 to use for the variables. By default these are the
#'                 default arguments to the vtree_palette() function.
#' @param na_fill The color to use for NA values. Default is "white".
#' @param by_freq If TRUE, the plot is scaled by frequency. If FALSE,
#'                all nodes have the same size.
#' @param legend If TRUE, a legend is added to the plot. Default is FALSE.
#' @return A ggplot object
#' @importFrom ggplot2 ggplot aes geom_segment geom_rect 
#' @importFrom ggplot2 scale_y_reverse coord_cartesian
#' @importFrom ggplot2 theme_void geom_text geom_label
#' @importFrom ggplot2 scale_fill_manual scale_color_manual theme
#' @export
plot.vtree <- function(x, 
                       ..., 
                       palettes = c("Blues", "Greens", "Reds", 
                                    "Oranges", "Purples"),
                       na_fill = "white",
                       by_freq = FALSE,
                       legend = FALSE) {
  stopifnot(inherits(x, "vtree"))

  nodes <- x |> activate(nodes) |> as_tibble()
  if(! "fill" %in% colnames(nodes)) {
    x <- vtree_pal_assign(x, palettes = palettes, na_fill = na_fill)
  }

  if(! "color" %in% colnames(nodes)) {
    x <- x |> activate(nodes) |>
      mutate(color = contrast_color(.data[["fill"]]))
  }

  nodes <- x |> activate(nodes) |> as_tibble()
  fill_scale  <- scale_fill_manual(name = NULL,
                                   values  = set_names(nodes$fill,
                                                       nodes$node_cv))
  color_scale <- scale_color_manual(name = NULL,
                                    values = set_names(nodes$color,
                                                       nodes$node_cv))
  if(by_freq) {
    p <- plot_by_freq(x, fill_scale, color_scale)
  } else {
    p <- plot_regular(x, fill_scale, color_scale)
  }

  p <- p + theme_void()

  if(!legend) {
    p <- p + theme(legend.position = "none")
  }

  p

}



