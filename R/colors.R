#' Get a contrasting color
#'
#' Get a color contrasting to another color
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
#' Generate and add color palettes to vtree objects.
#'
#' `add_palette()` assigns fill colors to the nodes of a vtree based on the
#' variable levels. The fill colors are stored in a new column in the nodes
#' data frame called "fill". If a `color` column is missing, it will be
#' added with automatic contrast colors as well, but it will not be
#' overwritten if present.
#'
#' If the parameter `what` is `color`, then instead of generating a fill
#' color from the palettes, the function generates a text color and chooses
#' a contrast fill automatically.
#'
#' `vtree_palette()` returns a color palette for a variable level in a vtree.
#' The colors are chosen from the RColorBrewer package.
#'
#' `var_palette()` generates a series of colors from a palette and assigns
#' them to the provided character vector.
#'
#' @param vtree A vtree object
#' @param palettes The names of RColorBrewer palettes corresponding to the
#'                 subsequent columns in the vtree
#' @param what By default, add_palette() adds a fill color for the nodes
#'             and automatically chooses a contrast color for the text. If
#'             'what' is 'color', it adds a text color for the node and
#'             automatically chooses a contrast color for the fill.
#' @param var_levels a character vector of values to which colors are
#'        assigned from a palette
#' @param var_palette a named list of named vectors. The var_palette names
#'        correspond to the variables; the names of the vectors are
#'        the levels of the given variable; the values are colors.
#' @param default_color default color to use if variable levels from var_palette are
#'        missing
#' @param pal name of a palette (e.g. "Greens")
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
#'   mark(path == "Class:1st/Sex:Male") |>
#'   # color the marked nodes in red
#'   mutate(fill = ifelse(mark, "red", fill)) |>
#'   plot()
#'
#' # color the NA nodes with red
#' vt |> add_palette(palettes = "Blues", na_fill = "red") |>
#'    plot()
#' 
#' # males blue, females red; rest automatic
#' vt |>
#'   add_palette(var_palette =
#'       list(Sex = c(Male = "blue", Female = "Red"))) |>
#'       plot()
#'
#' # same, but now the text color is generated from the palette
#' vt |>
#'   add_palette(what = "color",
#'       var_palette = list(Sex = c(Male = "blue", Female = "Red"))) |>
#'       plot()
#'
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
                                       "Oranges", "Purples"),
                          var_palette = NULL,
                          default_color = "white") {
  #family <- families[(level - 1L) %% length(families) + 1L]

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "vtree_palette() requires a vtree object"))
  }

  levs <- levels(vtree)
  levs <- map(levs, \(x) x[ !is.na(x)])

  palettes <- rep(palettes, length.out = length(levs))
  names(palettes) <- names(levs)

  ret <- imap(palettes, \(pal, var) {
    var_palette(levs[[var]], pal)
  })

  if(is.null(var_palette)) {
    return(ret)
  }

  nm <- names(var_palette)
  if(any(!nm %in% names(levs))) {
    nm <- nm[ !nm %in% names(levs) ]
    cli_abort(c(
      x = "Incorrect variables in var_palette:",
      i = "{nm}"))
  }

  for(n in nm) {
    ret[[n]] <- map_chr(set_names(names(ret[[n]])), \(.n) {
       if(is.na(var_palette[[n]][.n])) {
         default_color
       } else {
         var_palette[[n]][.n]
       }
    })
  }

  ret
}

#' @rdname vtree_palette
#' @export
var_palette <- function(var_levels, pal) {

 n <- length(var_levels)
 pal <- .vtree_pal(n, pal_name = pal)
 names(pal) <- var_levels
 pal

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
                             na_fill = "white",
                             var_palette = NULL,
                             what = "fill",
                             default_color = "white") {

  what <- match.arg(what, c("fill", "color"))
  print(what)

  if(what == "fill") {
    other <- "color"
  } else {
    other <- "fill"
  }

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "add_palette() requires a vtree object"))
  }

  pal <- vtree_palette(vtree, palettes = palettes,
        var_palette = var_palette,
        default_color = default_color)

  vtree <- vtree |>
    mutate(!!what := ifelse(is.na(.data[["node_val"]]),
                         na_fill,
                         .node_fill(.data[["node_col"]],
                                    .data[["node_val"]], na_fill, pal)
           ))

  nodes <- as_tibble(vtree)

  if(! other %in% colnames(nodes)) {
    vtree <- vtree |> activate("nodes") |>
      mutate(!!other := contrast_color(.data[[what]]))
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
