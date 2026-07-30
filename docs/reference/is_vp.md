# Is the vtree based on valid percentages?

If the tree is based on valid percentages (excluding NAs), the function
returns TRUE.

## Usage

``` r
is_vp(x)
```

## Arguments

- x:

  vtree or vtree_pattern object

## Value

TRUE if the object is based on valid percentages, FALSE otherwise.

## Details

The vtree calculations can use as denominator either all data or "valid"
data, i.e. data excluding the missing observations ("NAs"). For example,
if the variable "gender" contains 30 males, 30 females and 40 NAs, with
vp (which is the default setting), the percentage of either sex is 50%;
with vp=FALSE, it is 30%.

## Examples

``` r
data(titanicNA)
vt <- vtree(titanicNA)
is_vp(vt) # TRUE
#> [1] TRUE
vt <- vtree(titanicNA, Class, Survived, .vp = FALSE)
is_vp(vt) # FALSE
#> [1] FALSE
```
