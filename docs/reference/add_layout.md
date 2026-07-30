# Prepare a layout for plotting a vtree

A layout function for vtree adds several columns to both the nodes and
edges data frame which specify the positions and sizes of the nodes and
edges in the plot.

## Usage

``` r
add_layout(
  vtree,
  layout = c("regular", "proportional", "flushed", "precomputed"),
  layout_func = NULL,
  dir = "lr",
  lwidth = NA,
  lheight = NA,
  show_root = TRUE
)
```

## Arguments

- vtree:

  A vtree object

- layout:

  The layout type, either "regular" or "proportional"

- layout_func:

  A custom layout function.

- dir:

  The direction of the layout, either "lr" (left to right), "rl" (right
  to left), "tb" (top to bottom), or "bt" (bottom to top)

- lwidth, lheight:

  The width and height of the nodes, as the fraction of the available
  space. If NA, a sensible preset is chosen.

- show_root:

  Whether to show the root node in the layout.

## Value

an object of class vtree with additional columns in the nodes and edges
data frames

## Details

The builtin layouts are as follows:

- "regular" - a regular layout in which all nodes have the same width
  and height, and the nodes are evenly spaced along the y-axis.

- "proportional" - a layout in which the height of each node is
  proportional to the number of observations in that node, and the nodes
  are spaced along the y-axis according to their cumulative frequencies.

## Custom layouts

You can also provide a custom layout function. The function should take
a the following arguments: vtree, dir, lwidth, lheight, show_root. It
must return a vtree object with following additional columns in the
nodes data frame:

- x, y: the coordinates of the center of the node

- width, height: the width and height of the node

- full_w, full_h: the width and height of the total space allocated to
  the node including the margins

In addition, it can have the "shape" column which specifies the shape of
the node to use. It can be "rectangle" or "roundrectangle". If not
specified, the default is "roundrectangle".

In the edge data frame, the following additional columns should be
added:

- x1, y1: the coordinates of the start of the edge

- x2, y2: the coordinates of the end of the edge

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
add_layout(vt, layout = "regular", dir = "lr") |> tibble::as_tibble()
#> # A tibble: 29 × 28
#>    path  node_id node_key parent parent_id path_l       level node_col node_name
#>    <chr>   <int> <chr>    <chr>      <int> <list>       <dbl> <chr>    <chr>    
#>  1 root        1 node_1   NA            NA <lgl [1]>        0 root     ""       
#>  2 Clas…       2 node_2   root           1 <named list>     1 Class    "Class"  
#>  3 Clas…       3 node_3   root           1 <named list>     1 Class    "Class"  
#>  4 Clas…       4 node_4   root           1 <named list>     1 Class    "Class"  
#>  5 Clas…       5 node_5   root           1 <named list>     1 Class    "Class"  
#>  6 Clas…       6 node_6   Class…         2 <named list>     2 Sex      "Sex"    
#>  7 Clas…       7 node_7   Class…         2 <named list>     2 Sex      "Sex"    
#>  8 Clas…       8 node_8   Class…         3 <named list>     2 Sex      "Sex"    
#>  9 Clas…       9 node_9   Class…         3 <named list>     2 Sex      "Sex"    
#> 10 Clas…      10 node_10  Class…         4 <named list>     2 Sex      "Sex"    
#> # ℹ 19 more rows
#> # ℹ 19 more variables: node_val <chr>, node_cv <chr>, n <int>, tot_n <int>,
#> #   missing <int>, freq <dbl>, denom <int>, vp <lgl>, leaf <lgl>, nleafs <int>,
#> #   offset <int>, offset_tot <int>, width <dbl>, height <dbl>, full_w <dbl>,
#> #   full_h <dbl>, x <dbl>, y <dbl>, shape <chr>
# the layout parameter from plot() is passed on to add_layout()
plot(vt, layout="proportional")

plot(vt, layout="flushed", dir="tb")
```
