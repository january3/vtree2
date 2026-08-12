# add_labels works

    Code
      as_tibble(vt1)$label
    Output
       [1] "2201"              "1st\n325 (15%)"    "2nd\n285 (13%)"   
       [4] "3rd\n706 (32%)"    "Crew\n885 (40%)"   "Male\n180 (55%)"  
       [7] "Female\n145 (45%)" "Male\n179 (63%)"   "Female\n106 (37%)"
      [10] "Male\n510 (72%)"   "Female\n196 (28%)" "Male\n862 (97%)"  
      [13] "Female\n23 (3%)"   "Child\n5 (3%)"     "Adult\n175 (97%)" 
      [16] "Child\n1 (1%)"     "Adult\n144 (99%)"  "Child\n11 (6%)"   
      [19] "Adult\n168 (94%)"  "Child\n13 (12%)"   "Adult\n93 (88%)"  
      [22] "Child\n48 (9%)"    "Adult\n462 (91%)"  "Child\n31 (16%)"  
      [25] "Adult\n165 (84%)"  "Adult\n862 (100%)" "Adult\n23 (100%)" 
      [28] "Yes\n5 (100%)"     "No\n118 (67%)"     "Yes\n57 (33%)"    
      [31] "Yes\n1 (100%)"     "No\n4 (3%)"        "Yes\n140 (97%)"   
      [34] "Yes\n11 (100%)"    "No\n154 (92%)"     "Yes\n14 (8%)"     
      [37] "Yes\n13 (100%)"    "No\n13 (14%)"      "Yes\n80 (86%)"    
      [40] "No\n35 (73%)"      "Yes\n13 (27%)"     "No\n387 (84%)"    
      [43] "Yes\n75 (16%)"     "No\n17 (55%)"      "Yes\n14 (45%)"    
      [46] "No\n89 (54%)"      "Yes\n76 (46%)"     "No\n670 (78%)"    
      [49] "Yes\n192 (22%)"    "No\n3 (13%)"       "Yes\n20 (87%)"    

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
      [13] "Sex: Female\nN = 23 (3%)"     "Age: Child\nN = 5 (3%)"      
      [15] "Age: Adult\nN = 175 (97%)"    "Age: Child\nN = 1 (1%)"      
      [17] "Age: Adult\nN = 144 (99%)"    "Age: Child\nN = 11 (6%)"     
      [19] "Age: Adult\nN = 168 (94%)"    "Age: Child\nN = 13 (12%)"    
      [21] "Age: Adult\nN = 93 (88%)"     "Age: Child\nN = 48 (9%)"     
      [23] "Age: Adult\nN = 462 (91%)"    "Age: Child\nN = 31 (16%)"    
      [25] "Age: Adult\nN = 165 (84%)"    "Age: Adult\nN = 862 (100%)"  
      [27] "Age: Adult\nN = 23 (100%)"    "Survived: Yes\nN = 5 (100%)" 
      [29] "Survived: No\nN = 118 (67%)"  "Survived: Yes\nN = 57 (33%)" 
      [31] "Survived: Yes\nN = 1 (100%)"  "Survived: No\nN = 4 (3%)"    
      [33] "Survived: Yes\nN = 140 (97%)" "Survived: Yes\nN = 11 (100%)"
      [35] "Survived: No\nN = 154 (92%)"  "Survived: Yes\nN = 14 (8%)"  
      [37] "Survived: Yes\nN = 13 (100%)" "Survived: No\nN = 13 (14%)"  
      [39] "Survived: Yes\nN = 80 (86%)"  "Survived: No\nN = 35 (73%)"  
      [41] "Survived: Yes\nN = 13 (27%)"  "Survived: No\nN = 387 (84%)" 
      [43] "Survived: Yes\nN = 75 (16%)"  "Survived: No\nN = 17 (55%)"  
      [45] "Survived: Yes\nN = 14 (45%)"  "Survived: No\nN = 89 (54%)"  
      [47] "Survived: Yes\nN = 76 (46%)"  "Survived: No\nN = 670 (78%)" 
      [49] "Survived: Yes\nN = 192 (22%)" "Survived: No\nN = 3 (13%)"   
      [51] "Survived: Yes\nN = 20 (87%)" 

