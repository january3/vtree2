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
#' It also sets the mapping between colors and variable levels, stored in
#' the attribute "palette", which is used when showing the legend. If you
#' modify the `fill` and `color` columns manually (without using
#' `add_palette()`, you will not change the color code.
#'
#' If the parameter `what` is `color`, then instead of generating a fill
#' color from the palettes, the function generates a text color and chooses
#' a contrast fill color automatically.
#'
#' The following arguments determine the hierarchy of the color-control on
#' the resulting plot:
#'
#'  * `palettes` - determines both the palette for the legend and the
#'  colors of the nodes
#'  * `var_palette` - low level adjustment of colors. Does not have to
#'  include all variable and all variable levels, and does not influence
#'  the colors of the variable names shown on the legend, but it does
#'  change the colors of the variable levels shown on the legend.
#'  * `var_colors` - influences only the colors of the variable names shown
#'  on the legend. If NULL, a default from the `palettes` argument will be
#'  inferred.
#'  * `na` - color for the missing values for all variables. If `what` is
#'  "fill", then it is interpreted as the background fill color; if `what` is
#'  "text", then it is interpreted as the text (foreground) color.
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
#'             'what' is 'text', it adds a text color for the node and
#'             automatically chooses a contrast color for the fill.
#' @param var_levels a character vector of values to which colors are
#'        assigned from a palette
#' @param var_palette a named list of named vectors. The var_palette names
#'        correspond to the variables; the names of the vectors are
#'        the levels of the given variable; the values are colors.
#' @param var_colors A named character vector with text colors of the variables
#'        as shown on a legend. If NULL, the colors are taken over from the
#'        palettes defined by the `palettes` argument, even if
#'        `var_palette` is also defined.
#' @param pal name of a palette (e.g. "Greens")
#' @param na color used for nodes associated with NA values
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
#' vt |> add_palette(palettes = "Blues", na = "red") |>
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
#'   add_palette(what = "text",
#'       var_palette = list(Sex = c(Male = "blue", Female = "Red"))) |>
#'       plot()
#'
#' @return `vtree_palette()` returns a character vector of colors for the
#' levels of the variable. `add_palette()` returns the vtree object with
#' the columns `fill` `color`, and with additional attribute `palette`.
#' @importFrom RColorBrewer brewer.pal
#' @importFrom grDevices colorRampPalette
#' @importFrom purrr map imap map2_chr map_chr map_dfr set_names
#' @seealso See [contrast_color()] for generating white/black contrast
#' color automatically.
#' @export
vtree_palette <- function(vtree,
                          palettes = c("Reds", "Blues", "Greens",
                                       "Oranges", "Purples")) {

  ensure_vtree(vtree)

  levs <- levels(vtree)
  levs <- map(levs, \(x) x[ !is.na(x)])

  palettes <- rep(palettes, length.out = length(levs))
  names(palettes) <- names(levs)

  ret <- imap(palettes, \(pal, var) {
    var_palette(levs[[var]], pal)
  })

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

.node_fill <- function(node_col, node_val, na, pal) {

  node_val <- as.character(node_val)
  candidates <- map2_chr(node_val, node_col, \(val, var) {
      pal[[var]][as.character(val)] %||% na
  })

  ifelse(is.na(node_val), na, candidates)
}

# get a contrast palette for the given palette.
get_contrast_pal <- function(pal) {

  ret <- imap(pal, \(varpal, var) {
               if(var == "NAs") {
                 return(contrast_color(varpal))
               }
               map_chr(varpal, \(col) contrast_color(col))
             })
  ret
}

#' @rdname vtree_palette
#' @importFrom purrr map2_chr map_chr
#' @export
add_palette <- function(vtree,
                             palettes = c("Reds", "Blues", "Greens",
                                       "Oranges", "Purples"),
                             na = "white",
                             var_palette = NULL,
                             var_colors = NULL,
                             what = "fill") {

  ensure_vtree(vtree)
  what <- match.arg(what, c("fill", "text"))

  if(what == "fill") {
    other <- "text"
  } else {
    other <- "fill"
  }

  if(what == "text") { what <- "color" }
  if(other == "text") { other <- "color" }

  # the palette associated with the tree
  pal_at <- attr(vtree, "palette") %||% list()

  # generate the palette based on the provided params
  pal <- vtree_palette(vtree, palettes = palettes)

  # generate the variable colors
  if(is.null(var_colors)) {
    var_colors <- map_chr(set_names(names(pal)), \(var)
                  pal[[var]][ length(pal[[var]]) ])
  }


  # replace by colors defined by users
  pal <- scale_add(pal, var_palette)

  # assign to what will become the attribute
  pal_at[[what]] <- list(scale = pal,
                         na = na)

  # if other is missing, get a contrast one
  if(is.null(pal_at[[other]])) {
    pal_contrast <- get_contrast_pal(pal)
    pal_at[[other]] <- list(scale = pal_contrast,
                            na = contrast_color(na))
  }

  # now the vars. We choose to use the text color to be fill color.
  pal_at[[other]]$vars <- var_colors
  pal_at[[what]]$vars <- map_chr(var_colors, contrast_color)

  attr(vtree, "palette") <- pal_at

  ## now apply the color palette
  vtree <- .apply_pal(vtree, pal, na, what, other)
  vtree
}

.apply_pal <- function(vtree, pal, na, what, other) {

  vtree <- mutate(vtree, !!what := .node_fill(.data[["node_col"]],
                                    .data[["node_val"]], na, pal))

  if(! other %in% nodecols(vtree)) {
    vtree <- mutate(vtree, !!other := contrast_color(.data[[what]]))
  }
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
