# Get the levels of a vtree object

Returns a list of character vectors, one for each variable split in the
tree, with each ordered vector containing the levels of that variable.

## Usage

``` r
# S3 method for class 'vtree'
levels(x)
```

## Arguments

- x:

  A vtree object.

## Value

A list of character vectors, one for each variable split in the tree,

## Examples

``` r
vt <- vtree(titanicNA)
levels(vt)
#> $Class
#> [1] "1st"  "2nd"  "3rd"  "Crew"
#> 
#> $Sex
#> [1] "Male"   "Female"
#> 
#> $Age
#> [1] "Child" "Adult"
#> 
#> $Survived
#> [1] "No"  "Yes"
#> 
```
