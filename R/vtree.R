# A list of character vectors, one for each variable split in the tree,
# with each ordered vector containing the levels of that variable

#' Get the levels of a vtree object
#'
#' Get the levels of a vtree object
#'
#' Returns a list of character vectors, one for each variable split in the tree,
#' with each ordered vector containing the levels of that variable.
#' @param x A vtree object.
#' @return A list of character vectors, one for each variable split in the tree,
#' @export
levels.vtree <- function(x) {
  stopifnot(inherits(x, "vtree"))
  nodes <- x |> activate(nodes) |> as_tibble()

  cnms <- attr(x, "cols") |> set_names()

  ret <- map(cnms, \(cn) {
    vals <- nodes$node_val[nodes$node_col == cn]

    if(is.factor(vals)) {
      vals <- levels(vals)
    } else {
      vals <- unique(vals)
    }
  })
  ret <- ret[ names(ret) %in% nodes$node_col ]
  ret
}

#' Get the variable names of a vtree object
#'
#' @param x A vtree object.
#' @return A character vector of variable names
#' @export
names.vtree <- function(x) {
  stopifnot(inherits(x, "vtree"))
  attr(x, "cols")
}



#' Create, modify, and delete node columns
#'
#' This is a wrapper around the regular [dplyr::mutate()] 
#' function which preserves the vtree class.
#' @param .data A vtree object.
#' @param ... Name-value pairs of expressions, passed to [dplyr::mutate()].
#'   The name gives the name of the new or modified node attribute, and the
#'   value defines its contents. The expressions are evaluated using
#'   tidy evaluation in the context of the node table.
#' @return An object of class vtree
#' @seealso
#' [dplyr::mutate()], [tidygraph::activate()]
#' @export
mutate.vtree <- function(.data, ...) {
  stopifnot(inherits(.data, "vtree"))
  .data <- .data |> activate("nodes")
  class(.data) <- setdiff(class(.data), "vtree")
  .data |> mutate(...) |> as_vtree()
}




#' Print a vtree object
#'
#' Print a vtree object
#'
#' @param x A vtree object.
#' @param ... Ignored
#' @return Invisibly returns the input object.
#' @export
print.vtree <- function(x, ...) {
  stopifnot(inherits(x, "vtree"))
  cols <- attr(x, "cols")
  N <- attr(x, "N")
  cat("vtree object with", length(cols), "columns and", N, "observations\n")
  cat("Columns:", paste(cols, collapse = ", "), "\n")
  invisible(x)
}



#' Convert a tbl_graph to a vtree
#'
#' Convert a tbl_graph to a vtree
#'
#' @param x A tbl_graph object.
#' @return A vtree object
as_vtree <- function(x) {
  stopifnot(inherits(x, "tbl_graph"))

  # integrity checks
  # ------------------
  x <- x |> activate("nodes")

  nodes <- x |> as_tibble()
  req_cols <- c("ID", "node_col", "node_name", "node_val", "node_cv", 
                  "parent", "path", "level", "n", "freq")
  if(!all(req_cols %in% colnames(nodes))) {
    stop(sprintf("Columns %s not in colnames(nodes)",
                 paste(req_cols[ !req_cols %in% colnames(nodes) ], 
                       collapse=", ")
                 ))
  }


  # more than a root
  stopifnot(any(nodes$level > 0))

  # only one root
  stopifnot(sum(nodes$level == 0) == 1)

  N <- nodes$n[ nodes$level == 0 ]

  stopifnot(all(!is.na(nodes$node_col)))

  cnms <- unique(nodes$node_col[ nodes$level > 0 ])

  attr(x, "cols") <- cnms
  attr(x, "N") <- N
  attr(x, "vp") <- TRUE

  if("vp" %in% colnames(nodes) & !all(nodes[["vp"]])) {
    attr(x, "vp") <- FALSE
  }

  class(x) <- c("vtree", class(x))
  x
}



