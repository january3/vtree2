# add_labels works

    Code
      as_tibble(vt1)$label
    Output
       [1] "2201"              "1st\n325 (15%)"    "2nd\n285 (13%)"   
       [4] "3rd\n706 (32%)"    "Crew\n885 (40%)"   "Male\n180 (55%)"  
       [7] "Female\n145 (45%)" "Male\n179 (63%)"   "Female\n106 (37%)"
      [10] "Male\n510 (72%)"   "Female\n196 (28%)" "Male\n862 (97%)"  
      [13] "Female\n23 (3%)"   "No\n118 (66%)"     "Yes\n62 (34%)"    
      [16] "No\n4 (3%)"        "Yes\n141 (97%)"    "No\n154 (86%)"    
      [19] "Yes\n25 (14%)"     "No\n13 (12%)"      "Yes\n93 (88%)"    
      [22] "No\n422 (83%)"     "Yes\n88 (17%)"     "No\n106 (54%)"    
      [25] "Yes\n90 (46%)"     "No\n670 (78%)"     "Yes\n192 (22%)"   
      [28] "No\n3 (13%)"       "Yes\n20 (87%)"    

---

    Code
      as_tibble(vt2)$label
    Output
       [1] "All samples\nN = 2201 (100%)" "Class: 1st\nN = 325 (15%)"   
       [3] "Class: 2nd\nN = 285 (13%)"    "Class: 3rd\nN = 706 (32%)"   
       [5] "Class: Crew\nN = 885 (40%)"   "Sex: Male\nN = 180 (55%)"    
       [7] "Sex: Female\nN = 145 (45%)"   "Sex: Male\nN = 179 (63%)"    
       [9] "Sex: Female\nN = 106 (37%)"   "Sex: Male\nN = 510 (72%)"    
      [11] "Sex: Female\nN = 196 (28%)"   "Sex: Male\nN = 862 (97%)"    
      [13] "Sex: Female\nN = 23 (3%)"     "Survived: No\nN = 118 (66%)" 
      [15] "Survived: Yes\nN = 62 (34%)"  "Survived: No\nN = 4 (3%)"    
      [17] "Survived: Yes\nN = 141 (97%)" "Survived: No\nN = 154 (86%)" 
      [19] "Survived: Yes\nN = 25 (14%)"  "Survived: No\nN = 13 (12%)"  
      [21] "Survived: Yes\nN = 93 (88%)"  "Survived: No\nN = 422 (83%)" 
      [23] "Survived: Yes\nN = 88 (17%)"  "Survived: No\nN = 106 (54%)" 
      [25] "Survived: Yes\nN = 90 (46%)"  "Survived: No\nN = 670 (78%)" 
      [27] "Survived: Yes\nN = 192 (22%)" "Survived: No\nN = 3 (13%)"   
      [29] "Survived: Yes\nN = 20 (87%)" 

---

    Code
      as_tibble(vt4)$label
    Output
       [1] "2201"              "1st\n294 (15%)"    "2nd\n258 (13%)"   
       [4] "3rd\n633 (32%)"    "Crew\n793 (40%)"   "NA\n223"          
       [7] "Female\n120 (46%)" "Male\n142 (54%)"   "NA\n32"           
      [10] "Female\n84 (37%)"  "Male\n146 (63%)"   "NA\n28"           
      [13] "Female\n162 (28%)" "Male\n408 (72%)"   "NA\n63"           
      [16] "Female\n20 (3%)"   "Male\n698 (97%)"   "NA\n75"           
      [19] "Female\n39 (20%)"  "Male\n159 (80%)"   "NA\n25"           
      [22] "No\n3 (2%)"        "Yes\n117 (98%)"    "No\n99 (70%)"     
      [25] "Yes\n43 (30%)"     "No\n12 (38%)"      "Yes\n20 (62%)"    
      [28] "No\n12 (14%)"      "Yes\n72 (86%)"     "No\n127 (87%)"    
      [31] "Yes\n19 (13%)"     "No\n12 (43%)"      "Yes\n16 (57%)"    
      [34] "No\n89 (55%)"      "Yes\n73 (45%)"     "No\n340 (83%)"    
      [37] "Yes\n68 (17%)"     "No\n46 (73%)"      "Yes\n17 (27%)"    
      [40] "No\n3 (15%)"       "Yes\n17 (85%)"     "No\n538 (77%)"    
      [43] "Yes\n160 (23%)"    "No\n60 (80%)"      "Yes\n15 (20%)"    
      [46] "No\n10 (26%)"      "Yes\n29 (74%)"     "No\n123 (77%)"    
      [49] "Yes\n36 (23%)"     "No\n16 (64%)"      "Yes\n9 (36%)"     

