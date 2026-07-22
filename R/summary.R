
# calculate the overall product of all matches to select the correct
# classes
#' @importFrom stats IQR sd median
.find_match_recursively <- function(df, path, match = TRUE) {

  p <- path[[1]]

  if(is.na(p)) {
    return(match)
  }

  match <- match & 
    df[[ names(path)[1] ]] == path[[1]]

  if(length(path) > 1) {
    match <- .find_match_recursively(df, path[-1], match)
  }

  match
}

# get a single summary, the lowlevel function
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
        n = length(x),
        mean = mean(x, na.rm = TRUE),
        sd = sd(x, na.rm = TRUE),
        min = min(x, na.rm = TRUE),
        max = max(x, na.rm = TRUE),
        median = median(x, na.rm = TRUE),
        iqr = IQR(x, na.rm = TRUE),
        valid = sum(!is.na(x)),
        missing = sum(is.na(x))
      )
    } else {
      ret <- tibble(
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
#' `summary_vt()` summarizes a case variable for each node of a vtree. That
#' is, for each node in the vtree, it selects the cases that match the path
#' to that node and summarizes the specified variable for those cases.
#'
#' For example, in the Titanic data set, you can ask what were the
#' different proportions of survivors for males in the 1st class. This
#' corresponds to the summary of variable `Survived` for the node with
#' path `Class:1st/Sex:Male`.
#'
#' For numeric variables, the resulting data frame (tibble) will contain
#' the following columns: `n`, `mean`, `sd`, `min`, `max`, `median`, `iqr`,
#' `valid`, and `missing`.
#'
#' For factor variables, the resulting data frame will contain the following
#' columns: `n`, `valid`, `missing`, `unique`, `levels` and `levels_str`.
#' The `levels` column is a list column, and each cell contains a list of
#' the counts of each level of the factor variable for that node. The
#' `levels_str` column is a character column that contains a string
#' representation of the levels and their counts, which can be used for
#' labeling the nodes.
#'
#' You can use `summary_vt()` to create informative labels for the nodes.
#'
#' @param vtree A vtree object.
#' @param cases A data frame of cases, with one row per observation.
#' @param col The column variable to summarize. This should be a single
#'            column name, quoted or not.
#' @importFrom rlang ensym as_name
#' @return A tibble with one row per node of the vtree, and columns for the
#' summary statistics of the specified variable for the cases that match
#' the path to that node.
#' @examples
#'
#' cases <- cases_from_freqtable(Titanic)
#' vt <- vtree(cases, Class, Sex, Survived)
#'
#' library(tidyverse)
#' case_sm <- cases |> summary_vt(vt, Age)
#' vt |> 
#'   mutate(label = sprintf("%s\n%s", node_val, 
#'                          case_sm$levels_str)) |>
#'   plot()
#'
#' @export
summary_vt <- function(cases, vtree, col) {

  col <- rlang::ensym(col)
  col <- rlang::as_name(col)

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
