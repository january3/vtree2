# Summarize a case variable for each node of a vtree

The function `summarize_by_node()` summarizes a case variable for each
node of a vtree. That is, for each node in the vtree, it selects the
cases from the cases data frame that match the path to that node and
summarize the specified variable for those cases.

## Usage

``` r
summarize_by_node(cases, vtree, col, vp = is_vp(vtree))

fmt_label(x, fmt = NULL)
```

## Arguments

- cases:

  A data frame of cases, with one row per observation.

- vtree:

  A vtree object.

- col:

  The column variable to summarize. This should be a single column name,
  quoted or not. It uses tidyselect evaluation, so you can do
  `all_of("Survived")`.

- vp:

  whether frequencies should be calculated using valid percentages

- fmt:

  An expression for customized formatting. See Examples.

## Value

A tibble with one row per node of the vtree, and columns for the summary
statistics of the specified variable for the cases that match the path
to that node.

## Details

For example, in the Titanic data set, you can ask what were the
different proportions of survivors for males in the 1st class. This
corresponds to the summary of variable `Survived` for the node with path
`Class:1st/Sex:Male`.

The `fmt_label()` function creates a character vector with these
measures. The provided format is an expression evaluated in the context
of the data frame returned by `summarize_by_node()` and can use the
different columns created by that function.

For numeric variables, the data frame (tibble) returned by
`summarize_by_node()` will contain the following columns: `n`, `mean`,
`sd`, `min`, `max`, `median`, `q1`, `q3`, `iqr`, `valid`, and `missing`.

For factor variables (and variables which can be safely converted to a
factor, i.e. character and logical vectors), the resulting data frame
will contain the following columns: `n`, `valid`, `missing`, `denom`,
`unique` and `levels`. In addition, for each level "lev" of the factor,
it includes the columns "lev" and "lev_freq", which are the number and
percentage of the samples with this level of the variable.

The frequency calculation uses, by default, the same type of denominator
as the vtree. That is, if the vtree was calculated using valid
percentages, the denominator used to calculate the frequencies is equal
to the number of samples minus number of NAs; otherwise it is equal to
the number of samples and the frequencies are also calculated for the NA
samples.

The `levels` column is a list column, and each cell contains a list of
the counts of each level of the factor variable for that node. The
`levels_str` column is a character column that contains a string
representation of the levels and their counts, which can be used for
labeling the nodes.

You can use these functions to create informative labels for the nodes.

Using the `fmt` parameter, it is possible to create fully summaries. The
expression is evaluated within the context of the summary data frame,
which means that you can use all columns avaialble in that data frame.
For example, you can use an expression like
`sprintf("%s", fmt(median, digits = 2))` or `glue("{median}")`.

## Examples

``` r
cases <- cases_from_freqtable(Titanic)
vt <- vtree(cases, Class, Sex, Survived)

csm_txt <- cases |> summarize_by_node(vt, Age) |>
  fmt_label()
vt |> add_labels(fmt = csm_txt) |> plot()


# some random values
cases$Random <- rnorm(nrow(cases)) + (cases$Sex == "Male")
cases$Random[runif(nrow(cases)) < .1] <- NA
csm_txt <- cases |> summarize_by_node(vt, Random) |>
  fmt_label()
vt |> add_labels(fmt = csm_txt) |>
  retain(path == "Class:1st") |>
  plot(lwidth=.9)


# make some default labels
vt <- vt |> add_labels()
# add median to the labels
csm_txt <- cases |>
  summarize_by_node(vt, Random) |>
  fmt_label(fmt = sprintf("median: %.1f",median))
vt |>
  add_labels(fmt = paste0(label, "\n", csm_txt)) |>
  plot()


# now the same but only for the leafs
# leaf is a column in the nodes data frame, TRUE or FALSE
vt |>
  mutate(label = ifelse(leaf,
     paste0(label, "\n", csm_txt),
     label)) |>
  plot()


csm_txt <- cases |>
  summarize_by_node(vt, Random) |>
  fmt_label(fmt = sprintf("valid: %d/%d (%d%%)",
           valid, n, round(100 * valid/n)))

vt |>
  mutate(label = paste0(label, "\n", csm_txt)) |>
  retain(path == "Class:1st") |>
  plot(lwidth=.8)


# Directly use output from summarize_by_node
df <- cases |> summarize_by_node(vt, Age)
vt |>
  mutate(label = sprintf("%s\nChildren: %.0f%%", node_val,
                         df$Child_freq * 100)) |>
  plot()

```
