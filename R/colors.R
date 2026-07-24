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
#' The colors are chosen from the RColorBrewer package.
#'
#' `add_palette` assigns fill colors to the nodes of a vtree based on the
#' variable levels. The fill colors are stored in a new column in the nodes
#' data frame called "fill".
#' @param vtree A vtree object
#' @param palettes The names of RColorBrewer palettes corresponding to the
#'                 subsequent columns in the vtree
#' @param na_fill fill color used for nodes associated with NA values
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' vtree_palette(vt)
#' @return A character vector of colors for the levels of the variable
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom purrr map imap map2_chr map_chr map_dfr set_names
#' @export
vtree_palette <- function(vtree,
                          palettes = c("Reds", "Blues", "Greens",
                                       "Oranges", "Purples")) {
  #family <- families[(level - 1L) %% length(families) + 1L]

  if(!inherits(vtree, "vtree")) {
    cli_abort(x = "vtree_palette() requires a vtree object")
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


#' @rdname vtree_palette
#' @export
add_palette <- function(vtree,
                             palettes = c("Reds", "Blues", "Greens",
                                       "Oranges", "Purples"),
                             na_fill = "white") {

  if(!inherits(vtree, "vtree")) {
    cli_abort(x = "add_palette() requires a vtree object")
  }

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
