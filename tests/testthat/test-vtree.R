

test_that("vtree works", {
  cases <- cases_from_freqtable(Titanic)  
  vt <- vtree(cases, Class, Survived)
  expect_s3_class(vt, "vtree")
  expect_s3_class(vt, "tbl_graph")

  nodes <- as_tibble(vt)
  expect_equal(nrow(nodes), 13)
  expect_in(c("path", "node_col", "node_val", "parent",
              "path_l", "level", "n", "freq", "vp"), colnames(nodes))

  expect_setequal(c("root", "Class", "Survived"), unique(nodes$node_col))


  attr(cases, "levels") <- NULL
  vt <- vtree(cases, Class, Survived)
  lvs <- levels(vt)
  expect_type(lvs, "list")
  expect_setequal(names(lvs), c("Class", "Survived"))
  expect_setequal(lvs$Class, c("1st", "2nd", "3rd", "Crew"))

})

test_that("cases_from_freqtable works", {
  cases <- cases_from_freqtable(Titanic)  
  expect_equal(nrow(cases), 2201)
  expect_equal(ncol(cases), 4)

  cases <- cases_from_freqtable(Titanic, Class, Survived)
  expect_equal(ncol(cases), 2)

  cases <- cases_from_freqtable(Titanic, all_of(c("Class", "Survived")))
  expect_equal(ncol(cases), 2)

  expect_error(cases_from_freqtable(Titanic, all_of(c("Class", "Foo"))),
               "Can't subset elements that don't exist.")

  expect_error(cases_from_freqtable(Titanic, .freq_col = "foo"))

})


test_that("vtree_from_freqtable works", {
  vt <- vtree_from_freqtable(Titanic)  
  expect_s3_class(vt, "vtree")
  expect_s3_class(vt, "tbl_graph")

  nodes <- as_tibble(vt)

  expect_equal(nrow(nodes), 51)
  expect_in(c("path", "node_col", "node_val", "parent",
              "path_l", "level", "n", "freq", "vp"), colnames(nodes))
  expect_setequal(c("root", "Class", "Sex", "Age",
                    "Survived"), unique(nodes$node_col))

  vt <- vtree_from_freqtable(Titanic, Class, Survived)
  nodes <- vt |> activate(nodes) |> as_tibble()
  expect_equal(nrow(nodes), 13)

  expect_setequal(c("root", "Class",
                    "Survived"), unique(nodes$node_col))

  expect_error(vtree_from_freqtable(Titanic, .cols = c("Class", "Foo")))

  expect_error(vtree_from_freqtable(Titanic, .freq_col = "foo"))

  vt1 <- vtree_from_freqtable(Titanic)  
  n1 <- vt1 |> as_tibble()

  vt2 <- vtree(cases_from_freqtable(Titanic))
  n2 <- vt2 |> as_tibble()

  expect_identical(n1, n2)
})


