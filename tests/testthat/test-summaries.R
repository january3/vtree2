test_that("summary_vt works", {

  cases <- cases_from_freqtable(Titanic)
  vt <- vtree(cases, Class, Sex, Survived)
  nodes <- vt |> activate("nodes") |> as_tibble()

  stxt <- summary_vt(cases, vt, Survived)
  expect_equal(length(stxt), nrow(nodes))
  expect_snapshot(stxt)
 
  s1 <- summary_vt_df(cases, vt, Age)
  expect_in(c("ID", "n", "valid",
              "missing", "unique",
              "levels", "levels_str"), colnames(s1))

  expect_true(all(s1$n == s1$valid))
  expect_equal(nrow(s1), nrow(nodes))

  n <- sum(cases$Class == "1st" & cases$Sex == "Male")
  expect_equal(n, 180)
  for(cl in unique(cases$Class)) {
    for(sx in unique(cases$Sex)) {
      n1 <- sum(cases$Class == cl &
               cases$Sex == sx)
      id <- paste0("Class:", cl, "/",
                   "Sex:", sx)
      n2 <- s1$n[ s1$ID == id ]
      expect_equal(n1, n2)
    }
  }

                  
  cases$foo <- rnorm(nrow(cases))
  s1 <- summary_vt_df(cases, vt, foo)
  expect_equal(nrow(s1), nrow(nodes))
  expect_in(c("ID", "n", "mean", "sd", "min",
              "max", "median", "iqr", "q1", "q3",
              "valid", "missing"), colnames(s1))

  # now with some missing values
  cases <- cases_from_freqtable(Titanic)
  set.seed(123)
  cases$Survived[ runif(nrow(cases)) < .1 ] <- NA
  vt1 <- vtree(cases, Class, Sex, Survived)
  nodes <- vt1 |> as_tibble()
  s1 <- summary_vt_df(cases, vt1, Survived)
  expect_equal(nrow(s1), nrow(nodes))

  s1txt <- summary_vt(cases, vt1, Survived)
  expect_equal(length(s1txt), nrow(nodes))
  expect_snapshot(s1txt)

})
