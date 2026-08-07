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

.def_formats <- function(template) {

  # this only looks complicated because we have to use .data
  if(template == "simple") {
    fmt <- quo(ifelse(.data[["node_col"]] == "root",
               sprintf("%d", .data[["n"]]),
               ifelse(!is.na(.data[["val_alias"]]) & .data[["val_alias"]] == "",
               sprintf("%d\n(%.0f%%)", .data[["n"]], .data[["freq"]] * 100),
               sprintf("%s\n%d (%.0f%%)", .data[["val_alias"]],
                                          .data[["n"]], .data[["freq"]] * 100))))
    fmt_na = quo(ifelse(!is.na(.data[["val_alias"]]) & .data[["val_alias"]] == "",
                        sprintf("%d", .data[["n"]]),
                        sprintf("%s\n%d", .data[["val_alias"]], .data[["n"]]))
                       )
  } else if(template == "sameline") {
    fmt <- quo(ifelse(.data[["node_col"]] == "root",
               sprintf("%d", .data[["n"]]),
               ifelse(!is.na(.data[["val_alias"]]) & .data[["val_alias"]] == "",
               sprintf("%d (%.0f%%)", .data[["n"]], .data[["freq"]] * 100),
               sprintf("%s %d (%.0f%%)", .data[["val_alias"]],
                                          .data[["n"]], .data[["freq"]] * 100))))
    fmt_na = quo(ifelse(!is.na(.data[["val_alias"]]) & .data[["val_alias"]] == "",
                        sprintf("%d", .data[["n"]]),
                        sprintf("%s %d", .data[["val_alias"]], .data[["n"]]))
                       )
  } else if(template == "long") {
    fmt <- quo(ifelse(!is.na(.data[["val_alias"]]) & .data[["val_alias"]] == "",
               sprintf("All samples\nN = %d (100%%)", .data[["n"]]),
               sprintf("%s: %s\nN = %d (%.0f%%)",
                           .data[["col_alias"]],
                           .data[["val_alias"]],
                           .data[["n"]],
                           .data[["freq"]] * 100)))
    fmt_na = quo(sprintf("%s: %s\n%d", .data[["col_alias"]],
                            .data[["val_alias"]], .data[["n"]]))
  }

  list(fmt=fmt, fmt_na=fmt_na)
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

#' Add labels to a plot
#'
#' Adds or modifies a column called `label` to the node data frame of a vtree object.
#' Labels are used by the [plot.vtree()] function to show as node labels.
#'
#' By default, `add_labels()` produces simple node labels containing the
#' associated variable value, number of cases and percentage within the
#' parent node.
#'
#' Formatting can be done with the `fmt`/`fmt_na` parameter, which is
#' an R expression. You can use sprintf, glue, paste or whichever
#' expressions you like to construct a label from the following variables:
#'
#'  * `freq`, the frequency for a node
#'  * `n`, number of samples of a node
#'  * `node_col`, name of the variable associated with a node
#'  * `node_val`, value of the variable associated with a node
#'  * `col_alias`, the alias for the column/variable associated with a node
#'    (default same as node_col, but can be modified
#'    by providing a `var_alias` column in the vtree)
#'  * `val_alias`, the alias for the value of the variable associated with a node
#'    (default same as node_val, but can be modified 
#'    by providing a `val_alias` column in the vtree)
#'  * plus whatever new columns you have added to the vtree with mutate().
#'
#' @param vtree an object of class vtree
#' @param template One of the predefined formats; can be 'simple',
#'        'sameline' or 'long'.  If `fmt` or `fmt_na` is defined, it will
#'        be overridden by the respective formatting expression.
#' @param mask If not NULL, then a logical vector is expected indicating
#'        the nodes for which the labels will be modified.
#' @param fmt an R expression to format the valid value nodes. If not
#'        NULL, replaces the format from the template.
#' @param fmt_na an R expression to format NA nodes in trees with valid
#'        percentages. If not NULL, replaces the format from the template.
#'        This is mostly to omit frequency data from NA nodes if the
#'        missing data was not used as a denominator to calculate
#'        percentages. If NULL and fmt is not NULL, fmt will be used for NA
#'        nodes as well.
#' @param root_label Label to be used for the root node. If NA, do not
#'        modify the root label.
#' @return an object of class vtree with added labels
#' @importFrom rlang quo quo_is_null
#' @seealso [add_aliases()], [plot_vtree()]
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
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
#'   add_labels(fmt = sprintf("%d out of %d",
#'         n, round(n/freq)),
#'     fmt_na = "NA") |> plot()
#'
#' @export
add_labels <- function(vtree,
                       template = "simple",
                       mask = NULL,
                       fmt = NULL,
                       fmt_na = NULL,
                       root_label = NA) {

  template <- match.arg(template, c("simple", "sameline", "long"))

  userfmt <- enquo(fmt)
  userfmt_na <- enquo(fmt_na)
  default <- .def_formats(template)

  if(!quo_is_null(userfmt)) {
    fmt <- userfmt
  } else {
    fmt <- default$fmt
  }

  if(!quo_is_null(userfmt_na)) {
    fmt_na <- userfmt_na
  } else if(!quo_is_null(userfmt)) {
    fmt_na <- userfmt
  } else {
    fmt_na <- default$fmt_na
  }

  if(quo_is_null(fmt) || quo_is_null(fmt_na)) {
    stop("fmt/fmt_na not defined")
  }

  nodes <- as_tibble(vtree) |> .ensure_aliases()
  labels    <- eval_tidy(fmt, data = nodes)
  labels_na <- eval_tidy(fmt_na, data = nodes)

  if(is.null(mask)) {
    mask <- rep(TRUE, nrow(nodes))
  }

  # does the tree have valid percentages?
  is_vp <- attr(vtree, "vp") %||% TRUE

  # add label column if one is missing
  if(!"label" %in% colnames(nodes)) {
    vtree <- mutate(vtree, label = "")
  }

  vtree <- vtree |>
    mutate(label = ifelse(mask,
           ifelse(is.na(.data[["node_val"]]) & is_vp,
                          labels_na,
                          labels),
                          .data[["label"]]
           )) |>
    mutate(label = ifelse(.data[["node_id"]] == 1 & !is.na(root_label),
                root_label, .data[["label"]]))

  vtree <- as_vtree(vtree)
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
#'        to construct the labels and also stored in the column 'var_alias'
#'        of the nodes data frame. If a `var_alias` column is present, it
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



