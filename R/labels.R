# code around add_labels() and add_aliases() functions

# make sure that all levels are included in the val_alias list
.normalize_val_alias <- function(val_alias, vtree) {
  defaults <- levels(vtree)
  defaults <- map(defaults, \(x) set_names(as.character(x)))

  if(is.null(val_alias)) {
    return(defaults)
  }

  val_alias[["NAs"]] <- val_alias[["NAs"]] %||% "NA"

  for(col in names(vtree)) {
    if(!col %in% names(val_alias)) {
      val_alias[[col]] <- setNames(as.character(defaults[[col]]),
                                   defaults[[col]])
    } else {
      # make sure all levels are included
      missing <- setdiff(defaults[[col]], names(val_alias[[col]]))
      if(length(missing) > 0) {
        val_alias[[col]][missing] <- missing
      }
    }
  }
  val_alias
}

# ensure all columns (variables) are included in the col_alias list, and
# add a root alias if missing
.normalize_col_alias <- function(col_alias, vtree) {
  defaults <- map(names(vtree), ~ .x)
  names(defaults) <- names(vtree)
  defaults <- c(list(root = ""), defaults)

  if(is.null(col_alias)) {
    return(defaults)
  }

  for(col in c("root", names(vtree))) {
    if(!col %in% names(col_alias)) {
      col_alias[[col]] <- defaults[[col]]
    }
  }
  col_alias
}

.def_formats <- function(template,
                         fmt, fmt_na, fmt_root) {

  if(template == "simple") {
    .fmt_root <- "{n}"
    .fmt <- "{val_alias}\n{n} ({pct}%)"
    .fmt_na <- "{val_alias}\n{n}"
  } else if(template == "sameline") {
    .fmt_root <- "{n}"
    .fmt <- "{val_alias} {n} ({pct}%)"
    .fmt_na <- "{val_alias} {n}"
  } else if(template == "long") {
    .fmt_root <- "All samples\nN = {n} (100%)"
    .fmt <- "{col_alias}: {val_alias}\nN = {n} ({pct}%)"
    .fmt_na <- "{col_alias}: {val_alias}\nN = {n}"
  }

  list(fmt=fmt %||% .fmt,
       fmt_na=fmt_na %||% fmt %||% .fmt_na,
       fmt_root=fmt_root %||% fmt %||% .fmt_root)
}

.ensure_aliases <- function(df) {

  if(!"val_alias" %in% names(df)) {
    df[["val_alias"]] <- df[["node_val"]]
  }

  if(!"col_alias" %in% names(df)) {
    df[["col_alias"]] <- df[["node_col"]]
  }

  df
}

.add_convenience_cols <- function(df, digits) {

  df <- df |>
    mutate(pct = round(100 * .data[["freq"]], digits=digits)) |>
    mutate(f = .data[["pct"]] / 100)

  df
}

