#' Add graphics to a vtree
#'
#' Add graphics (images, plots) to vtree nodes. The graphical object should
#' be a grob (grid graphics object such as a gTree), which can be easily
#' created from images and ggplot plots.
#'
#' Any graphical object which can be converted to a "grob" (grid package
#' graphical object) can be included in a node label. The conversion is
#' relatively straightforward with both, images (jpeg, png etc.) and
#' ggplot2 plots.
#'
#' For bitmaps (raster images) such as jpeg or png, use the
#' [grid::rasterGrob()] function. For ggplot2 objects, use the
#' [ggplot2::ggplotGrob()] function. See the vtree vignette for examples.
#'
#' @param vtree an object of class vtree
#' @param grobs a list either of length 1 or of the same length as the
#'        number of nodes in the vtree.
#' @param side on which side of the node the grob should be inserted. Can
#'        be one of `l`, `r`, `t`, `b` (left, right, top, bottom).
#' @param shape shape of the node ("rectangle" or "roundrectangle").
#' @param frac fraction of space occupied by the graphics (horizontally if
#'        side is `l` or `r`, vertically if side is `t` or `b`).
#' @param condition Condition to evaluate in the context of the nodes data
#'        frame, returning a logical vector. Only nodes for which the result is
#'        TRUE will be assigned a grob.
#' @return a vtree object with graphics.
#' @export
add_graphics <- function(vtree, grobs,
                      side = "b",
                      frac = .8,
                      shape = "rectangle",
                      condition=NULL) {

  side <- match.arg(side, c("l", "r", "t", "b"))

  nodes <- as_tibble(vtree)
  nn <- nrow(nodes)

  if(frac < 0 || frac > 1) {
    cli_abort(c(x=
                "Incorrect frac parameter: {frac}",
              i="frac must be between 0 and 1"))
  }

  if(length(grobs) == 1L) {
    grobs <- lapply(1:nn, \(i) grobs[[1]])
  } else if(length(grobs) != nn) {
    cli_abort(c(x =
      "Incorrect grob list length: {length(grobs)} != {nn}"))
  }

  mask <- rep(TRUE, nn)

  condition <- enquo(condition)

  if(!quo_is_null(condition)) {
    mask <- find_nodes(vtree, !!condition)
  }

  if(!"grob" %in% names(nodes)) {
    old_grobs <- vector("list", nn)
  } else {
    old_grobs <- nodes$grob
  }

  # make sure the grobs are ther
  mask <- mask & !purrr::map_lgl(grobs, is.null)

  vtree <- vtree |>
    mutate(grob = lapply(1:nn, \(i) {
                         if(mask[i]) {
                           list(grob=grobs[[i]],
                                side=side,
                                shape=shape,
                                frac=frac)
                         } else {
                           old_grobs[[i]]
                         }}))


  vtree
}
