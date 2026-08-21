test_that("layout functions work", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)

  vtl <- add_layout(vt, layout = "regular")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))
  at <- attributes(vtl)
  expect_true(!is.null(at$show_root))
  expect_true(!is.null(at$dir))
  expect_equal(at$dir, "lr")
  expect_true(at$show_root)
  expect_equal(attr(vtl, "layout_arg"), "regular")

  expect_no_error(vtl <- add_layout(vt, layout_func = layout_regular))
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))
  expect_equal(attr(vtl, "layout_arg"), "custom")

  vtl <- add_layout(vt, show_root = FALSE)
  at <- attributes(vtl)
  expect_false(at$show_root)

  vtl <- add_layout(vt, dir = "tb")
  at <- attributes(vtl)
  expect_equal(at$dir, "tb")

  vtl <- add_layout(vt, show_root = FALSE)
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))

  vtl <- add_layout(vt, layout = "proportional")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))
  expect_equal(attr(vtl, "layout_arg"), "proportional")

  vtl <- add_layout(vt, layout = "flushed_left")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))

  vtl <- add_layout(vt, layout = "flushed_right")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))

  expect_error(add_layout(vt, layout = "tight"), "tight layout requires labels")
  vtl <- add_labels(vt) |> add_layout(layout = "tight")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))

  vtl <- add_layout(vt,
                    varspace=c(root=3, Class = 2, Sex = 1))
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))

  nd <- as_tibble(vtl)
  w1 <- nd$full_w[nd$node_col == "root"]
  w2 <- nd$full_w[nd$node_col == "Class"][1]
  w3 <- nd$full_w[nd$node_col == "Sex"][1]

  expect_true(abs(w2/w1 - 2/3) < 1e-6)
  expect_true(abs(w3/w2 - 1/2) < 1e-6)
})

test_that("errors are raised", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)

  expect_error(add_layout(vt, varspace=NA),
               "varspace lacks required names:")
  expect_error(add_layout(vt, varspace=c(root="10", Class = "10", Sex = "5")),
               "varspace argument must be numeric")
  expect_error(add_layout(vt, varsize=NA),
               "varsize lacks required names:")
  expect_error(add_layout(vt, varsize=c(root=10, Class = 10, Sex = 5)),
               "varsize must be less than or equal to 1")
  expect_error(plot(add_layout(vt), dir="tb"),
               "vtree has a precomputed layout with direction 'lr'")
  expect_warning(plot(add_layout(vt), lwidth=.5),
               "vtree already has a layout")

  vtl <- add_layout(vt)
  attr(vtl, "dir") <- NULL
  expect_error(plot(vtl), "cannot determine direction")
})

test_that("precomputed layouts work with plots", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)

  vt <- add_layout(vt, layout = "regular")
  expect_no_error(plot(vt))
  vt <- add_layout(vt, layout = "proportional")
  expect_no_error(plot(vt))
  vt <- add_layout(vt, layout = "flushed_left")
  expect_no_error(plot(vt))
  vt <- add_layout(vt, layout = "flushed_right")
  expect_no_error(plot(vt))
})

test_that(".ensure_layout_cols works", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)

  expect_error(.ensure_layout_cols(vt),
               "layout is missing required node columns")
  vt <- vt |>
    mutate(x = 0, y = 0, width = 1, height = 1)

  expect_error(.ensure_layout_cols(vt),
               "layout is missing required edge columns")
  vt <- vt |>
    mutate(x1 = 0, y1 = 0, x2 = 1, y2 = 1, .edges = TRUE)
  expect_no_error(vte <- .ensure_layout_cols(vt))

  expect_in(c("full_w", "full_h", "shape"), nodecols(vte))
  expect_in(c("width", "height"), edgecols(vte))

})
