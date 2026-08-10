# is.na() works

    Code
      nd2$path
    Output
       [1] "root"                               "Class:1st"                         
       [3] "Class:2nd"                          "Class:3rd"                         
       [5] "Class:Crew"                         "Class:NA"                          
       [7] "Class:1st/Sex:Male"                 "Class:1st/Sex:Female"              
       [9] "Class:1st/Sex:NA"                   "Class:2nd/Sex:Male"                
      [11] "Class:2nd/Sex:Female"               "Class:2nd/Sex:NA"                  
      [13] "Class:3rd/Sex:Male"                 "Class:3rd/Sex:Female"              
      [15] "Class:3rd/Sex:NA"                   "Class:Crew/Sex:Male"               
      [17] "Class:Crew/Sex:Female"              "Class:Crew/Sex:NA"                 
      [19] "Class:1st/Sex:Male/Survived:No"     "Class:1st/Sex:Male/Survived:Yes"   
      [21] "Class:1st/Sex:Female/Survived:No"   "Class:1st/Sex:Female/Survived:Yes" 
      [23] "Class:1st/Sex:NA/Survived:No"       "Class:1st/Sex:NA/Survived:Yes"     
      [25] "Class:2nd/Sex:Male/Survived:No"     "Class:2nd/Sex:Male/Survived:Yes"   
      [27] "Class:2nd/Sex:Female/Survived:No"   "Class:2nd/Sex:Female/Survived:Yes" 
      [29] "Class:2nd/Sex:NA/Survived:No"       "Class:2nd/Sex:NA/Survived:Yes"     
      [31] "Class:3rd/Sex:Male/Survived:No"     "Class:3rd/Sex:Male/Survived:Yes"   
      [33] "Class:3rd/Sex:Female/Survived:No"   "Class:3rd/Sex:Female/Survived:Yes" 
      [35] "Class:3rd/Sex:NA/Survived:No"       "Class:3rd/Sex:NA/Survived:Yes"     
      [37] "Class:Crew/Sex:Male/Survived:No"    "Class:Crew/Sex:Male/Survived:Yes"  
      [39] "Class:Crew/Sex:Female/Survived:No"  "Class:Crew/Sex:Female/Survived:Yes"
      [41] "Class:Crew/Sex:NA/Survived:No"      "Class:Crew/Sex:NA/Survived:Yes"    

---

    Code
      nd2b$path
    Output
       [1] "root"                               "Class:1st"                         
       [3] "Class:2nd"                          "Class:3rd"                         
       [5] "Class:Crew"                         "Class:NA"                          
       [7] "Class:1st/Sex:Male"                 "Class:1st/Sex:Female"              
       [9] "Class:1st/Sex:NA"                   "Class:2nd/Sex:Male"                
      [11] "Class:2nd/Sex:Female"               "Class:2nd/Sex:NA"                  
      [13] "Class:3rd/Sex:Male"                 "Class:3rd/Sex:Female"              
      [15] "Class:3rd/Sex:NA"                   "Class:Crew/Sex:Male"               
      [17] "Class:Crew/Sex:Female"              "Class:Crew/Sex:NA"                 
      [19] "Class:1st/Sex:Male/Survived:No"     "Class:1st/Sex:Male/Survived:Yes"   
      [21] "Class:1st/Sex:Female/Survived:No"   "Class:1st/Sex:Female/Survived:Yes" 
      [23] "Class:1st/Sex:NA/Survived:No"       "Class:1st/Sex:NA/Survived:Yes"     
      [25] "Class:2nd/Sex:Male/Survived:No"     "Class:2nd/Sex:Male/Survived:Yes"   
      [27] "Class:2nd/Sex:Female/Survived:No"   "Class:2nd/Sex:Female/Survived:Yes" 
      [29] "Class:2nd/Sex:NA/Survived:No"       "Class:2nd/Sex:NA/Survived:Yes"     
      [31] "Class:3rd/Sex:Male/Survived:No"     "Class:3rd/Sex:Male/Survived:Yes"   
      [33] "Class:3rd/Sex:Female/Survived:No"   "Class:3rd/Sex:Female/Survived:Yes" 
      [35] "Class:3rd/Sex:NA/Survived:No"       "Class:3rd/Sex:NA/Survived:Yes"     
      [37] "Class:Crew/Sex:Male/Survived:No"    "Class:Crew/Sex:Male/Survived:Yes"  
      [39] "Class:Crew/Sex:Female/Survived:No"  "Class:Crew/Sex:Female/Survived:Yes"
      [41] "Class:Crew/Sex:NA/Survived:No"      "Class:Crew/Sex:NA/Survived:Yes"    

