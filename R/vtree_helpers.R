## helper functions for constructing vtrees
.get_levels <- function(x, cnms) {
  if(!all(cnms %in% names(x))) {
    missing <- setdiff(cnms, names(x))
    cli_abort(c(x = "x does not contain columns {missing}"))
  }

  levels <- map(cnms, \(nm) {
    if(is.factor(x[[nm]])) {
      levels(x[[nm]])
    } else {
      unique(x[[nm]])
    }
  })
  names(levels) <- cnms
  levels
}

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
      mutate(!!paste0(nm, "_freq") := n() / .data[["denom"]]) |>
      mutate(!!paste0(nm, "_denom") := .data[["denom"]])
  }

  # selected columns
  selcnms <- map(cnms, ~ c(.x,
                           paste0(.x, "_n"),
                           paste0(.x, "_tot_n"),
                           paste0(.x, "_freq"),
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
# df |>
#   select(all_of(c("node_id", "parent_id"))) |>
#   mutate(from = match(.data[["parent_id"]], .data[["node_id"]])) |>
#   mutate(to = 1:n()) |>
#   # root has no parent! poor orphan
#   filter(!is.na(.data[["parent_id"]])) |>
#   select(all_of(c("from", "to")))

  ret <- df |>
    filter(!is.na(.data[["parent_id"]])) |>
    mutate(parent_key = paste0("node_", .data[["parent_id"]])) |>
    select(all_of(c("node_key", "parent_key"))) |>
    # root has no parent! poor orphan
    rename(from = "parent_key", to = "node_key")
  ret
}

# determine whether two paths are identical
same_paths <- function(p1, p2) {

  if(length(p1) != length(p2)) {
    return(FALSE)
  }

  if(!identical(names(p1), names(p2))) {
    return(FALSE)
  }

  for(n in names(p1)) {
    v1 <- p1[[n]]
    v2 <- p2[[n]]
    if(!identical(v1, v2)) {
      return(FALSE)
    }
  }

  return(TRUE)
}

# for a given node, find the parent node
find_parent <- function(path, all_paths) {

  # root has just an NA value without a var name
  if(is.null(names(path))) {
    return(NA) # this is the root
  }

  if(length(path) == 1L) {
    return(1) # root ID
  }

  pp <- path[-length(path)]

  ret <- purrr::map_lgl(all_paths, \(x) same_paths(x, pp))
  ret <- which(ret)

  if(length(ret) != 1) {
    cli_abort(c(x = "Cannot find parent. This should not happen."))
  }

  return(ret)
}


# from the pattern data frame, which contains one path through the tree per
# row, collect all unique nodes.
collect_nodes <- function(pattern, columns,
                          cv_sep=":", path_sep="/") {

  # map over the levels. i denotes the level; the node is defined by the
  # columns 1:i.
  ret <- map_dfr(seq_along(columns), \(i) {
      # select one representative row for each node
      distinct(pattern, pick(columns[1:i]), .keep_all = TRUE) |>

      # ignore columns below the current level
      select(all_of(c(columns[1:i],
                      paste0(columns[i], c("_n", "_tot_n",
                      "_missing", "_freq", "_denom"))))) |>

      # n instead of colname_n etc.
      rename(n = paste0(columns[i], "_n"),
             tot_n = paste0(columns[i], "_tot_n"),
             missing = paste0(columns[i], "_missing"),
             freq = paste0(columns[i], "_freq"),
             denom = paste0(columns[i], "_denom")) |>
      mutate(level = i) |>

      # this complex bit constructs the parent and path columns. The parent
      # is constructed from the previous columns, and the path is constructed
      # from all columns up to the current one. The path consist of column
      # name:value pairs separated by slashes.
      # the c_across is specifically for rowwise operations
      rowwise() |>
      mutate(parent = ifelse(i == 1, "root",
        paste0(paste0(columns[1:(i-1)], cv_sep,
                      c_across(all_of(columns[1:(i-1)]))), collapse = path_sep))) |>
      mutate(path = paste0(paste0(columns[1:i], cv_sep,
                      c_across(all_of(columns[1:i]))), collapse = path_sep)) |>

      # we want also to store the path as a list column for easier
      # processing downstream
      mutate(path_l = list(as.list(pick(all_of(columns[1:i]))))) |>


      ungroup() |>

      # rather than keeping all the columns, we only keep
      # node_col, which holds the column name, and node_val, which holds the
      # value of that column for the given node.
      mutate(node_col = columns[i]) |>
      mutate(node_val = .data[[columns[i]]]) |>

      select(all_of(c("path", "node_col", "node_val", "parent",
                      "path_l", "level", "n", "tot_n", "missing",
                      "freq", "denom")))
  })

  ret
}

# this one creates a node data frame directly from the pattern,
# one line per node. It also collects the order of the nodes.
pat2nodes <- function(pattern, columns, cv_sep, path_sep) {

  ret <- collect_nodes(pattern, columns, cv_sep, path_sep)
  N <- sum(ret |> filter(.data[["level"]] == 1) |> pull("n"))

  # that special root node
  ret <- bind_rows(tibble(path = "root",
                          node_col = "root",
                          node_val = "",
                          parent = NA_character_,
                          path_l = list(NA),
                          level = 0,
                          n = N,
                          tot_n = N,
                          missing = NA,
                          freq = 1,
                          denom = N), ret)
  ret <- ret |>
    mutate(node_id = dplyr::row_number()) |>
    mutate(parent_id = purrr::map_int(.data[["path_l"]],
                       \(x) find_parent(x, .data[["path_l"]]))) |>
    mutate(node_key = paste0("node_", .data[["node_id"]])) |>
    select(all_of(c("path", "node_id", "node_key", "parent", "parent_id",
                    "path_l", "level", "node_col", "node_val",
                    "n", "tot_n", "missing", "freq", "denom")))
  ret
}

.check_col_types <- function(x) {

  cnms <- colnames(x)
  coltypes <- purrr::map_lgl(x, \(xx) is.character(xx) || is.factor(xx))

  if(any(!coltypes)) {
    sel <- cnms[!coltypes]
    cli_abort(c(
        x = "Only factor or character columns are supported by vtree",
        "Following columns are neither: {sel}",
        i = "Convert numerical or logical columns explicitly"))
  }
}

.check_col_names <- function(cnms, reserved, cv_sep=':', path_sep='/') {

  .check_col_names_sep(cnms, cv_sep, path_sep)

  if(any(cnms %in% reserved)) {
    sel <- cnms[ cnms %in% reserved ]
    cli_abort(c(
      x = "Reserved columns used in the cases data frame",
      "Following column names are reserved: {sel}",
      i = "using these columns may lead to unexpected behavior"))
  }
}


.check_col_names_sep <- function(cnms, cv_sep=':', path_sep='/') {

  cv_violate <- grepl(cv_sep, cnms, fixed=TRUE)
  path_violate <- grepl(path_sep, cnms, fixed=TRUE)

  if(any(cv_violate)) {
    sel <- cnms[cv_violate]
    cli::cli_warn(
      c(x = "Column names contain col/val separator `{cv_sep}`",
      "Following columns contain the separator: {sel}",
      i = "Change the .cv_sep parameter to use another separator"

    ))
  }

  if(any(path_violate)) {
    sel <- cnms[path_violate]
    cli::cli_warn(
      c(x = "Column names contain path separator `{path_sep}`",
      "Following columns contain the separator: {sel}",
      i = "Change the .path_sep parameter to use another separator"
      ))
  }
}
