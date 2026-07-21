# A list of character vectors, one for each variable split in the tree,
# with each ordered vector containing the levels of that variable

#' Get the levels of a vtree object
#'
#' Get the levels of a vtree object
#'
#' Returns a list of character vectors, one for each variable split in the tree,
#' with each ordered vector containing the levels of that variable.
#' @param x A vtree object.
#' @return A list of character vectors, one for each variable split in the tree,
#' @export
levels.vtree <- function(x) {
  stopifnot(inherits(x, "vtree"))
  nodes <- x |> activate(nodes) |> as_tibble()

  cnms <- attr(x, "cols") |> set_names()

  ret <- map(cnms, \(cn) {
    vals <- nodes$node_val[nodes$node_col == cn]

    if(is.factor(vals)) {
      vals <- levels(vals)
    } else {
      vals <- unique(vals)
    }
  })
  ret <- ret[ names(ret) %in% nodes$node_col ]
  ret
}

#' Get the variable names of a vtree object
#'
#' Get the variable names of a vtree object
#'
#' @param x A vtree object.
#' @return A character vector of variable names
#' @export
names.vtree <- function(x) {
  stopifnot(inherits(x, "vtree"))
  attr(x, "cols")
}


#' Print a vtree object
#'
#' Print a vtree object
#'
#' @param x A vtree object.
#' @return Invisibly returns the input object.
#' @export
print.vtree <- function(x, ...) {
  stopifnot(inherits(x, "vtree"))
  cols <- attr(x, "cols")
  N <- attr(x, "N")
  cat("vtree object with", length(cols), "columns and", N, "observations\n")
  cat("Columns:", paste(cols, collapse = ", "), "\n")
  invisible(x)
}



#' Convert a tbl_graph to a vtree
#'
#' Convert a tbl_graph to a vtree
#'
#' @param x A tbl_graph object.
#' @return A vtree object
as_vtree <- function(x) {
  stopifnot(inherits(x, "tbl_graph"))

  # integrity checks
  # ------------------
  nodes <- x |> activate(nodes) |> as_tibble()
  stopifnot(all(c("ID", "node_col", "node_val", "parent", "level", "n", "freq") 
                %in% colnames(nodes)))

  # more than a root
  stopifnot(any(nodes$level > 0))

  # only one root
  stopifnot(sum(nodes$level == 0) == 1)

  N <- nodes$n[ nodes$level == 0 ]

  stopifnot(all(!is.na(nodes$node_col)))

  attr(x, "cols") <- cnms
  attr(x, "N") <- N

  class(x) <- c("vtree", class(x))
  x
}



#' Create a vtree object from a data frame
#'
#' Create a vtree object from a data frame of cases
#'
#' The cases data frame used as a first argument should have one row per
#' observation. The selected columns will correspond to the nodes of the vtree.
#'
#' With `vtree_from_freqtable()`, you can create a vtree from a frequency
#' table, where each row corresponds to a unique combination of values and
#' a frequency count.
#'
#' Manipulating a vtree object
#'
#' Vtree objects are little more than tidygraph object of class tbl_graph.
#' You can use the tidygraph package to manipulate them, and the ggraph
#' package to plot them. The vtree class is mostly a convenience for
#' plotting. You can manipulate the vtree object using regular tidygraph
#' functions, and then use as_vtree to convert it back to a vtree object
#' for plotting.
#' @examples
#' library(tidyverse)
#' data(Titanic)
#' vt <- vtree_from_freqtable(Titanic, Class, Survived)
#' set.seed(123)
#' # create a new data set with NAs
#' titanicNA <- Titanic |>
#'   cases_from_freqtable(Class, Sex, Survived) |>
#'   # change all classes to character
#'   mutate(across(everything(), as.character)) |>
#'   # add some random NAs to each column
#'   mutate(Class = ifelse(runif(n()) < 0.1, NA, Class)) |>
#'   mutate(Sex = ifelse(runif(n()) < 0.1, NA, Sex)) |>
#'   mutate(Age = ifelse(runif(n()) < 0.1, NA, Age))            
#'
#' vt <- vtree(titanicNA, Class, Sex, Survived)
#' @param cases A data frame, one row per observation, one column per variable
#' @param x A frequency table (matrix, table or data frame)
#' @param ... Columns to use for the tree
#' @param .cols Provide column names as a character vector instead of using the ... argument. This is useful when the column names are stored in a variable.
#' @param .freq_col The name of the column in a frequency table that
#' contains the frequency counts. Default is "Freq".
#' @return an object of class vtree
#' @importFrom dplyr select mutate group_by summarize ungroup 
#' @importFrom dplyr distinct rename rowwise c_across
#' @importFrom rlang enquos as_name
#' @export
vtree <- function(cases, ..., .cols = NULL) {
  if (!is.null(.cols)) {
    cnms <- .cols
  } else {
    # enquos the columns so we can play with them
    cols <- rlang::enquos(...)
    # get the column names as strings
    cnms <- map_chr(cols, rlang::as_name)
  }

  stopifnot(length(cnms) > 0)
  stopifnot(all(cnms %in% colnames(cases)))

  cases <- select(cases, all_of(cnms))
  N <- nrow(cases)

  pat <- vtree_pat(cases, cnms)

  df <- pat2df(pat, cnms)
  edges <- df2edge(df)
  vtree <- tbl_graph(nodes = df, edges = edges, directed = TRUE, node_key = "ID")

  as_vtree(vtree)

}

