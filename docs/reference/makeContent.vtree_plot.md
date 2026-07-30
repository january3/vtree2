# Hook for vtree plots

This function is called whenever a vtree_plot is plotted on a device.
It's purpose is to fit the labels text into the allocated node space.

## Usage

``` r
# S3 method for class 'vtree_plot'
makeContent(x)
```

## Arguments

- x:

  A vtree_plot object

## Value

A gTree object with the labels adjusted to fit into the allocated space.
