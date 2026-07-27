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
  cat("# vtree pattern\n")
  cnms <- attr(x, "cols")

  labs <- map_dfc(cnms, \(cn) {
    tibble(!!cn := sprintf("%s n=%d (%.0f%%)", x[[cn]],
            x[[paste0(cn, "_n")]],
            100 * x[[paste0(cn, "_freq")]]))
  })

  # determine maximum string length for each column
  max_lens <- imap_int(labs, \(col, cn) max(nchar(c(cn, col))))

  labs <- map_dfc(1:length(cnms), \(i) {
    cn <- cnms[i]
    col <- labs[[i]]
    max_len <- max_lens[i]
    # pad the column with spaces to the right
    padded_col <- sprintf(paste0("% ", max_len, "s"), col)
    tibble(!!cn := padded_col)
  }) |>
    mutate(across(everything(), \(col) { 
                    col[duplicated(col)] <- "" 
                    col })) # remove duplicates

  print(labs)
  invisible(x)
}

#' Convert a vtree to a pattern
#'
#' Convert a vtree to a pattern
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
#' variables. However, as a pattern is just a data frame, it can be sorted
#' in any way you like.
#'
#' For a better overview, the default print() method for vtree patterns
#' will printe a nicely formatted version of the data frame. You can see
#' the underlying data frame by using as.data.frame() on the pattern object.
#' @param vtree A vtree object.
#' @return A data frame of class vtree_pattern in 
#'         which each row corresponds to one path through the tree.
#' @export
pattern <- function(vtree) {
  if(!inherits(vtree, "vtree")) {
    cli_abort(x = "pattern() requires a vtree object")
  }

  nodes <- as_tibble(vtree)

  maxl <- max(nodes[["level"]])

  # get the column names
  cnms <- attr(vtree, "cols")

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

  d1 <- d1 |>
    mutate(ID = nodes$ID[match(.data[["node_id"]], nodes$node_id)]) |>
    select(all_of(c("ID", "node_id")), everything())

  class(d1) <- c("vtree_pattern", class(d1))
  attr(d1, "cols") <- cnms
  attr(d1, "N") <- attr(vtree, "N")
  attr(d1, "vp") <- attr(vtree, "vp")
  d1
}


# create a vtree from a pattern for plotting purposes.
vtree_from_pattern <- function(pat) {
  if(!inherits(pat, "vtree_pattern")) {
    cli_abort(x = "Input must be a vtree_pattern object")
  }

  cnms <- attr(pat, "cols")

  # we create the vtree manually. This is mostly for plotting purposes.
  # first, the root.
  root <- tibble(
                  ID = "root",
                  node_col = "root",
                  node_val = "",
                  parent = NA_character_,
                  path = list(list()),
                  level = 0,
                  n = attr(pat, "N"),
                  tot_n = attr(pat, "N"),
                  missing = NA,
                  freq = 1.0,
                  denom = attr(pat, "N"))

  # for each row in the pattern, we create one branch of the tree with the
  # interim nodes. The long branches are attached to the root only.

  nodes <- map_dfr(1:nrow(pat), \(i) {
    collect_nodes(pat[i, ], cnms) |>
      mutate(level = row_number())
  }) 

  nodes <- bind_rows(root, nodes) |>
    mutate(node_id = row_number()) |>
    mutate(parent_id = lag(.data[["node_id"]])) |>
    mutate(parent_id = ifelse(.data[["level"]] == 1, 1, .data[["parent_id"]])) |>
    mutate(node_key = paste0("node_", .data[["node_id"]])) |>
    arrange(level, node_id)

  edges <- node2edge(nodes)
  
  vtree <- tbl_graph(nodes = nodes, edges = edges,
                     directed = TRUE, node_key = "node_key")

  as_vtree(vtree)
}
