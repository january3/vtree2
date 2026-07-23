
# calculate the overall product of all matches to select the correct
# classes
.find_match_recursively <- function(df, path, match = TRUE) {

  # if path is missing, e.g. for root node
  if(!is.list(path)) {
    # root node matches everything
    return(TRUE)
  }

  v1 <- df[[ names(path)[1] ]]
  v2 <- path[[1]]

  match <- match & 
    (
    (is.na(v1) & is.na(v2)) |
    ((!is.na(v1) & !is.na(v2)) & (v1 == v2))
    )

  if(length(path) > 1) {
    match <- .find_match_recursively(df, path[-1], match)
  }

  match
}

# get a single summary, the lowlevel function
#' @importFrom stats quantile IQR sd median
.get_summary <- function(cases, col, matches) {

  num <- is.numeric(cases[[col]])
  if(!is.factor(cases[[col]])) {
    fa <- factor(cases[[col]])
  } else {
    fa <- cases[[col]]
  }

  ret <- map_dfr(matches, \(m) {
    x <- cases[[col]][m]
    if(num) {
      ret <- tibble(
        col = col,
        type = "numeric",
        n = length(x),
        mean = mean(x, na.rm = TRUE),
        sd = sd(x, na.rm = TRUE),
        min = min(x, na.rm = TRUE),
        max = max(x, na.rm = TRUE),
        median = median(x, na.rm = TRUE),
        q1 = quantile(x, .25, na.rm = TRUE),
        q3 = quantile(x, .75, na.rm = TRUE),
        iqr = IQR(x, na.rm = TRUE),
        valid = sum(!is.na(x)),
        missing = sum(is.na(x))
      )
    } else {
      ret <- tibble(
        col = col,
        type = "categorical",
        n = length(x),
        valid = sum(!is.na(x)),
        missing = sum(is.na(x)),
        unique = length(unique(x)),
        levels = list(summary(fa[m]))
      ) |>
      mutate(levels_str = 
             map_chr(levels, \(l) paste(names(l), l, sep = ":", collapse = "\n")))
    }
    ret
  })

  ret
}

