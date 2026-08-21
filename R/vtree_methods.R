#' Convert a vtree_graph to a tbl_graph
#'
#' Convert a vtree_graph to a tbl_graph
#'
#' @param x A vtree object
#' @param ... Ignored
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' as_tbl_graph(vt) |> plot()
#' @return A tbl_graph object
#' @export
as_tbl_graph.vtree <- function(x, ...) {
  class(x) <- setdiff(class(x), "vtree")
  x
}

# A list of character vectors, one for each variable split in the tree,
# with each ordered vector containing the levels of that variable

#' Get the variable names of a vtree object
#'
#' @param x A vtree object.
#' @return A character vector of variable names
#' @examples
#' vt <- vtree(titanicNA)
#' names(vt)
#' @export
names.vtree <- function(x) {
  attr(x, "cols")
}

#' Is the vtree based on valid percentages?
#'
#' If the tree is based on valid percentages (excluding NAs), the function
#' returns TRUE.
#'
#' The vtree calculations can use as denominator either all data or "valid"
#' data, i.e. data excluding the missing observations ("NAs"). For example,
#' if the variable "gender" contains 30 males, 30 females and 40 NAs, with
#' vp (which is the default setting), the percentage of either sex is 50%;
#' with vp=FALSE, it is 30%.
#' @param x vtree or vtree_pattern object
#' @examples
#' data(titanicNA)
#' vt <- vtree(titanicNA)
#' is_vp(vt) # TRUE
#' vt <- vtree(titanicNA, Class, Survived, .vp = FALSE)
#' is_vp(vt) # FALSE
#' @return TRUE if the object is based on valid percentages, FALSE
#'         otherwise.
#' @export
is_vp <- function(x) {
  ensure_vtree(x)
  attr(x, "vp")
}


#' Create, modify, and delete node columns
#'
#' This is a wrapper around the regular [dplyr::mutate()]
#' function which preserves the vtree class.
#'
#' Immutable columns: some columns of the vtree are immutable. Changing
#' them can result in very bad things happening, starting with plots that
#' don't work and ending up with incorrect numbers on your figure. Of course,
#' there are many ways to modify them if you really want to, but at least
#' this mutate gives some protection.
#' @param .data A vtree object.
#' @param .edges If TRUE, modify the edges rather than the nodes.
#' @param .check If TRUE, make sure that the immutable columns did not
#'        change
#' @param ... Name-value pairs of expressions, passed to [dplyr::mutate()].
#'   The name gives the name of the new or modified node attribute, and the
#'   value defines its contents. The expressions are evaluated using
#'   tidy evaluation in the context of the node table.
#' @return An object of class vtree
#' @seealso
#' [dplyr::mutate()], [tidygraph::activate()]
#' @examples
#' vt <- vtree(titanicNA) |>
#'   add_labels() |>
#'   mutate(label = ifelse(is.na(node_val), "Missing", label))
#' @export
mutate.vtree <- function(.data, ..., .edges = FALSE, .check = TRUE) {
  if(.edges) {
    .data <- .data |> activate("edges")
  } else {
    .data <- .data |> activate("nodes")
  }

  class(.data) <- setdiff(class(.data), "vtree")
  ret <- .data |> mutate(...) |> activate("nodes") |> as_vtree()
  if(!.check) {
    return(ret)
  }

  immutable <- c("node_col", "node_id", "path", "freq", "count",
                 "denom", "node_key", "tot_n", "vp")

  retnodes <- as_tibble(ret)
  datanodes <- as_tibble(.data)
  all_good <- purrr::map_lgl(set_names(immutable), \(col) {
                   all(retnodes[[col]] == datanodes[[col]])
                 })
  if(!all(all_good)) {
    changed <- immutable[!all_good]
    cli_abort(c(x = 
     "you tried to modify following immutable column(s) of a vtree object:",
     "{changed}"))
  }
  ret
}


#' Get the levels of a vtree object
#' 
#' Returns a list of character vectors, one for each variable split in the tree,
#' with each ordered vector containing the levels of that variable.
#' @param x A vtree object.
#' @return A list of character vectors, one for each variable split in the tree,
#' @examples
#' vt <- vtree(titanicNA)
#' levels(vt)
#' @export
levels.vtree <- function(x) {
  attr(x, "levels")
}

#' Get the column names of a vtree object
#'
#' Returns the column names of the node data frame of a vtree object.
#' @param x A vtree object.
#' @return A character vector of column names
#' @examples
#' vt <- vtree(titanicNA, Class, Sex, Survived)
#' nodecols(vt)
#' @export
nodecols <- function(x) {
  colnames(as_tibble(x))
}


#' Print a vtree object
#'
#' Prints a vtree object and shows selected columns from the node data
#' frame.
#' @param x A vtree object.
#' @param ... Ignored
#' @return Invisibly returns the input object.
#' @export
print.vtree <- function(x, ...) {
  cols <- attr(x, "cols")
  N <- attr(x, "N")
  cat(cli::col_blue(paste("vtree object with",
               length(cols), "variables and", N, "observations\n")))
  cat("Variables:", paste(cols, collapse = ", "), "\n")
  if(is_vp(x)) {
    cat("Frequencies computed as valid percentages (vp == TRUE)\n")
  } else {
    cat("Frequencies computed with total numbers (vp == FALSE)\n")
  }
  if(has_layout(x)) {
    cat("Object has a layout\n")
  }

  cols2check <- c("label", "color", "fill", "col_alias", "var_alias")
  cols2check <- cols2check[ cols2check %in% nodecols(x) ]
  if(length(cols2check) > 0L) {
    cat("Properties present: ")
    cat(paste(cols2check, collapse=", "))
    cat("\n")
  }

  col_to_show <- c("path", "n", "freq",
                   "tot_n", "missing", "denom")
  cat(cli::col_blue("Overview:\n"))
  colorDF::print_colorDF(as_tibble(x |> select(all_of(col_to_show))), ...)
  invisible(x)
}


#' Show per-variable summaries of a vtree object data
#'
#' Show per-variable summaries of the data on which a vtree object was
#' constructed. The summary does not change when the vtree object is modified.
#'
#' For each variable included in a vtree object, and for all levels of that
#' variable, the counts and calculated frequencies of that level in the
#' variable are shown, as well as labels that can be used for displaying
#' information. The frequency calculation depends on whether the tree was
#' constructed with valid percentages (i.e., excluding the NAs), or with
#' all samples.
#'
#' Summary returned by `summary.vtree()` is the original data summary; it
#' does not change when the vtree object is modified.
#'
#' The returned data frame (tibble) contains the following columns:
#'  * `node_col`: the name of the variable
#'  * `node_val`: the level of the variable
#'  * `count`: number of samples which have this level
#'  * `freq`: frequency of this level relative to the denominator
#'  * `denom`: the denominator used to calculate the frequency
#'  * `label`: a printable label constructed from these values
#' @param object A vtree object.
#' @param ... Ignored
#' @return A data frame with summaries (counts and frequencies) for each
#' level of each variable in the vtree.
#' @export
summary.vtree <- function(object, ...) {
  attr(object, "source_summary")
}


has_layout <- function(x) {
  ensure_vtree(x)

  node_names <- igraph::vertex_attr_names(x)
  edge_names <- igraph::edge_attr_names(x)

  has_cols <- all(c("x", "y", "width", "height") %in% node_names) &&
              all(c("x1", "x2", "y1", "y2") %in% edge_names)

  has_cols || inherits(x, "vtree_layout")
}

has_fill <- function(x) {
  ensure_vtree(x)
  "fill" %in% nodecols(x)
}
