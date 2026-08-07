# Create a vtree object from a data frame

Create a vtree object from a data frame of cases. That is, a data frame
containing one row per sample and one column per variable. For
converting frequency tables, where one of the columns gives the number
of samples that correspond to a combination of variable levels, see
`vtree_from_freqtable()`.

## Usage

``` r
vtree(cases, ..., .vp = TRUE, .cols = NULL)

vtree_from_freqtable(x, ..., .freq_col = "Freq", .vp = TRUE, .cols = NULL)
```

## Arguments

- cases:

  A data frame, one row per observation, one column per variable

- ...:

  Columns to use for the tree. If no columns are specified, all columns
  (except the frequency column for the frequency tables) will be used

- .vp:

  valid percentage; when calculating frequencies / percentages, omit NA
  values from the denominator

- .cols:

  Provide column names as a character vector instead of using the ...
  argument. This is useful when the column names are stored in a
  variable.

- x:

  A frequency table (matrix, table or data frame)

- .freq_col:

  The name of the column in a frequency table that contains the
  frequency counts. Default is "Freq".

## Value

an object of class vtree

## Details

The cases data frame used as a first argument should have one row per
observation. The selected columns will correspond to the nodes of the
vtree.

With `vtree_from_freqtable()`, you can create a vtree from a frequency
table, where each row corresponds to a unique combination of values and
a frequency count.

There are several basic methods implemented for vtrees:
[`summary.vtree()`](https://january3.github.io/vtree2/reference/summary.vtree.md),
[`plot.vtree()`](https://january3.github.io/vtree2/reference/plot.vtree.md),
[`levels.vtree()`](https://january3.github.io/vtree2/reference/levels.vtree.md),
[`print.vtree()`](https://january3.github.io/vtree2/reference/print.vtree.md),
[`names.vtree()`](https://january3.github.io/vtree2/reference/names.vtree.md).

## Manipulating a vtree object

Vtree objects are little more than tidygraph object of class tbl_graph.
You can use the tidygraph package to manipulate them, and the ggraph
package to plot them. The vtree class is mostly a convenience for
plotting. You can manipulate the vtree object using regular tidygraph
functions, and then use as_vtree to convert it back to a vtree object
for plotting.

The main difference between the `tbl_graph` and `vtree` is that you can
directly get the nodes table with
[`as_tibble()`](https://tibble.tidyverse.org/reference/as_tibble.html)
and you can use
[`mutate()`](https://dplyr.tidyverse.org/reference/mutate.html) to
modify or create the columns of a `vtree` object.

## Columns in the nodes data frame

The vtree object, like the `tbl_graph` objects, consists of two data
frames: nodes and edges. The nodes data frame in vtree contains all
information pertaining the different nodes of the vtree. Below is the
list of the columns; in parentheses, you will find example values for a
node from the `Titanic` example.

- `path`: human readable path of the node (`Class:1st/Sex:Female`). Note
  that if you are using slashes or colons in column names or values,
  this can be unreliable.

- `node_id`: unique numeric ID of the node.

- `node_key`: unique character string ID of the node.

- `node_col`: the column of the original cases data frame to which the
  node corresponds to (`Sex`)

- `node_name`: node name used for labelling (`Sex`).

- `node_val`: the value of the node variable at this node (`Female`).

- `node_cv`: combination of node column and node value (`Sex:Female`).

- `parent`: path of the parent node (`Class:1st`).

- `path_l`: is a list node; i.e., each element is a list. The path
  describes all nodes from the root to the current node, excluding the
  root and including the current node.
  (`list(Class = "1st", Sex = "Female")`.

- `level`: the level of the node, with 0 for the root node. Equal to the
  length of the path (`2`).

- `n`: total number of cases at the node (`145`).

- `tot_n`: total number of cases at the parent node (`325`).

- `missing`: number of cases missing for that variable in the parent
  node (`0`).

- `freq`: calculated frequency relative to the number of valid or total
  cases in the parent node (`0.446`).

- `denom`: the denominator used to calculate the frequency (`325`). If
  `.vp` is true, this is equal to the number of valid observations in
  the parent node; if `.vp` is false, this is equal to `n` of the parent
  node.

- `vp`: whether the valid percentage was calculated (`TRUE`).

- `leaf`: whether the node is a leaf (`FALSE`).

Note that the variables `tot_n`, `denom` and `missing` all refer to the
*parent* node, not to the current node. For example, if the current node
is `Class:1st/Sex:Female`, then `tot_n` will be the total number of
persons in the 1st class, and `n` will be the total number of females in
the 1st class. Likewise, `missing` will be the total number of persons
in the 1st class for which we do not know whether they were male or
female. The `denom` variable will depend on `.vp`. If we need the valid
percentages (default), then `denom` will be equal to `tot_n - missing`;
otherwise it will be `tot_n`.

The `tot_n` information is redundant, since it can be read directly from
`n` of the parent node (`Class:1st` in case of `Class:1st/Sex:Female`).
However, it makes the calculations transparent.

## Examples

``` r
data(Titanic)
vt <- vtree_from_freqtable(Titanic, Class, Survived)
plot(vt)

plot(vt, layout = "proportional")


data(titanicNA)
vt <- vtree(titanicNA, Class, Sex, Survived)
plot(vt)
```
