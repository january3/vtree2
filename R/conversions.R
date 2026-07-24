#' Convert a vtree_graph to a tbl_graph
#'
#' Convert a vtree_graph to a tbl_graph
#'
#' @param vtree A vtree object
#' @return A tbl_graph object
#' @export
as_tbl_graph <- function(vtree) {
  stopifnot(inherits(vtree, "vtree"))
  class(vtree) <- setdiff(class(vtree), "vtree")
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
#' This function is close to the `crosstabToCases()` function from
#' the original vtree package.
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

  stopifnot(.freq_col %in% colnames(x))
  stopifnot(all(cnms %in% colnames(x)))

  if(length(cnms) < 1) {
    cnms <- setdiff(colnames(x), .freq_col)
  }
  stopifnot(length(cnms) > 0)

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




