# vtree calculations are correct

    Code
      nodes
    Output
      # A tibble: 15 x 16
         path   node_id node_key parent parent_id path_l       level node_col node_val
         <chr>    <int> <chr>    <chr>      <int> <list>       <dbl> <chr>    <chr>   
       1 Class~       7 node_7   Class~         2 <named list>     2 Sex      Female  
       2 Class~       8 node_8   Class~         2 <named list>     2 Sex      Male    
       3 Class~       9 node_9   Class~         2 <named list>     2 Sex      <NA>    
       4 Class~      10 node_10  Class~         3 <named list>     2 Sex      Female  
       5 Class~      11 node_11  Class~         3 <named list>     2 Sex      Male    
       6 Class~      12 node_12  Class~         3 <named list>     2 Sex      <NA>    
       7 Class~      13 node_13  Class~         4 <named list>     2 Sex      Female  
       8 Class~      14 node_14  Class~         4 <named list>     2 Sex      Male    
       9 Class~      15 node_15  Class~         4 <named list>     2 Sex      <NA>    
      10 Class~      16 node_16  Class~         5 <named list>     2 Sex      Female  
      11 Class~      17 node_17  Class~         5 <named list>     2 Sex      Male    
      12 Class~      18 node_18  Class~         5 <named list>     2 Sex      <NA>    
      13 Class~      19 node_19  Class~         6 <named list>     2 Sex      Female  
      14 Class~      20 node_20  Class~         6 <named list>     2 Sex      Male    
      15 Class~      21 node_21  Class~         6 <named list>     2 Sex      <NA>    
      # i 7 more variables: n <int>, tot_n <int>, missing <int>, freq <dbl>,
      #   denom <int>, vp <lgl>, leaf <lgl>

