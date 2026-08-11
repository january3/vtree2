# summary_vt works

    Code
      stxt
    Output
       [1] "Survived\nNo: 1490\nYes: 711" "Survived\nNo: 122\nYes: 203" 
       [3] "Survived\nNo: 167\nYes: 118"  "Survived\nNo: 528\nYes: 178" 
       [5] "Survived\nNo: 673\nYes: 212"  "Survived\nNo: 118\nYes: 62"  
       [7] "Survived\nNo: 4\nYes: 141"    "Survived\nNo: 154\nYes: 25"  
       [9] "Survived\nNo: 13\nYes: 93"    "Survived\nNo: 422\nYes: 88"  
      [11] "Survived\nNo: 106\nYes: 90"   "Survived\nNo: 670\nYes: 192" 
      [13] "Survived\nNo: 3\nYes: 20"     "Survived\nNo: 118\nYes: 0"   
      [15] "Survived\nNo: 0\nYes: 62"     "Survived\nNo: 4\nYes: 0"     
      [17] "Survived\nNo: 0\nYes: 141"    "Survived\nNo: 154\nYes: 0"   
      [19] "Survived\nNo: 0\nYes: 25"     "Survived\nNo: 13\nYes: 0"    
      [21] "Survived\nNo: 0\nYes: 93"     "Survived\nNo: 422\nYes: 0"   
      [23] "Survived\nNo: 0\nYes: 88"     "Survived\nNo: 106\nYes: 0"   
      [25] "Survived\nNo: 0\nYes: 90"     "Survived\nNo: 670\nYes: 0"   
      [27] "Survived\nNo: 0\nYes: 192"    "Survived\nNo: 3\nYes: 0"     
      [29] "Survived\nNo: 0\nYes: 20"    

---

    Code
      s1txt
    Output
       [1] "Survived\nNo: 1341\nYes: 637\nNAs: 223"
       [2] "Survived\nNo: 114\nYes: 180\nNAs: 31"  
       [3] "Survived\nNo: 151\nYes: 107\nNAs: 27"  
       [4] "Survived\nNo: 475\nYes: 158\nNAs: 73"  
       [5] "Survived\nNo: 601\nYes: 192\nNAs: 92"  
       [6] "Survived\nNo: 111\nYes: 53\nNAs: 16"   
       [7] "Survived\nNo: 3\nYes: 127\nNAs: 15"    
       [8] "Survived\nNo: 139\nYes: 24\nNAs: 16"   
       [9] "Survived\nNo: 12\nYes: 83\nNAs: 11"    
      [10] "Survived\nNo: 379\nYes: 77\nNAs: 54"   
      [11] "Survived\nNo: 96\nYes: 81\nNAs: 19"    
      [12] "Survived\nNo: 598\nYes: 174\nNAs: 90"  
      [13] "Survived\nNo: 3\nYes: 18\nNAs: 2"      
      [14] "Survived\nNo: 111\nYes: 0"             
      [15] "Survived\nNo: 0\nYes: 53"              
      [16] "Survived\nNo: 0\nYes: 0\nNAs: 16"      
      [17] "Survived\nNo: 3\nYes: 0"               
      [18] "Survived\nNo: 0\nYes: 127"             
      [19] "Survived\nNo: 0\nYes: 0\nNAs: 15"      
      [20] "Survived\nNo: 139\nYes: 0"             
      [21] "Survived\nNo: 0\nYes: 24"              
      [22] "Survived\nNo: 0\nYes: 0\nNAs: 16"      
      [23] "Survived\nNo: 12\nYes: 0"              
      [24] "Survived\nNo: 0\nYes: 83"              
      [25] "Survived\nNo: 0\nYes: 0\nNAs: 11"      
      [26] "Survived\nNo: 379\nYes: 0"             
      [27] "Survived\nNo: 0\nYes: 77"              
      [28] "Survived\nNo: 0\nYes: 0\nNAs: 54"      
      [29] "Survived\nNo: 96\nYes: 0"              
      [30] "Survived\nNo: 0\nYes: 81"              
      [31] "Survived\nNo: 0\nYes: 0\nNAs: 19"      
      [32] "Survived\nNo: 598\nYes: 0"             
      [33] "Survived\nNo: 0\nYes: 174"             
      [34] "Survived\nNo: 0\nYes: 0\nNAs: 90"      
      [35] "Survived\nNo: 3\nYes: 0"               
      [36] "Survived\nNo: 0\nYes: 18"              
      [37] "Survived\nNo: 0\nYes: 0\nNAs: 2"       

# numeric summaries work

    Code
      s1
    Output
      # A tibble: 29 x 15
         node_id path       col   type      n    mean    sd   min   max  median     q1
           <int> <chr>      <chr> <chr> <int>   <dbl> <dbl> <dbl> <dbl>   <dbl>  <dbl>
       1       1 root       foo   nume~  2201  0.0340 0.993 -3.05  3.39  0.0330 -0.625
       2       2 Class:1st  foo   nume~   325  0.0184 0.994 -2.60  3.24  0.0219 -0.644
       3       3 Class:2nd  foo   nume~   285  0.0249 0.951 -2.32  2.48 -0.0429 -0.593
       4       4 Class:3rd  foo   nume~   706  0.0134 0.970 -2.81  3.29  0.0345 -0.589
       5       5 Class:Crew foo   nume~   885  0.0586 1.02  -3.05  3.39  0.0549 -0.643
       6       6 Class:1st~ foo   nume~   180 -0.0440 0.962 -2.31  3.24 -0.0431 -0.696
       7       7 Class:1st~ foo   nume~   145  0.0955 1.03  -2.60  2.82  0.120  -0.600
       8       8 Class:2nd~ foo   nume~   179  0.101  0.992 -2.01  2.48  0.0425 -0.579
       9       9 Class:2nd~ foo   nume~   106 -0.106  0.866 -2.32  1.99 -0.0704 -0.658
      10      10 Class:3rd~ foo   nume~   510  0.0287 0.988 -2.81  3.29  0.0678 -0.606
      # i 19 more rows
      # i 4 more variables: q3 <dbl>, iqr <dbl>, valid <int>, missing <int>

# summary_at_var works

    Code
      sm1
    Output
                    1st               2nd               3rd              Crew 
       "1st: 294 (15%)"  "2nd: 258 (13%)"  "3rd: 633 (32%)" "Crew: 793 (40%)" 
                   <NA> 
         "Missing: 223" 

---

    Code
      sm2
    Output
                       1st                  2nd                  3rd 
          "1st: 294 (13%)"     "2nd: 258 (12%)"     "3rd: 633 (29%)" 
                      Crew                 <NA> 
         "Crew: 793 (36%)" "Missing: 223 (10%)" 

