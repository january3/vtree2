# Get the variable names of a vtree object

Get the variable names of a vtree object

## Usage

``` r
# S3 method for class 'vtree'
names(x)
```

## Arguments

- x:

  A vtree object.

## Value

A character vector of variable names

## Examples

``` r
vt <- vtree(titanicNA)
names(vt)
#> [1] "Class"    "Sex"      "Age"      "Survived"
```
