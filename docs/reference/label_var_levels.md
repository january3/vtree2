# Get a value list as character vector

For each node of the tree, identify the cases that correspond to that
node and create a formatted string label listing all values of variable
`var` which correspond to that node.

## Usage

``` r
label_var_levels(
  cases,
  vtree,
  var,
  width = 60,
  shorten = TRUE,
  sort = TRUE,
  sep = ", "
)
```

## Arguments

- cases:

  a data frame with cases (one sample per row)

- var:

  a variable name from cases and vt

- width:

  formatting width in characters

- shorten:

  if a variable level occurs more than once, should it be mentioned only
  once with the number of occurences appended (default TRUE)

- sort:

  whether the variable levels should be sorted (default TRUE)

- sep:

  separator to put between the values

- vt:

  a vtree object

## Value

a character vector of length equal to the number rows in the nodes data
frame of the vtree object

## Details

Simple wrapper around
[`vtree_apply()`](https://january3.github.io/vtree2/reference/vtree_apply.md)
to create formatted labels which contain a list of values for each node.

## Examples

``` r
library(tibble)
library(dplyr)
#> 
#> Attaching package: ‘dplyr’
#> The following objects are masked from ‘package:stats’:
#> 
#>     filter, lag
#> The following objects are masked from ‘package:base’:
#> 
#>     intersect, setdiff, setequal, union
mt <- mtcars |>
  mutate(across(c(cyl, gear, carb), as.factor)) |>
  rownames_to_column("name")
vt <- vtree(mt, cyl, gear, carb)
# car names into a label
ids <- label_var_levels(mt, vt, "name", width=60)
vt |>
  add_labels(template="sameline", root_label = "All cars") |>
  add_labels(template="sameline", mask = find_nodes(vt, leaf),
             suffix = ids) |>
  add_layout(varspace=c(root=1, cyl=1, gear=1, carb=3), lwidth=.8) |>
  plot(fontsizes = list(nodes="adaptive"))
```
