# extract a data frame corresponding to one level of the tree
.extract_level <- function(nodes, cn) {

  nodes |>
    filter(.data[["node_col"]] == cn) |>
    select(all_of(c("node_id", "parent_id", "node_val", "n", "freq",
                    "tot_n", "missing", "denom"))) |>
    rename(!!cn := "node_val") |>
    rename(!!paste0(cn, "_n") := "n") |>
    rename(!!paste0(cn, "_freq") := "freq") |>
    rename(!!paste0(cn, "_tot_n") := "tot_n") |>
    rename(!!paste0(cn, "_missing") := "missing") |>
    rename(!!paste0(cn, "_denom") := "denom")
}



#' Print a vtree pattern
#'
#' @param x A vtree pattern object.
#' @param ... Ignored
#' @importFrom purrr imap_int
#' @return Invisibly returns the input object.
#' @export
print.vtree_pattern <- function(x, ...) {
  cols <- get_cols(x)
  N <- get_n(x)

  cat(cli::col_blue(paste("vtree pattern object with",
               length(cols), "variables and", N, "observations\n")))
  cat("Variables:", paste(cols, collapse = ", "), "\n")
  cat(cli::col_blue("Overview:\n"))

  labs <- map_dfc(cols, \(cn) {
    tibble(!!cn := sprintf("%s n=%d (%.0f%%)", x[[cn]],
            x[[paste0(cn, "_n")]],
            100 * x[[paste0(cn, "_freq")]]))
  })

  # determine maximum string length for each column
  max_lens <- imap_int(labs, \(col, cn) max(nchar(c(cn, col))))

  labs <- map_dfc(1:length(cols), \(i) {
    cn <- cols[i]
    col <- labs[[i]]
    max_len <- max_lens[i]
    # pad the column with spaces to the right
    padded_col <- sprintf(paste0("% ", max_len, "s"), col)
    tibble(!!cn := padded_col)
  }) |>
    mutate(across(everything(), \(col) { 
      col[c(FALSE, col[-1] == col[-length(col)])] <- "" # remove duplicates
      col
  }))

  colorDF::print_colorDF(labs)
  invisible(x)
}

#' Convert a vtree to a pattern
#'
#' Converts a vtree object to a pattern data frame, showing unique
#' combinations of variable levels and their frequency.
#'
#' A "pattern" is a data frame in which each rows corresponds to one path
#' through the tree. Each row contains the values of the variables
#' corresponding to nodes along that path, along with the calculated
#' frequencies and counts for each variable along the path.
#'
#' Paterns are useful to understand which combinations of variables are
#' present and which are most frequent in the data.
#'
#' By default, the patern sorting is given by the initial order of the
#' variables. However, as a pattern is just a data frame (tibble), it can
#' be sorted and filtered in any way you like, e.g. with dplyr::arrange()
#' or dplyr::filter(). However, mind that the result still has the
#' `vtree_pattern` class, so you can still use plot() on it.
#'
#' For a better overview, the default print() method for vtree patterns
#' will printe a nicely formatted version of the data frame. You can see
#' the underlying data frame by using as_tibble() on the pattern object.
#' @param vtree A vtree object.
#' @return A data frame of class vtree_pattern in 
#'         which each row corresponds to one path through the tree.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' pat <- pattern(vt) |> dplyr::arrange(desc(Survived_n))
#' plot(pat)
#' @export
pattern <- function(vtree) {
  ensure(vtree, "vtree")

  nodes <- as_tibble(vtree)

  maxl <- max(nodes[["level"]])

  # get the column names
  cnms <- get_cols(vtree)

  d1 <- .extract_level(nodes, cnms[1]) |>
    select(-all_of("parent_id"))

  for(i in 2:maxl) {
    cn <- cnms[i]
    d2 <- .extract_level(nodes, cn)
    d1 <- merge(d1, d2, by.x = "node_id", by.y = "parent_id", all = TRUE) |>
      # replace the node_id column with the latest node_id
      # eventually, each row is id'ed by the last node (leaf) in the path.
      select(-all_of("node_id")) |>
      rename(node_id = "node_id.y")
  }

  totn <- get_n(vtree)

  d1 <- d1 |>
    mutate(path = nodes$path[match(.data[["node_id"]], nodes$node_id)]) |>
    select(all_of(c("path", "node_id")), everything()) |>
    mutate(freq = .data[[ paste0(last(cnms), "_n") ]] / totn)

  d1 <- as_tibble(d1)
  class(d1) <- c("vtree_pattern", class(d1))
  d1 <- set_cols(d1, cnms)
  d1 <- copy_attrs(d1, vtree, c("N", "vp", "levels", "sep", "alias",
                                    "palette", "source_summary"))
  d1
}


