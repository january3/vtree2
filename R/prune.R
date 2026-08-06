# rig a data frame which contains columns with names taken from node_col
# and values taken from node_val.
.add_virt_cols <- function(nodes) {

  colnames <- unique(na.omit(nodes$node_col))
  mask_df <- map_dfc(colnames, \(nm) {
    tibble(!!nm := ifelse(nodes$node_col == nm, nodes$node_val, NA))

  })

  bind_cols(nodes, mask_df)
}





# here we need to a) create a mask vector which tells which nodes to keep
# and which to prune, b) create a new graph not only with the nodes pruned
# which are indicated by mask, but also by all nodes that follow them. We
# do this with map_bfs_lgl() which traverses the graph in breadth-first order
# Note: the problem here is when you try is.na(), b/c nodes which are not
# for the given column will also have NA values, so you can't distinguish
# between a "true" NA value and "not applicable" NA value.
# Possible solutions: 1) we only allow categorical data. For categorical
# data, we can define a "special" NA value, smth like "____NA" or similar,
# unlikely to be a real value for the columns. 2) define a special
# "has_attr()" function which must be used in conjunction with is.na() to
# check whether the node has that attribute.

#' Find nodes and prune a vtree graph
#'
#' `prune()` prunes the tree by condition, `mark()` marks nodes by
#' condition, `retain()` prunes everything but the nodes that fullfil a
#' condition and `find_nodes()` returns a logical vector for nodes by
#' condition.
#'
#' `prune()` prunes a vtree graph by removing nodes that satisfy a given condition.
#' The condition is evaluated in the context of the node attributes,
#' allowing for flexible pruning based on node values.
#' If a node is pruned, all subsequent nodes in the path are also pruned.
#'
#' `retain()` is a convenience function that retains only the nodes that
#' satisfy the condition and prunes everything else, except for any node
#' that precedes the selected nodes.
#'
#' `find_nodes()` returns a logical vector identifying the nodes which
#' fullfill a certain condition. With `follow_only=TRUE`, it returns TRUE
#' for each node which *follows* (directly or indirectly) a node which
#' fullfills the condition.
#'
#' `mark()` is the same as `find_nodes()`, except that the logical vector
#' is then inserted into the column `mark` of the node data frame in the
#' vtree and the vtree is returned. It is a shortcut for `prune(condition,
#' mark_only=TRUE)`.
#'
#' `condition` can be any logical vector that refers to either the columns
#' in the node data frame of the vtree object, or the names of the vtree
#' variables. For example, you can use `node_col` to find nodes which
#' correspond to a certain variable, and then use the variable name to
#' search for a specific value.
#'
#' @section retain vs prune:
#'
#' Note that `retain()` is not a simple complement of `prune()`, because if you
#' use retain to select a node, then if the parent node does not fullfill the
#' condition it will still be kept. However, if you mark a node for pruning
#' with `prune()`, then all subsequent nodes will be pruned, even if they
#' fullfill the condition.
#'
#' In the Titanic example, if you prune all nodes where frequency is less
#' than 15%, then the node for adult females from the crew will be pruned,
#' because the frequency of the node Crew:Adult/Sex:Female is below 15% and
#' all subsequent nodes are also pruned. However, if you specify to keep
#' all nodes where frequency is above 15%, then the node
#' Crew:Adult/Sex:Female will be kept despite having a low frequency,
#' because the subsequent nodes – like percentage of survivorship for
#' female crew members – are above 15%.
#'
#' @section keep_na_sisters:
#'
#' If the tree was created with valid percentages (`.vp=TRUE`), then the
#' percentage and count for a node cannot be used to calculate the
#' total count for that variable. For example, if we know that in the 1st
#' Class on the Titanic there were 120 (46%) females (as in the titanicNA
#' data set), we cannot calculate the total number of passengers in the 1st
#' class without knowing for how many passengers in the 1st class we lack
#' the information about their sex. Therefore, by default NA nodes are kept
#' if the tree was created with `.vp = TRUE` (see also [is_vp()]). You can
#' control this behavior with `keep_na_sisters`.
#'
#' @param vtree A vtree graph object.
#' @param condition A logical expression that defines the pruning
#'              condition. If no condition is provided, no pruning is done,
#'              except for the removal of nodes with NA values with
#'              `na.rm`.
#' @param follow_only if TRUE, retain the nodes selected by condition, but
#'              prune all following nodes.
#' @param keep If TRUE, keeps the nodes that satisfy the condition and prunes
#'              everything else.
#' @param keep_follow If keep is specified, and keep_follow is true, then
#'          nodes following the selected node (i.e., its children) are also
#'          kept even if they do not fulfill the condition.
#' @param keep_na_sisters If TRUE, then when pruning/keeping nodes, NA
#'        nodes which are sisters with a kept node (share the same parent) 
#'        are also kept.
#' @param mark_only If TRUE, marks the nodes that satisfy the condition in
#'          the node data frame with a new column `mark` but does not prune
#'          the graph. Useful for debugging. The values of the column are
#'          `hit` for the nodes that satisfy the condition, otherwise
#'          `keep` for the nodes that would be kept, and `prune` for the
#'          nodes that would be pruned.
#' @param na.rm If TRUE, removes nodes with NA values in the evaluated
#'              condition. If it is a character vector, then it is treated
#'              as a vector of column names for which all NA values should
#'              be removed.
#' @return `retain()` and `prune()` return a pruned vtree object.
#' `find_nodes()` returns a logical vector corresponding to the tree nodes
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#'
#' # find the node corresponding to the 1st Class
#' mask <- find_nodes(vt, node_col == "Class" & Class == "1st")
#'
#' # find nodes with frequencies below 15%
#' mask <- find_nodes(vt, freq < .15)
#'
#' # find nodes where the fraction of survivorship was less than 80
#' mask <- find_nodes(vt, node_col == "Survived" &
#'                    node_val == "No" & freq > .2)
#'
#' # mark these nodes with red color on the plot
#' vt |> mutate(fill = ifelse(mask, "red", "white")) |> plot()
#'
#' # mark the nodes directly
#' mark(vt, node_col == "Survived" & node_val == "No" & freq > .2) |>
#'   mutate(fill = ifelse(mark, "red", "white")) |> plot()
#'
#' # mark all nodes that follow the 3rd Class node
#' mark(vt, path == "Class:3rd", follow_only=TRUE) |>
#'   mutate(fill = ifelse(mark, "red", "white")) |> plot()
#'
#' # how keep_na_sisters influences the plot
#' vt <- vtree(titanicNA)
#' vt |> retain(path == "Class:1st/Sex:Female") |>
#'   plot()
#' vt |>
#'   retain(path == "Class:1st/Sex:Female",
#'        keep_na_sisters = FALSE) |>
#'   plot()
#'
#' @importFrom rlang is_empty enquo eval_tidy expr
#' @importFrom stats na.omit
#' @importFrom dplyr bind_cols n
#' @importFrom tibble tibble
#' @export
prune <- function(vtree, condition, follow_only = FALSE,
                  mark_only = FALSE,
                  keep_na_sisters = is_vp(vtree),
                  keep = FALSE, na.rm = FALSE) {
  if(missing(condition)) {
    condition <- expr(FALSE)
  }

  if(na.rm) {
    keep_na_sisters <- FALSE
  }

  condition <- enquo(condition)

  if(is.character(na.rm)) {
    if(!all(na.rm %in% names(vtree))) {
      na.rm <- na.rm[!na.rm %in% names(vtree)]
      na.rm <- paste(na.rm, collapse = ", ")
      present <- paste(names(vtree), collapse = ", ")
      cli_abort(c(
        "na.rm must be a logical value or a character vector of column names",
        i = "Columns present in the vtree: {present}",
        x = "Following columns are not present in the vtree: {na.rm}"))
    }
  }

  .prune(vtree, condition, follow_only = follow_only,
         mark_only = mark_only,
         keep_na_sisters = keep_na_sisters,
         keep = keep, na.rm = na.rm)

}


