test_that("summarize_by_node works", {

  cases <- cases_from_freqtable(Titanic)
  vt <- vtree(cases, Class, Sex, Survived)
  nodes <- as_tibble(vt)

  stxt <- fmt_label(summarize_by_node(cases, vt, Survived))
  expect_equal(length(stxt), nrow(nodes))
  expect_snapshot(stxt)
 
  s1 <- summarize_by_node(cases, vt, Age)
  expect_in(c("node_id", "path", "n", "valid",
              "missing", "unique",
              "levels",
              "denom", "Child",
              "Child_freq", "Adult", "Adult_freq",
              "col"), colnames(s1))

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

                  
  # now with some missing values
  cases <- cases_from_freqtable(Titanic)
  set.seed(123)
  cases$Survived[ runif(nrow(cases)) < .1 ] <- NA
  vt1 <- vtree(cases, Class, Sex, Survived)
  nodes <- vt1 |> as_tibble()
  s1 <- summarize_by_node(cases, vt1, Survived)
  expect_equal(nrow(s1), nrow(nodes))

  s1txt <- fmt_label(s1)
  expect_equal(length(s1txt), nrow(nodes))
  expect_snapshot(s1txt)

  # check that the vp argument works
  vt1 <- vtree(titanicNA, Class, Survived)
  s1 <- summarize_by_node(titanicNA, vt1, Sex)
  expect_all_true(s1$Male_freq == s1$Male / s1$valid)
  expect_all_true(abs(s1$Male_freq + s1$Female_freq - 1) < 1e-6)
  expect_all_true(s1$valid == s1$denom)
  expect_all_true(!c("NAs", "NAs_freq") %in% colnames(s1))

  vt1 <- vtree(titanicNA, Class, Survived, .vp = FALSE)
  s1 <- summarize_by_node(titanicNA, vt1, Sex)
  expect_all_true(s1$Male_freq == s1$Male / s1$n)
  expect_all_true(abs(s1$Male_freq + s1$Female_freq + s1$NAs_freq - 1) < 1e-6)
  expect_all_true(s1$denom == s1$n)
  expect_all_true(c("NAs", "NAs_freq") %in% colnames(s1))
})

test_that("numeric summaries work", {

  cases <- cases_from_freqtable(Titanic)
  vt <- vtree(cases, Class, Sex, Survived)
  nodes <- vt |> activate("nodes") |> as_tibble()

  set.seed(123)
  cases$foo <- rnorm(nrow(cases))
  cases$foo[ runif(nrow(cases)) < .1 ] <- NA

  s1 <- summarize_by_node(cases, vt, foo)
  expect_equal(nrow(s1), nrow(nodes))
  expect_in(c("node_id", "path", "n", "mean", "sd", "min",
              "max", "median", "iqr", "q1", "q3",
              "valid", "missing"), colnames(s1))
  expect_all_true(s1$valid + s1$missing == s1$n)
  expect_snapshot(s1)

  s2 <- fmt_label(s1)
  expect_length(s2, nrow(nodes))
  expect_type(s2, "character")
  expect_all_true(grepl("^foo", s2))
  expect_all_true(grepl("mean", s2))
  expect_all_true(grepl("median", s2))
  expect_all_true(grepl("IQR", s2))
  expect_all_true(grepl("range", s2))
})

test_that("errors are raised", {

  cases <- cases_from_freqtable(Titanic)
  vt <- vtree(cases, Class, Sex, Survived)

  expect_error(summarize_by_node(vt, cases, Survived),
               "is not a data frame")
  expect_error(summarize_by_node(cases, vt, all_of(c("Survived", "Sex"))),
               "Only one column can be summarized at a time")
  expect_error(summarize_by_node(cases, as_tibble(vt), Survived),
               "is not a vtree object")
  expect_error(summarize_by_node(cases, vt, Foooo),
               "Can't select columns that don't exist.")
  cases$foo <- rnorm(nrow(cases))
  expect_error(vtree_apply(vt, vt, \(x) mean(x$foo)),
               "is not a data frame")
  expect_error(vtree_apply(cases, cases, \(x) mean(x$foo)),
               "is not a vtree object")
  expect_error(vtree_apply(cases, vt, \(x) mean(x$foo),
                           .mask=c(TRUE, FALSE)),
               "length of .mask must be equal to the number of nodes")
  expect_error(vtree_apply(cases, vt, \(x) mean(x$foo),
                           .args = c("nodes", "foo")),
               "args may only contain following values:")

  cases <- cases[, c("Class", "Survived")]
  expect_error(summarize_by_node(cases, vt, Survived),
               "columns in the vtree are not found in the cases data frame")
  expect_error(vtree_apply(cases, vt, \(x) mean(x$foo)),
               "columns in the vtree are not found in the cases data frame")

})

