#' @importFrom grid roundrectGrob
draw_key_rrect <- function(data, params, size) {
  radius <- params$radius %||% 0.1

  grid::roundrectGrob(
    x = 0.5,
    y = 0.5,
    width = 0.8,
    height = 0.8,
    r = grid::unit(radius, "snpc"),
    default.units = "npc",
    gp = grid::gpar(
      col = data$colour %||% NA,
      fill = scales::alpha(
        data$fill %||% "grey35",
        data$alpha %||% NA_real_
      ),
      lwd = (data$linewidth %||% 0.5) * ggplot2::.pt,
      lty = data$linetype %||% 1,
      linejoin = "round"
    )
  )
}

#' Rounded rectangles
#'
#' Draw rectangles with rounded corners.
#'
#' @inheritParams ggplot2::geom_rect
#' @param radius Corner radius as fraction of the rect width, .1 - .5
#'
#' @importFrom rlang list2
#' @export
geom_rrect <- function(
    mapping = NULL,
    data = NULL,
    stat = "identity",
    position = "identity",
    ...,
    radius = .2,
    na.rm = FALSE,
    show.legend = NA,
    inherit.aes = TRUE
) {
  ggplot2::layer(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = GeomRrect,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list2(
      radius = radius,
      na.rm = na.rm,
      ...
    )
  )
}

draw_panel_rrect <- function(
      data,
      panel_params,
      coord,
      radius = 0.1
) {
  if (!coord$is_linear()) {
    cli::cli_abort(
      "{.fn geom_rrect} only supports linear coordinate systems."
    )
  }

  if (
    length(radius) != 1L ||
    !is.numeric(radius) ||
    is.na(radius) ||
    radius < 0 ||
    radius > 0.5
  ) {
    cli::cli_abort(
      "{.arg radius} must be a number between 0 and 0.5."
    )
  }

  coords <- coord$transform(data, panel_params)

  keep <- stats::complete.cases(
    coords$xmin,
    coords$xmax,
    coords$ymin,
    coords$ymax
  )

  coords <- coords[keep, , drop = FALSE]

  if (nrow(coords) == 0L) {
    return(grid::nullGrob())
  }

  grobs <- lapply(seq_len(nrow(coords)), function(i) {
    row <- coords[i, , drop = FALSE]

    width  <- abs(row$xmax - row$xmin)
    height <- abs(row$ymax - row$ymin)

    grid::roundrectGrob(
      x = 0.5,
      y = 0.5,
      width = 1,
      height = 1,
      r = grid::unit(radius, "snpc"),
      default.units = "npc",
      vp = grid::viewport(
        x = (row$xmin + row$xmax) / 2,
        y = (row$ymin + row$ymax) / 2,
        width = width,
        height = height,
        default.units = "native"
      ),
      gp = grid::gpar(
        col = row$colour,
        fill = scales::alpha(row$fill, row$alpha),
        lwd = row$linewidth * ggplot2::.pt,
        lty = row$linetype,
        linejoin = "round"
      )
    )
  })

  grid::grobTree(
    children = do.call(grid::gList, grobs)
  )
}


#' @rdname geom_rrect
#' @format NULL
#' @usage NULL
#' @export
GeomRrect <- ggplot2::ggproto(
  "GeomRrect",
  ggplot2::Geom,

  required_aes = c("xmin", "xmax", "ymin", "ymax"),

  default_aes = ggplot2::aes(
    colour = NA,
    fill = "grey35",
    linewidth = 0.5,
    linetype = 1,
    alpha = NA
  ),

  draw_key = draw_key_rrect,
  draw_panel = draw_panel_rrect,
)


