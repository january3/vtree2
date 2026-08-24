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

  if(!all(req_cols %in% colnames(nodes))) {
    missing <- req_cols[ !req_cols %in% colnames(nodes) ]
    cli_abort(c(x = 
       "Required columns {missing} are missing from the nodes data frame"))
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

  if(is.null(get_vp(x))) {
    cli_abort(c(x = "VTree object lacks vp attribute"))
  }

  cnms <- unique(nodes$node_col[ nodes$level > 0 ])

  if(is.null(get_cols(x))) {
    x <- set_cols(x, cnms)
  }

  if(is.null(get_n(x))) {
    x <- set_n(x, N)
  }

  if(length(get_levels(x)) == 0L) {
    cli_abort(c(x = "The vtree must have an attribute 'levels'"))
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
#' * `node_val`: the value of the node variable at this node (`Female`).
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
#' vt <- vtree(titanicNA, -Age)
#' # same as:
#' vt <- vtree(titanicNA, Class, Sex, Survived)
#' plot(vt, dir="tb")
#'
#' # using derived variables
#' vt <- vtree(titanicNA, Class, Gender=Sex, Survived)
#' names(vt)         # "Class" "Gender" "Survived"
#' vt <- vtree(ToothGrowth,
#'       dose_mg = as.character(dose), supplement=supp)
#' names(vt)         # "dose_mg" "supplement"
#' @param cases A data frame, one row per observation, one column per variable
#' @param x A frequency table (matrix, table or data frame)
#' @param ... Columns to use for the tree. If no columns are specified, all
#'            columns (except the frequency column for the frequency
#'            tables) will be used. Use tidy select syntax to access
#'            columns. Named expressions to modify or rename columns are
#'            also allowed (see examples).
#' @param .vp valid percentage; when calculating frequencies / percentages,
#'           omit NA values from the denominator
#' @param .freq_col The name of the column in a frequency table that
#' contains the frequency counts. Default is "Freq".
#' @param .cv_sep,.path_sep By default, the `path` column of the node data
#' frame contains entries such as 'Class:1st/Survived:No'. If your data var
#' columns contain `:` or `/`, change these parameters.
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
vtree <- function(cases, ..., .vp = TRUE,
                  .cv_sep = ':', .path_sep = '/') {

  ensure(cases, "data.frame")

  if(length(colnames(cases)) < 1L) {
    cli_abort(c(x = "No columns in the data frame cases"))
  }

  dots <- rlang::enquos(...)
  dotnames <- names(dots)
  is_deriv <- nzchar(dotnames)

  dots_tidysel <- dots[!is_deriv]

  # tidyselect for directly selected columns
  if (length(dots_tidysel) > 0) {
    cols <- tidyselect::eval_select(
      rlang::expr(c(!!!dots_tidysel)),
      data = cases
    )
    cnms <- names(cols)
  } else {
    cnms <- character()
  }

  ## Derived variables
  if (any(is_deriv)) {
    for (i in which(is_deriv)) {
      cases[[dotnames[[i]]]] <- rlang::eval_tidy(
        dots[[i]],
        data = cases
      )
    }
  }

  cnms <- c(cnms, dotnames[is_deriv])

  if(length(cnms) < 1L) {
    cnms <- colnames(cases)
  }

  reserved <- c("node_col", "node_id", "path", "freq", "count",
                 "denom", "node_key", "tot_n")

  .check_col_names(cnms, reserved, .cv_sep, .path_sep)

  levels <- .get_levels(cases, cnms)

  if(!all(cnms %in% names(levels))) {
    cli_abort(c(x="not all column names in levels"))
  }

  cases <- select(cases, all_of(cnms))
  .check_col_types(cases)

  N <- nrow(cases)

  pat <- vtree_pat(cases, cnms, vp = .vp)
  df <- pat2nodes(pat, cnms, .cv_sep, .path_sep)

  edges <- node2edge(df)
  vtree <- tbl_graph(nodes = df, edges = edges,
                     directed = TRUE, node_key = "node_key")

  vtree <- set_vp(vtree, .vp)
  vtree <- set_levels(vtree, levels)
  vtree <- as_vtree(vtree)

  summaries <- map_dfr(set_names(names(levels)), \(var) {
                     summary_at_var(vtree, all_of(var), as_df=TRUE)
  })

  vtree <- set_source_summary(vtree, summaries)
  vtree <- set_sep(vtree, list(cv = .cv_sep, path = .path_sep))
  vtree <- set_pruned(vtree, FALSE)
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
#' @param .freq_col The name of the column containing the frequency counts.
#' @examples
#' cases <- cases_from_freqtable(Titanic)
#' cases <- cases_from_freqtable(Titanic, Class, Sex, Survived)
#' # same as:
#' cases <- cases_from_freqtable(Titanic, -Age)
#' cols <- c("Class", "Sex", "Survived")
#' cases <- cases_from_freqtable(Titanic, all_of(cols),
#'               .freq_col = "Freq")
#' cases <- cases_from_freqtable(Titanic, Class,
#'                               Gender=Sex, Survived)
#' @inheritParams vtree
#' @importFrom rlang as_name
#' @return A tibble of cases, one row per observation, one column per variable
#' @export
cases_from_freqtable <- function(x, ..., .freq_col = "Freq") {

  if(!is.data.frame(x)) {
    x <- as.data.frame(x)
  }

  rownames(x) <- NULL

  x <- as_tibble(x)

  dots <- rlang::enquos(...)
  dotnames <- names(dots)
  is_deriv <- nzchar(dotnames)

  dots_tidysel <- dots[!is_deriv]

  # tidyselect for directly selected columns
  if (length(dots_tidysel) > 0) {
    cols <- tidyselect::eval_select(
      rlang::expr(c(!!!dots_tidysel)),
      data = x
    )
    cnms <- names(cols)
  } else {
    cnms <- character()
  }

  ## Derived variables
  if (any(is_deriv)) {
    for (i in which(is_deriv)) {
      x[[dotnames[[i]]]] <- rlang::eval_tidy(
        dots[[i]],
        data = x
      )
    }
  }

  cnms <- c(cnms, dotnames[is_deriv])

  # cols <- tidyselect::eval_select(
  #   rlang::expr(c(...)),
  #   data = x)

  # cnms <- names(cols)
  cnms <- setdiff(cnms, .freq_col)

  if(!.freq_col %in% colnames(x)) {
      fcol <- .freq_col
    cli_abort(c(
      x = "Frequency column {fcol} not found in the data frame",
      i = "Available columns: {paste(colnames(x), collapse = ', ')}"
    ))
  }

  if(length(cnms) < 1L) {
    cnms <- setdiff(colnames(x), .freq_col)
  }

  if(!length(cnms) > 0L) {
    cli_abort(c(
      x = "No usable columns found in the data frame",
      i = "Available columns: {paste(colnames(x), collapse = ', ')}"
    ))
  }

  x <- x[ rep.int(seq_len(nrow(x)), x[[.freq_col]]), ]
  x <- x[ , cnms, drop = FALSE ]

  rownames(x) <- NULL
  x
}


#' @rdname vtree
#' @export
vtree_from_freqtable <- function(x, ..., .freq_col = "Freq", 
                                 .vp = TRUE,
                                 .cv_sep = ':', .path_sep = '/') {

  x <- cases_from_freqtable(x, ..., .freq_col = .freq_col)
  cnms <- colnames(x)
  vtree(cases = x, all_of(cnms), .vp = .vp,
        .cv_sep = .cv_sep, .path_sep = .path_sep)
}
