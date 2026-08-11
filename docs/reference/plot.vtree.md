# Plot a vtree

Plots a vtree object using a variety of layouts.

## Usage

``` r
# S3 method for class 'vtree'
plot(x, ...)

plot_vtree(
  x,
  layout = c("regular", "proportional", "flushed_left", "flushed_right"),
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"),
  na_fill = "white",
  show_root = TRUE,
  legend = "tiny",
  margins = NULL,
  fontsizes = NULL,
  richtext = FALSE,
  lwidth = NA,
  lheight = NA,
  lwd = 1,
  dir = NA
)
```

## Arguments

- x:

  A vtree object

- ...:

  Arguments passed to `plot_vtree()`

- layout:

  The layout type, either "regular", "flushed" or "proportional". If
  "proportional", then the height of each node is proportional to the
  number of observations in that node. See
  [`add_layout()`](https://january3.github.io/vtree2/reference/add_layout.md)
  for details. If layout is NA, then it is assumed that the vtree
  already has a layout with all necessary columns and no layout is
  calculated.

- palettes:

  A character vector with names of RColorBrewer palettes to use for the
  variables. By default these are the default arguments to the
  vtree_palette() function.

- na_fill:

  The color to use for NA values. Default is "white".

- show_root:

  If TRUE (default), show the root node (total population).

- legend:

  If "tiny" (default), only minimal legend with variable names is shown.
  If FALSE or "none", no legend is shown. If TRUE or "full", a full
  legend with variable level summaries is shown.

- margins:

  numerical vector: top/right/bottom/left margins in fraction of
  available space (from 0 to 1).

- fontsizes:

  Manually select font sizes. A named list with following optional
  fields: `nodes`, `var_labels`, `legend_labels`. Each element can be
  either a number (font size), or either "fixed" or "adaptive"; "fixed"
  means that all objects within the group will have the same
  automatically adjusted font, and "adaptive" that each label will be
  fit separately.

- richtext:

  If TRUE, use
  [`gridtext::richtext_grob()`](https://wilkelab.org/gridtext/reference/richtext_grob.html)
  for node labels, which is much slower, but allows fine control over
  text formatting. Default is FALSE.

- lwidth:

  Label width relative to available space

- lheight:

  Label height relative to available space

- lwd:

  line width for use with plotting

- dir:

  direction of the tree. One of "lr" (left to right), "rl" (right to
  left), "tb" (top to bottom), "bt" (bottom to top). Default is "lr".

## Value

A grid::gTree object of class vtree_plot.

## Details

`plot.vtree()` plots a vtree object using a variety of layouts. The
default layout, "regular", simply shows the tree structure with all
nodes having the same size. The "proportional" layout shows the nodes
with sizes proportional to the number of observations in that node.

Colors, fill colors, node labels and other details can be customized by
modifying the vtree object directly with the
[`mutate.vtree()`](https://january3.github.io/vtree2/reference/mutate.vtree.md)
function. Otherwise, default colors and labels are filled in
automatically.

## Colors

By default, fill colors are assigned automatically based on the variable
level in the tree. Each node gets its own palette, and from that palette
fill colors are assigned to the levels of the variable by their order of
appearance or factor level in the data. The variables with the lowest
factor levels or appearing first will get the darkest fill colors. NA
values are colored white.

If the vtree object contains, in the node data frame, a column called
"fill", then the fill colors will be taken from that column instead of
being assigned automatically.

If the vtree object contains a column called "color", then the text
colors will be taken from that column. Otherwise, the either white or
black will be chosen depending on the fill color for each node. You can
easily create this column with the
[`mutate.vtree()`](https://january3.github.io/vtree2/reference/mutate.vtree.md)
function (see examples below).

## Labels

Similarly, some default labels are created automatically. However, if a
`label` column is present in the nodes data frame, it will be used
instead for node labels. Here, there are several columns that can be
used to create a label:

- `freq`, the frequency for a node

- `n`, number of samples of a node

- `node_col`, name of the variable associated with a node

- `node_val`, value of the variable associated with a node

See [`vtree()`](https://january3.github.io/vtree2/reference/vtree.md)
for a list of all columns in the node data frame.

Manipulating these columns is straightforward using the
[`mutate.vtree()`](https://january3.github.io/vtree2/reference/mutate.vtree.md)
function (see below).

For variables which are not associated with the nodes and additional
summary variables (ranges, medians, standard deviations and more), see
`summary_vt()`.

## See also

[`mutate.vtree()`](https://january3.github.io/vtree2/reference/mutate.vtree.md)
for modifying the node data frame, and
[`add_labels()`](https://january3.github.io/vtree2/reference/add_labels.md)
for adding labels to the nodes. For layout details, see
[`add_layout()`](https://january3.github.io/vtree2/reference/add_layout.md).

## Examples

``` r
vt <- vtree_from_freqtable(Titanic)

# regular plot
plot(vt)


# full legend
plot(vt, legend = "full")


# proportional plot
plot(vt, layout = "proportional")


# create custom labels as simple numbers with mutate()
library(dplyr)
vt |> mutate(label = as.character(1:n())) |> plot()


# a bit more complex example
vt |>
  mutate(label = paste0(node_col, " = ",
                        node_val, '\n',
         ifelse(is.na(node_val), '-',
             sprintf("%.0f%%", 100 * freq)))) |>
  plot()


# some color manipulation
pal <- colorRampPalette(c("white", "steelblue"))(101)

vt |>
  mutate(fill = pal[round(freq * 100) + 1]) |>
  plot()
#> ℹ palette attribute is NULL
#> legend will be black and white


vt |>
  mutate(abs_freq = n / max(n)) |>
  mutate(fill = pal[round(abs_freq * 100) + 1]) |>
 plot()
#> ℹ palette attribute is NULL
#> legend will be black and white

```
