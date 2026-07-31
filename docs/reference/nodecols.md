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
vt <- vtree(Titanic, Class, Sex, Survived)
#> Error in vtree(Titanic, Class, Sex, Survived): Columns specified for the vtree are not in the cases data frame
#> ✖ Columns not found: Class, Sex, and Survived
nodecols(vt)
#> Error: object 'vt' not found
```
