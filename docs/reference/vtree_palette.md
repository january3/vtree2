# Color palettes for a variable levels

Color palettes for a variable levels

## Usage

``` r
vtree_palette(
  vtree,
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples")
)

add_palette(
  vtree,
  palettes = c("Reds", "Blues", "Greens", "Oranges", "Purples"),
  na_fill = "white"
)
```

## Arguments

- vtree:

  A vtree object

- palettes:

  The names of RColorBrewer palettes corresponding to the subsequent
  columns in the vtree

- na_fill:

  fill color used for nodes associated with NA values

## Value

`vtree_palette()` returns a character vector of colors for the levels of
the variable. `add_palette()` returns the vtree object with the columns
`fill` and `color`, and with additional attributes `palette` and
`palette_vars`.

## Details

`vtree_palette()` returns a color palette for a variable level in a
vtree. The colors are chosen from the RColorBrewer package.

`add_palette()` assigns fill colors to the nodes of a vtree based on the
variable levels. The fill colors are stored in a new column in the nodes
data frame called "fill". If a `color` column is missing, it will be
added with automatic contrast colors as well, but it will not be
overwritten if present.

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
vt |> add_palette(palettes = "Blues", na_fill = "red") |>
   plot()
```
