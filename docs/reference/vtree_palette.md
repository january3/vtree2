# Color palettes for a variable levels

Generate and add color palettes to vtree objects.

## Usage

``` r
vtree_palette(x, palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"))

# S3 method for class 'vtree'
vtree_palette(x, palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"))

# S3 method for class 'vtree_pattern'
vtree_palette(x, palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"))

var_palette(var_levels, pal)

add_palette(
  x,
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"),
  na = "white",
  var_palette = NULL,
  var_colors = NULL,
  what = "fill"
)

# S3 method for class 'vtree'
add_palette(
  x,
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"),
  na = "white",
  var_palette = NULL,
  var_colors = NULL,
  what = "fill"
)

# S3 method for class 'vtree_pattern'
add_palette(
  x,
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"),
  na = "white",
  var_palette = NULL,
  var_colors = NULL,
  what = "fill"
)
```

## Arguments

- x:

  A vtree or vtree pattern object

- palettes:

  The names of RColorBrewer palettes corresponding to the subsequent
  columns in the vtree

- var_levels:

  a character vector of values to which colors are assigned from a
  palette

- pal:

  name of a palette (e.g. "Greens")

- na:

  color used for nodes associated with NA values

- var_palette:

  a named list of named vectors. The var_palette names correspond to the
  variables; the names of the vectors are the levels of the given
  variable; the values are colors.

- var_colors:

  A named character vector with text colors of the variables as shown on
  a legend. If NULL, the colors are taken over from the palettes defined
  by the `palettes` argument, even if `var_palette` is also defined.

- what:

  By default, add_palette() adds a fill color for the nodes and
  automatically chooses a contrast color for the text. If 'what' is
  'text', it adds a text color for the node and automatically chooses a
  contrast color for the fill.

- vtree:

  A vtree object

## Value

`vtree_palette()` returns a character vector of colors for the levels of
the variable. `add_palette()` returns the vtree object with the columns
`fill` `color`, and with additional attribute `palette`.

## Details

`add_palette()` assigns fill colors to the nodes of a vtree based on the
variable levels. The fill colors are stored in a new column in the nodes
data frame called "fill". If a `color` column is missing, it will be
added with automatic contrast colors as well, but it will not be
overwritten if present.

It also sets the mapping between colors and variable levels, stored in
the attribute "palette", which is used when showing the legend. If you
modify the `fill` and `color` columns manually (without using
`add_palette()`, you will not change the color code shown on the legend.

If the parameter `what` is `text` instead of the default `fill`, then
instead of generating a fill color from the palettes, the function
generates a text color and chooses a contrast fill color automatically
(but only if the `fill` column is not already present).

Additional arguments, `var_palette` and `var_colors`, allow for more
fine-grained control of the colors of the nodes and the legend.
`var_palette` allows to specify colors for specific variable levels,
while `var_colors` allows to specify colors for the variable names in
the legend. If some variable names are missing from `var_colors`, or
some variable levels are missing from `var_palette`, the colors will be
inferred from the `palettes` argument.

In summary, the following arguments determine the hierarchy of the
color-control on the resulting plot:

- `palettes` - determines both the palette for the legend and the colors
  of the nodes. Ignored if the tree already has a palette attribute set.

- `var_palette` - low level adjustment of colors. Does not have to
  include all variable and all variable levels.

- `var_colors` - influences only the colors of the variable *names*
  shown on the legend. If NULL, a default from the `palettes` argument
  or from the `var_palette` argument (if provided) will be inferred
  automatically.

- `na` - color for the missing values for all variables. If `what` is
  "fill", then it is interpreted as the background fill color; if `what`
  is "text", then it is interpreted as the text (foreground) color.

`vtree_palette()` returns a color palette for a variable level in a
vtree. The colors are chosen from the RColorBrewer package.

`var_palette()` generates a series of colors from a palette and assigns
them to the provided character vector.

## See also

See
[`contrast_color()`](https://january3.github.io/vtree2/reference/contrast_color.md)
for generating white/black contrast color automatically.

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
vtree_palette(vt)
#> $Class
#>       1st       2nd       3rd      Crew 
#> "#FEE5D9" "#FCAE91" "#FB6A4A" "#CB181D" 
#> 
#> $Sex
#>      Male    Female 
#> "#DEEBF7" "#3182BD" 
#> 
#> $Survived
#>        No       Yes 
#> "#E5F5E0" "#31A354" 
#> 

# only blues for all variables!
vt |> add_palette(palettes = "Blues") |> plot()

# same as
plot(vt, palettes = "Blues")

# manipulate color for some of the nodes
vt |> add_palette(palettes = "Blues") |>
  # don't prune, just mark the nodes in the mark col
  mark(path == "Class:1st/Sex:Male") |>
  # color the marked nodes in red
  mutate(fill = ifelse(mark, "red", fill)) |>
  plot()


# color the NA nodes with red
vt |> add_palette(palettes = "Blues", na = "red") |>
   plot()


# males blue, females red; rest automatic
vt |>
  add_palette(var_palette =
      list(Sex = c(Male = "blue", Female = "Red"))) |>
      plot()


# same, but now the text color is generated from the palette
vt |>
  add_palette(what = "text",
      var_palette = list(Sex = c(Male = "blue", Female = "Red"))) |>
      plot()

```