#' Add labels to a plot
#'
#' Adds or modifies a column called `label` to the node data frame of a
#' vtree object. Labels are used by the [plot.vtree()] function to show as
#' node labels.
#'
#' By default, `add_labels()` produces simple node labels containing the
#' associated variable value, number of cases and percentage within the
#' parent node. This can be customized by one of the following:
#'
#'  * choose a different `template` parameter: `simple` (default),
#'  `sameline` (same as simple, but on one line) or `long` (with variable
#'  names). The templates all reasonably handle NA nodes and root node.
#'  * use a [glue::glue()] syntax for the parameters `fmt`, `fmt_na` and
#'  `fmt_root`, where variable names are put in curly
#'  braces. The variable names are the same as column names of the node
#'  data frame of the vtree object, plus `pct` and `f` (see below). The
#'  three parameters will be used to generate regular, NA-nodes or root
#'  node labels, respectively.
#'  * use an arbitrary R expression (parameter `expr`) which is evaluated with
#'  [rlang::eval_tidy()] in the context of the nodes data frame of the
#'  vtree object.
#'
#' Both the glue format syntax and the arbitrary expression syntax can use
#' any column name which is already present in the nodes data frame,
#' including:
#'
#'  * `freq`, the frequency for a node
#'  * `n`, number of samples of a node
#'  * `col_alias`, the alias for the column/variable associated with a node
#'    (default same as node_col, but can be modified
#'    by providing a `col_alias` column in the vtree)
#'  * `val_alias`, the alias for the value of the variable associated with a node
#'    (default same as node_val, but can be modified
#'    by providing a `val_alias` column in the vtree)
#'  * `node_col`, name of the variable associated with a node
#'  * `node_val`, value of the variable associated with a node
#'  * plus whatever new columns you have added to the vtree with mutate().
#'
#' In addition, `add_labels()` provides two additional, preformatted
#' values:
#'
#'  * `pct`, percentage rounded to the specified number of digits (the
#'  `digits` parameter)
#'  * `f`, equal to pct / 100 (so if the percentage is rounded with 0
#'  digits after decimal point, `f` will have two digits after decimal
#'  point).
#'
#' @section Parameter precedence:
#'
#' If `expr` is not NULL, it will be used for all labels chosen by the
#' mask.
#'
#' If `fmt` is NULL, the selected template will be used.
#' If `fmt_na` is NULL and `fmt` is not NULL, then `fmt_na` will be `fmt`,
#' otherwise the selected template will be used. Same for `fmt_root`: first
#' `fmt`, if defined, otherwise the template.
#'
#' `fmt_na` is used for NA values only if `is_vp(vtree)` is `TRUE`; this is
#' because for a vp tree the NA value percentages are meaningless.
#'
#' @param vtree an object of class vtree
#' @param template One of the predefined formats; can be 'simple',
#'        'sameline' or 'long'.  If `fmt` or `fmt_na` is defined, it will
#'        be overridden by the respective formatting expression.
#' @param mask a logical vector indicating
#'        the nodes for which the labels will be modified.
#' @param fmt a glue string to format the valid value nodes. If not
#'        NULL, replaces the format from the template.
#' @param fmt_na glue string to format NA nodes in trees with valid
#'        percentages. If not NULL, replaces the format from the template.
#'        This is mostly to omit frequency data from NA nodes if the
#'        missing data was not used as a denominator to calculate
#'        percentages. If NULL and fmt is not NULL, fmt will be used for NA
#'        nodes as well.
#' @param fmt_root a glue string to format the root node. If NULL and `fmt`
#'        is not NULL, then `fmt` will be used instead, otherwise template
#'        format will be used.
#' @param expr R expression to generate the labels; if not NULL it will be
#'        evaluated in the context of the vtree object node data frame.
#' @param digits number of decimal digits to keep when rounding the percentage
#'        column (`pct`). This will also influence the number of digits of
#'        the formatted frequency column `f`, since f = pct/100.
#' @param prefix add a prefix (character vector) to the label
#' @param suffix add a suffix (character vector) to the label
#' @param sep separator for prefix/suffix
#' @return an object of class vtree with added labels
#' @importFrom rlang quo quo_is_null
#' @seealso [add_aliases()], [plot_vtree()]
#' @examples
#' # a tree with Class, Sex and Survived vars
#' vt <- vtree_from_freqtable(Titanic, -Age)
#' # look at the labels
#' add_labels(vt) |> pull(label)
#' add_labels(vt) |> plot()
#'
#' vt |> add_labels(template = "long") |> plot()
#'
#' # only add labels to some nodes
#' mask <- find_nodes(vt, freq > .30)
#' vt |> add_labels(mask = mask) |>
#'   plot(layout = "proportional")
#'
#' # customize the format
#' vt |>
#'   retain(path == "Class:1st") |>
#'   add_labels(fmt = "{n} out of {max(n)}",
#'     fmt_na = "NA") |> plot(lwidth=.7)
#'
#' # only change the format for the root
#' vt |>
#'   retain(path == "Class:1st") |>
#'   add_labels(fmt_root = "Total:\n{n} samples") |>
#'   plot()
#'
#' # using expr
#' vt |>
#'   add_labels(expr =
#'                ifelse(leaf,
#'                       sprintf("%s:%s\n%d (%.0f)%%",
#'                               col_alias,
#'                               val_alias,
#'                               n, pct),
#'                       val_alias)) |>
#'   plot()
#' @importFrom glue glue_data
#' @export
add_labels <- function(vtree,
                       template = "simple",
                       mask = TRUE,
                       fmt = NULL,
                       fmt_na = NULL,
                       fmt_root = NULL,
                       prefix = NULL,
                       suffix = NULL,
                       sep = "\n",
                       expr = NULL,
                       digits = 0) {

  ensure(vtree, "vtree")
  ensure(mask, "logical")

  template <- match.arg(template, c("simple", "sameline", "long"))

  dflt <- .def_formats(template, fmt, fmt_na, fmt_root)
  expr <- enquo(expr)

  nodes <- as_tibble(vtree) |>
    .ensure_aliases() |>
    .add_convenience_cols(digits)

  if(is.null(prefix)) {
    prefix <- ""
  } else {
    prefix <- paste0(prefix, sep)
  }

  if(is.null(suffix)) {
    suffix <- ""
  } else {
    suffix <- paste0(sep, suffix)
  }

  if(!quo_is_null(expr)) {
    labels_root <-
      labels_na <-
         labels <- eval_tidy(expr, data = nodes)
  } else {
    labels <- glue_data(nodes, dflt$fmt)
    labels_na <- glue_data(nodes, dflt$fmt_na)
    labels_root <- glue_data(nodes, dflt$fmt_root)
  }

  labels      <- paste0(prefix, labels, suffix)
  labels_na   <- paste0(prefix, labels_na, suffix)
  labels_root <- paste0(prefix, labels_root, suffix)

  # add label column if one is missing
  if(!"label" %in% colnames(nodes)) {
    vtree <- mutate(vtree, label = "")
  }

  # normalize mask
  if(length(mask) == 1L) {
    mask <- rep(mask, nrow(nodes))
  } else if(length(mask) != nrow(nodes)) {
    cli_abort(c(x= "Parameter mask should have a length of {nrow(nodes)} or 1"))
  }

  vtree <- vtree |>
    mutate(label =
             ifelse(mask,
               ifelse(is.na(.data[["node_val"]]) & is_vp(vtree),
                      labels_na,
                      labels),
               .data[["label"]])) |>

    mutate(label =
             ifelse(mask & .data[["node_id"]] == 1,
               labels_root,
               .data[["label"]]))

  vtree
}


