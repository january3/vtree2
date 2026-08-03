.na_comp <- function(x, y) {
  (is.na(x) & is.na(y)) |
  (!is.na(x) & !is.na(y) & x == y)
}

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
             map_chr(levels, \(l) paste(names(l), l, sep = ": ", collapse = "\n")))
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
#' Using the `fmt` parameter, it is possible to create fully
#' summaries. The expression is evaluated within the context of the summary
#' data frame, which means that you can use all columns avaialble in that
#' data frame. For example, you can use an expression like
#' `sprintf("%s", fmt(median, digits = 2))` or `glue("{median}")`.
#'
#' @param vtree A vtree object.
#' @param cases A data frame of cases, with one row per observation.
#' @param fmt An expression for customized formatting. See Examples.
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
#'              fmt = sprintf("median: %.1f",median))
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
#'      fmt = sprintf("valid: %d/%d (%d%%)",
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
summary_vt <- function(cases, vtree, col, fmt = NULL, .col = NULL) {

  fmt <- enquo(fmt)

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
    ret <- .summary_vt_categoric(df, fmt)
  } else {
    ret <- .summary_vt_numeric(df, fmt)
  }

  ret

}

.summary_vt_categoric <- function(summary_df, fmt=NULL) {

  if(quo_is_null(fmt)) {
    fmt <- quo(
      sprintf("%s\n%s",
        .data[["col"]],
        .data[["levels_str"]]))
  }

  ret <- eval_tidy(fmt, data = summary_df)
  ret
}

.summary_vt_numeric <- function(summary_df, fmt=NULL) {

  if(quo_is_null(fmt)) {
    fmt <- quo(
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

  ret <- eval_tidy(fmt, data = summary_df)
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

  if(!length(col) == 1L) {
    cli_abort(c(
      x = "Only one column can be summarized at a time",
      i = "You provided {length(col)} columns: {paste(col, collapse = ', ')}"
    ))
  }

  if(!is.data.frame(cases)) {
    cli_abort(c(
      x = "cases must be a data frame",
      i = "You provided an object of class {class(cases)}"
    ))
  }

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(
      x = "vtree must be a vtree object",
      i = "You provided an object of class {class(vtree)}"
    ))
  }

  # first, check that all necessary variables are in the colnames of cases
  cols <- names(vtree)

  if(!all(cols %in% colnames(cases))) {
    missing_cols <- setdiff(cols, colnames(cases))
    cli_abort(c(
      x = "Some columns in the vtree are not found in the cases data frame",
      i = "All columns from the vtree must be present in the cases data frame",
      i = "Missing columns: {missing_cols}",
      i = "Columns in cases: {colnames(cases)}"
    ))
  }

  if(!col %in% colnames(cases)) {
    cli_abort(c(
      x = "The column to summarize is not found in the cases data frame",
      i = "You provided column: {col}",
      i = "Columns in cases: {colnames(cases)}"
    ))
  }

  nodes <- as_tibble(vtree)

  # next create a match vector between the vtree and the cases data frame
  # probably a clever grouping operation would be more efficient rather
  # than looking for each combination of variables manually
  matches <- map(nodes$path_l, \(p) .find_match_recursively(cases, p))

  ret <- .get_summary(cases, col, matches) |>
    mutate(path = nodes$path) |>
    select(all_of("path"), everything())
  ret
}

# returns a formatted summary for a variable at the given node of the vtree

