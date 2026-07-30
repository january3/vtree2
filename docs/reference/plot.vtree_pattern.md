# Plot a pattern object

Plots a vtree pattern object.

## Usage

``` r
# S3 method for class 'vtree_pattern'
plot(
  x,
  ...,
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"),
  pattern_fill = "#fc9272",
  lwidth = 0.4,
  lheight = 0.9,
  show_root = FALSE
)
```

## Arguments

- x:

  A vtree pattern object.

- ...:

  Additional arguments passed to plot.vtree()

- palettes:

  A vector of color palettes to use for the nodes.

- pattern_fill:

  The fill color for the pattern nodes.

- lwidth, lheight:

  The width and height of the nodes in the plot, relative to the maximum
  available space.

- show_root:

  Whether to show the root node in the plot.

## Value

A vtree plot (a grid::gTree object) of the pattern object, invisibly.

## See also

[`plot.vtree()`](plot.vtree.md) for plotting vtree objects.

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
pat <- pattern(vt) |> dplyr::arrange(-Survived_n)
plot(pat)
```
