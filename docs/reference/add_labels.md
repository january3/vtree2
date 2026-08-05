# Add labels to a plot

Adds or modifies a column called `label` to the node data frame of a
vtree object. Labels are used by the
[`plot.vtree()`](https://january3.github.io/vtree2/reference/plot.vtree.md)
function to show as node labels.

## Usage

``` r
add_labels(
  vtree,
  template = "simple",
  mask = NULL,
  fmt = NULL,
  fmt_na = NULL,
  val_alias = NULL,
  col_alias = NULL,
  root_label = NA
)
```

## Arguments

- vtree:

  an object of class vtree

- template:

  One of the predefined formats; can be 'simple' or 'long'. If 'custom',
  you must provide the `fmt` and `fmt_NA` parameters.

- mask:

  If not NULL, then a logical vector is expected indicating the nodes
  for which the labels will be modified.

- fmt:

  an R expression to format the valid value nodes. If not NULL, replaces
  the format from the template.

- fmt_na:

  an R expression to format NA nodes. If not NULL, replaces the format
  from the template.

- val_alias:

  A list specifying aliases for the levels of the variables. Each
  element of the list should be a named character vector, where the
  names are the levels of the variable and the values are the labels to
  be displayed for those levels. If NULL (default), the original levels
  of the variables are used as labels. The list needs not to be
  complete; if a variable is not included in the list, its original
  levels are used. The aliases are then used to construct the labels and
  also stored in the column 'val_alias' of the nodes data frame. The
  list may include aliases for NA values under then name `NAs`. If a
  `val_alias` column is present, it will be overwritten.

- col_alias:

  A list specifying aliases for the columns (variables). Each name of
  the list is a column/variable name (one of the values of
  `names(vtree)`) and the value is the alias to be used for that
  variable when constructing labels. If a name is missing from the list,
  the original column name is used. The aliases are then used to
  construct the labels and also stored in the column 'var_alias' of the
  nodes data frame. If a `var_alias` column is present, it will be
  overwritten.

- root_label:

  Label to be used for the root node. If NA, do not modify the root
  label.

## Value

an object of class vtree with added labels

## Details

By default, `add_labels()` produces simple node labels containing the
associated variable value, number of cases and percentage within the
parent node.

Formatting can be done with the `fmt`/`fmt_na` parameter, which is an R
expression. You can use sprintf, glue, paste or whichever expressions
you like to construct a label from the following variables:

- `freq`, the frequency for a node

- `n`, number of samples of a node

- `node_col`, name of the variable associated with a node

- `node_val`, value of the variable associated with a node

- `node_cv`, same as `paste0(node_col, ':', node_val)`

- `col_alias`, the alias for the column/variable associated with a node
  (default same as node_col, but can be modified with the `col_alias`
  parameter or by providing a `var_alias` column in the vtree)

- `val_alias`, the alias for the value of the variable associated with a
  node (default same as node_val, but can be modified with the
  `val_alias` parameter or by providing a `val_alias` column in the
  vtree)

- plus whatever new columns you have added to the vtree with mutate().

(the difference between node_col and node_name is that you can set
node_name to whatever you like, while node_col must remain unchanged)

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
# look at the labels
add_labels(vt) |> pull(label)
#>  [1] "2201\n(100%)"      "1st\n325 (15%)"    "2nd\n285 (13%)"   
#>  [4] "3rd\n706 (32%)"    "Crew\n885 (40%)"   "Male\n180 (55%)"  
#>  [7] "Female\n145 (45%)" "Male\n179 (63%)"   "Female\n106 (37%)"
#> [10] "Male\n510 (72%)"   "Female\n196 (28%)" "Male\n862 (97%)"  
#> [13] "Female\n23 (3%)"   "No\n118 (66%)"     "Yes\n62 (34%)"    
#> [16] "No\n4 (3%)"        "Yes\n141 (97%)"    "No\n154 (86%)"    
#> [19] "Yes\n25 (14%)"     "No\n13 (12%)"      "Yes\n93 (88%)"    
#> [22] "No\n422 (83%)"     "Yes\n88 (17%)"     "No\n106 (54%)"    
#> [25] "Yes\n90 (46%)"     "No\n670 (78%)"     "Yes\n192 (22%)"   
#> [28] "No\n3 (13%)"       "Yes\n20 (87%)"    
add_labels(vt) |> plot()
#> Warning: There was 1 warning in `mutate()`.
#> ℹ In argument: `nleafs = map_bfs_back_int(...)`.
#> Caused by warning:
#> ! The `father` argument of `bfs()` is deprecated as of igraph 2.2.0.
#> ℹ Please use the `parent` argument instead.
#> ℹ The deprecated feature was likely used in the tidygraph package.
#>   Please report the issue at <https://github.com/thomasp85/tidygraph/issues>.


vt |> add_labels(template = "long") |> plot()


# only add labels to some nodes
mask <- find_nodes(vt, freq > .30)
vt |> add_labels(mask = mask) |>
  plot(layout = "proportional")


# customize the format
vt |>
  add_labels(fmt = sprintf("%d out of %d",
        n, round(n/freq)),
    fmt_na = "NA") |> plot()

```
