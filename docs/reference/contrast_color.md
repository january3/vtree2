# Get a contrasting color

Get a color contrasting to another color

## Usage

``` r
contrast_color(color)
```

## Arguments

- color:

  A character vector with colors in any format accepted by R (e.g.,
  "red", "#FF0000", etc.)

## Value

A character string representing the contrasting color ("black" or
"white")

## Details

Returns a contrasting color (black or white) for a given color. This is
useful for ensuring that text is readable against a background color.

## Examples

``` r
contrast_color("red")    # returns "white"
#>     red 
#> "white" 
```
