# vertical legend arrangement
.legend_vertical <- function(legend, titles, margins, title_size = 2) {

  maxpos <- max(legend$nitems) + title_size
  hg <- max(legend$full_h) / maxpos

  pad <- .25 * hg


  legend <- legend |>
    mutate(x = margins$left / 2) |>
    mutate(width = .8 * margins$left) |>
    mutate(height = hg) |>
    mutate(y = .data[["y"]] -
           (.data[["nitems"]] + title_size) * hg / 2 +
           (.data[["nitems"]] - .data[["pos"]]) * hg +
           hg / 2 + pad)

  titles <- titles |>
    mutate(x = margins$left / 2) |>
    mutate(width = .8 * margins$left) |>
    mutate(y = .data[["y"]] +
           (.data[["nitems"]] + title_size) * hg / 2 -
           hg +
           pad) |>
    mutate(height = title_size * hg - 2 * pad)

  list(levels=legend, titles=titles)
}

# horizontal legend arrangements
.legend_horizontal <- function(legend, titles, margins, title_size = 2) {

  maxpos <- max(legend$nitems) + title_size
  hg <- margins$bottom / maxpos

  # pad goes: to the below the items, between items and title, and above
  # the title. The necessary amount of space is removed from the title
  # height, so 3 * pad must be smaller than hg * title_size.
  pad <- 0.2 * hg

  legend <- legend |>
    mutate(x = .data[["x"]]) |>
    mutate(y = margins$bottom -
             (.data[["pos"]] + title_size) * hg +
             hg/2 + pad) |>
    mutate(height = hg) |>
    mutate(width = .data[["width"]])

  maxy <- max(legend[["y"]]) + hg / 2

  titles <- titles |>
    mutate(height = hg * title_size - 3 * pad) |>
    mutate(y = maxy + .data[["height"]]/2 + pad)

  list(levels=legend, titles=titles)
}

# prepare a summary using the aliases
#' @importFrom purrr map_chr map2_chr
.layout_summary <- function(layout) {

  ret <- summary(layout)
  nodes <- as_tibble(layout)
# if(!
#    (all(nodes[-1, ][["node_col"]] %in% ret[["node_col"]]) &&
#     all(nodes[-1, ][["node_val"]] %in% ret[["node_val"]]))) {
#   cli_abort(c(x="corrupted vtree object: summary and node table not compatible"))
# }

  c_alias <- get_aliases(layout, "col")

  if(!is.null(c_alias)) {
    ret[["col_alias"]] <- map_chr(ret[["node_col"]],
                                 \(col) c_alias[[col]] %||% col)
  } else {
    ret[["col_alias"]] <- ret[["node_col"]]
  }

  v_alias <- get_aliases(layout, "val")
  if(!is.null(v_alias)) {
    ret[["val_alias"]] <- map2_chr(ret[["node_col"]], ret[["node_val"]],
                                   \(col, val) if(is.na(val)) {
                                     v_alias[["NAs"]] %||% "NA"
                                   } else {
                                     v_alias[[col]][val] %||% val
                                   })
  } else {
    ret[["val_alias"]] <- ret[["node_val"]]
  }

  ret[["label"]] <- sprintf("%s: %d (%.0f%%)",
                            ret[["val_alias"]],
                            ret[["count"]],
                            ret[["freq"]] * 100)

  ret
}


.get_legend_pal <- function(layout) {
  pal <- get_palette(layout)

  pals <- list()

  pals$color <- NULL
  pals$fill <- NULL
  pals$na_text <- "black"
  pals$na_fill <- "white"
  pals$vt <- NULL
  pals$vf <- NULL

  if(length(pal) == 0 || is.null(pal)) {
    cli::cli_inform(c(i="palette attribute is NULL",
               "legend will be black and white"))
  } else {
    pals$color <- pal$color$scale %||% NULL
    pals$fill <- pal$fill$scale %||% NULL
    pals$na_text <- pal$color$na %||% "black"
    pals$na_fill <- pal$fill$na %||% "white"
    pals$vt <- pal$color$vars %||% NULL
    pals$vf <- pal$fill$vars %||% NULL
  }

  pals
}

# create a layout for the legend.
layout_legend <- function(layout, margins) {

  dir <- get_dir(layout)

  #req_cols <- c("x", "y", "width", "height", "shape", "fill", "label"))
  cnms <- names(layout)

  # we get the positions of the variables from the layout, ignoring the
  # root
  pospar <- as_tibble(layout) |>
    filter(.data[["node_key"]] != "node_1") |>
    distinct(pick("node_col"), .keep_all = TRUE) |>
    select(all_of(c("node_col", "level", "x", "y", "width", "height", "full_w",
                    "full_h", "shape")))

  lvls <- levels(layout)

  pals <- .get_legend_pal(layout)

  summaries <- .layout_summary(layout) |>
    group_by(.data[["node_col"]]) |>
    mutate(pos = 1:n()) |>
    ungroup() |>
    filter(.data[["count"]] != 0) |>
    mutate(fill = get_vals(.data[["node_col"]],
                            .data[["node_val"]],
                            pals$fill, pals$na_fill) %||% pals$na_fill) |>
    mutate(color = get_vals(.data[["node_col"]],
                             .data[["node_val"]],
                             pals$color, pals$na_text) %||% pals$na_text)


  legend <- merge(pospar, summaries, by = "node_col", all.y=TRUE) |>
      mutate(node_key = paste0("legend_", 1:n())) |>
      mutate(label_type = "var_level_label") |>
      filter(!is.na(.data[["x"]])) |>
      group_by(.data[["node_col"]]) |>
      mutate(nitems = n()) |>
      ungroup()

  titles <- legend |>
    group_by(.data[["node_col"]]) |>
    dplyr::slice(1) |>
    ungroup() |>
    mutate(node_key = paste0("legend_title_", 1:n())) |>
    mutate(label = .data[["col_alias"]]) |>
    mutate(label_type = "var_name_label") |>
    mutate(shape = NA)

  if(is.null(pals$vt) || is.null(pals$vf)) {
    titles$color <- "black"
    titles$fill <- "white"
  } else {
    titles$color <- pals$vf[ titles$node_col ]
    titles$fill  <- pals$vt[ titles$node_col ]
  }

  if(dir %in% c("tb", "bt")) {
    legend <- .legend_vertical(legend, titles, margins)
  } else {
    legend <- .legend_horizontal(legend, titles, margins)
  }

  legend
}

# just the variable titles
layout_legend_minimal <- function(layout, margins) {

  dir <- get_dir(layout)

  nodes <- as_tibble(layout) |>
    distinct(.data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1) |>
    mutate(node_key = paste0("legend_title_", 1:n())) |>
    mutate(label = .data[["node_col"]]) |>
    mutate(label_type = "var_name_label") |>
    mutate(shape = NA)

  pals <- .get_legend_pal(layout)

  if(!is.null(pals$vf) & !is.null(pals$vt)) {
    nodes$color <- pals$vf[ nodes[["node_col"]] ]
    nodes$fill  <- pals$vt[ nodes[["node_col"]] ]
  } else {
    nodes$color <- "black"
    nodes$fill <- "white"
  }

  if(dir %in% c("bt", "tb")) {
    nodes$width <- .8 * margins$left
    nodes$height <- nodes$full_h[1]
    nodes$x <- margins$left / 2
  } else {
    nodes$width <- max(.6 * nodes$full_w[1], nodes$width[1])
    nodes$height <- .8 * margins$bottom
    nodes$y <- margins$bottom / 2
  }

  nodes <- .use_alias_col(nodes, layout)
  list(titles = nodes)
}
