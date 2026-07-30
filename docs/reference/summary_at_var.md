# Summarize a variable at a given node of a vtree

Summarizes a variable at a given node of a vtree. It returns a character
string with the counts and percentages of each level of the variable at
that node. If the variable has missing values, it also includes the
count and percentage of missing values.

## Usage

``` r
summary_at_var(vtree, varname, as_char = FALSE, as_df = FALSE)
```

## Arguments

- vtree:

  A vtree object

- varname:

  The name of the variable to summarize

- as_char:

  If TRUE (default), return a formatted character string with the counts
  and percentages of each level of the variable at that node. If FALSE,
  return a named integer vector with the counts of each level of the
  variable at that node.

- as_df:

  Returns a data frame (tibble) with node column, value, number of
  counts, frequency, denominator and label.

## Value

if `as_char` is TRUE, a character string with the counts and percentages
of each level of the variable at that node. If `as_char` is FALSE
(default), a named integer vector with the counts of each level of the
variable at that node.

## Details

Note that if a tree was pruned, these summaries will differ from the
summaries shown by `summary(vtree)`

If the tree was constructed using valid percentages (`attr(vtree, "vp")`
is TRUE), the percentages are calculated based on the valid (non-NA)
counts. If the tree was constructed using total percentages, the
percentages are calculated based on the total counts.

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
summary_at_var(vt, "Class")
#>  1st  2nd  3rd Crew <NA> 
#>  325  285  706  885    0 
summary_at_var(vt, "Class", as_char = TRUE)
#>               1st               2nd               3rd              Crew 
#>  "1st: 325 (15%)"  "2nd: 285 (13%)"  "3rd: 706 (32%)" "Crew: 885 (40%)" 
summary_at_var(vt, "Class", as_df = TRUE)
#> # A tibble: 5 × 6
#>   node_col node_val count  freq denom label          
#>   <chr>    <chr>    <int> <dbl> <int> <chr>          
#> 1 Class    1st        325 0.148  2201 1st: 325 (15%) 
#> 2 Class    2nd        285 0.129  2201 2nd: 285 (13%) 
#> 3 Class    3rd        706 0.321  2201 3rd: 706 (32%) 
#> 4 Class    Crew       885 0.402  2201 Crew: 885 (40%)
#> 5 Class    NA           0 0      2201 Missing: 0     

data(titanicNA)
vt2 <- vtree(titanicNA, Class, Sex, Survived)
summary_at_var(vt2, "Class")
#>  1st  2nd  3rd Crew <NA> 
#>  294  258  633  793  223 

# not using valid percentages - NAs count towards the total
vt3 <- vtree(titanicNA, Class, Sex,
                            Survived, .vp=FALSE)
summary_at_var(vt3, "Class")
#>  1st  2nd  3rd Crew <NA> 
#>  294  258  633  793  223 

# summaries differ if you prune the tree!
vt_p <- prune(vt, freq < .15) 
summary_at_var(vt_p, "Class", as_df = TRUE)
#> # A tibble: 5 × 6
#>   node_col node_val count  freq denom label          
#>   <chr>    <chr>    <int> <dbl> <int> <chr>          
#> 1 Class    1st          0 0      1591 1st: 0 (0%)    
#> 2 Class    2nd          0 0      1591 2nd: 0 (0%)    
#> 3 Class    3rd        706 0.444  1591 3rd: 706 (44%) 
#> 4 Class    Crew       885 0.556  1591 Crew: 885 (56%)
#> 5 Class    NA           0 0      1591 Missing: 0     
# compare with:
summary(vt_p)
#> # A tibble: 11 × 6
#>    node_col node_val count  freq denom label            
#>    <chr>    <chr>    <int> <dbl> <int> <chr>            
#>  1 Class    1st        325 0.148  2201 1st: 325 (15%)   
#>  2 Class    2nd        285 0.129  2201 2nd: 285 (13%)   
#>  3 Class    3rd        706 0.321  2201 3rd: 706 (32%)   
#>  4 Class    Crew       885 0.402  2201 Crew: 885 (40%)  
#>  5 Class    NA           0 0      2201 Missing: 0       
#>  6 Sex      Male      1731 0.786  2201 Male: 1731 (79%) 
#>  7 Sex      Female     470 0.214  2201 Female: 470 (21%)
#>  8 Sex      NA           0 0      2201 Missing: 0       
#>  9 Survived No        1490 0.677  2201 No: 1490 (68%)   
#> 10 Survived Yes        711 0.323  2201 Yes: 711 (32%)   
#> 11 Survived NA           0 0      2201 Missing: 0       
```
