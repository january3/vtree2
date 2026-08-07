# Get the column names of a vtree object

Returns the column names of the node data frame of a vtree object.

## Usage

``` r
nodecols(x)
```

## Arguments

- x:

  A vtree object.

## Value

A character vector of column names

## Examples

``` r
vt <- vtree(titanicNA, Class, Sex, Survived)
nodecols(vt)
#>  [1] "path"      "node_id"   "node_key"  "parent"    "parent_id" "path_l"   
#>  [7] "level"     "node_col"  "node_val"  "n"         "tot_n"     "missing"  
#> [13] "freq"      "denom"     "vp"        "leaf"     
```