test_that("vtree calculations are correct", {

  vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
  nodes <- vt |> activate(nodes) |> as_tibble()

  expect_all_true(nodes$n == c(2201, 325, 285, 706, 885, 180, 145,
                              179, 106, 510, 196, 862, 23, 118,
                              62, 4, 141, 154, 25, 13, 93, 422, 88,
                              106, 90, 670, 192, 3, 20))

  expect_all_true(abs(nodes$freq -
                  c(1.00, 0.15, 0.13, 0.32, 0.40, 0.55, 0.45, 0.63,
                    0.37, 0.72, 0.28, 0.97, 0.03, 0.66, 0.34, 0.03,
                    0.97, 0.86, 0.14, 0.12, 0.88, 0.83, 0.17, 0.54,
                    0.46, 0.78, 0.22, .13, .87)) < .1)
  set.seed(123)

  # checking the correct denominator when there are NAs in the data
  titanic <- cases_from_freqtable(Titanic)
  titanicNA <- titanic |>
    # change all classes to character
    mutate(across(everything(), as.character)) |>
    # add some random NAs to each column
    mutate(Class = ifelse(runif(n()) < 0.1, NA, Class)) |>
    mutate(Sex = ifelse(runif(n()) < 0.1, NA, Sex)) |>
    mutate(Age = ifelse(runif(n()) < 0.1, NA, Age))

  vt <- vtree(titanicNA, Class, Sex, Survived)
  nodes <- vt |> activate(nodes) |> as_tibble()
  expect_equal(sum(is.na(nodes$node_val)), 6)

  # denominator for Class should be equal to the number of valid
  # observations in Class
  expect_all_true(
    (nodes |> filter(level == 1) |> pull(denom)) ==
    sum(!is.na(titanicNA$Class)))

  nodes <- nodes |> filter(level == 2)

  expect_all_true(abs(nodes$freq -
                  c(0.46, 0.54, 0.12, 0.37, 0.63, 0.12, 0.28, 0.72,
                    0.11, 0.03, 0.97, 0.10, 0.20, 0.80, 0.13)) < .1)

  # checking that .vp = FALSE works
  vt <- vtree(titanicNA, Class, Sex, Survived, .vp = FALSE)
  nodes <- vt |> activate(nodes) |> as_tibble()
  expect_equal(sum(is.na(nodes$node_val)), 6)

  # denominator for Class should be equal to the total number of
  # observations in Class
  expect_all_true(
    (nodes |> filter(level == 1) |> pull(denom)) ==
    nrow(titanicNA))


  nodes <- nodes |> filter(level == 2)

  expect_all_true(abs(nodes$freq -
                  c(0.41, 0.48, 0.11, 0.33, 0.57, 0.11, 0.26, 0.64,
                    0.10, 0.03, 0.88, 0.09, 0.17, 0.71, 0.11)) < .1)
  expect_snapshot(nodes)
})


test_that("summary works", {

  vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
  sm <- summary(vt)
  expect_s3_class(sm, "data.frame")
  expect_named(sm, c("node_col", "node_val", "count",
                     "freq", "denom", "label"))
  expect_equal(nrow(sm), 11)
  expect_all_true(sm$count == c(325, 285, 706, 885, 0, 1731, 470,
                                0, 1490, 711, 0))
})


test_that("methods work", {

  vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
  expect_setequal(names(vt), c("Class", "Sex", "Survived"))

  otp <- capture_output(print(vt))
  expect_match(otp, "vtree object with 3 variables and 2201 observations")

  lv <- levels(vt)

  expect_type(lv, "list")
  expect_setequal(names(lv), c("Class", "Sex", "Survived"))
  expect_setequal(lv$Class, c("1st", "2nd", "3rd", "Crew"))

})

test_that("errors are raised", {

  vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)

  cases <- cases_from_freqtable(Titanic)
  expect_error(as_vtree(cases), "x must be a tbl_graph object")

  tbl <- as_tbl_graph(vt) |> select(-node_id)
  expect_error(as_vtree(tbl), "Columns node_id not in colnames")

  tbl <- as_tbl_graph(vt) |> dplyr::slice(1)
  expect_error(as_vtree(tbl),
               "vtree must have at least one node other than the root")

  tbl <- as_tbl_graph(vt) |> mutate(level = 0)
  expect_error(as_vtree(tbl),
               "vtree must have at least one node other than the root")

  tbl <- as_tbl_graph(vt) |> mutate(level = level - 1)
  expect_error(as_vtree(tbl), "vtree must have exactly one root node")

  tbl <- as_tbl_graph(vt)
  attr(tbl, "levels") <- NULL

  expect_error(as_vtree(tbl),
               "vtree must have an attribute 'levels'")

  cases <- cases_from_freqtable(Titanic)
  expect_error(vtree(cases, Foo, Bar), "Can't select columns that don't exist.")
  xx <- data.frame()
  expect_error(vtree(xx), "No columns in the data frame cases")

  attr(cases, "levels") <- list(Class = "1st")
  expect_error(vtree(cases, Sex), "not all column names in levels")

  expect_error(mutate(vt, tot_n = 99),
               "tried to modify following immutable column")
  expect_no_error(mutate(vt, tot_n = 99, .check = FALSE))

})
