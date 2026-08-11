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
# numeric summary
.get_summary_numeric <- function(vec, matches) {

  ret <- map_dfr(matches, \(m) {
    x <- vec[m]
    tibble(
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
  })

  ret
}

.get_summary_factor <- function(vec, matches, vp) {

  if(is.logical(vec)) {
    vec <- as.character(vec)
  }

  # factor/character summary
  if(!is.factor(vec)) {
    fa <- factor(vec)
  } else {
    fa <- vec
  }

  ret <- map_dfr(matches, \(m) {
    x <- vec[m]
    tibble(
      type = "categorical",
      n = length(x),
      valid = sum(!is.na(x)),
      missing = sum(is.na(x)),
      unique = length(unique(x)),
      levels = list(summary(fa[m]))
    )
  })

  ret <- cbind(ret, perc_var_levels(vec, ret, vp))
  ret
}

#' Summarize a case variable for each node of a vtree
#'
#' The function `summarize_by_node()` summarizes a case variable for each
#' node of a vtree. That is, for each node in the vtree, it selects the
#' cases from the cases data frame that match the path to that node and
#' summarize the specified variable for those cases.
#'
#' For example, in the Titanic data set, you can ask what were the
#' different proportions of survivors for males in the 1st class. This
#' corresponds to the summary of variable `Survived` for the node with
#' path `Class:1st/Sex:Male`.
#'
#' The `fmt_label()` function creates a character vector with these
#' measures. The provided format is an expression evaluated in the context
#' of the data frame returned by `summarize_by_node()` and can use the
#' different columns created by that function.
#'
#' For numeric variables, the data frame (tibble) returned by
#' `summarize_by_node()` will contain
#' the following columns: `n`, `mean`, `sd`, `min`, `max`, `median`, `q1`,
#' `q3`, `iqr`, `valid`, and `missing`.
#'
#' For factor variables (and variables which can be safely converted to a
#' factor, i.e. character and logical vectors), the resulting data frame
#' will contain the following columns: `n`, `valid`, `missing`, `denom`,
#' `unique` and `levels`. In addition, for each level "lev" of the factor,
#' it includes the columns "lev" and "lev_freq", which are the number and
#' percentage of the samples with this level of the variable.
#'
#' The frequency calculation uses, by default, the same type of denominator
#' as the vtree. That is, if the vtree was calculated using valid
#' percentages, the denominator used to calculate the frequencies is equal
#' to the number of samples minus number of NAs; otherwise it is equal to
#' the number of samples and the frequencies are also calculated for the NA
#' samples.
#'
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
#' @param vp whether frequencies should be calculated using valid percentages
#' @param fmt An expression for customized formatting. See Examples.
#' @param col The column variable to summarize. This should be a single
#'            column name, quoted or not. It uses tidyselect evaluation, so
#'            you can do `all_of("Survived")`.
#' @importFrom rlang ensym as_name
#' @return A tibble with one row per node of the vtree, and columns for the
#' summary statistics of the specified variable for the cases that match
#' the path to that node.
#' @examples
#'
#' cases <- cases_from_freqtable(Titanic)
#' vt <- vtree(cases, Class, Sex, Survived)
#'
#' csm_txt <- cases |> summarize_by_node(vt, Age) |>
#'   fmt_label()
#' vt |> add_labels(fmt = csm_txt) |> plot()
#'
#' # some random values
#' cases$Random <- rnorm(nrow(cases)) + (cases$Sex == "Male")
#' cases$Random[runif(nrow(cases)) < .1] <- NA
#' csm_txt <- cases |> summarize_by_node(vt, Random) |>
#'   fmt_label()
#' vt |> add_labels(fmt = csm_txt) |>
#'   retain(path == "Class:1st") |>
#'   plot(lwidth=.9)
#'
#' # make some default labels
#' vt <- vt |> add_labels()
#' # add median to the labels
#' csm_txt <- cases |>
#'   summarize_by_node(vt, Random) |>
#'   fmt_label(fmt = sprintf("median: %.1f",median))
#' vt |>
#'   add_labels(fmt = paste0(label, "\n", csm_txt)) |>
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
#' csm_txt <- cases |>
#'   summarize_by_node(vt, Random) |>
#'   fmt_label(fmt = sprintf("valid: %d/%d (%d%%)",
#'            valid, n, round(100 * valid/n)))
#'
#' vt |>
#'   mutate(label = paste0(label, "\n", csm_txt)) |>
#'   retain(path == "Class:1st") |>
#'   plot(lwidth=.8)
#'
#' # Directly use output from summarize_by_node
#' df <- cases |> summarize_by_node(vt, Age)
#' vt |>
#'   mutate(label = sprintf("%s\nChildren: %.0f%%", node_val,
#'                          df$Child_freq * 100)) |>
#'   plot()
#'
#' @export
summarize_by_node <- function(cases, vtree, col, vp=is_vp(vtree)) {
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

  col <- enquo(col)
  col <- tidyselect::eval_select(col, data = cases)
  col <- names(col)

  if(!length(col) == 1L) {
    cli_abort(c(
      x = "Only one column can be summarized at a time",
      i = "You provided {length(col)} columns: {paste(col, collapse = ', ')}"
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

  vec <- cases[[col]]
  if(is.numeric(vec)) {
    ret <- .get_summary_numeric(vec, matches)
  } else {
    ret <- .get_summary_factor(vec, matches, vp)
  }

  ret <- ret |>
    mutate(node_id = nodes$node_id) |>
    mutate(path = nodes$path) |>
    mutate(col = col) |>
    select(all_of(c("node_id", "path", "col", "type")),
           everything())
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

# Compute summary statistics such as percentage and sample size of a
# variable from the `cases` data frame for each node of a vtree.
#
# @param cases a data frame with cases (one row per sample)
# @param df result of summary_vt_df
# @param var variable name
# @return a data frame with number of rows equal to the number rows in the
# nodes data frame of the vtree object. The columns of the data frame
# correspond to the frequency, number of observations, number of valid
# observations and number of missing values.
perc_var_levels <- function(col, df, vp) {

  levs <- levnames <- levels(col)

  if(!vp) {
    levs <- c(levnames, "NAs")
  }

  ret <- map_dfc(set_names(levs), \(l) {
    n <- map_int(df$levels, \(x) {
                   if(l %in% names(x)) x[[l]] else 0
      })
    ret <- tibble(!!l := n)
  })

  ret <- cbind(df[ , c("n", "missing", "valid")], ret)

  if(vp) {
    ret <- ret |>
      mutate(denom = .data[["valid"]]) |>
      mutate(across(all_of(levs),
                  list(freq= ~ .x/denom),
                  .names = "{.col}_{.fn}"))
  } else {
    ret <- ret |>
      mutate(denom = .data[["n"]]) |>
      mutate(across(all_of(levs),
                  list(freq= ~ .x/denom),
                  .names = "{.col}_{.fn}"))
  }

  ret <- ret |>
    select(denom,
           starts_with(levs))
  return(ret)
}

#' @rdname summarize_by_node
#' @export
fmt_label <- function(x, fmt = NULL) {
  fmt <- enquo(fmt)

  type <- x$type[1]
  type <- match.arg(type, c("categorical", "numeric"))

  if(type == "categorical") {
    pst <- \(l) paste(names(l), l, sep=": ", collapse="\n")
    x <- mutate(x, levels_str = map_chr(levels, pst))
    ret <- .summary_vt_categoric(x, fmt)
  } else {
    ret <- .summary_vt_numeric(x, fmt)
  }

  ret
}






#' Apply a function to a data frame by nodes in the vtree
#'
#' Apply a function to a data frame by nodes in the vtree. The data frame
#' must contain the same variables as the vtree. It is split by the levels
#' of the variables such that for each node in the vtree, the function is
#' applied to the subset of data that matches the path to that node.
#'
#' `vtree_apply` applies the function FUN sequentially to groups of samples
#' from the `cases` data frame corresponding to a given node. By default,
#' the argument passed to the function is the subset of the cases data
#' frame, however two other arguments may be included: the row from the
#' vtree node data frame corresponding to the given node (including the
#' node id, path etc.), and a logical vector of the same length as the
#' number of rows in the cases data frame and a TRUE value if the given row
#' is included in the current node.
#'
#' Order and number of arguments are given by the `.args` parameter.
#' @param cases A data frame of cases, with one row per observation.
#' @param vtree A vtree object.
#' @param FUN A function to apply to the subset of cases that match the path
#'            to each node in the vtree.
#' @param .mask An optional logical vector of the same length as the number of
#'              nodes in the vtree. If provided,
#'              only the nodes for which .mask is TRUE will be processed.
#' @param .args character vector specifying which arguments should FUN be
#'        called with: `cases` for the relevant fragment of the cases data
#'        frame; 'nodes` for a single-row nodes data frame with the given
#'        node; `sel` for the logical selection vector.
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
#' sumfnc <- \(df, ...) summary(df$Survived)
#' sm <- vtree_apply(titanicNA, vt, sumfnc, .mask = mask) |>
#'       purrr::map_chr(\(x) paste0(names(x), ": ", x, collapse = "\n"))
#'
#' # plot with custom layout making more space for the labels in the last
#' # node ("Sex")
#' vt |> add_labels() |>
#'   add_labels(mask = mask,
#'              fmt = paste0(label, "\n", sm[node_key])) |>
#'   add_layout(varspace = c(root=1, Class=1, Sex=3),
#'              dir="tb", lheight=.8) |>
#'   plot(dir="tb", legend=FALSE)
#' @export
vtree_apply <- function(cases, vtree, FUN, ...,
                        .mask=NULL, .args="cases") {

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "vtree_apply() requires a vtree object"))
  }

  if(!is.data.frame(cases)) {
    cli_abort(c(x = "vtree_apply() requires a data frame for cases"))
  }

  allowed <- c("cases", "nodes", "sel")
  if(any(!.args %in% allowed)) {
    wrong <- .args[!.args %in% allowed]
    cli_abort(c(x=
      ".args may only contain following values: {allowed}",
    i = "following values are not allowed: {wrong}"))
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

  ret <- map(seq_along(matches), \(i) {
               m <- matches[[i]]
               args <- list(sel=m,
                            nodes = nodes[i, , drop=FALSE],
                            cases = cases[m, , drop=FALSE])
               #args <- c(args[.args], ...)
               args <- c(args[.args], ...)
               names(args) <- NULL

               do.call(FUN, args)

  })
  names(ret) <- nodes$node_key[.mask]
  ret
}





#' Get a value list as character vector
#'
#' For each node of the tree, identify the cases that correspond to that
#' node and create a formatted string label listing all values of variable
#' `var` which correspond to that node.
#'
#' Simple wrapper around [`vtree_apply()`] to create formatted labels which
#' contain a list of values for each node.
#'
#' @param cases a data frame with cases (one sample per row)
#' @param vtree a vtree object
#' @param var a variable name from cases and vt. It is a tidyselect data
#' var, so you don't need to quote it.
#' @param width formatting width in characters
#' @param sort whether the variable levels should be sorted (default TRUE)
#' @param shorten if a variable level occurs more than once, should it be
#' mentioned only once with the number of occurences appended (default
#' TRUE)
#' @param sep separator to put between the values
#' @return a character vector of length equal to the number rows in the
#' nodes data frame of the vtree object
#' @examples
#' library(tibble)
#' library(dplyr)
#' mt <- mtcars |>
#'   mutate(across(c(cyl, gear, carb), as.factor)) |>
#'   rownames_to_column("name")
#' vt <- vtree(mt, cyl, gear, carb)
#' # car names into a label
#' ids <- label_var_levels(mt, vt, name, width=60)
#' vt |>
#'   add_labels(template="sameline", root_label = "All cars") |>
#'   add_labels(template="sameline", mask = find_nodes(vt, leaf),
#'              suffix = ids) |>
#'   add_layout(varspace=c(root=1, cyl=1, gear=1, carb=3), lwidth=.8) |>
#'   plot(fontsizes = list(nodes="adaptive"))
#' @export
label_var_levels <- function(cases, vtree, var,
                          width=60,
                          shorten=TRUE,
                          sort=TRUE,
                          sep=", ") {

  if(!inherits(vtree, "vtree")) {
    cli_abort(c(x = "vtree_apply() requires a vtree object"))
  }

  if(!is.data.frame(cases)) {
    cli_abort(c(x = "vtree_apply() requires a data frame for cases"))
  }

  var <- enquo(var)
  var <- tidyselect::eval_select(var, data = cases)
  var <- names(var)

  if(!var %in% colnames(cases)) {
    cli_abort(c(x = "Column {var} not found in cases data frame"))
  }

  func <- \(df) {
    ret <- df[[var]]
    if(sort) {
      ret <- sort(ret)
    }
    ret <- as.character(ret)

    if(shorten) {
      sret <- summary(factor(ret))[unique(ret)]
      ret <- names(sret)
      ret <- ifelse(sret == 1L,
                    ret,
                    sprintf("%s (n=%d)",
                            ret, sret))
    }

    ret <- paste(ret, collapse=sep)
    ret <- strwrap(ret, width)
    ret <- paste(ret, collapse="\n")
    ret
  }

  ret <- vtree_apply(cases, vtree, func)
  unlist(ret)
}

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
