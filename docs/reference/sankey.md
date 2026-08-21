# Create a Sankey tree from a vtree object

Sankey trees can be used to visualize data without the conditional
frequencies that are used in a standard vtree.

## Usage

``` r
sankey(vtree)

# S3 method for class 'sankey_tree'
plot(x, ...)
```

## Arguments

- vtree, x:

  A vtree object.

- ...:

  Additional arguments passed to
  [`plot_vtree()`](https://january3.github.io/vtree2/reference/plot.vtree.md).

## Value

A sankey_tree object, which is also a vtree object. `plot.sankey_tree()`
can be used to plot the object and returns a
[`grid::gTree`](https://rdrr.io/r/grid/grid.grob.html) object.

## Details

Unlike the using sankey layout for regular vtrees, this function does
not preserve the conditional frequencies of the vtree. The node
visualization shows the marginal frequencies of the variable levels -
that is, the overall frequencies of levels for each variable, equivalent
to the values produced in vtree plots with `legend=TRUE`.

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Age, Survived)
sankey(vt) |> plot()
```
