# vertical legend arrangement
.legend_vertical <- function(legend, titles, maxpos, margins) {

  legend <- legend |>
    mutate(height = .data[["full_h"]] / maxpos) |>
    mutate(x = margins$left / 2) |>
    mutate(width = .8 * margins$left) |>
    mutate(y = .data[["y"]] - .data[["full_h"]] / 2 +
           (maxpos - .data[["pos"]] - 1.5) * .data[["height"]])

  titles <- titles |>
    mutate(height = 2 * .data[["full_h"]] / maxpos) |>
    mutate(x = margins$left / 2) |>
    mutate(width = .8 * margins$left) |>
    mutate(y = .data[["y"]] + maxpos * .data[["height"]]/4 -
           2*.data[["height"]]/3)

  list(levels=legend, titles=titles)
}

# horizontal legend arrangements
.legend_horizontal <- function(legend, titles, maxpos, margins) {
  legend <- legend |>
    mutate(x = .data[["x"]],
           y = margins$bottom -
             (.data[["pos"]] + 1) * margins$bottom / maxpos) |>
    mutate(height = .9 * margins$bottom / maxpos) |>
    mutate(width = .data[["width"]])

  maxy <- max(legend[["y"]])

  titles <- titles |>
    mutate(height = .9 * margins$bottom / maxpos) |>
    mutate(y = maxy + .data[["height"]] * 1.1) |>
    mutate(height = .data[["height"]] * 2)

  list(levels=legend, titles=titles)
}

# prepare a summary using the aliases
#' @importFrom purrr map_chr map2_chr
.layout_summary <- function(layout) {

  ret <- summary(layout)
  nodes <- as_tibble(layout)
  if(!
     (all(nodes[-1, ][["node_col"]] %in% ret[["node_col"]]) &&
      all(nodes[-1, ][["node_val"]] %in% ret[["node_val"]]))) {
    cli_abort(c(x="corrupted vtree object: summary and node table not compatible"))
  }

  c_alias <- get_alias_attr(layout, "col")

  if(!is.null(c_alias)) {
    ret[["col_alias"]] <- map_chr(ret[["node_col"]],
                                 \(col) c_alias[[col]] %||% col)
  } else {
    ret[["col_alias"]] <- ret[["node_col"]]
  }

  v_alias <- get_alias_attr(layout, "val")
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

# create a layout for the legend.
layout_legend <- function(layout, margins) {

  dir <- attr(layout, "dir")

  #req_cols <- c("x", "y", "width", "height", "shape", "fill", "label"))
  cnms <- names(layout)

  pospar <- as_tibble(layout) |>
    filter(.data[["node_key"]] != "node_1") |>
    distinct(pick("node_col"), .keep_all = TRUE) |>
    select(all_of(c("node_col", "level", "x", "y", "width", "height", "full_w",
                    "full_h", "shape")))

  lvls <- levels(layout)
  pal <- attr(layout, "palette")

  if(is.null(pal)) {
    cli::cli_inform(c(i="palette attribute is NULL",
               "legend will be black and white"))
    pals_color <- NULL
    pals_fill <- NULL
    na_text <- "black"
    na_fill <- "white"
    pals_vt <- NULL
    pals_vf <- NULL
  } else {
    pals_color <- pal$color$scale %||% NULL
    pals_fill <- pal$fill$scale %||% NULL
    na_text <- pal$color$na %||% "black"
    na_fill <- pal$fill$na %||% "white"
    pals_vt <- pal$color$vars %||% NULL
    pals_vf <- pal$fill$vars %||% NULL
  }

  summaries <- .layout_summary(layout) |>
    group_by(.data[["node_col"]]) |>
    mutate(pos = 1:n()) |>
    ungroup() |>
    filter(.data[["count"]] != 0) |>
    mutate(fill = .get_vals(.data[["node_col"]],
                            .data[["node_val"]],
                            pals_fill, na_fill) %||% na_fill) |>
    mutate(color = .get_vals(.data[["node_col"]],
                             .data[["node_val"]],
                             pals_color, na_text) %||% na_text)


  legend <- merge(pospar, summaries, by = "node_col", all.y=TRUE) |>
      mutate(node_key = paste0("legend_", 1:n())) |>
      mutate(label_type = "var_level_label") |>
      filter(!is.na(.data[["x"]]))

  maxpos <- max(legend[["pos"]]) + 2

  titles <- legend |>
    group_by(.data[["node_col"]]) |>
    dplyr::slice(1) |>
    ungroup() |>
    mutate(node_key = paste0("legend_title_", 1:n())) |>
    mutate(label = .data[["col_alias"]]) |>
    mutate(label_type = "var_name_label") |>
    mutate(shape = NA)

  if(is.null(pals_vt) || is.null(pals_vf)) {
    titles$color <- "black"
    titles$fill <- "white"
  } else {
    titles$color <- pals_vt[ titles$node_col ]
    titles$fill  <- pals_vf[ titles$node_col ]
  }

  if(dir %in% c("tb", "bt")) {
    legend <- .legend_vertical(legend, titles, maxpos, margins)
  } else {
    legend <- .legend_horizontal(legend, titles, maxpos, margins)
  }

  legend
}

# just the variable titles
layout_legend_minimal <- function(layout, margins) {

  dir <- attr(layout, "dir")

  nodes <- as_tibble(layout) |>
    distinct(.data[["node_col"]], .keep_all = TRUE) |>
    dplyr::slice(-1) |>
    mutate(node_key = paste0("legend_title_", 1:n())) |>
    mutate(label = .data[["node_col"]]) |>
    mutate(label_type = "var_name_label") |>
    mutate(shape = NA)

  if(is.null(attr(layout, "palette"))) {
    cli::cli_inform(c(i="palette attribute is NULL",
               "legend will be black and white"))
    pals_vt <- NULL
    pals_vf <- NULL
  } else {
    pals_vt <- attr(layout, "palette")$color$vars
    pals_vf <- attr(layout, "palette")$fill$vars
  }

  if(!is.null(pals_vf) & !is.null(pals_vt)) {
    nodes$color <- pals_vt[ nodes[["node_col"]] ]
    nodes$fill  <- pals_vf[ nodes[["node_col"]] ]
  } else {
    nodes$color <- "black"
    nodes$fill <- "white"
  }

  if(dir %in% c("bt", "tb")) {
    nodes$width <- margins$left
    nodes$height <- nodes$full_h[1]
    nodes$x <- margins$left / 2
  } else {
    nodes$width <- nodes$full_w[1]
    nodes$height <- margins$bottom
    nodes$y <- margins$bottom / 2
  }

  nodes <- .use_alias_col(nodes, layout)
  list(titles = nodes)
}
