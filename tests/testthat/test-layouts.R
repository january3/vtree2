test_that("layout functions work", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)

  vt <- add_layout(vt, layout = "regular")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vt))

  vt <- add_layout(vt, layout = "proportional")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vt))

  vt <- add_layout(vt, layout = "flushed_left")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vt))

  vt <- add_layout(vt, layout = "flushed_right")
  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vt))

  expect_error(add_layout(vt, varspace=NA),
               "varspace lacks required names:")
  expect_error(add_layout(vt, varsize=NA),
               "varsize lacks required names:")
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
