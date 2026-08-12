# summarize_by_node works

    Code
      stxt
    Output
      Survived
      No: 1490
      Yes: 711
      Survived
      No: 122
      Yes: 203
      Survived
      No: 167
      Yes: 118
      Survived
      No: 528
      Yes: 178
      Survived
      No: 673
      Yes: 212
      Survived
      No: 118
      Yes: 62
      Survived
      No: 4
      Yes: 141
      Survived
      No: 154
      Yes: 25
      Survived
      No: 13
      Yes: 93
      Survived
      No: 422
      Yes: 88
      Survived
      No: 106
      Yes: 90
      Survived
      No: 670
      Yes: 192
      Survived
      No: 3
      Yes: 20
      Survived
      No: 118
      Yes: 0
      Survived
      No: 0
      Yes: 62
      Survived
      No: 4
      Yes: 0
      Survived
      No: 0
      Yes: 141
      Survived
      No: 154
      Yes: 0
      Survived
      No: 0
      Yes: 25
      Survived
      No: 13
      Yes: 0
      Survived
      No: 0
      Yes: 93
      Survived
      No: 422
      Yes: 0
      Survived
      No: 0
      Yes: 88
      Survived
      No: 106
      Yes: 0
      Survived
      No: 0
      Yes: 90
      Survived
      No: 670
      Yes: 0
      Survived
      No: 0
      Yes: 192
      Survived
      No: 3
      Yes: 0
      Survived
      No: 0
      Yes: 20

---

    Code
      s1txt
    Output
      Survived
      No: 1341
      Yes: 637
      NAs: 223
      Survived
      No: 114
      Yes: 180
      NAs: 31
      Survived
      No: 151
      Yes: 107
      NAs: 27
      Survived
      No: 475
      Yes: 158
      NAs: 73
      Survived
      No: 601
      Yes: 192
      NAs: 92
      Survived
      No: 111
      Yes: 53
      NAs: 16
      Survived
      No: 3
      Yes: 127
      NAs: 15
      Survived
      No: 139
      Yes: 24
      NAs: 16
      Survived
      No: 12
      Yes: 83
      NAs: 11
      Survived
      No: 379
      Yes: 77
      NAs: 54
      Survived
      No: 96
      Yes: 81
      NAs: 19
      Survived
      No: 598
      Yes: 174
      NAs: 90
      Survived
      No: 3
      Yes: 18
      NAs: 2
      Survived
      No: 111
      Yes: 0
      Survived
      No: 0
      Yes: 53
      Survived
      No: 0
      Yes: 0
      NAs: 16
      Survived
      No: 3
      Yes: 0
      Survived
      No: 0
      Yes: 127
      Survived
      No: 0
      Yes: 0
      NAs: 15
      Survived
      No: 139
      Yes: 0
      Survived
      No: 0
      Yes: 24
      Survived
      No: 0
      Yes: 0
      NAs: 16
      Survived
      No: 12
      Yes: 0
      Survived
      No: 0
      Yes: 83
      Survived
      No: 0
      Yes: 0
      NAs: 11
      Survived
      No: 379
      Yes: 0
      Survived
      No: 0
      Yes: 77
      Survived
      No: 0
      Yes: 0
      NAs: 54
      Survived
      No: 96
      Yes: 0
      Survived
      No: 0
      Yes: 81
      Survived
      No: 0
      Yes: 0
      NAs: 19
      Survived
      No: 598
      Yes: 0
      Survived
      No: 0
      Yes: 174
      Survived
      No: 0
      Yes: 0
      NAs: 90
      Survived
      No: 3
      Yes: 0
      Survived
      No: 0
      Yes: 18
      Survived
      No: 0
      Yes: 0
      NAs: 2

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

