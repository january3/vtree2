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

  if(length(colnames(cases)) < 1L) {
    cli_abort(c(x = "No columns in the data frame cases"))
  }

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

#' Convert a frequency table to a data frame of cases
#'
#' Convert a frequency table to a data frame of cases
#'
#' A frequency table is a data frame in which each row corresponds to a
#' unique combination of values of the variables, and a column (by default
#' named "Freq") contains the frequency counts for that combination. This
#' function expands the frequency table into a data frame of cases, where
#' each row corresponds to one observation.
#'
#' If the columns of the frequency table are factors, the levels of the
#' factors are recorded and assigned to the `levels` attribute of the
#' returned data frame. If the columns are not factors, the unique values
#' of the columns area stored in the `levels` attribute instead.
#'
#' This function is close to the `crosstabToCases()` function from
#' the original vtree package.
#' @param x A frequency table, as a data frame or a table object.
#' @param ... The columns to use for the cases. If not specified, all columns
#'       except the frequency column are used.
#' @param .freq_col The name of the column containing the frequency counts.
#' @examples
#' cases <- cases_from_freqtable(Titanic)
#' cases <- cases_from_freqtable(Titanic, Class, Sex, Survived)
#' cases <- cases_from_freqtable(Titanic,
#'               .freq_col = "Freq",
#'               .cols = c("Class", "Sex", "Survived"))
#' @inheritParams vtree
#' @importFrom rlang as_name
#' @return A tibble of cases, one row per observation, one column per variable
#' @export
cases_from_freqtable <- function(x, ..., .freq_col = "Freq", .cols = NULL) {

  if(!is.data.frame(x)) {
    x <- as.data.frame(x)
  }

  rownames(x) <- NULL

  x <- as_tibble(x)

  if (!is.null(.cols)) {
    cnms <- .cols
  } else {
    # enquos the columns so we can play with them
    cols <- enquos(...)
    # get the column names as strings
    cnms <- map_chr(cols, rlang::as_name)
  }

  if(!.freq_col %in% colnames(x)) {
      fcol <- .freq_col
    cli_abort(c(
      x = "Frequency column {fcol} not found in the data frame",
      i = "Available columns: {paste(colnames(x), collapse = ', ')}"
    ))
  }

  if(!all(cnms %in% colnames(x))) {
    missing_cols <- setdiff(cnms, colnames(x))
    cli_abort(c(
      x = "Some columns specified in .cols or ... are not found in the data frame",
      i = "Missing columns: {paste(missing_cols, collapse = ', ')}",
      i = "Available columns: {paste(colnames(x), collapse = ', ')}"
    ))
  }

  if(length(cnms) < 1) {
    cnms <- setdiff(colnames(x), .freq_col)
  }

  if(!length(cnms) > 0) {
    cli_abort(c(
      x = "No usable columns found in the data frame",
      i = "Available columns: {paste(colnames(x), collapse = ', ')}"
    ))
  }

  levels <- .get_levels(x, cnms)

  x <- x[ rep.int(seq_len(nrow(x)), x[[.freq_col]]), ]
  x <- x[ , cnms, drop = FALSE ]

  rownames(x) <- NULL
  attr(x, "levels") <- levels
  x
}


#' @rdname vtree
#' @export
vtree_from_freqtable <- function(x, ..., .freq_col = "Freq", 
                                 .vp = TRUE, .cols = NULL) {

  if (!is.null(.cols)) {
    cnms <- .cols
  } else {
    # enquos the columns so we can play with them
    cols <- rlang::enquos(...)
    # get the column names as strings
    cnms <- map_chr(cols, rlang::as_name)
  }

  x <- cases_from_freqtable(x, .freq_col = .freq_col, .cols = cnms)

  vtree(cases = x, .vp = .vp, .cols = cnms)
}