#' Add aliases columns to vtree
#'
#' Aliases are alternative labels / variable names which are shown on the
#' plots. This function allows to define aliases for both, variable names
#' and the variable values (levels).
#' @param vtree an object of class vtree
#' @param col_alias A list specifying aliases for the columns (variables). Each name
#'        of the list is a column/variable name (one of the values of
#'        `names(vtree)`) and the value is the alias to be used for that
#'        variable when constructing labels. If a name is missing from the
#'        list, the original column name is used. The aliases are then used
#'        to construct the labels and also stored in the column 'col_alias'
#'        of the nodes data frame. If a `col_alias` column is present, it
#'        will be overwritten.
#' @param val_alias A list specifying aliases for the levels of the
#'       variables. Each element of the list should be a named character
#'       vector, where the names are the levels of the variable and the
#'       values are the labels to be displayed for those levels. If NULL
#'       (default), the original levels of the variables are used as
#'       labels. The list needs not to be complete; if a variable is not
#'       included in the list, its original levels are used. The aliases
#'       are then used to construct the labels and also stored in the
#'       column 'val_alias' of the nodes data frame. The list may include
#'       aliases for NA values under then name `NAs`. If a `val_alias`
#'       column is present, it will be overwritten.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived) |>
#'       add_aliases(val_alias = list(Class = c("1st" = "First",
#'                                              "2nd" = "Second",
#'                                              "3rd" = "Third")),
#'                     col_alias = list(Sex = "Gender"))
#' plot(vt)
#' @return Returns an object of class vtree with added columns `col_alias`
#' and `val_alias` in the node data frame. The aliases are also stored as
#' an attribute of the vtree object.
#' @export
add_aliases <- function(vtree, val_alias = NULL, col_alias = NULL) {
  ensure_vtree(vtree)

  val_alias_n <- .normalize_val_alias(val_alias, vtree)
  col_alias_n <- .normalize_col_alias(col_alias, vtree)

  nodes <- as_tibble(vtree)

  if("col_alias" %in% colnames(nodes) && !is.null(col_alias)) {
    cli::cli_warn("Overwriting existing col_alias column in vtree")
  }

  if("val_alias" %in% colnames(nodes) && !is.null(val_alias)) {
    cli::cli_warn("Overwriting existing val_alias column in vtree")
  }

  # add new values only if column is missing or if user provided a new alias
  if(!"col_alias" %in% colnames(nodes) || !is.null(col_alias)) {
    aliases <- purrr::map_chr(nodes[["node_col"]],
                    \(x) col_alias_n[[x]] %||% x)
    vtree <- mutate(vtree, col_alias = aliases)
  }

  if(!"val_alias" %in% colnames(nodes) || !is.null(val_alias)) {
    aliases <- purrr::map2_chr(nodes[["node_col"]], nodes[["node_val"]],
                    \(.x, .y) if(is.na(.y)) {
                             val_alias_n[["NAs"]] %||% "NA"
                    } else {
                             val_alias_n[[.x]][.y] %||% .y
                    })

    vtree <- mutate(vtree, val_alias = aliases)

  }

  attr(vtree, "alias") <- list(val=val_alias_n,
                               col=col_alias_n)
  vtree
}