---

    Code
      nd2c$path
    Output
       [1] "root"                               "Class:1st"                         
       [3] "Class:2nd"                          "Class:3rd"                         
       [5] "Class:Crew"                         "Class:1st/Sex:Male"                
       [7] "Class:1st/Sex:Female"               "Class:1st/Sex:NA"                  
       [9] "Class:2nd/Sex:Male"                 "Class:2nd/Sex:Female"              
      [11] "Class:2nd/Sex:NA"                   "Class:3rd/Sex:Male"                
      [13] "Class:3rd/Sex:Female"               "Class:3rd/Sex:NA"                  
      [15] "Class:Crew/Sex:Male"                "Class:Crew/Sex:Female"             
      [17] "Class:Crew/Sex:NA"                  "Class:1st/Sex:Male/Survived:No"    
      [19] "Class:1st/Sex:Male/Survived:Yes"    "Class:1st/Sex:Female/Survived:No"  
      [21] "Class:1st/Sex:Female/Survived:Yes"  "Class:1st/Sex:NA/Survived:No"      
      [23] "Class:1st/Sex:NA/Survived:Yes"      "Class:2nd/Sex:Male/Survived:No"    
      [25] "Class:2nd/Sex:Male/Survived:Yes"    "Class:2nd/Sex:Female/Survived:No"  
      [27] "Class:2nd/Sex:Female/Survived:Yes"  "Class:2nd/Sex:NA/Survived:No"      
      [29] "Class:2nd/Sex:NA/Survived:Yes"      "Class:3rd/Sex:Male/Survived:No"    
      [31] "Class:3rd/Sex:Male/Survived:Yes"    "Class:3rd/Sex:Female/Survived:No"  
      [33] "Class:3rd/Sex:Female/Survived:Yes"  "Class:3rd/Sex:NA/Survived:No"      
      [35] "Class:3rd/Sex:NA/Survived:Yes"      "Class:Crew/Sex:Male/Survived:No"   
      [37] "Class:Crew/Sex:Male/Survived:Yes"   "Class:Crew/Sex:Female/Survived:No" 
      [39] "Class:Crew/Sex:Female/Survived:Yes" "Class:Crew/Sex:NA/Survived:No"     
      [41] "Class:Crew/Sex:NA/Survived:Yes"    

---

    Code
      nd3$path
    Output
       [1] "root"                             "Class:NA"                        
       [3] "Class:NA/Sex:Male"                "Class:NA/Sex:Female"             
       [5] "Class:NA/Sex:NA"                  "Class:NA/Sex:Male/Survived:No"   
       [7] "Class:NA/Sex:Male/Survived:Yes"   "Class:NA/Sex:Female/Survived:No" 
       [9] "Class:NA/Sex:Female/Survived:Yes" "Class:NA/Sex:NA/Survived:No"     
      [11] "Class:NA/Sex:NA/Survived:Yes"    

---

    Code
      nd4$path
    Output
       [1] "root"                               "Class:1st"                         
       [3] "Class:2nd"                          "Class:3rd"                         
       [5] "Class:Crew"                         "Class:NA"                          
       [7] "Class:1st/Sex:Male"                 "Class:1st/Sex:Female"              
       [9] "Class:1st/Sex:NA"                   "Class:2nd/Sex:Male"                
      [11] "Class:2nd/Sex:Female"               "Class:2nd/Sex:NA"                  
      [13] "Class:3rd/Sex:Male"                 "Class:3rd/Sex:Female"              
      [15] "Class:3rd/Sex:NA"                   "Class:Crew/Sex:Male"               
      [17] "Class:Crew/Sex:Female"              "Class:Crew/Sex:NA"                 
      [19] "Class:1st/Sex:Male/Survived:No"     "Class:1st/Sex:Male/Survived:Yes"   
      [21] "Class:1st/Sex:Female/Survived:No"   "Class:1st/Sex:Female/Survived:Yes" 
      [23] "Class:1st/Sex:NA/Survived:No"       "Class:1st/Sex:NA/Survived:Yes"     
      [25] "Class:2nd/Sex:Male/Survived:No"     "Class:2nd/Sex:Male/Survived:Yes"   
      [27] "Class:2nd/Sex:Female/Survived:No"   "Class:2nd/Sex:Female/Survived:Yes" 
      [29] "Class:2nd/Sex:NA/Survived:No"       "Class:2nd/Sex:NA/Survived:Yes"     
      [31] "Class:3rd/Sex:Male/Survived:No"     "Class:3rd/Sex:Male/Survived:Yes"   
      [33] "Class:3rd/Sex:Female/Survived:No"   "Class:3rd/Sex:Female/Survived:Yes" 
      [35] "Class:3rd/Sex:NA/Survived:No"       "Class:3rd/Sex:NA/Survived:Yes"     
      [37] "Class:Crew/Sex:Male/Survived:No"    "Class:Crew/Sex:Male/Survived:Yes"  
      [39] "Class:Crew/Sex:Female/Survived:No"  "Class:Crew/Sex:Female/Survived:Yes"
      [41] "Class:Crew/Sex:NA/Survived:No"      "Class:Crew/Sex:NA/Survived:Yes"    