test_that("summary_at_var works", {

  data(titanicNA)
  vt <- vtree(titanicNA, Class, Sex, Survived)

  expect_error(summary_at_var(titanicNA, "Class", as_char=FALSE),
               "is not a vtree object")

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


test_that("vtree_apply works", {

  cases <- cases_from_freqtable(Titanic)
  cases$foo <- rnorm(nrow(cases))
  vt <- vtree(cases, Class, Sex, Survived)
  nd <- as_tibble(vt)

  vtf <- vtree_apply(cases, vt, \(x) mean(x$foo))

  expect_type(vtf, "list")
  expect_length(vtf, nrow(nd))
  expect_all_true(names(vtf) == nd$node_key)
  expect_all_true(purrr::map_lgl(vtf, is.numeric) == TRUE)

  vtf <- vtree_apply(cases, vt, \(x) x, .args = "nodes") 
  expect_type(vtf, "list")
  expect_length(vtf, nrow(nd))
  expect_all_true(names(vtf) == nd$node_key)

  vtf_df <- Reduce(rbind, vtf)
  expect_identical(nd, vtf_df)

  vtf <- vtree_apply(cases, vt, \(x) is.logical(x), .args = "sel")
  expect_all_true(unlist(vtf))

  vtf <- vtree_apply(cases, vt, \(x) is.data.frame(x), .args = "nodes")
  expect_all_true(unlist(vtf))
  vtf <- vtree_apply(cases, vt, \(x) nrow(x) == 1, .args = "nodes")
  expect_all_true(unlist(vtf))

})

test_that("label_var_levels works", {
  cases <- cases_from_freqtable(Titanic)
  vt <- vtree(cases, Class, Survived)

  labs <- label_var_levels(cases, vt, "Sex")
  expect_match(labs, "Male \\(n=[[:digit:]]+\\), Female \\(n=[[:digit:]]+\\)")

  labs <- label_var_levels(cases, vt, "Sex", sep="%")
  expect_match(labs, "%Female")

  vt <- vtree(InsectSprays, spray)
  labs <- label_var_levels(InsectSprays, vt, "count", shorten=F,
      width=1e6)
  lab2 <- as.numeric(unlist(strsplit(labs[2], ", ")))
  expect_setequal(lab2, subset(InsectSprays, spray == "A")$count)
})

test_that("fmt_label works", {

  set.seed(123)
  cases <- titanicNA |>
    mutate(foo = 100 * runif(n()))
  vt <- vtree(cases, Class, Survived)
  s1 <- summarize_by_node(cases, vt, Sex)

  labs <- fmt_label(s1)
  expect_length(labs, nrow(s1))
  expect_all_true(grepl("Sex", labs))

  labs <- fmt_label(s1, fmt="foo")
  expect_length(labs, nrow(s1))
  expect_all_equal(labs, "foo")

  labs <- fmt_label(s1, fmt="{node_id}")
  expect_all_true(labs == as.character(s1$node_id))

  labs <- fmt_label(s1, expr=ifelse(missing > 20, "MANY", "FEW"))
  expect_length(labs, nrow(s1))
  expect_all_true(labs[s1$missing > 20] == "MANY")
  expect_all_true(labs[s1$missing <= 20] == "FEW")

  s1 <- summarize_by_node(cases, vt, foo)
  labs <- fmt_label(s1)
  expect_all_true(grepl("mean", labs))
  expect_all_true(grepl("median", labs))
  expect_all_true(grepl("range", labs))

  labs <- fmt_label(s1, "{mean}", digits=2)
  expect_all_true(nchar(labs) <= 5L)
  labs <- fmt_label(s1, "{mean}", digits=1)
  expect_all_true(nchar(labs) <= 4L)
  labs <- fmt_label(s1, "{mean}", digits=0)
  expect_all_true(nchar(labs) <= 2L)
  expect_all_true(as.numeric(labs) == round(s1$mean, 0))

})
