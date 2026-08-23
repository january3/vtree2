copy_attrs <- function(to, from, attributes=NULL) {

  if(is.null(attributes)) {
    attributes <- setdiff(names(attributes(from)), "class")
  }

  for(attr in attributes) {
    attr(to, attr) <- attr(from, attr)
  }

  to
}

set_pruned <- function(x, pruned) {
  attr(x, "pruned") <- pruned
  x
}

get_pruned <- function(x) {
  attr(x, "pruned") %||% FALSE
}

get_cols <- function(x) {
  attr(x, "cols")
}

set_cols <- function(x, cols) {
  attr(x, "cols") <- cols
  x
}

get_palette <- function(x) {
  attr(x, "palette") %||% list()
}

set_palette <- function(x, pal) {
  attr(x, "palette") <- pal
  x
}

get_dir <- function(x) {
  attr(x, "dir")
}

set_dir <- function(x, dir) {
  attr(x, "dir") <- dir
  x
}

get_layout_arg <- function(x) {
  attr(x, "layout_arg")
}

set_layout_arg <- function(x, layout_arg) {
  attr(x, "layout_arg") <- layout_arg
  x
}

get_show_root <- function(x) {
  attr(x, "show_root") %||% TRUE
}

set_show_root <- function(x, show_root=TRUE) {
  attr(x, "show_root") <- show_root
  x
}

get_vp <- function(x) {
  attr(x, "vp")
}

set_vp <- function(x, vp) {
  attr(x, "vp") <- vp
  x
}

get_n <- function(x) {
  attr(x, "N")
}

set_n <- function(x, N) {
  attr(x, "N") <- N
  x
}

get_sep <- function(x) {
  attr(x, "sep") %||% list()
}

set_sep <- function(x, sep) {
  attr(x, "sep") <- sep
  x
}

get_levels <- function(x) {
  attr(x, "levels") %||% list()
}

set_levels <- function(x, levels) {
  attr(x, "levels") <- levels
  x
}

get_source_summary <- function(x) {
  attr(x, "source_summary")
}

set_source_summary <- function(x, source_summary) {
  attr(x, "source_summary") <- source_summary
  x
}

set_aliases <- function(x, col=NULL, val=NULL) {
  alias <- list(col=col, val=val)
  attr(x, "alias") <- alias
  x
}

get_aliases <- function(x, what=NULL) {
  alias <- attr(x, "alias")

  if(is.null(alias)) {
    return(NULL)
  }

  if(is.null(alias$col)) {
    cli::cli_warn(c("!" = "alias attribute appears corrupted, missing col element"))
    return(NULL)
  }

  if(is.null(alias$val)) {
    cli::cli_warn(c("!" = "alias attribute appears corrupted, missing val element"))
    return(NULL)
  }

  if(!is.null(what)) {
    if(!what %in% c("col", "val")) {
      cli_abort(c("!" = "unknown alias element {.val {what}}"))
    }

    return(alias[[what]])
  }

  return(alias)
}

has_layout <- function(x) {
  ensure_vtree(x)

  # we trust add_layout()
  if(inherits(x, "vtree_layout")) {
    return(TRUE)
  }

  # but maybe the user created their own layout
  node_names <- igraph::vertex_attr_names(x)
  edge_names <- igraph::edge_attr_names(x)

  has_cols <- all(c("x", "y", "width", "height") %in% node_names) &&
              all(c("x1", "x2", "y1", "y2") %in% edge_names)

  has_cols
}

has_fill <- function(x) {
  ensure_vtree(x)
  "fill" %in% nodecols(x)
}