---

    Code
      nd5$path
    Output
       [1] "root"                               "Class:1st"                         
       [3] "Class:2nd"                          "Class:3rd"                         
       [5] "Class:Crew"                         "Class:1st/Sex:Male"                
       [7] "Class:1st/Sex:Female"               "Class:1st/Sex:NA"                  
       [9] "Class:2nd/Sex:Male"                 "Class:2nd/Sex:Female"              
      [11] "Class:2nd/Sex:NA"                   "Class:3rd/Sex:Male"                
      [13] "Class:3rd/Sex:Female"               "Class:3rd/Sex:NA"                  
      [15] "Class:Crew/Sex:Male"                "Class:Crew/Sex:Female"             
      [17] "Class:Crew/Sex:NA"                  "Class:1st/Sex:Male/Survived:No"    
      [19] "Class:1st/Sex:Male/Survived:Yes"    "Class:1st/Sex:Female/Survived:No"  
      [21] "Class:1st/Sex:Female/Survived:Yes"  "Class:1st/Sex:NA/Survived:No"      
      [23] "Class:1st/Sex:NA/Survived:Yes"      "Class:2nd/Sex:Male/Survived:No"    
      [25] "Class:2nd/Sex:Male/Survived:Yes"    "Class:2nd/Sex:Female/Survived:No"  
      [27] "Class:2nd/Sex:Female/Survived:Yes"  "Class:2nd/Sex:NA/Survived:No"      
      [29] "Class:2nd/Sex:NA/Survived:Yes"      "Class:3rd/Sex:Male/Survived:No"    
      [31] "Class:3rd/Sex:Male/Survived:Yes"    "Class:3rd/Sex:Female/Survived:No"  
      [33] "Class:3rd/Sex:Female/Survived:Yes"  "Class:3rd/Sex:NA/Survived:No"      
      [35] "Class:3rd/Sex:NA/Survived:Yes"      "Class:Crew/Sex:Male/Survived:No"   
      [37] "Class:Crew/Sex:Male/Survived:Yes"   "Class:Crew/Sex:Female/Survived:No" 
      [39] "Class:Crew/Sex:Female/Survived:Yes" "Class:Crew/Sex:NA/Survived:No"     
      [41] "Class:Crew/Sex:NA/Survived:Yes"    

---

    Code
      nd6$path
    Output
       [1] "root"                               "Class:1st"                         
       [3] "Class:2nd"                          "Class:3rd"                         
       [5] "Class:Crew"                         "Class:1st/Sex:Male"                
       [7] "Class:1st/Sex:Female"               "Class:1st/Sex:NA"                  
       [9] "Class:2nd/Sex:Male"                 "Class:2nd/Sex:Female"              
      [11] "Class:2nd/Sex:NA"                   "Class:3rd/Sex:Male"                
      [13] "Class:3rd/Sex:Female"               "Class:3rd/Sex:NA"                  
      [15] "Class:Crew/Sex:Male"                "Class:Crew/Sex:Female"             
      [17] "Class:Crew/Sex:NA"                  "Class:1st/Sex:Male/Survived:No"    
      [19] "Class:1st/Sex:Male/Survived:Yes"    "Class:1st/Sex:Female/Survived:No"  
      [21] "Class:1st/Sex:Female/Survived:Yes"  "Class:1st/Sex:NA/Survived:No"      
      [23] "Class:1st/Sex:NA/Survived:Yes"      "Class:2nd/Sex:Male/Survived:No"    
      [25] "Class:2nd/Sex:Male/Survived:Yes"    "Class:2nd/Sex:Female/Survived:No"  
      [27] "Class:2nd/Sex:Female/Survived:Yes"  "Class:2nd/Sex:NA/Survived:No"      
      [29] "Class:2nd/Sex:NA/Survived:Yes"      "Class:3rd/Sex:Male/Survived:No"    
      [31] "Class:3rd/Sex:Male/Survived:Yes"    "Class:3rd/Sex:Female/Survived:No"  
      [33] "Class:3rd/Sex:Female/Survived:Yes"  "Class:3rd/Sex:NA/Survived:No"      
      [35] "Class:3rd/Sex:NA/Survived:Yes"      "Class:Crew/Sex:Male/Survived:No"   
      [37] "Class:Crew/Sex:Male/Survived:Yes"   "Class:Crew/Sex:Female/Survived:No" 
      [39] "Class:Crew/Sex:Female/Survived:Yes" "Class:Crew/Sex:NA/Survived:No"     
      [41] "Class:Crew/Sex:NA/Survived:Yes"    

