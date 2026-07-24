# vtree calculations are correct

    Code
      nodes
    Output
      # A tibble: 15 x 15
         ID        node_col node_name node_val node_cv parent path         level     n
         <chr>     <chr>    <chr>     <chr>    <chr>   <chr>  <list>       <dbl> <int>
       1 Class:1s~ Sex      Sex       Female   Sex:Fe~ Class~ <named list>     2   120
       2 Class:1s~ Sex      Sex       Male     Sex:Ma~ Class~ <named list>     2   142
       3 Class:1s~ Sex      Sex       <NA>     Sex:NA  Class~ <named list>     2    32
       4 Class:2n~ Sex      Sex       Female   Sex:Fe~ Class~ <named list>     2    84
       5 Class:2n~ Sex      Sex       Male     Sex:Ma~ Class~ <named list>     2   146
       6 Class:2n~ Sex      Sex       <NA>     Sex:NA  Class~ <named list>     2    28
       7 Class:3r~ Sex      Sex       Female   Sex:Fe~ Class~ <named list>     2   162
       8 Class:3r~ Sex      Sex       Male     Sex:Ma~ Class~ <named list>     2   408
       9 Class:3r~ Sex      Sex       <NA>     Sex:NA  Class~ <named list>     2    63
      10 Class:Cr~ Sex      Sex       Female   Sex:Fe~ Class~ <named list>     2    20
      11 Class:Cr~ Sex      Sex       Male     Sex:Ma~ Class~ <named list>     2   698
      12 Class:Cr~ Sex      Sex       <NA>     Sex:NA  Class~ <named list>     2    75
      13 Class:NA~ Sex      Sex       Female   Sex:Fe~ Class~ <named list>     2    39
      14 Class:NA~ Sex      Sex       Male     Sex:Ma~ Class~ <named list>     2   159
      15 Class:NA~ Sex      Sex       <NA>     Sex:NA  Class~ <named list>     2    25
      # i 6 more variables: tot_n <int>, missing <int>, freq <dbl>, denom <int>,
      #   vp <lgl>, leaf <lgl>

