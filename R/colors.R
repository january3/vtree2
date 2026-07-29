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

#' Color palettes for a variable levels
#'
#' Color palettes for a variable levels
#'
#' `vtree_palette()` returns a color palette for a variable level in a vtree.
#' The colors are chosen from the RColorBrewer package.
#'
#' `add_palette()` assigns fill colors to the nodes of a vtree based on the
#' variable levels. The fill colors are stored in a new column in the nodes
#' data frame called "fill". If a `color` column is missing, it will be
#' added with automatic contrast colors as well, but it will not be
#' overwritten if present.
#' @param vtree A vtree object
#' @param palettes The names of RColorBrewer palettes corresponding to the
#'                 subsequent columns in the vtree
#' @param na_fill fill color used for nodes associated with NA values
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' vtree_palette(vt)
#' 
#' # only blues for all variables!
#' vt |> add_palette(palettes = "Blues") |> plot()
#' # same as
#' plot(vt, palettes = "Blues")
#'
#' # manipulate color for some of the nodes
#' vt |> add_palette(palettes = "Blues") |>
#'   # don't prune, just mark the nodes in the mark col
#'   prune(path == "Class:1st/Sex:Male", mark_only = TRUE) |>
#'   # color the marked nodes in red
#'   mutate(fill = ifelse(mark == "keep", fill, "red")) |>
#'   plot()
#' @return `vtree_palette()` returns a character vector of colors for the
#' levels of the variable. `add_palette()` returns the vtree object with
#' the columns `fill` and `color`, and with additional attributes `palette`
#' and `palette_vars`.
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom purrr map imap map2_chr map_chr map_dfr set_names
#' @export
vtree_palette <- function(vtree,
                          palettes = c("Reds", "Blues", "Greens",
                                       "Oranges", "Purples")) {
  #family <- families[(level - 1L) %% length(families) + 1L]

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "vtree_palette() requires a vtree object"))
  }

  levs <- levels(vtree)
  levs <- map(levs, \(x) x[ !is.na(x)])

  palettes <- rep(palettes, length.out = length(levs))
  names(palettes) <- names(levs)

  ret <- imap(palettes, \(pal, var) {
    n <- length(levs[[var]])
    pal <- .vtree_pal(n, pal_name = pal)
    names(pal) <- levs[[var]]
    pal
  })

  ret
}

.node_fill <- function(node_col, node_val, na_fill, pal) {

  node_val <- as.character(node_val)
  candidates <- map2_chr(node_val, node_col, \(val, var) {
      pal[[var]][as.character(val)] %||% na_fill
  })

  ifelse(is.na(node_val), na_fill, candidates)
}

#' @rdname vtree_palette
#' @importFrom purrr map2_chr map_chr
#' @export
add_palette <- function(vtree,
                             palettes = c("Reds", "Blues", "Greens",
                                       "Oranges", "Purples"),
                             na_fill = "white") {

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "add_palette() requires a vtree object"))
  }

  pal <- vtree_palette(vtree, palettes = palettes)

  vtree <- vtree |>
    mutate(fill = ifelse(is.na(.data[["node_val"]]),
                         na_fill,
                         .node_fill(.data[["node_col"]],
                                    .data[["node_val"]], na_fill, pal)
           )) |>
    mutate(fill_class = map_chr(.data[["node_col"]], \(var) 
      pal[[var]][length(pal[[var]])] %||% na_fill))

  nodes <- as_tibble(vtree)

  if(! "color" %in% colnames(nodes)) {
    vtree <- vtree |> activate("nodes") |>
      mutate(color = contrast_color(.data[["fill"]]))
  }

  pal_vars <- map_chr(set_names(names(pal)), \(var) 
                  pal[[var]][ length(pal[[var]]) ])

  attr(vtree, "palette") <- pal
  attr(vtree, "palette_vars") <- pal_vars
  vtree
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
