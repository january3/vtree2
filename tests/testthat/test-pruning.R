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

  vt2 <- vtNA |> prune(na.rm = TRUE)
  expect_equal(nrow(as_tibble(vt2)), 29)

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
})

