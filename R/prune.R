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

#' Find nodes and prune a vtree graph
#'
#' `prune()` prunes a vtree graph by removing nodes that satisfy a given condition.
#' The condition is evaluated in the context of the node attributes,
#' allowing for flexible pruning based on node values.
#' If a node is pruned, all subsequent nodes in the path are also pruned.
#'
#' `keep()` is a convenience function that keeps only the nodes that
#' satisfy the condition and prunes everything else.
#'
#' `find_nodes()` returns a logical vector identifying the nodes which
#' fullfill a certain condition.
#'
#' `condition` can be any logical vector that refers to either the columns
#' in the node data frame of the vtree object, or the names of the vtree
#' variables. For example, you can use `node_col` to find nodes which
#' correspond to a certain variable, and then use the variable name to
#' search for a specific value.
#'
#' @param vtree A vtree graph object.
#' @param condition A logical expression that defines the pruning
#'              condition. If no condition is provided, no pruning is done,
#'              except for the removal of nodes with NA values with
#'              `na.rm`.
#' @param follow_only if TRUE, keep the nodes selected by condition, but
#'              prune all following nodes.
#' @param keep If TRUE, keeps the nodes that satisfy the condition and prunes
#'              everything else.
#' @param na.rm If TRUE, removes nodes with NA values in the evaluated
#'              condition. If it is a character vector, then it is treated
#'              as a vector of column names for which all NA values should
#'              be removed.
#' @return `keep()` and `prune()` return a pruned vtree object.
#' `find_nodes()` returns a logical vector corresponding to the tree nodes
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#'
#' # find the node corresponding to the 1st Class
#' mask <- find_nodes(vt, node_col == "Class" & Class == "1st")
#'
#' # find nodes with frequencies below 15%
#' mask <- find_nodes(vt, freq < .15)
#'
#' # find nodes where the fraction of survivorship was less than 80
#' mask <- find_nodes(vt, node_col == "Survived" &
#'                    node_val == "No" & freq > .2)
#'
#' # mark these nodes with red color on the plot
#' vt |> mutate(fill = ifelse(mask, "red", "white")) |> plot()
#' @importFrom rlang is_empty enquo eval_tidy expr
#' @importFrom stats na.omit
#' @importFrom dplyr bind_cols n
#' @importFrom tibble tibble
#' @export
prune <- function(vtree, condition, follow_only = FALSE,
                  keep = FALSE, na.rm = FALSE) {
  if(missing(condition)) {
    condition <- expr(FALSE)
  }
  condition <- enquo(condition)

  .prune(vtree, condition, follow_only = follow_only,
         keep = keep, na.rm = na.rm)

}


#' @rdname prune
#' @export
find_nodes <- function(vtree, condition) {
  condition <- enquo(condition)

  mask <- .get_mask(vtree, condition)
  mask
}

.get_mask <- function(vtree, condition, keep = FALSE, na.rm = FALSE) {

  # we need these cols to be able to naturally evaluate the condition using
  # data vars
  vcols <- .add_virt_cols(vtree |> activate("nodes") |> as_tibble())

  # here we create the pruning mask
  mask <- eval_tidy(condition, data = vcols)

  # now, some comparisons may return NA.
  # we ignore them - assume that it's not a match.
  mask[ is.na(mask) ] <- FALSE

  # na.rm may be a character vector of columns to check
  # for potential NAs
  if(is.character(na.rm)) {
    stopifnot(all(na.rm %in% colnames(vcols)))
    nas <- lapply(na.rm, \(col) {
      vcols$node_col == col & is.na(vcols$node_val)
    }) |> reduce(`|`)
    mask <- mask | nas
  } else if(na.rm) {
    nas <- vcols |> pull("node_val") |> is.na()
    mask <- mask | nas
  }

  if(keep) {
    mask <- !mask
  }

  mask
}


.find_follow_nodes <- function(vtree, mask) {

  follow <- vtree |>
    activate("nodes") |>
    mutate(.vtree_prune = mask) |>
    mutate(.vtree_prune2 = map_bfs_lgl(
      root = 1,
      mode = "out",
      .f = \(node, path, ...) {
        return(any(.N()$.vtree_prune[path$node]))
  })) |> pull(".vtree_prune2")

  follow
}

# here we actually do the pruning
# follow only: prune only the following nodes, not the nodes that are
# selected by the condition
# na.rm: remove the NA nodes
.prune <- function(vtree, condition,
                   follow_only = FALSE,
                   keep = FALSE, na.rm = FALSE) {

  prune <- .get_mask(vtree, condition, keep, na.rm)

  # find all nodes that follow a node
  follow_mask <- .find_follow_nodes(vtree, prune)

  if(follow_only) {
    mask <- follow_mask
  } else {
    mask <- prune | follow_mask
  }

  ret <- vtree |>
    activate("nodes") |>
    filter(!mask)

  as_vtree(ret)
}

#' @rdname prune
#' @export
keep <- function(vtree, condition) {
  condition <- rlang::enquo(condition)
  prune(vtree, !!condition, keep = TRUE)
}