#' Summarize a variable at a given node of a vtree
#'
#' Summarizes a variable at a given node of a vtree. It
#' returns a character string with the counts and percentages of each level
#' of the variable at that node. If the variable has missing values, it
#' also includes the count and percentage of missing values.
#'
#' Note that if a tree was pruned, these summaries will differ from the
#' summaries shown by `summary(vtree)`
#'
#' If the tree
#' was constructed using valid percentages (`attr(vtree, "vp")` is TRUE),
#' the percentages are calculated based on the valid (non-NA) counts. If
#' the tree was constructed using total percentages, the percentages are
#' calculated based on the total counts.
#' @return if `as_char` is TRUE, a character string with the counts and
#' percentages of each level of the variable at that node. If `as_char` 
#' is FALSE (default), a named integer vector with the counts of each 
#' level of the variable at that node.
#'
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' summary_at_var(vt, "Class")
#' summary_at_var(vt, "Class", as_char = TRUE)
#' summary_at_var(vt, "Class", as_df = TRUE)
#'
#' data(titanicNA)
#' vt2 <- vtree(titanicNA, Class, Sex, Survived)
#' summary_at_var(vt2, "Class")
#'
#' # not using valid percentages - NAs count towards the total
#' vt3 <- vtree(titanicNA, Class, Sex,
#'                             Survived, .vp=FALSE)
#' summary_at_var(vt3, "Class")
#'
#' # summaries differ if you prune the tree!
#' vt_p <- prune(vt, freq < .15) 
#' summary_at_var(vt_p, "Class", as_df = TRUE)
#' # compare with:
#' summary(vt_p)
#' @param vtree A vtree object
#' @param varname The name of the variable to summarize
#' @param as_char If TRUE (default), return a formatted character string
#'        with the counts and percentages of each level of the variable at
#'        that node. If FALSE, return a named integer vector with the
#'        counts of each level of the variable at that node.
#' @param as_df Returns a data frame (tibble) with node column, value,
#'        number of counts, frequency, denominator and label.
#' @export
#' @importFrom purrr map map_lgl map_dbl map_int
summary_at_var <- function(vtree, varname, as_char = FALSE,
                           as_df = FALSE) {
  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "summary_at_var() requires a vtree object"))
  }

  if(as_df) {
    as_char = TRUE
  }

  nodes <- as_tibble(vtree)
  vp <- attr(vtree, "vp")

  levels <- levels(vtree)[[varname]] %||%
    cli_abort(c(
      x = "Variable {varname} not found in vtree levels",
      i = "Available variables: {paste(names(levels(vtree)), collapse = ', ')}"
    ))

  if(!any(is.na(levels))) {
    levels <- c(levels, NA)
  }

  # which nodes are variable splits for our variable?
  sel <- map_lgl(nodes[["path_l"]], \(p) {
    if(is.null(names(p))) {
      return(FALSE)
    }
    varname == names(p)[length(p)]
  })

  # get the selections for each level of the variable
  selections <- map(levels, \(l) {
    map_lgl(nodes[["path_l"]][sel], \(p) {
      # TRUE if both p[[varname]] and l are NA, or if they are equal
      (is.na(l) && is.na(p[[varname]])) ||
      (!is.na(l) && !is.na(p[[varname]]) && p[[varname]] == l)
    })
  })
  names(selections) <- levels

  # add the counts of the nodes that correspond to the variable and the
  # level
  counts <- map_int(selections, \(selval) {
    sum(nodes[["n"]][sel][selval], na.rm = TRUE)
  })

  if(!as_char) {
    return(counts)
  }

  notna <- !is.na(names(counts))

  if(vp) {
    N <- sum(counts[notna])
  } else {
    N <- sum(counts)
  }

  freqs <- map_dbl(counts, \(c) c / N)

  ret <- paste(names(counts[notna]),
        sprintf("%d (%.0f%%)", counts[notna], 100 * freqs[notna]),
        sep = ": ")

        #, collapse = "\n")
  names(ret) <- names(counts[notna])

  if(counts[!notna] > 0 || as_df) {
    if(!vp) {
    ret <- c(ret, paste0("Missing: ",
                  counts[!notna],
                  " (", sprintf("%.0f%%", 100 * freqs[!notna]), ")"))
    } else {
      ret <- c(ret, paste("Missing:", counts[!notna]))
    }
    names(ret) <- names(counts)
  }

  if(as_df) {
    ret <- tibble(
                  node_col = varname,
                  node_val = names(counts),
                  count = counts,
                  freq = freqs,
                  denom = N,
                  label = ret)

  }

  ret
}


#' Apply a function to a data frame by nodes in the vtree
#'
#' Apply a function to a data frame by nodes in the vtree. The data frame
#' must contain the same variables as the vtree. It is split by the levels
#' of the variables such that for each node in the vtree, the function is
#' applied to the subset of data that matches the path to that node.
#' @param cases A data frame of cases, with one row per observation.
#' @param vtree A vtree object.
#' @param FUN A function to apply to the subset of cases that match the path
#'            to each node in the vtree.
#' @param .mask An optional logical vector of the same length as the number of
#'              nodes in the vtree. If provided,
#'              only the nodes for which .mask is TRUE will be processed.
#' @param ... Additional arguments to pass to FUN.
#' @return A list of the results of applying FUN to each subset of cases
#'         named with the node_key of the corresponding node in the vtree.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex)
#'
#' # only leaf nodes
#' mask <- find_nodes(vt, leaf)
#'
#' # prepare labels with summary of Survived for each node
#' sm <- vtree_apply(titanicNA, vt, \(df) summary(df$Survived), .mask = mask) |>
#'   map_chr(\(x) paste0(names(x), ": ", x, collapse = "\n"))
#'
#' # plot with custom layout making more space for the labels in the last
#' # node ("Sex")
#' vt |> add_labels() |>
#'   mutate(label = ifelse(mask, paste0(label, "\n", sm[node_key]), label)) |>
#'   add_layout(varspace = c(root=1, Class=1, Sex=3),
#'              dir="tb", lheight=.8) |>
#'   plot(dir="tb")
#' @export
vtree_apply <- function(cases, vtree, FUN, ..., .mask=NULL) {

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "vtree_apply() requires a vtree object"))
  }

  if(!is.data.frame(cases)) {
    cli_abort(c(x = "vtree_apply() requires a data frame for cases"))
  }


  # check that all necessary variables are in the colnames of cases
  cols <- names(vtree)
  if(!all(cols %in% colnames(cases))) {
    missing_cols <- setdiff(cols, colnames(cases))
    cli_abort(c(
      x = "Some columns in the vtree are not found in the cases data frame",
      i = "All columns from the vtree must be present in the cases data frame",
      i = "Missing columns: {missing_cols}",
      i = "Columns in cases: {colnames(cases)}"
    ))
  }

  nodes <- as_tibble(vtree)

  if(is.null(.mask)) {
    .mask <- rep(TRUE, nrow(nodes))
  } else {
    if(length(.mask) != nrow(nodes)) {
      cli_abort(c(
        x = "The length of .mask must be equal to the number of nodes in the vtree",
        i = "You provided a mask of length {length(.mask)} for a vtree with {nrow(nodes)} nodes"
      ))
    }
  }

  # next create a match vector between the vtree and the cases data frame
  matches <- map(nodes$path_l[.mask], \(p) .find_match_recursively(cases, p))

  ret <- map(matches, \(m) FUN(cases[m, , drop = FALSE], ...))
  names(ret) <- nodes$node_key[.mask]
  ret
}