#' @rdname prune
#' @export
find_nodes <- function(vtree, condition, follow_only = FALSE) {
  condition <- enquo(condition)

  mask <- .get_mask(vtree, condition)
  if(follow_only) {
    mask <- find_children(vtree, mask)
  }
  mask
}


#' Find all nodes that follow or precede the nodes for which the mask is TRUE
#'
#' Find all nodes that follow or precede the nodes for which the mask is TRUE
#'
#' `find_children` identifies all nodes in a vtree graph that follow the
#' nodes for which the provided mask is TRUE.
#'
#' `find_parents` identifies all nodes in a vtree graph that precede the
#' nodes for which the provided mask is TRUE.
#' @param vtree A vtree graph object.
#' @param mask A logical vector indicating which nodes to consider for finding
#'             their following or preceding nodes.
#' @examples
#' vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
#' mask <- find_nodes(vt, path == "Class:1st/Sex:Male")
#' follow <- find_children(vt, mask)
#' precede <- find_parents(vt, mask)
#' vt |> mutate(fill =
#'             ifelse(path == "Class:1st/Sex:Male", "green", "white")) |>
#'       mutate(fill =
#'             ifelse(follow, "red",
#'                    ifelse(precede, "blue", fill))) |>
#'       plot()
#'
#' @return A logical vector indicating which nodes follow or precede the nodes
#' @export
find_children <- function(vtree, mask) {

  follow <- vtree |>
    mutate(.mask = mask) |>
    mutate(.follow = map_bfs_lgl(
      root = 1,
      mode = "out",
      .f = \(node, path, ...) {
        return(any(.N()$.mask[path$node]))
  })) |> pull(".follow")

  follow
}

#' @rdname find_children
#' @importFrom tidygraph map_bfs_back_lgl
#' @export
find_parents <- function(vtree, mask) {

  precede <- vtree |>
    mutate(.mask = mask) |>
    mutate(.precede = map_bfs_back_lgl(
      root = 1,
      mode = "out",
      .f = \(node, path, ...) {
        return(any(.N()$.mask[path$node]) ||
               any(unlist(path$result)))
  })) |> pull(".precede")

  precede
}

