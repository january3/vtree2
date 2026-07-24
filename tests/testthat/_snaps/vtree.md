# vtree calculations are correct

    Code
      nodes
    Output
      # A tibble: 15 x 18
         ID    node_id node_key parent parent_id path         level node_col node_name
         <chr>   <int> <chr>    <chr>      <int> <list>       <dbl> <chr>    <chr>    
       1 Clas~       7 node_7   Class~         2 <named list>     2 Sex      Sex      
       2 Clas~       8 node_8   Class~         2 <named list>     2 Sex      Sex      
       3 Clas~       9 node_9   Class~         2 <named list>     2 Sex      Sex      
       4 Clas~      10 node_10  Class~         3 <named list>     2 Sex      Sex      
       5 Clas~      11 node_11  Class~         3 <named list>     2 Sex      Sex      
       6 Clas~      12 node_12  Class~         3 <named list>     2 Sex      Sex      
       7 Clas~      13 node_13  Class~         4 <named list>     2 Sex      Sex      
       8 Clas~      14 node_14  Class~         4 <named list>     2 Sex      Sex      
       9 Clas~      15 node_15  Class~         4 <named list>     2 Sex      Sex      
      10 Clas~      16 node_16  Class~         5 <named list>     2 Sex      Sex      
      11 Clas~      17 node_17  Class~         5 <named list>     2 Sex      Sex      
      12 Clas~      18 node_18  Class~         5 <named list>     2 Sex      Sex      
      13 Clas~      19 node_19  Class~         6 <named list>     2 Sex      Sex      
      14 Clas~      20 node_20  Class~         6 <named list>     2 Sex      Sex      
      15 Clas~      21 node_21  Class~         6 <named list>     2 Sex      Sex      
      # i 9 more variables: node_val <chr>, node_cv <chr>, n <int>, tot_n <int>,
      #   missing <int>, freq <dbl>, denom <int>, vp <lgl>, leaf <lgl>

