# Apply a function to a data frame by nodes in the vtree

Apply a function to a data frame by nodes in the vtree. The data frame
must contain the same variables as the vtree. It is split by the levels
of the variables such that for each node in the vtree, the function is
applied to the subset of data that matches the path to that node.

## Usage

``` r
vtree_apply(cases, vtree, FUN, ..., .mask = NULL, .args = "cases")
```

## Arguments

- cases:

  A data frame of cases, with one row per observation.

- vtree:

  A vtree object.

- FUN:

  A function to apply to the subset of cases that match the path to each
  node in the vtree.

- ...:

  Additional arguments to pass to FUN.

- .mask:

  An optional logical vector of the same length as the number of nodes
  in the vtree. If provided, only the nodes for which .mask is TRUE will
  be processed.

- .args:

  character vector specifying which arguments should FUN be called with:
  `cases` for the relevant fragment of the cases data frame;
  'nodes`for a single-row nodes data frame with the given node;`sel\`
  for the logical selection vector.

## Value

A list of the results of applying FUN to each subset of cases named with
the node_key of the corresponding node in the vtree.

## Details

`vtree_apply` applies the function FUN sequentially to groups of samples
from the `cases` data frame corresponding to a given node. By default,
the argument passed to the function is the subset of the cases data
frame, however two other arguments may be included: the row from the
vtree node data frame corresponding to the given node (including the
node id, path etc.), and a logical vector of the same length as the
number of rows in the cases data frame and a TRUE value if the given row
is included in the current node.

Order and number of arguments are given by the `.args` parameter.

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex)

# only leaf nodes
mask <- find_nodes(vt, leaf)

# prepare labels with summary of Survived for each node
sumfnc <- \(df, ...) summary(df$Survived)
sm <- vtree_apply(titanicNA, vt, sumfnc, .mask = mask) |>
      purrr::map_chr(\(x) paste0(names(x), ": ", x, collapse = "\n"))

# plot with custom layout making more space for the labels in the last
# node ("Sex")
vt |> add_labels() |>
  add_labels(mask = mask,
             fmt = paste0(label, "\n", sm[node_key])) |>
  add_layout(varspace = c(root=1, Class=1, Sex=3),
             dir="tb", lheight=.8) |>
  plot(dir="tb", legend=FALSE)
```
