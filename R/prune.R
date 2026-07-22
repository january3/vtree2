# rig a data frame which contains columns with names taken from node_col
# and values taken from node_val.
.add_virt_cols <- function(nodes) {

  colnames <- unique(na.omit(nodes$node_col))
  mask_df <- map_dfc(colnames, \(nm) {
    tibble(!!nm := ifelse(nodes$node_col == nm, nodes$node_val, NA))

  })

  bind_cols(nodes, mask_df)
}





# here we need to a) create a mask vector which tells which nodes to keep
# and which to prune, b) create a new graph not only with the nodes pruned
# which are indicated by mask, but also by all nodes that follow them. We
# do this with map_bfs_lgl() which traverses the graph in breadth-first order
# Note: the problem here is when you try is.na(), b/c nodes which are not
# for the given column will also have NA values, so you can't distinguish
# between a "true" NA value and "not applicable" NA value.
# Possible solutions: 1) we only allow categorical data. For categorical
# data, we can define a "special" NA value, smth like "____NA" or similar,
# unlikely to be a real value for the columns. 2) define a special
# "has_attr()" function which must be used in conjunction with is.na() to
# check whether the node has that attribute.

#' Prune a vtree graph
#'
#' `prune()` prunes a vtree graph by removing nodes that satisfy a given condition.
#' The condition is evaluated in the context of the node attributes,
#' allowing for flexible pruning based on node values.
#' If a node is pruned, all subsequent nodes in the path are also pruned.
#'
#' `keep()` is a convenience function that keeps only the nodes that
#' satisfy the condition and prunes everything else.
#'
#' @param vtree A vtree graph object.
#' @param condition A logical expression that defines the pruning
#'              condition. If no condition is provided, no pruning is done,
#'              except for the removal of nodes with NA values with
#'              `na.rm`.
#' @param keep If TRUE, keeps the nodes that satisfy the condition and prunes
#'              everything else.
#' @param na.rm If TRUE, removes nodes with NA values in the evaluated
#'              condition. If it is a character vector, then it is treated
#'              as a vector of column names for which all NA values should
#'              be removed.
#' @return A pruned vtree object.
#' @importFrom rlang is_empty enquo eval_tidy
#' @importFrom stats na.omit
#' @importFrom dplyr bind_cols
#' @importFrom tibble tibble
#' @export
prune <- function(vtree, condition, keep = FALSE, na.rm = FALSE) {
  if(missing(condition)) {
    condition <- expr(FALSE)
  }
  condition <- enquo(condition)

  .prune(vtree, condition, keep = keep, na.rm = na.rm)

}

.prune <- function(vtree, condition, keep = FALSE, na.rm = FALSE,
                   return_mask = FALSE) {
  # we need these cols to be able to naturally evaluate the condition using
  # data vars
  vcols <- .add_virt_cols(vtree |> activate("nodes") |> as_tibble())

  # here we create the pruning mask
  prune <- eval_tidy(condition, data = vcols)

  if(is.character(na.rm)) {
    stopifnot(all(na.rm %in% colnames(vcols)))
    nas <- lapply(na.rm, \(col) {
      vcols$node_col == col & is.na(vcols$node_val)
    }) |> reduce(`|`)
    prune <- prune | nas
  } else if(na.rm) {
    nas <- vcols |> pull("node_val") |> is.na()
    prune <- prune | nas
  }

  if(keep) {
    prune <- !prune
  }

  ret <- vtree |>
    activate("nodes") |>
    mutate(.vtree_prune = prune) |>
    mutate(.vtree_prune2 = map_bfs_lgl(
      root = 1,
      mode = "out",
      .f = \(node, path, ...) {
        #print(node)
        #print(path)
        return(.N()$.vtree_prune[node] || any(.N()$.vtree_prune[path$node]))
    })) |>
    filter(!.data[[".vtree_prune2"]]) |>
    select(-all_of(c(".vtree_prune", ".vtree_prune2")))

  as_vtree(ret)
}

#' @rdname prune
#' @export
keep <- function(vtree, condition) {
  condition <- rlang::enquo(condition)
  prune(vtree, !!condition, keep = TRUE)
}