# converts a data frame to a pattern data frame, one line per each pattern
# / path through the tree.
vtree_pat <- function(data, cnms) {
  # enquos the columns so we can play with them
  nc <- length(cnms)

  # we only need the columns mentioned

  for(i in 1:nc) {
    nm <- cnms[i]
    data <- data |>
      # denom is the denominator: the number of non-NA values for the given
      # column.
      # we rely here on the fact that the data is already grouped by the
      # previous columns! e.g. in the Titanic example, when var is Sex, the
      # data is already grouped by Class.
      mutate(..denom.. = sum(!is.na(.data[[nm]]))) |>
      group_by(across(cnms[1:i])) |>
      mutate(!!paste0(nm, "_n") := n()) |>
      mutate(!!paste0(nm, "_frac") := n() / ..denom..)
  }

  # selected columns
  selcnms <- map(cnms, ~ c(.x, paste0(.x, "_n"), paste0(.x, "_frac"))) |> unlist()

  # we are not interested in individual data points, only in the summaries
  data <- data |> 
    summarize(across(starts_with(cnms), first),
              .groups = "drop_last") |>
    ungroup() |>
    select(all_of(selcnms))

  data
}


# this converts the data frame returned by pat2df to an edge data frame
df2edge <- function(df) {

  df |>
    select(ID, parent) |>
    filter(!is.na(parent)) |>
    rename(from = parent, to = ID)
}

# this one creates a node data frame directly from the pattern,
# one line per node. It also collects the order of the nodes.
pat2df <- function(pattern, columns) {

  # map over the levels. i denotes the level; the node is defined by the
  # columns 1:i.
  ret <- map_dfr(seq_along(columns), \(i) {
    df <- pattern |>

      # select one representative row for each node
      distinct(pick(columns[1:i]), .keep_all = TRUE) |>

      # ignore columns below the current level
      select(all_of(c(columns[1:i], 
                      paste0(columns[i], "_n"), 
                      paste0(columns[i], "_frac")))) |>
      
      # n instead of colname_n etc.
      rename(n = paste0(columns[i], "_n"),
             freq = paste0(columns[i], "_frac")) |>
      mutate(level = i) |>

      # this complex bit constructs the parent and ID columns. The parent
      # is constructed from the previous columns, and the ID is constructed
      # from all columns up to the current one. The ID consist of column
      # name:value pairs separated by slashes.
      # the c_across is specifically for rowwise operations
      rowwise() |>
      mutate(parent = ifelse(i == 1, "__ALL__:__ALL__", 
        paste0(paste0(columns[1:(i-1)], ":", 
                      c_across(all_of(columns[1:(i-1)]))), collapse = "/"))) |>
      mutate(ID = paste0(paste0(columns[1:i], ":", 
                      c_across(all_of(columns[1:i]))), collapse = "/")) |>
      ungroup() |>

      # rather than keeping all the columns, we only keep
      # node_col, which holds the column name, and node_val, which holds the 
      # value of that column for the given node.
      mutate(node_col = columns[i]) |>
      mutate(node_val = .data[[columns[i]]]) |>

      select(all_of(c("ID", "node_col", "node_val", 
                      "parent", "level", "n", "freq")))
  })

  N <- sum(ret |> filter(.data[["level"]] == 1) |> pull("n"))

  ret <- rbind(data.frame(ID = "__ALL__:__ALL__", 
                               node_col = "__ALL__",
                               node_val = "__ALL__",
                               parent = NA, 
                               level = 0, 
                               n = N,
                               freq = 1), ret)
  ret
}
