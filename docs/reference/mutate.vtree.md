# Create, modify, and delete node columns

This is a wrapper around the regular
[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html)
function which preserves the vtree class.

## Usage

``` r
# S3 method for class 'vtree'
mutate(.data, ..., .edges = FALSE, .check = TRUE)
```

## Arguments

- .data:

  A vtree object.

- ...:

  Name-value pairs of expressions, passed to
  [`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html).
  The name gives the name of the new or modified node attribute, and the
  value defines its contents. The expressions are evaluated using tidy
  evaluation in the context of the node table.

- .edges:

  If TRUE, modify the edges rather than the nodes.

- .check:

  If TRUE, make sure that the immutable columns did not change

## Value

An object of class vtree

## Details

Immutable columns: some columns of the vtree are immutable. Changing
them can result in very bad things happening, starting with plots that
don't work and ending up with incorrect numbers on your figure. Of
course, there are many ways to modify them if you really want to, but at
least this mutate gives some protection.

## See also

[`dplyr::mutate()`](https://dplyr.tidyverse.org/reference/mutate.html),
[`tidygraph::activate()`](https://tidygraph.data-imaginist.com/reference/activate.html)
