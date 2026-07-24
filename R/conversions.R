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
#' @return A data frame of cases, one row per observation, one column per variable
#' @export
cases_from_freqtable <- function(x, ..., .freq_col = "Freq", .cols = NULL) {

  if(!is.data.frame(x)) {
    x <- as.data.frame(x)
  }

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

  x <- x[ rep.int(seq_len(nrow(x)), x[[.freq_col]]), ]
  x <- x[ , cnms, drop = FALSE ]

  rownames(x) <- NULL
  x
}


#' @rdname vtree
#' @export
vtree_from_freqtable <- function(x, ..., .freq_col = "Freq", 
                                 .vp = TRUE, .cols = NULL) {

  if(!is.data.frame(x)) {
    x <- as.data.frame(x)
  }

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




