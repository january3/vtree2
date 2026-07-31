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
#'  * `node_name`, display name of the variable associated with a node
#'  * `node_val`, value of the variable associated with a node
#'  * `node_cv`, same as `paste0(node_col, ':', node_val)`
#'  * plus whatever new columns you have added to the vtree with mutate().
#'
#' (the difference between node_col and node_name is that you can set
#' node_name to whatever you like, while node_col must remain unchanged)
#
#'
#' @param vtree an object of class vtree
#' @param template One of the predefined formats; can be 'simple' or
#' 'long'. If 'custom', you must provide the `fmt` and `fmt_NA`
#' parameters.
#' @param mask If not NULL, then a logical vector is expected indicating
#' the nodes for which the labels will be modified.
#' @param fmt an R expression to format the valid value nodes. If not
#' NULL, replaces the format from the template.
#' @param fmt_na an R expression to format NA nodes. If not NULL,
#' replaces the format from the template.
#' @param root_label Label to be used for the root node. If NA, do not
#'                    modify the root label.
#' @return an object of class vtree with added labels
#' @importFrom rlang quo quo_is_null
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

  template <- match.arg(template, c("simple", "long"))

  userfmt <- enquo(fmt)
  userfmt_na <- enquo(fmt_na)

  # this only looks complicated because we have to use .data
  if(template == "simple") {
    fmt <- quo(ifelse(!is.na(.data[["node_val"]]) & .data[["node_val"]] == "",
               sprintf("%d\n(%.0f%%)", .data[["n"]], .data[["freq"]] * 100),
               sprintf("%s\n%d (%.0f%%)",
         .data[["node_val"]],
         .data[["n"]], .data[["freq"]] * 100)))
    fmt_na = quo(ifelse(!is.na(.data[["node_val"]]) & .data[["node_val"]] == "",
                        sprintf("%d", .data[["n"]]),
                        sprintf("%s\n%d", .data[["node_val"]], .data[["n"]]))
                       )
  } else if(template == "long") {
    fmt <- quo(sprintf("%s: %s\nN = %d (%.0f%%)",
         .data[["node_name"]],
         .data[["node_val"]],
         .data[["n"]],
         .data[["freq"]] * 100))
    fmt_na = quo(sprintf("%s: %s\n%d", .data[["node_name"]],
                            .data[["node_val"]], .data[["n"]]))
  }

  if(!quo_is_null(userfmt)) {
    fmt <- userfmt
  }

  if(!quo_is_null(userfmt_na)) {
    fmt_na <- userfmt_na
  } else if(!quo_is_null(userfmt)) {
    fmt_na <- userfmt
  }

  if(quo_is_null(fmt) || quo_is_null(fmt_na)) {
    stop("fmt/fmt_na not defined")
  }

  nodes <- vtree |> activate("nodes") |> as_tibble()
  labels    <- eval_tidy(fmt, data = nodes)
  labels_na <- eval_tidy(fmt_na, data = nodes)

  if(is.null(mask)) {
    mask <- rep(TRUE, nrow(nodes))
  }

  is_vp <- attr(vtree, "vp") %||% TRUE

  # add label column if one is missing
  if(!"label" %in% colnames(nodes)) {
    vtree <- mutate(vtree, label = "")
  }


  vtree <- vtree |> activate("nodes") |>
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



