# Show per-variable summaries of a vtree object

Show per-variable summaries of a vtree object

## Usage

``` r
# S3 method for class 'vtree'
summary(object, ...)
```

## Arguments

- object:

  A vtree object.

- ...:

  Ignored

## Value

A data frame with summaries (counts and frequencies) for each level of
each variable in the vtree.

## Details

For each variable included in a vtree object, and for all levels of that
variable, the counts and calculated frequencies of that level in the
variable are shown, as well as labels that can be used for displaying
information. The frequency calculation depends on whether the tree was
constructed with valid percentages (i.e., excluding the NAs), or with
all samples.

These sumaries are calculate the original data summaries; they do not
change when the vtree object is modified.

The returned data frame (tibble) contains the following columns:

- `node_col`: the name of the variable

- `node_val`: the level of the variable

- `count`: number of samples which have this level

- `freq`: frequency of this level relative to the denominator

- `denom`: the denominator used to calculate the frequency

- `label`: a printable label constructed from these values