#' Summarize a case variable for each node of a vtree
#'
#' `summary_vt()` and `summary_vt_df()` summarize a case variable for each
#' node of a vtree. That is, for each node in the vtree, they select the
#' cases that match the path to that node and summarize the specified
#' variable for those cases.
#'
#' For example, in the Titanic data set, you can ask what were the
#' different proportions of survivors for males in the 1st class. This
#' corresponds to the summary of variable `Survived` for the node with
#' path `Class:1st/Sex:Male`.
#'
#' The `summary_vt_df()` function returns a data frame with columns
#' corresponding to various and column data type dependent statistic
#' measures, while `summary_vt()` creates a character vector with these
#' measures.
#'
#' For numeric variables, the resulting data frame (tibble) returned by
#' `summary_vt_df()` will contain
#' the following columns: `n`, `mean`, `sd`, `min`, `max`, `median`, `q1`,
#' `q3`, `iqr`, `valid`, and `missing`.
#'
#' For factor variables, the resulting data frame will contain the following
#' columns: `n`, `valid`, `missing`, `unique`, `levels` and `levels_str`.
#' The `levels` column is a list column, and each cell contains a list of
#' the counts of each level of the factor variable for that node. The
#' `levels_str` column is a character column that contains a string
#' representation of the levels and their counts, which can be used for
#' labeling the nodes.
#'
#' You can use these functions to create informative labels for the nodes.
#'
#' Using the `format` parameter, it is possible to create fully
#' summaries. The expression is evaluated within the context of the summary
#' data frame, which means that you can use all columns avaialble in that
#' data frame. For example, you can use an expression like 
#' `sprintf("%s", format(median, digits = 2))` or `glue("{median}")`.
#'
#' @param vtree A vtree object.
#' @param cases A data frame of cases, with one row per observation.
#' @param format An expression for customized formatting. See Examples.
#' @param col The column variable to summarize. This should be a single
#'            column name, quoted or not.
#' @param .col If you want to provide a column name in a variable, use .col
#' and not col.
#' @importFrom rlang ensym as_name
#' @return A tibble with one row per node of the vtree, and columns for the
#' summary statistics of the specified variable for the cases that match
#' the path to that node.
#' @examples
#'
#' cases <- cases_from_freqtable(Titanic)
#' vt <- vtree(cases, Class, Sex, Survived)
#'
#' csm_txt <- cases |> summary_vt(vt, Age)
#' vt |> mutate(label = csm_txt) |> plot()
#'
#' cases$Random <- rnorm(nrow(cases)) + (cases$Sex == "Male")
#' csm_txt <- cases |> summary_vt(vt, Random)
#' vt |> mutate(label = csm_txt) |> plot()
#'
#' # make some default labels
#' vt <- vt |> add_labels()
#' csm_txt <- cases |>
#'   summary_vt(vt, Random,
#'              format = sprintf("median: %.1f",median))
#' vt |>
#'   mutate(label = paste0(label, "\n", csm_txt)) |> 
#'   plot()
#'
#' # now the same but only for the leafs
#' # leaf is a column in the nodes data frame, TRUE or FALSE
#' vt |>
#'   mutate(label = ifelse(leaf,
#'      paste0(label, "\n", csm_txt),
#'      label)) |>
#'   plot()
#'
#' # introduce a few missing values
#' cases$Random[ runif(nrow(cases)) < .1 ] <- NA
#'
#' csm_txt <- cases |>
#'   summary_vt(vt, Random,
#'      format = sprintf("valid: %d/%d (%d%%)",
#'            valid, n, round(100 * valid/n)))
#'
#' vt |>
#'   mutate(label = paste0(label, "\n", csm_txt)) |> 
#'   plot()
#'
#' # Example for the data frame variant
#' csm_df <- cases |> summary_vt_df(vt, Age)
#' vt |> 
#'   mutate(label = sprintf("%s\n%s", node_val, 
#'                          csm_df$levels_str)) |>
#'   plot()
#'
#' @export
summary_vt <- function(cases, vtree, col, format = NULL, .col = NULL) {

  format <- enquo(format)

  if(!is.null(.col)) {
    col <- .col
  } else {
    col <- rlang::ensym(col)
    col <- rlang::as_name(col)
  }

  df <- summary_vt_df(cases, vtree, col, .col = col)

  type <- df$type[1]
  type <- match.arg(type, c("categorical", "numeric"))

  if(type == "categorical") {
    ret <- .summary_vt_categoric(df, format)
  } else {
    ret <- .summary_vt_numeric(df, format)
  }

  ret

}

.summary_vt_categoric <- function(summary_df, format=NULL) {

  if(quo_is_null(format)) {
    format <- quo(
      sprintf("%s\n%s",
        .data[["col"]],
        .data[["levels_str"]]))
  }

  ret <- eval_tidy(format, data = summary_df)
  ret
}

.summary_vt_numeric <- function(summary_df, format=NULL) {

  if(quo_is_null(format)) {
    format <- quo(
      sprintf(
        "%s\nNAs: %d\nmean %s SD %s\nmedian %s IQR %s, %s\nrange %s, %s",
         .data[["col"]],
         .data[["missing"]],
         format(.data[["mean"]], digits=1),
         format(.data[["sd"]], digits=1),
         format(.data[["median"]], digits=1),
         format(.data[["q1"]], digits=1),
         format(.data[["q3"]], digits=1),
         format(.data[["min"]], digits=1),
         format(.data[["max"]], digits=1)

         ))
  }

  ret <- eval_tidy(format, data = summary_df)
  ret
}

#' @rdname summary_vt
#' @export
summary_vt_df <- function(cases, vtree, col, .col = NULL) {

  if(!is.null(.col)) {
    col <- .col
  } else {
    col <- rlang::ensym(col)
    col <- rlang::as_name(col)
  }

  stopifnot(length(col) == 1L)
  stopifnot(is.data.frame(cases))
  stopifnot(inherits(vtree, "vtree"))

  # first, check that all necessary variables are in the colnames of cases
  cols <- names(vtree)
  stopifnot(all(cols %in% colnames(cases)))
  stopifnot(all(col %in% colnames(cases)))

  nodes <- vtree |> activate(nodes) |> as_tibble()

  # next create a match vector between the vtree and the cases data frame
  # probably a clever grouping operation would be more efficient rather
  # than looking for each combination of variables manually
  matches <- map(nodes$path, \(p) .find_match_recursively(cases, p))

  ret <- .get_summary(cases, col, matches) |>
    mutate(ID = nodes$ID) |>
    select(all_of("ID"), everything())
  ret
}
