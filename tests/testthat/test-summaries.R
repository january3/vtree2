test_that("summary_vt works", {

  cases <- cases_from_freqtable(Titanic)
  vt <- vtree(cases, Class, Sex, Survived)
  nodes <- vt |> activate("nodes") |> as_tibble()

  stxt <- summary_vt(cases, vt, Survived)
  expect_equal(length(stxt), nrow(nodes))
  expect_snapshot(stxt)
 
  s1 <- summary_vt_df(cases, vt, Age)
  expect_in(c("path", "n", "valid",
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
      n2 <- s1$n[ s1$path == id ]
      expect_equal(n1, n2)
    }
  }

                  
  cases$foo <- rnorm(nrow(cases))
  s1 <- summary_vt_df(cases, vt, foo)
  expect_equal(nrow(s1), nrow(nodes))
  expect_in(c("path", "n", "mean", "sd", "min",
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


test_that("summary_at_var works", {

  data(titanicNA)
  vt <- vtree(titanicNA, Class, Sex, Survived)

  expect_error(summary_at_var(titanicNA, "Class", as_char=FALSE),
               "summary_at_var\\(\\) requires a vtree object")

  sm1 <- summary_at_var(vt, "Class", as_char=TRUE)
  expect_snapshot(sm1)

  vt <- vtree(titanicNA, Class, Sex, Survived, .vp = FALSE)
  sm2 <- summary_at_var(vt, "Class", as_char=TRUE)
  expect_snapshot(sm2)

  sm <- summary_at_var(vt, "Class", as_char=FALSE)
  expect_all_true(levels(vt)$Class %in% names(sm))
  expect_all_true(sm == c(294, 258, 633, 793, 223))
  sm4 <- summary_at_var(vt, "Class")
  expect_identical(sm, sm4)
  sm4 <- summary_at_var(vt, "Class", as_df=TRUE)
  #expect_equal(nrow(sm5), 5)

  sm5 <- summary_at_var(vt, "Sex", as_df=TRUE)
  expect_equal(nrow(sm5), 3)
  expect_s3_class(sm5, "data.frame")
  expect_all_true(sm5[["count"]] == c(1553, 425, 223))
  expect_all_equal(sm5[["denom"]], 2201)
  expect_all_equal(sm5[["node_col"]], "Sex")



})
