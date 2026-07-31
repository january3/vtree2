# A list of character vectors, one for each variable split in the tree,
# with each ordered vector containing the levels of that variable

#' Get the variable names of a vtree object
#'
#' @param x A vtree object.
#' @return A character vector of variable names
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
  if(!inherits(x, "vtree") & !inherits(x, "vtree_pattern")) {
    cli_abort(c(x = 
                "x must be a vtree or vtree_pattern object"))
  }

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

  all_good <- purrr::map_lgl(set_names(immutable), \(col) {
                   all(as_tibble(ret)[[col]] == as_tibble(.data)[[col]])
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
#' vt <- vtree(Titanic, Class, Sex, Survived)
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



#' Convert a tbl_graph to a vtree
#'
#' Convert a tbl_graph to a vtree
#'
#' @param x A tbl_graph object.
#' @return A vtree object
as_vtree <- function(x) {
  if(!inherits(x, "tbl_graph")) {
    cli_abort(c(x = "x must be a tbl_graph object"))
  }

  # integrity checks
  # ------------------
  nodes <- as_tibble(x)
  req_cols <- c("path", "node_id", "node_key",
                "tot_n", "missing", "denom",
                "parent_id", "node_col", "node_val",
                "parent", "path_l", "level", "n", "freq")
  # this columns are usually created but not critical:
  # node_cv, node_name

  if(!all(req_cols %in% colnames(nodes))) {
    stop(sprintf("Columns %s not in colnames(nodes)",
                 paste(req_cols[ !req_cols %in% colnames(nodes) ],
                       collapse=", ")
                 ))
  }

  x <- x |> activate("nodes") |>
    mutate(leaf = .data[["level"]] == max(.data[["level"]]))

  # more than a root
  if(!any(nodes$level > 0) || nrow(nodes) < 2) {
    cli_abort(c(x = "The vtree must have at least one node other than the root"))
  }

  # only one root
  if(!sum(nodes$level == 0) == 1) {
    cli_abort(c(x = "The vtree must have exactly one root node"))
  }

  N <- nodes$n[ nodes$level == 0 ]

  if(any(is.na(nodes$node_col))) {
    cli_abort(c(x = "The node_col column must not contain NA values"))
  }

  cnms <- unique(nodes$node_col[ nodes$level > 0 ])

  if(is.null(attr(x, "cols"))) {
    attr(x, "cols") <- cnms
  }

  if(is.null(attr(x, "N"))) {
    attr(x, "N") <- N
  }

  if(is.null(attr(x, "vp"))) {
    attr(x, "vp") <- TRUE
  }

  if(is.null(attr(x, "levels"))) {
    cli_abort(c(x = "The vtree must have an attribute 'levels'"))
  }

  if("vp" %in% colnames(nodes) & !all(nodes[["vp"]])) {
    attr(x, "vp") <- FALSE
  }

  class(x) <- c("vtree", class(x))
  x
}



#' Create a vtree object from a data frame
#'
#' Create a vtree object from a data frame of cases. That is, a data frame
#' containing one row per sample and one column per variable. For
#' converting frequency tables, where one of the columns gives the number
#' of samples that correspond to a combination of variable levels, see
#' [vtree_from_freqtable()].
#'
#' The cases data frame used as a first argument should have one row per
#' observation. The selected columns will correspond to the nodes of the vtree.
#'
#' With `vtree_from_freqtable()`, you can create a vtree from a frequency
#' table, where each row corresponds to a unique combination of values and
#' a frequency count.
#'
#' There are several basic methods implemented for vtrees: [summary.vtree()],
#' [plot.vtree()], [levels.vtree()], [print.vtree()], [names.vtree()].
#'
#' @section Manipulating a vtree object:
#'
#' Vtree objects are little more than tidygraph object of class tbl_graph.
#' You can use the tidygraph package to manipulate them, and the ggraph
#' package to plot them. The vtree class is mostly a convenience for
#' plotting. You can manipulate the vtree object using regular tidygraph
#' functions, and then use as_vtree to convert it back to a vtree object
#' for plotting.
#'
#' The main difference between the `tbl_graph` and `vtree` is that you can
#' directly get the nodes table with `as_tibble()` and you can use
#' `mutate()` to modify or create the columns of a `vtree` object.
#'
#' @section Columns in the nodes data frame:
#'
#' The vtree object, like the `tbl_graph` objects, consists of two data
#' frames: nodes and edges. The nodes data frame in vtree contains all
#' information pertaining the different nodes of the vtree. Below is the
#' list of the columns; in parentheses, you will find example values for a
#' node from the `Titanic` example.
#'
#' * `path`: human readable path of the node (`Class:1st/Sex:Female`). Note
#'   that if you are using slashes or colons in column names or values,
#'   this can be unreliable.
#' * `node_id`: unique numeric ID of the node.
#' * `node_key`: unique character string ID of the node.
#' * `node_col`: the column of the original cases data frame to which the
#'    node corresponds to (`Sex`)
#' * `node_name`: node name used for labelling (`Sex`).
#' * `node_val`: the value of the node variable at this node (`Female`).
#' * `node_cv`: combination of node column and node value (`Sex:Female`).
#' * `parent`: path of the parent node (`Class:1st`).
#' * `path_l`: is a list node; i.e., each element is a list. The path describes
#'    all nodes from the root to the current node, excluding the root and
#'    including the current node. (`list(Class = "1st", Sex = "Female")`.
#' * `level`: the level of the node, with 0 for the root node. Equal to the
#'    length of the path (`2`).
#' * `n`: total number of cases at the node (`145`).
#' * `tot_n`: total number of cases at the parent node (`325`).
#' * `missing`: number of cases missing for that variable in the parent
#' node (`0`).
#' * `freq`: calculated frequency relative to the number of valid or total
#'   cases in the parent node (`0.446`).
#' * `denom`: the denominator used to calculate the frequency (`325`). If
#'   `.vp` is true, this is equal to the number of valid observations in the
#'   parent node; if `.vp` is false, this is equal to `n` of the parent
#'   node.
#' * `vp`: whether the valid percentage was calculated (`TRUE`).
#' * `leaf`: whether the node is a leaf (`FALSE`).
#'
#' Note that the variables `tot_n`, `denom` and `missing` all refer to the
#' *parent* node, not to the current node. For example, if the current node is
#' `Class:1st/Sex:Female`, then `tot_n` will be the total number of persons in
#' the 1st class, and `n` will be the total number of females in the 1st
#' class. Likewise, `missing` will be the total number of persons in the 1st
#' class for which we do not know whether they were male or female. The
#' `denom` variable will depend on `.vp`. If we need the valid percentages
#' (default), then `denom` will be equal to `tot_n - missing`; otherwise it will
#' be `tot_n`.
#'
#' The `tot_n` information is redundant, since it can be read directly from
#' `n` of the parent node (`Class:1st` in case of `Class:1st/Sex:Female`). However,
#' it makes the calculations transparent.
#' @examples
#'
#' data(Titanic)
#' vt <- vtree_from_freqtable(Titanic, Class, Survived)
#' plot(vt)
#' plot(vt, layout = "proportional")
#'
#' data(titanicNA)
#' vt <- vtree(titanicNA, Class, Sex, Survived)
#' plot(vt)
#' @param cases A data frame, one row per observation, one column per variable
#' @param x A frequency table (matrix, table or data frame)
#' @param ... Columns to use for the tree. If no columns are specified, all
#'            columns (except the frequency column for the frequency
#'            tables) will be used
#' @param .cols Provide column names as a character vector instead of using
#'         the ... argument. This is useful when the column names are
#'         stored in a variable.
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

  if(length(cnms) < 1L) {
    cli_abort(c(x = "No columns specified for the vtree"))
  }

  if(!all(cnms %in% colnames(cases))) {
    cnms <- cnms[ !cnms %in% colnames(cases) ]
    cli_abort(
    c("Columns specified for the vtree are not in the cases data frame",
      "x" = "Columns not found: {cnms}")
    )
  }

  if(!is.null(attr(cases, "levels"))) {
    levels <- attr(cases, "levels")
    if(!all(cnms %in% names(levels))) {
      cli_abort("not all column names in provided levels")
    }
    levels <- levels[cnms]
  } else {
    levels <- .get_levels(cases, cnms)
  }

  cases <- select(cases, all_of(cnms))
  N <- nrow(cases)

  pat <- vtree_pat(cases, cnms, vp = .vp)

  df <- pat2nodes(pat, cnms)
  df[["vp"]] <- .vp

  edges <- node2edge(df)
  vtree <- tbl_graph(nodes = df, edges = edges,
                     directed = TRUE, node_key = "node_key")

  attr(vtree, "levels") <- levels
  vtree <- as_vtree(vtree)

  summaries <- map_dfr(set_names(names(levels)), \(var) {
                     summary_at_var(vtree, var, as_df=TRUE)
  })

  attr(vtree, "source_summary") <- summaries
  attr(vtree, "pruned") <- FALSE
  vtree


}


