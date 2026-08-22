test_that("ensure works", {

  expect_error(ensure(1, "vtree"), "is not a vtree object")
  expect_error(ensure(1, "function"), "is not a function")
  expect_error(ensure(mtcars, "numeric"), "is not a number")
  expect_error(ensure(1, "list"), "is not a list")
  expect_error(ensure(1, "logical"), "is not a logical vector")
  expect_error(ensure(1, "character"), "is not a character vector")
  expect_error(ensure(1, "data.frame"), "is not a data frame")
  expect_error(ensure(pi, "integer"), "is not a vector of integer numbers")
  expect_error(ensure(1, "factor"), "is not a factor")

  vt <- vtree(titanicNA)

  expect_no_error(ensure(vt, "vtree"))
  expect_no_error(ensure(\(x) x, "function"))
  expect_no_error(ensure(mean, "function"))
  expect_no_error(ensure(1, "numeric"))
  expect_no_error(ensure(list(a=1), "list"))
  expect_no_error(ensure(FALSE, "logical"))
  expect_no_error(ensure("a", "character"))
  expect_no_error(ensure(mtcars, "data.frame"))
  expect_no_error(ensure(1L, "integer"))
  expect_no_error(ensure(factor("a"), "factor"))

})

test_that("high level ensure funcs work", {

  vt <- vtree(titanicNA, Class, Sex)

  expect_error(ensure_fill(vt), "does not have a fill column")
  vt <- vt |> mutate(fill = "foo")
  expect_no_error(ensure_fill(vt))
  expect_error(ensure_fill(vt, color=TRUE), "does not have a color column")
  expect_error(ensure_fill(1L), "is not a vtree object")

  expect_error(ensure_node_cols(vt, "foo"),
               "Argument `vt` is missing required node columns: foo")
  expect_no_error(ensure_node_cols(vt, "n"))
  expect_error(ensure_edge_cols(vt, "foo"),
               "Argument `vt` is missing required edge columns: foo")
  expect_no_error(ensure_edge_cols(vt, "from"))

})

test_that("methods throw errors for non-vtree objects", {
  expect_error(vtree(1), "is not a data frame")
  expect_error(pattern(1), "is not a vtree object")
  expect_error(vtree_palette(1), "is not a vtree object")
  expect_error(add_aliases(1), "is not a vtree object")
  expect_error(add_layout(1), "is not a vtree object")
  expect_error(add_labels(1), "is not a vtree object")
  expect_error(add_palette(1), "is not a vtree object")
  expect_error(plot_vtree(1), "is not a vtree object")
  expect_error(as_vtree_layout(1, 1, 1), "is not a vtree object")
  expect_error(summarize_by_node(1, 1, 1), "is not a data frame")
  expect_error(summarize_by_node(mtcars, 1, 1), "is not a vtree object")
  expect_error(vtree_apply(1, 1, 1), "is not a data frame")
  expect_error(vtree_apply(mtcars, 1, 1), "is not a vtree object")
  expect_error(fmt_label(1), "is not a data frame")
})