# create a vtree from a pattern for plotting purposes.
#' @importFrom dplyr last row_number
vtree_from_pattern <- function(pat) {
  ensure(pat, "vtree_pattern")

  cnms <- get_cols(pat)
  levels <- get_levels(pat)

  # we create the vtree manually. This is mostly for plotting purposes.
  # first, the root.
  root <- tibble(path = "root",
                 node_col = "root",
                 node_val = "",
                 parent = NA_character_,
                 path_l = list(list()),
                 level = 0,
                 n = get_n(pat),
                 tot_n = get_n(pat),
                 missing = NA,
                 freq = 1.0,
                 denom = get_n(pat),
                 branch = NA_integer_,
                 depth = 0L)

  # for each row in the pattern, we create one branch of the tree with the
  # interim nodes. The long branches are attached to the root only.

  sep <- get_sep(pat)
  sep_cv <- sep$cv %||% ':'
  sep_path <- sep$path %||% '/'

  P <- nrow(pat)
  K <- length(cnms)

  pattern_nodes <- tibble(
    path = "pattern",
    node_col = "pattern",
    node_val = "",
    parent = "root",
    path_l = rep(list(list()), P),
    level = 1L,
    n = pat[[paste0(cnms[K], "_n")]],
    tot_n = get_n(pat),
    missing = 0,
    freq = pat[[paste0(cnms[K], "_n")]] / get_n(pat),
    denom = get_n(pat),
    branch = seq_len(P),
    depth = 0L
  )

  value_nodes <- purrr::map_dfr(seq_along(cnms), \(i) {
    cn <- cnms[i]

    parts <- lapply(cnms[seq_len(i)], \(cc) {
      paste0(cc, sep_cv, pat[[cc]])
    })

    paths <- do.call(paste, c(parts, sep = sep_path))
    paths_parent <- do.call(paste, c(parts[-length(parts)], sep = sep_path))

    tibble(
      path = paths,
      node_col = cn,
      node_val = pat[[cn]],
      parent = ifelse(i == 1, "pattern", paths_parent),
      path_l = rep(list(list()), length(paths)),
      level = i + 1L,
      n = pat[[paste0(cn, "_n")]],
      tot_n = pat[[paste0(cn, "_tot_n")]],
      missing = pat[[paste0(cn, "_missing")]],
      freq = pat[[paste0(cn, "_freq")]],
      denom = pat[[paste0(cn, "_denom")]],
      branch = seq_len(P),
      depth = i
    )
  })

  nodes <- rbind(root, pattern_nodes, value_nodes) |>
    mutate(node_id = row_number()) |>
    group_by(.data[["branch"]]) |>
    mutate(parent_id = lag(.data[["node_id"]], default=1)) |>
    ungroup() |>
    mutate(parent_id = ifelse(.data[["level"]] == 0, NA, .data[["parent_id"]])) |>
    mutate(node_key = paste0("node_", .data[["node_id"]])) |>
    dplyr::arrange(.data[["level"]], .data[["node_id"]])

  edges <- node2edge(nodes)
  
  vtree <- tbl_graph(nodes = nodes, edges = edges,
                     directed = TRUE, node_key = "node_key")

  vtree <- set_cols(vtree, c("pattern", cnms))
  vtree <- set_levels(vtree, c(pattern="", levels))
  vtree <- copy_attrs(vtree, pat, c("N", "sep", "vp", "alias", "levels",
                                    "palette", "source_summary"))
  ret <- as_vtree(vtree)
  class(ret) <- c("vtree_from_pattern", class(ret))
  ret
}

#' Plot a pattern object
#'
#' Plots a vtree pattern object.
#'
#' @param x A vtree pattern object.
#' @param ... Additional arguments passed to plot.vtree()
#' @param sort_by The variable to sort the nodes by. Can be "freq" (default),
#'       "n", or any of the variable names in the pattern object. If NA,
#'       the pattern will be plotted in the order of the rows in the pattern object.
#' @param lwidth,lheight The width and height of the nodes in the plot,
#'        relative to the maximum available space.
#' @param palettes A vector of color palettes to use for the nodes.
#' @param pattern_fill The fill color for the pattern nodes (the ones on
#'        the left side of the tree, showing how frequent each pattern is).
#' @param show_root Whether to show the root node in the plot.
#' @seealso [plot.vtree()] for plotting vtree objects.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' pat <- pattern(vt) |> dplyr::arrange(-Survived_n)
#' plot(pat)
#' @return A vtree plot (a grid::gTree object) of the pattern object,
#'         invisibly.
#' @export
plot.vtree_pattern <- function(x, ...,
                      sort_by = freq,
                      palettes = c("Reds", "Blues", "Greens",
                                   "Oranges", "Purples"),
                      pattern_fill = "#fc9272",
                      lwidth = .4, lheight = .9,
                      show_root = FALSE) {
  ensure(x, "vtree_pattern")
  sort_by <- rlang::enquo(sort_by)
  if(!rlang::is_na(rlang::quo_get_expr(sort_by))) {
    x <- arrange(x, !!sort_by)
  }

  vt <- vtree_from_pattern(x)

  mask <- find_nodes(vt, level == 1)
  vt <- vt |>
    add_labels(fmt="{val_alias}") |>
    add_labels(fmt="{n} ({pct}%)", mask=mask)

  # cautious color handling
  palettes <- c("Blues", palettes)
  pal <- get_palette(vt)

  if(length(pal) == 0) {
    vt <- add_palette(vt, palettes = palettes) |>
      mutate(fill = ifelse(.data[["level"]] == 1,
                           pattern_fill, .data[["fill"]])) |>
      mutate(color = contrast_color(.data[["fill"]]))
  } else {
    # we need to repopulate the fill and color columns
    # they got lost on the way from vtree to pattern and
    # now we are coming back to a vtree.
    vt <- add_palette(vt, palettes = palettes,
                          var_palette = pal$fill$scale,
                          var_colors = pal$fill$vars) |>
          add_palette(palettes = palettes, what="text",
                          var_palette = pal$color$scale,
                          var_colors = pal$color$vars)
  }


  # fix the pattern node colors
  vt <- mutate(vt, fill = ifelse(.data[["level"]] == 1,
                           pattern_fill, .data[["fill"]])) |>
        mutate(color = ifelse(.data[["level"]] == 1,
                           contrast_color(pattern_fill), .data[["color"]]))

  plot(vt, show_root = FALSE,
       layout = "regular",
       lwidth = lwidth, lheight = lheight, ...)
}
