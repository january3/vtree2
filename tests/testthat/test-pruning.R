vt <- vtree_from_freqtable(Titanic, Class, Sex, Age, Survived)
vtNA <- vtree(titanicNA, Class, Sex, Survived)

nodes <- vt |> as_tibble()

test_that("masking works", {
  
  m <- find_nodes(vt, Class == "1st")
  expect_equal(sum(m, na.rm=TRUE), 1)

  m <- find_nodes(vt, freq < .12)
  expect_equal(sum(m), 7)

  m <- find_nodes(vt, n > 20 & freq < .12)
  expect_equal(sum(m), 2)

  expect_setequal(nodes$path[m], c("Class:Crew/Sex:Female",
                                 "Class:3rd/Sex:Male/Age:Child"))

})


test_that("pruning works", {

  vt2 <- vt |> prune(freq < .12)
  expect_equal(nrow(as_tibble(vt2)), 36)

  vt2 <- vt |> prune(freq < .12, follow_only = TRUE)
  expect_equal(nrow(as_tibble(vt2)), 43)

  vt2 <- vt |> retain(freq > .12, keep_follow = FALSE)
  expect_equal(nrow(as_tibble(vt2)), 49)

  vt2 <- vt |> retain(node_col == "Sex" & Sex == "Female",
                    keep_follow = TRUE)
  expect_equal(nrow(as_tibble(vt2)), 28)
  vt2 <- vt |> retain(node_col == "Sex" & Sex == "Female",
                    keep_follow = FALSE)
  expect_equal(nrow(as_tibble(vt2)), 9)

  # now with some missing values
  cases <- cases_from_freqtable(Titanic)
  set.seed(128)
  cases$Sex[ runif(nrow(cases)) < .1 ] <- NA
  vt1 <- vtree(cases, Class, Sex, Survived)
  vt2 <- prune(vt1, freq < .12)
  expect_equal(nrow(vt2 |> as_tibble()), 37)
  vt2 <- prune(vt1, Class == "1st")
  expect_equal(nrow(vt2 |> as_tibble()), 31)
  vt2 <- prune(vt1, Sex == "Male")
  expect_equal(nrow(vt2 |> as_tibble()), 29)
})

test_that("is.na() works", {
  vtna <- vtree(titanicNA, Class, Sex, Survived)
  nd <- as_tibble(vtna)

  # this is counter-intuitive. is.na() targets the NA node, but with
  # keep_na_sisters it must be retained so that the remaining nodes on this
  # level can be correctly evaluated.
  vtna2 <- prune(vtna, is.na(Class))
  nd2 <- as_tibble(vtna2)
  expect_in("Class:NA", nd2$path)
  expect_all_true(!grepl("Class:NA/", nd2$path))
  expect_equal(nrow(nd2), nrow(nd) - sum(grepl("Class:NA/", nd$path)))
  expect_snapshot(nd2$path)

  # this should retain the Class:NA node, but not its children
  vtna2b <- prune(vtna, is.na(Class), follow_only = TRUE)
  nd2b <- as_tibble(vtna2b)
  expect_in("Class:NA", nd2b$path)
  expect_all_true(!grepl("Class:NA/", nd2b$path))
  expect_equal(nrow(nd2b), nrow(nd) - sum(grepl("Class:NA", nd$path)) + 1)
  expect_snapshot(nd2b$path)

  # here we remove the Class:NA node and its children, so the NA node is
  # not retained
  vtna2c <- prune(vtna, is.na(Class), keep_na_sisters = FALSE)
  nd2c <- as_tibble(vtna2c)
  expect_all_true((!is.na(nd2c$node_val)) | nd2c$node_col != "Class")
  expect_all_true(!grepl("Class:NA", nd2c$path))
  expect_equal(nrow(nd2c), nrow(nd) - sum(grepl("Class:NA", nd$path)))
  expect_snapshot(nd2c$path)

  # only NA node remains
  vtna3 <- prune(vtna, !is.na(Class))
  nd3 <- as_tibble(vtna3)
  expect_equal(sum(nd3$node_col == "Class"), 1)
  expect_true(is.na(nd3$node_val[nd3$node_col == "Class"]))
  expect_equal(nrow(nd3), 1 + nrow(nd) - sum(!grepl("Class:NA", nd$path)))
  expect_snapshot(nd3$path)

  # this should, by default, retain the Class:NA node due to 
  # is_vp(vtna4) == TRUE, but not its children
  vtna4 <- retain(vtna, !is.na(Class))
  nd4 <- as_tibble(vtna4)
  expect_in("Class:NA", nd4$path)
  expect_equal(sum(grepl("Class:NA/", nd4$path)), 0)
  expect_equal(nrow(nd4), nrow(nd) - sum(grepl("Class:NA/", nd$path)))
  expect_snapshot(nd4$path)

  # we switch off this behavior with keep_na_sisters = FALSE
  vtna5 <- retain(vtna, !is.na(Class), keep_na_sisters = FALSE)
  nd5 <- as_tibble(vtna5)
  expect_equal(sum(grepl("Class:NA", nd5$path)), 0)
  expect_snapshot(nd5$path)

  # or we can construct the tree with vp=FALSE, this should also result in
  # not keeping NA sisters
  vtna <- vtree(titanicNA, Class, Sex, Survived, .vp=FALSE)
  nd <- as_tibble(vtna)
  vtna6 <- retain(vtna, !is.na(Class))
  nd6 <- as_tibble(vtna6)
  expect_equal(sum(grepl("Class:NA", nd6$path)), 0)
  expect_snapshot(nd6$path)
})

