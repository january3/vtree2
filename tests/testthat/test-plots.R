test_that("plotting works", {

  vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")
  p1 <- expect_no_error(plot(vt))
  expect_s3_class(p1, "gg")
  p1 <- ggplot2::ggplot_build(p1)

  expect_equal(length(p1@data), 3)

  expect_no_error(plot(vt, dir = "bt"))
  expect_no_error(plot(vt, dir = "tb"))
  expect_no_error(plot(vt, dir = "rl"))
  expect_no_error(plot(vt, proportional = TRUE))
  expect_no_error(plot(vt, proportional = TRUE, dir = "bt"))
  expect_no_error(plot(vt, proportional = TRUE, dir = "tb"))
  expect_no_error(plot(vt, proportional = TRUE, dir = "rl"))
  expect_no_error(plot(vt, lfontsize = 11))
  expect_no_error(plot(vt, lheight = .1))
  expect_no_error(plot(vt, lwidth = .1))
  expect_no_error(plot(vt, lwidth = .1, proportional = TRUE))
  expect_no_error(plot(vt, legend=TRUE))
  expect_no_error(plot(vt, legend=TRUE, proportional = TRUE))
})


test_that("adding labels works", {
  vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")

  nodes <- vt |> add_labels() |> as_tibble()
  expect_in("label", colnames(nodes))

  nodes <- vt |> add_labels(template = "long") |> as_tibble()
  expect_in("label", colnames(nodes))

  nodes <- vt |> add_labels(fmt = "foo", fmt_na = "foo") |> as_tibble()
  expect_true(all(nodes$label == "foo"))
})

