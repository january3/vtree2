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
  mask = TRUE,
  fmt = NULL,
  fmt_na = NULL,
  fmt_root = NULL,
  prefix = NULL,
  suffix = NULL,
  sep = "\n",
  expr = NULL,
  digits = 0
)
```

## Arguments

- vtree:

  an object of class vtree

- template:

  One of the predefined formats; can be 'simple', 'sameline' or 'long'.
  If `fmt` or `fmt_na` is defined, it will be overridden by the
  respective formatting expression.

- mask:

  a logical vector indicating the nodes for which the labels will be
  modified.

- fmt:

  an R expression to format the valid value nodes. If not NULL, replaces
  the format from the template.

- fmt_na:

  an R expression to format NA nodes in trees with valid percentages. If
  not NULL, replaces the format from the template. This is mostly to
  omit frequency data from NA nodes if the missing data was not used as
  a denominator to calculate percentages. If NULL and fmt is not NULL,
  fmt will be used for NA nodes as well.

- prefix:

  add a prefix (character vector) to the label

- suffix:

  add a suffix (character vector) to the label

- sep:

  separator for prefix/suffix

- root_label:

  Label to be used for the root node. If NA, do not modify the root
  label.

## Value

an object of class vtree with added labels

## Details

By default, `add_labels()` produces simple node labels containing the
associated variable value, number of cases and percentage within the
parent node. This can be customized by one of the following:

- choose a different `template` parameter: `short` (default), `sameline`
  (same as short, but on one line) or `long` (with variable names). The
  templates all reasonably handle NA nodes and root node.

- use a [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html)
  syntax for the parameters `fmt`, `fmt_na` and `fmt_root`, where
  variable names are put in curly braces. The variable names are the
  same as column names of the node data frame of the vtree object, plus
  `pct` and `f` (see below). The three parameters will be used to
  generate regular, NA-nodes or root node labels, respectively.

- use an arbitrary R expression (parameter `expr`) which is evaluated
  with
  [`rlang::eval_tidy()`](https://rlang.r-lib.org/reference/eval_tidy.html)
  in the context of the nodes data frame of the vtree object.

Both the glue format syntax and the arbitrary expression syntax can use
any column name which is already present in the nodes data frame,
including:

- `freq`, the frequency for a node

- `n`, number of samples of a node

- `col_alias`, the alias for the column/variable associated with a node
  (default same as node_col, but can be modified by providing a
  `var_alias` column in the vtree)

- `val_alias`, the alias for the value of the variable associated with a
  node (default same as node_val, but can be modified by providing a
  `val_alias` column in the vtree)

- `node_col`, name of the variable associated with a node

- `node_val`, value of the variable associated with a node

- plus whatever new columns you have added to the vtree with mutate().

In addition, `add_labels()` provides two additional, preformatted
values:

- `pct`, percentage rounded to the specified number of digits (the
  `digits` parameter)

- `f`, equal to pct / 100 (so if the percentage is rounded with 0 digits
  after decimal point, `f` will have two digits after decimal point).

## Parameter precedence

If `expr` is not NULL, it will be used for all labels chosen by the
mask.

If `fmt` is NULL, the selected template will be used. If `fmt_na` is
NULL and `fmt` is not NULL, then `fmt_na` will be `fmt`, otherwise the
selected template will be used. Same for `fmt_root`: first `fmt`, if
defined, otherwise the template.

`fmt_na` is used for NA values only if `is_vp(vtree)` is `TRUE`; this is
because for a vp tree the NA value percentages are meaningless.

## See also

[`add_aliases()`](https://january3.github.io/vtree2/reference/add_aliases.md),
[`plot_vtree()`](https://january3.github.io/vtree2/reference/plot.vtree.md)

## Examples

``` r
# a tree with Class, Sex and Survived vars
vt <- vtree_from_freqtable(Titanic, -Age)
# look at the labels
add_labels(vt) |> pull(label)
#>  [1] "2201"              "1st\n325 (15%)"    "2nd\n285 (13%)"   
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


vt |> add_labels(template = "long") |> plot()


# only add labels to some nodes
mask <- find_nodes(vt, freq > .30)
vt |> add_labels(mask = mask) |>
  plot(layout = "proportional")


# customize the format
vt |>
  retain(path == "Class:1st") |>
  add_labels(fmt = "{n} out of {max(n)}",
    fmt_na = "NA") |> plot(lwidth=.7)


# only change the format for the root
vt |> 
  retain(path == "Class:1st") |>
  add_labels(fmt_root = "Total:\n{n} samples") |>
  plot()


# using expr
vt |>
  add_labels(expr =
               ifelse(leaf,
                      sprintf("%s:%s\n%d (%.0f)%%",
                              col_alias,
                              val_alias,
                              n, pct),
                      val_alias)) |>
  plot()
```