---

    Code
      as_tibble(vt2b)$label
    Output
       [1] "2201"             "1st 325 (15%)"    "2nd 285 (13%)"    "3rd 706 (32%)"   
       [5] "Crew 885 (40%)"   "Male 180 (55%)"   "Female 145 (45%)" "Male 179 (63%)"  
       [9] "Female 106 (37%)" "Male 510 (72%)"   "Female 196 (28%)" "Male 862 (97%)"  
      [13] "Female 23 (3%)"   "Child 5 (3%)"     "Adult 175 (97%)"  "Child 1 (1%)"    
      [17] "Adult 144 (99%)"  "Child 11 (6%)"    "Adult 168 (94%)"  "Child 13 (12%)"  
      [21] "Adult 93 (88%)"   "Child 48 (9%)"    "Adult 462 (91%)"  "Child 31 (16%)"  
      [25] "Adult 165 (84%)"  "Adult 862 (100%)" "Adult 23 (100%)"  "Yes 5 (100%)"    
      [29] "No 118 (67%)"     "Yes 57 (33%)"     "Yes 1 (100%)"     "No 4 (3%)"       
      [33] "Yes 140 (97%)"    "Yes 11 (100%)"    "No 154 (92%)"     "Yes 14 (8%)"     
      [37] "Yes 13 (100%)"    "No 13 (14%)"      "Yes 80 (86%)"     "No 35 (73%)"     
      [41] "Yes 13 (27%)"     "No 387 (84%)"     "Yes 75 (16%)"     "No 17 (55%)"     
      [45] "Yes 14 (45%)"     "No 89 (54%)"      "Yes 76 (46%)"     "No 670 (78%)"    
      [49] "Yes 192 (22%)"    "No 3 (13%)"       "Yes 20 (87%)"    

---

    Code
      as_tibble(vt4)$label
    Output
       [1] "2201"              "1st\n294 (15%)"    "2nd\n258 (13%)"   
       [4] "3rd\n633 (32%)"    "Crew\n793 (40%)"   "NA\n223"          
       [7] "Male\n142 (54%)"   "Female\n120 (46%)" "NA\n32"           
      [10] "Male\n146 (63%)"   "Female\n84 (37%)"  "NA\n28"           
      [13] "Male\n408 (72%)"   "Female\n162 (28%)" "NA\n63"           
      [16] "Male\n698 (97%)"   "Female\n20 (3%)"   "NA\n75"           
      [19] "Male\n159 (80%)"   "Female\n39 (20%)"  "NA\n25"           
      [22] "No\n99 (70%)"      "Yes\n43 (30%)"     "No\n3 (2%)"       
      [25] "Yes\n117 (98%)"    "No\n12 (38%)"      "Yes\n20 (62%)"    
      [28] "No\n127 (87%)"     "Yes\n19 (13%)"     "No\n12 (14%)"     
      [31] "Yes\n72 (86%)"     "No\n12 (43%)"      "Yes\n16 (57%)"    
      [34] "No\n340 (83%)"     "Yes\n68 (17%)"     "No\n89 (55%)"     
      [37] "Yes\n73 (45%)"     "No\n46 (73%)"      "Yes\n17 (27%)"    
      [40] "No\n538 (77%)"     "Yes\n160 (23%)"    "No\n3 (15%)"      
      [43] "Yes\n17 (85%)"     "No\n60 (80%)"      "Yes\n15 (20%)"    
      [46] "No\n123 (77%)"     "Yes\n36 (23%)"     "No\n10 (26%)"     
      [49] "Yes\n29 (74%)"     "No\n16 (64%)"      "Yes\n9 (36%)"     

