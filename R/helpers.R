#' @importFrom cli cli_abort
die <- function(message = "Unspecified error.",
                call = .envir, .envir = parent.frame()) {
  cli_abort(c(x = message), call = call)
}


# extract required columns from a tidygraph object
# this is b/c extracting all vertex attributes is costly
node_attrs <- function(graph, cols) {
  tibble::as_tibble(
    setNames(
      lapply(cols, \(col) igraph::vertex_attr(graph, col)),
      cols
    ))
}


as_nibble <- function(vtree) {
  cols <- c("node_id", "node_key",
            "parent_id", "parent",
            "node_col", "node_val",
            "level", "freq")

  node_attrs(vtree, cols)
}

# if grobs are in the vtree, extract them and return as a list
extract_grobs <- function(vtree) {
  grobs <- NULL

  vtree_names <- igraph::vertex_attr_names(vtree)
  if("grob" %in% vtree_names) {
    grobs <- igraph::vertex_attr(vtree, "grob")
  }

  grobs
}

remove_grobs <- function(vtree) {
  vtree_names <- igraph::vertex_attr_names(vtree)
  if("grob" %in% vtree_names) {
    vtree <- vtree |> mutate(grob = NULL)
  }

  vtree
}

insert_grobs <- function(vtree, grobs) {
  if(!is.null(grobs)) {
    vtree <- vtree |> mutate(grob = grobs)
  }

  vtree
}
