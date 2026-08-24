# Convert a frequency table to a data frame of cases

Convert a frequency table to a data frame of cases

## Usage

``` r
cases_from_freqtable(x, ..., .freq_col = "Freq")
```

## Arguments

- x:

  A frequency table, as a data frame or a table object.

- ...:

  Columns to use for the tree. If no columns are specified, all columns
  (except the frequency column for the frequency tables) will be used.
  Use tidy select syntax to access columns. Named expressions to modify
  or rename columns are also allowed (see examples).

- .freq_col:

  The name of the column containing the frequency counts.

## Value

A tibble of cases, one row per observation, one column per variable

## Details

A frequency table is a data frame in which each row corresponds to a
unique combination of values of the variables, and a column (by default
named "Freq") contains the frequency counts for that combination. This
function expands the frequency table into a data frame of cases, where
each row corresponds to one observation.

If the columns of the frequency table are factors, the levels of the
factors are recorded and assigned to the `levels` attribute of the
returned data frame. If the columns are not factors, the unique values
of the columns area stored in the `levels` attribute instead.

This function is close to the `crosstabToCases()` function from the
original vtree package.

## Examples

``` r
cases <- cases_from_freqtable(Titanic)
cases <- cases_from_freqtable(Titanic, Class, Sex, Survived)
# same as:
cases <- cases_from_freqtable(Titanic, -Age)
cols <- c("Class", "Sex", "Survived")
cases <- cases_from_freqtable(Titanic, all_of(cols),
              .freq_col = "Freq")
cases <- cases_from_freqtable(Titanic, Class,
                              Gender=Sex, Survived)
```
