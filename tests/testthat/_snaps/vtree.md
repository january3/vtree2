# vtree calculations are correct

    Code
      nodes
    Output
      # A tibble: 15 x 17
         ID    node_id parent parent_id path         level node_col node_name node_val
         <chr>   <int> <chr>      <int> <list>       <dbl> <chr>    <chr>     <chr>   
       1 Clas~       7 Class~         2 <named list>     2 Sex      Sex       Female  
       2 Clas~       8 Class~         2 <named list>     2 Sex      Sex       Male    
       3 Clas~       9 Class~         2 <named list>     2 Sex      Sex       <NA>    
       4 Clas~      10 Class~         3 <named list>     2 Sex      Sex       Female  
       5 Clas~      11 Class~         3 <named list>     2 Sex      Sex       Male    
       6 Clas~      12 Class~         3 <named list>     2 Sex      Sex       <NA>    
       7 Clas~      13 Class~         4 <named list>     2 Sex      Sex       Female  
       8 Clas~      14 Class~         4 <named list>     2 Sex      Sex       Male    
       9 Clas~      15 Class~         4 <named list>     2 Sex      Sex       <NA>    
      10 Clas~      16 Class~         5 <named list>     2 Sex      Sex       Female  
      11 Clas~      17 Class~         5 <named list>     2 Sex      Sex       Male    
      12 Clas~      18 Class~         5 <named list>     2 Sex      Sex       <NA>    
      13 Clas~      19 Class~         6 <named list>     2 Sex      Sex       Female  
      14 Clas~      20 Class~         6 <named list>     2 Sex      Sex       Male    
      15 Clas~      21 Class~         6 <named list>     2 Sex      Sex       <NA>    
      # i 8 more variables: node_cv <chr>, n <int>, tot_n <int>, missing <int>,
      #   freq <dbl>, denom <int>, vp <lgl>, leaf <lgl>

