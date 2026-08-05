# Add aliases columns to vtree

Aliases are alternative labels / variable names which are shown on the
plots. This function allows to define aliases for both, variable names
and the variable values (levels).

## Usage

``` r
add_aliases(vtree, val_alias = NULL, col_alias = NULL)
```

## Arguments

- vtree:

  an object of class vtree

- val_alias:

  A list specifying aliases for the levels of the variables. Each
  element of the list should be a named character vector, where the
  names are the levels of the variable and the values are the labels to
  be displayed for those levels. If NULL (default), the original levels
  of the variables are used as labels. The list needs not to be
  complete; if a variable is not included in the list, its original
  levels are used. The aliases are then used to construct the labels and
  also stored in the column 'val_alias' of the nodes data frame. The
  list may include aliases for NA values under then name `NAs`. If a
  `val_alias` column is present, it will be overwritten.

- col_alias:

  A list specifying aliases for the columns (variables). Each name of
  the list is a column/variable name (one of the values of
  `names(vtree)`) and the value is the alias to be used for that
  variable when constructing labels. If a name is missing from the list,
  the original column name is used. The aliases are then used to
  construct the labels and also stored in the column 'var_alias' of the
  nodes data frame. If a `var_alias` column is present, it will be
  overwritten.
