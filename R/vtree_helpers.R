## helper functions for constructing vtrees


# converts a data frame to a pattern data frame, one line per each pattern
# / path through the tree.
#' @importFrom dplyr first
vtree_pat <- function(data, cnms, vp = TRUE) {
  # enquos the columns so we can play with them
  nc <- length(cnms)

  # we only need the columns mentioned

  for(i in 1:nc) {
    nm <- cnms[i]
    data <- data |>
      mutate(!!paste0(nm, "_missing") := sum(is.na(.data[[nm]]))) |>
      mutate(!!paste0(nm, "_tot_n") := length(.data[[nm]]))

    if(vp) {
      data <- data |>
        mutate(denom = sum(!is.na(.data[[nm]])))
    } else {
      data <- data |>
        mutate(denom = length(.data[[nm]]))
    }

    data <- data |>
      # denom is the denominator: the number of non-NA values for the given
      # column.
      # we rely here on the fact that the data is already grouped by the
      # previous columns! e.g. in the Titanic example, when var is Sex, the
      # data is already grouped by Class.
      group_by(across(cnms[1:i])) |>
      mutate(!!paste0(nm, "_n") := n()) |>
      mutate(!!paste0(nm, "_frac") := n() / .data[["denom"]]) |>
      mutate(!!paste0(nm, "_denom") := .data[["denom"]])
  }

  # selected columns
  selcnms <- map(cnms, ~ c(.x,
                           paste0(.x, "_n"),
                           paste0(.x, "_tot_n"),
                           paste0(.x, "_frac"),
                           paste0(.x, "_denom"),
                           paste0(.x, "_missing"))) |> unlist()

  # we are not interested in individual data points, only in the summaries
  # why setdiff: you can't summarize across grouping columns
  data <- data |>
    summarize(across(all_of(setdiff(selcnms, cnms)), dplyr::first),
              .groups = "drop_last") |>
    ungroup() |>
    select(all_of(selcnms))

  data
}


# this converts the data frame returned by pat2nodes to an edge data frame
node2edge <- function(df) {

  df |>
    select(all_of(c("ID", "parent"))) |>
    filter(!is.na(.data[["parent"]])) |>
    rename(from = "parent", to = "ID")
}

# this one creates a node data frame directly from the pattern,
# one line per node. It also collects the order of the nodes.
pat2nodes <- function(pattern, columns) {

  # map over the levels. i denotes the level; the node is defined by the
  # columns 1:i.
  ret <- map_dfr(seq_along(columns), \(i) {
    df <- pattern |>

      # select one representative row for each node
      distinct(pick(columns[1:i]), .keep_all = TRUE) |>

      # ignore columns below the current level
      select(all_of(c(columns[1:i],
                      paste0(columns[i], "_n"),
                      paste0(columns[i], "_tot_n"),
                      paste0(columns[i], "_missing"),
                      paste0(columns[i], "_frac"),
                      paste0(columns[i], "_denom")))) |>

      # n instead of colname_n etc.
      rename(n = paste0(columns[i], "_n"),
             tot_n = paste0(columns[i], "_tot_n"),
             missing = paste0(columns[i], "_missing"),
             freq = paste0(columns[i], "_frac"),
             denom = paste0(columns[i], "_denom")) |>
      mutate(level = i) |>

      # this complex bit constructs the parent and ID columns. The parent
      # is constructed from the previous columns, and the ID is constructed
      # from all columns up to the current one. The ID consist of column
      # name:value pairs separated by slashes.
      # the c_across is specifically for rowwise operations
      rowwise() |>
      mutate(parent = ifelse(i == 1, "root",
        paste0(paste0(columns[1:(i-1)], ":",
                      c_across(all_of(columns[1:(i-1)]))), collapse = "/"))) |>
      mutate(ID = paste0(paste0(columns[1:i], ":",
                      c_across(all_of(columns[1:i]))), collapse = "/")) |>

      # we want also to store the path as a list column for easier
      # processing downstream
      mutate(path = list(as.list(pick(all_of(columns[1:i]))))) |>


      ungroup() |>

      # rather than keeping all the columns, we only keep
      # node_col, which holds the column name, and node_val, which holds the
      # value of that column for the given node.
      mutate(node_col = columns[i]) |>
      mutate(node_val = .data[[columns[i]]]) |>

      select(all_of(c("ID", "node_col", "node_val", "parent",
                      "path", "level", "n", "tot_n", "missing", "freq", "denom")))
  })

  N <- sum(ret |> filter(.data[["level"]] == 1) |> pull("n"))

  # that special root node
  ret <- bind_rows(tibble(ID = "root",
                               node_col = "root",
                               node_val = "",
                               parent = NA_character_,
                               path = list(NA),
                               level = 0,
                               n = N,
                               tot_n = N,
                               missing = NA,
                               freq = 1,
                               denom = N), ret)
  ret <- ret |>
    mutate(node_cv = paste0(.data[["node_col"]], ":",
                            .data[["node_val"]])) |>
    mutate(node_name = ifelse(.data[["ID"]] == "root",
                              "", .data[["node_col"]])) |>
    select(all_of(c("ID", "node_col", "node_name", "node_val", "node_cv", "parent",
                    "path", "level", "n", "tot_n", "missing", "freq", "denom")))
  ret
}
