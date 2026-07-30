# Convert a vtree_graph to a tbl_graph

Convert a vtree_graph to a tbl_graph

## Usage

``` r
# S3 method for class 'vtree'
as_tbl_graph(x, ...)
```

## Arguments

- x:

  A vtree object

- ...:

  Ignored

## Value

A tbl_graph object

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
as_tbl_graph(vt) |> plot()
```
