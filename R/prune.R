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
prune <- function(graph, condition, .keep = FALSE, na.rm = FALSE) {
  condition <- rlang::enquo(condition)

  # we need these cols to be able to naturally evaluate the condition using
  # data vars
  vcols <- .add_virt_cols(graph |> activate("nodes") |> as_tibble())

  # here we create the pruning mask
  prune <- rlang::eval_tidy(condition, data = vcols)
  if(na.rm) {
    nas <- vcols |> pull("node_val") |> is.na()
    prune <- prune | nas
  }

  if(.keep) {
    prune <- !prune
  }

  ret <- graph |>
    activate(nodes) |>
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

  class(ret) <- c("vtree_graph", class(ret))
  ret
}

keep <- function(graph, condition) {
  condition <- rlang::enquo(condition)
  prune(graph, !!condition, .keep = TRUE)
}