.get_mask <- function(vtree, condition, na.rm = FALSE) {

  # we need these cols to be able to naturally evaluate the condition using
  # data vars
  vcols <- .add_virt_cols(as_tibble(vtree))

  # here we create the pruning mask
  mask <- eval_tidy(condition, data = vcols)

  # now, some comparisons may return NA.
  # we ignore them - assume that it's not a match.
  mask[ is.na(mask) ] <- FALSE

  # na.rm may be a character vector of columns to check
  # for potential NAs
  if(is.character(na.rm)) {
    nas <- lapply(na.rm, \(col) {
      vcols$node_col == col & is.na(vcols$node_val)
    }) |> reduce(`|`)
    mask <- mask | nas
  } else if(na.rm) {
    nas <- vcols |> pull("node_val") |> is.na()
    mask <- mask | nas
  }

  mask
}

# given a node_id, find out whether there is a sister node (sharing the
# same parent) with an NA value and return its node_id
.find_sister_na <- function(nodes, node_key) {
  sel <- node_key == nodes$node_key
  node_id <- nodes$node_id[sel]
  parent_id <- nodes$parent_id[sel]

  if(is.na(parent_id)) {
    return(character(0))
  }

  nasel <- nodes$node_key[ nodes$parent_id == parent_id &
                          is.na(nodes$node_val) ]
  return(nasel)
}

# return a logical vector where each element corresponds to a node; nodes
# are marked TRUE if 1) they are NA and 2) they are sister nodes of a node
# which is shown on the figure.
.find_sister_na_nodes <- function(vtree, mask) {
  nodes <- as_tibble(vtree)

  if(!length(mask) == nrow(nodes)) {
    die("Incorrect mask length: mask={length(mask)} vs vtree={nrow(nodes)}")
  }

  node_keys <- nodes$node_key[ mask ]

  nasiss <- map(node_keys, \(nk) .find_sister_na(nodes, nk)) |>
    unlist()

  mask <- nodes$node_key %in% nasiss
  mask
}


# here we actually do the pruning
# follow only: prune only the following nodes, not the nodes that are
# selected by the condition
# na.rm: remove the NA nodes
.prune <- function(vtree, condition,
                   follow_only = FALSE,
                   keep_follow = TRUE,
                   mark_only = FALSE,
                   find_only = FALSE,
                   keep_na_sisters = TRUE,
                   keep = FALSE, na.rm = FALSE) {

  mask_cond <- .get_mask(vtree, condition, na.rm)

  if(find_only) {
    return(vtree |> mutate(mark = mask_cond))
  }

  # inverse mask if we want to keep the nodes
  # that satisfy the condition
  if(keep) {
    # first, which nodes precede our selected nodes?
    # we need to keep them!
    precede <- find_parents(vtree, mask_cond)
    mask <- mask_cond | precede

    if(keep_follow) {
      follow <- find_children(vtree, mask_cond)
      mask <- mask | follow
    }

    # now inverse the mask, so anything FALSE ("do not keep")
    # becomes TRUE ("prune")
    mask <- !mask

    # nodes <- as_tibble(vtree) |>
    #   select(path, freq) |>
    #   mutate(cond = mask_cond,
    #          precede = precede,
    #          follow = follow,
    #          mask = mask) |>
    # colorDF::print_colorDF()

  } else {
    mask <- mask_cond
  }

  # find all nodes that follow a node
  follow_mask <- find_children(vtree, mask)

  # pruning only follow nodes
  if(follow_only) {
    mask <- follow_mask
  } else {
    mask <- mask | follow_mask
  }

  if(keep_na_sisters) {
    sisters <- !.find_sister_na_nodes(vtree, !mask)
    mask <- mask & sisters
  }

  if(mark_only) {
    ret <- vtree |>
     mutate(mark = mask)
     #mutate(mark = ifelse(mask,
     #                     "prune", "keep")) |>
     #mutate(mark = ifelse(mask_cond, "hit", .data[["mark"]]))
  } else {
    ret <- vtree |>
      filter(!mask)
  }


  nodes <- as_tibble(ret)
  if(nrow(nodes) < 1) {
    die("No nodes remain after pruning")
  }

  attr(ret, "pruned") <- TRUE
  as_vtree(ret)
}

#' @rdname prune
#' @export
retain <- function(vtree, condition,
                 keep_follow = TRUE,
                 keep_na_sisters = is_vp(vtree),
                 mark_only = FALSE) {
  condition <- enquo(condition)
  #prune(vtree, condition, keep = TRUE, mark_only = mark_only)
  .prune(vtree, condition, follow_only = FALSE,
         mark_only = mark_only,
         keep = TRUE, keep_follow = keep_follow,
         keep_na_sisters = keep_na_sisters,
         na.rm = FALSE)

}

#' @rdname prune
#' @export
mark <- function(vtree, condition, follow_only=FALSE) {

  condition <- enquo(condition)
  mask <- .get_mask(vtree, condition)

  if(follow_only) {
    mask <- find_children(vtree, mask)
  }
  mutate(vtree, mark = mask)
}