#' Create a vtree object from a data frame
#'
#' Create a vtree object from a data frame of cases
#'
#' The cases data frame used as a first argument should have one row per
#' observation. The selected columns will correspond to the nodes of the vtree.
#'
#' With `vtree_from_freqtable()`, you can create a vtree from a frequency
#' table, where each row corresponds to a unique combination of values and
#' a frequency count.
#'
#' Manipulating a vtree object
#'
#' Vtree objects are little more than tidygraph object of class tbl_graph.
#' You can use the tidygraph package to manipulate them, and the ggraph
#' package to plot them. The vtree class is mostly a convenience for
#' plotting. You can manipulate the vtree object using regular tidygraph
#' functions, and then use as_vtree to convert it back to a vtree object
#' for plotting.
#' @examples
#' library(tidyverse)
#' data(Titanic)
#' vt <- vtree_from_freqtable(Titanic, Class, Survived)
#' if(interactive()) {
#'   plot(vt, by_freq = TRUE)
#' }
#' set.seed(123)
#' # create a new data set with NAs
#' titanicNA <- Titanic |>
#'   cases_from_freqtable() |>
#'   # change all classes to character
#'   mutate(across(everything(), as.character)) |>
#'   # add some random NAs to each column
#'   mutate(Class = ifelse(runif(n()) < 0.1, NA, Class)) |>
#'   mutate(Sex = ifelse(runif(n()) < 0.1, NA, Sex)) |>
#'   mutate(Age = ifelse(runif(n()) < 0.1, NA, Age))            
#' 
#' vt <- vtree(titanicNA, Class, Sex, Survived)
#' if(interactive()) {
#'   plot(vt)
#' }
#' @param cases A data frame, one row per observation, one column per variable
#' @param x A frequency table (matrix, table or data frame)
#' @param ... Columns to use for the tree. If no columns are specified, all
#'            columns (except the frequency column for the frequency
#'            tables) will be used
#' @param .cols Provide column names as a character vector instead of using the ... argument. This is useful when the column names are stored in a variable.
#' @param .vp valid percentage; when calculating frequencies / percentages,
#'           omit NA values from the denominator
#' @param .freq_col The name of the column in a frequency table that
#' contains the frequency counts. Default is "Freq".
#' @return an object of class vtree
#' @importFrom dplyr select mutate group_by summarize ungroup 
#' @importFrom dplyr distinct rename rowwise c_across all_of
#' @importFrom dplyr first .data n pull filter as_tibble lag
#' @importFrom dplyr pick across bind_rows
#' @importFrom tidyselect everything starts_with
#' @importFrom purrr map map_chr map_dfr reduce map_dfc
#' @importFrom rlang enquos as_name :=
#' @importFrom tidygraph tbl_graph activate map_bfs_lgl map_bfs_int
#' @importFrom tidygraph tbl_graph map_bfs_back_int
#' @importFrom tidygraph .N .E
#' @export
vtree <- function(cases, ..., .vp = TRUE, .cols = NULL) {
  if (!is.null(.cols)) {
    cnms <- .cols
  } else {
    # enquos the columns so we can play with them
    cols <- rlang::enquos(...)
    # get the column names as strings
    cnms <- map_chr(cols, rlang::as_name)
  }

  if(length(cnms) < 1L) {
    cnms <- colnames(cases)
  }
  stopifnot(length(cnms) > 0L)
  stopifnot(all(cnms %in% colnames(cases)))

  cases <- select(cases, all_of(cnms))
  N <- nrow(cases)

  pat <- vtree_pat(cases, cnms, vp = .vp)

  df <- pat2nodes(pat, cnms)
  df[["vp"]] <- .vp

  edges <- node2edge(df)
  vtree <- tbl_graph(nodes = df, edges = edges, directed = TRUE, node_key = "ID")

  as_vtree(vtree)
}


