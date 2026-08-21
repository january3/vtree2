# Get the column names of a vtree object edges

Returns the column names of the edges data frame of a vtree object.

## Usage

``` r
edgecols(x)
```

## Arguments

- x:

  A vtree object.

## Value

A character vector of column names

## Examples

``` r
vt <- vtree(titanicNA, Class, Sex, Survived)
edgecols(vt)
#> [1] "from" "to"  
```
