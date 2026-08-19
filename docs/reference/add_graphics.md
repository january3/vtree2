# Add graphics to a vtree

Add graphics (images, plots) to vtree nodes. The graphical object should
be a grob (grid graphics object such as a gTree), which can be easily
created from images and ggplot plots.

## Usage

``` r
add_graphics(
  vtree,
  grobs,
  side = "b",
  frac = 0.8,
  shape = "rectangle",
  condition = NULL,
  mask = TRUE
)
```

## Arguments

- vtree:

  an object of class vtree

- grobs:

  a list either of length 1 or of the same length as the number of nodes
  in the vtree.

- side:

  on which side of the node the grob should be inserted. Can be one of
  `l`, `r`, `t`, `b` (left, right, top, bottom).

- frac:

  fraction of space occupied by the graphics (horizontally if side is
  `l` or `r`, vertically if side is `t` or `b`).

- shape:

  shape of the node ("rectangle" or "roundrectangle").

- condition:

  Condition to evaluate in the context of the nodes data frame. Only
  nodes for which the result is TRUE will be assigned a grob.

- mask:

  a logical vector of the same length as the number of nodes. A graphics
  will be assigned to a node only if the corresponding mask value is
  TRUE.

## Value

a vtree object with graphics.

## Details

Any graphical object which can be converted to a "grob" (grid package
graphical object) can be included in a node label. The conversion is
relatively straightforward with both, images (jpeg, png etc.) and
ggplot2 plots.

For bitmaps (raster images) such as jpeg or png, use the
[`grid::rasterGrob()`](https://rdrr.io/r/grid/grid.raster.html)
function. For ggplot2 objects, use the
[`ggplot2::ggplotGrob()`](https://ggplot2.tidyverse.org/reference/ggplotGrob.html)
function. See the vtree vignette for examples.