test_that("%in% override works", {
  vtna <- vtree(titanicNA, Class, Sex, Survived)
  nd <- as_tibble(vtna)

  vtna2 <- prune(vtna, Class %in% c("1st", "2nd"))
  nd2 <- as_tibble(vtna2)
  expect_equal(sum(nd2$node_col == "Class"), 3)

  # this should retain the Class:NA node, but not its children
  vtna2b <- prune(vtna, !Class %in% c("1st", "2nd"))
  nd2b <- as_tibble(vtna2b)
  expect_equal(sum(nd2b$node_col == "Class"), 3)
  expect_equal(sum(grepl("Class:NA", nd2b$path)), 1)

  # this should not preserve the Class:NA node
  vtna2c <- prune(vtna, !Class %in% c("1st", "2nd"), keep_na_sisters = FALSE)
  nd2c <- as_tibble(vtna2c)
  expect_equal(sum(nd2c$node_col == "Class"), 2)
  expect_equal(sum(grepl("Class:NA", nd2c$path)), 0)

  vtna3 <- retain(vtna, Class %in% c("1st", "2nd"))
  nd3 <- as_tibble(vtna3)
  expect_equal(sum(nd3$node_col == "Class"), 3)
  expect_equal(sum(grepl("Class:NA", nd3$path)), 1)

  vtna4 <- retain(vtna, !Class %in% c("3rd", "Crew"))
  nd4 <- as_tibble(vtna4)
  expect_true(!any(grepl("Class:3rd", nd4$path)))
  expect_true(!any(grepl("Class:Crew", nd4$path)))
  expect_equal(sum(nd4$node_col == "Class"), 3)
  expect_equal(nrow(nd4),
               nrow(nd) - sum(grepl("Class:3rd", nd$path)) -
                          sum(grepl("Class:Crew", nd$path)))

})



test_that("keep_na_sisters works", {
  vt2 <- vtNA |> prune(freq < .12)
  expect_equal(nrow(as_tibble(vt2)), 34)

  vt2 <- vtNA |> prune(freq < .12, keep_na_sisters = TRUE)
  expect_equal(nrow(as_tibble(vt2)), 34)

  vt2 <- vtNA |> prune(node_col == "Class" & (is.na(Class) | !Class == "1st"))
  expect_equal(nrow(as_tibble(vt2)), 12)

  # this one is without vp, so the NA sister should not be kept
  vtNA2 <- vtree(titanicNA, Class, Sex, Survived, .vp=FALSE)
  vt2 <- vtNA2 |> prune(node_col == "Class" & (is.na(Class) | !Class == "1st"))
  expect_equal(nrow(as_tibble(vt2)), 11)

  vt2 <- vtNA |> prune(freq < .12, keep_na_sisters = FALSE, follow_only = TRUE)
  expect_equal(nrow(as_tibble(vt2)), 36)
})


test_that("marking works", {

  vt2 <- mark(vt, freq < .12)
  n2 <- as_tibble(vt2)
  expect_equal(sum(n2$mark), 7)
  expect_all_true(n2$freq[n2$mark] < .12)
  expect_all_true(n2$freq[!n2$mark] >= .12)

  vt3 <- mark(vt, path == "Class:3rd", follow_only = TRUE)
  n3 <- as_tibble(vt3)
  expect_all_true(grepl("Class:3rd", n3$path[n3$mark]))
  expect_all_true(!grepl("Class:3rd/", n3$path[!n3$mark]))
  expect_true(!n3$mark[n3$path == "Class:3rd"])

  vt4 <- prune(vt, freq < .12, mark_only = TRUE)
  nd <- as_tibble(vt4)
  expect_in("mark", names(nd))
  expect_equal(sum(nd$mark), 15)

  vt5 <- retain(vt, freq < .12, mark_only = TRUE)
  nd <- as_tibble(vt5)
  expect_in("mark", names(nd))
  expect_equal(sum(nd$mark), 26)
})


test_that("errors are raised", {
  expect_error(prune(vt, freq < Inf),
    "No non-root nodes remain after pruning")
  expect_error(retain(vt, freq < -1),
    "No non-root nodes remain after pruning")
  expect_error(prune(vt, c(TRUE, TRUE)),
    "evaluated condition returned a vector with unexpected length")
})
