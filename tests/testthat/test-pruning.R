vt <- vtree_from_freqtable(Titanic, Class, Sex, Age, Survived)
nodes <- vt |> as_tibble()

test_that("masking works", {
  
  m <- find_nodes(vt, Class == "1st")
  expect_equal(sum(m, na.rm=TRUE), 1)

  m <- find_nodes(vt, freq < .12)
  expect_equal(sum(m), 7)

  m <- find_nodes(vt, n > 20 & freq < .12)
  expect_equal(sum(m), 2)

  expect_setequal(nodes$ID[m], c("Class:Crew/Sex:Female",
                                 "Class:3rd/Sex:Male/Age:Child"))

})


test_that("pruning works", {

  vt2 <- vt |> prune(freq < .12)
  expect_equal(nrow(vt2 |> as_tibble()), 36)

  vt2 <- vt |> prune(freq < .12, follow_only = TRUE)
  expect_equal(nrow(vt2 |> as_tibble()), 43)

  vt2 <- vt |> mutate(node_val = ifelse(freq < .12, NA, node_val))
  vt3 <- vt2 |> prune(na.rm = TRUE)
  expect_equal(nrow(vt3 |> as_tibble()), 36)

  vt2 <- vt |> keep(freq > .12)
  expect_equal(nrow(vt2 |> as_tibble()), 36)

  # now with some missing values
  cases <- cases_from_freqtable(Titanic)
  cases$Sex[ runif(nrow(cases)) < .1 ] <- NA
  vt1 <- vtree(cases, Class, Sex, Survived)
  vt2 <- prune(vt1, freq < .12)
  expect_equal(nrow(vt2 |> as_tibble()), 28)
  vt2 <- prune(vt1, Class == "1st")
  expect_equal(nrow(vt2 |> as_tibble()), 31)
  vt2 <- prune(vt1, Sex == "Male")
  expect_equal(nrow(vt2 |> as_tibble()), 29)


})
