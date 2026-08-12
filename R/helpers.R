ensure <- function(x, what) {

  arg <- rlang::caller_arg(x)

  if(what == "list") {
    check <- is.list(x)
  } else if(what == "character") {
    check <- is.character(x)
    what <- "character vector"
  } else if(what == "function") {
    check <- is.function(x)
  } else if(what == "data.frame") {
    check <- is.data.frame(x)
    what <- "data frame"
  } else if(what == "numeric") {
    check <- is.numeric(x)
    what <- "number"
  } else if(what == "integer") {
    check <- is.integer(x)
    what <- "vector of integer numbers"
  } else if(what == "logical") {
    check <- is.logical(x)
    what <- "logical vector"
  } else if(what == "factor") {
    check <- is.factor(x)
    what <- "factor"
  } else {
    check <- inherits(x, what)
    what <- paste(what, "object")
  }

  if(!check) {
    cli_abort(c(x = "Argument `{arg}` is not a {what}",
      i = "You provided an object of class {class(x)}"),
          call = rlang::caller_env())
  }
  x
}

ensure_vtree <- function(x) {
  arg <- rlang::caller_arg(x)
  if(!inherits(x, "vtree")) {
    cli_abort(c(x = "Argument `{arg}` is not a vtree object",
      i = "You provided an object of class {class(x)}"),
          call = rlang::caller_env())
  }
  x
}

ensure_data_frame <- function(x) {
  arg <- rlang::caller_arg(x)

  if(!is.data.frame(x)) {
    cli_abort(c(x = "Argument `{arg}` is not a data frame",
      i = "You provided an object of class {class(x)}"
    ))
  }
  x
}

#' @importFrom cli cli_abort
die <- function(message = "Unspecified error.",
                call = .envir, .envir = parent.frame()) {
  cli_abort(c(x = message), call = call)
}


# extract required columns from a tidygraph object
# this is b/c extracting all vertex attributes is costly
#' @importFrom stats setNames
node_attrs <- function(graph, cols) {
  tibble::as_tibble(
    setNames(
      lapply(cols, \(col) igraph::vertex_attr(graph, col)),
      cols
    ))
}

# if grobs are in the vtree, extract them and return as a list
extract_grobs <- function(vtree) {
  grobs <- NULL

  vtree_names <- igraph::vertex_attr_names(vtree)
  if("grob" %in% vtree_names) {
    grobs <- igraph::vertex_attr(vtree, "grob")
  }

  grobs
}

remove_grobs <- function(vtree) {
  vtree_names <- igraph::vertex_attr_names(vtree)
  if("grob" %in% vtree_names) {
    vtree <- vtree |> mutate(grob = NULL)
  }

  vtree
}

insert_grobs <- function(vtree, grobs) {
  if(!is.null(grobs)) {
    vtree <- vtree |> mutate(grob = grobs)
  }

  vtree
}


get_alias_attr <- function(x, what=NULL) {
  alias <- attr(x, "alias")

  if(is.null(alias)) {
    return(NULL)
  }

  if(is.null(alias$col)) {
    cli::cli_warn(c("!" = "alias attribute appears corrupted, missing col element"))
    return(NULL)
  }

  if(is.null(alias$val)) {
    cli::cli_warn(c("!" = "alias attribute appears corrupted, missing val element"))
    return(NULL)
  }

  if(!is.null(what)) {
    if(!what %in% c("col", "val")) {
      cli_abort(c("!" = "unknown alias element {.val {what}}"))
    }

    return(alias[[what]])
  }

  return(alias)
}

# add values from mapping to the existing scale
scale_add <- function(scale, mapping) {

  # add mapping to existing scale
  if(!is.null(mapping)) {
    if(!is.list(mapping)) {
      cli_abort(c(x = "mapping should be a list"))
    }

    for(n in names(scale)) {

      if(!is.null(mapping[[n]])) {
        dn <- mapping[[n]]
        dn <- dn[ names(dn) %in% names(scale[[n]]) ]
        scale[[n]][ names(dn) ] <- dn
      }
    }
  }

  scale
}

# levels is a list of character values, e.g. one returned by
# levels(vtree); defaults are the default values for the structure
# na is the value to be used for missing values
# mapping is customized mapping to be used
get_scale <- function(levels,
                      defaults=NULL,
                      default_value = NA,
                      na=NA) {

  # populate with the default value
  scale <- map(levels, \(l) {
                    .r <- rep(as.character(default_value), length(l))
                    set_names(.r, l)
                })

  scale <- scale_add(scale, defaults)

  ret <- list(scale=scale, na=na)
  ret
}


# get values from a 2-level mapping
.get_vals <- function(key1, key2, mapping, na=NA) {
  if(is.null(mapping)) { return(NULL) }

  ret <- Map(\(nc, nv) {
               if(is.na(nv)) { return(na) }
               mapping[[nc]][nv]
             }, key1, key2)
  ret <- unlist(ret)
  ret
}
