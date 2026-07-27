test_that("plotting works", {

  vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")
  p1 <- expect_no_error(plot(vt))
  expect_s3_class(p1, "vtree_plot")
  expect_s3_class(p1, "gTree")

  expect_no_error(plot(vt, dir = "bt"))
  expect_no_error(plot(vt, dir = "tb"))
  expect_no_error(plot(vt, dir = "rl"))
  expect_no_error(plot(vt, layout = "proportional"))
  expect_no_error(plot(vt, layout = "proportional", dir = "bt"))
  expect_no_error(plot(vt, layout = "proportional", dir = "tb"))
  expect_no_error(plot(vt, layout = "proportional", dir = "rl"))
  expect_no_error(plot(vt, lfontsize = 11))
  expect_no_error(plot(vt, lheight = .1))
  expect_no_error(plot(vt, lwidth = .1))
  expect_no_error(plot(vt, lwidth = .1, layout = "proportional"))
  expect_no_error(plot(vt, show_root = FALSE))
  expect_no_error(plot(vt, var_labels = FALSE))
})

test_that("ggplot plotting works", {

  vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")
  p1 <- expect_no_error(plot_ggplot(vt))
  expect_s3_class(p1, "ggplot")

  expect_no_error(plot_ggplot(vt, dir = "bt"))
  expect_no_error(plot_ggplot(vt, dir = "tb"))
  expect_no_error(plot_ggplot(vt, dir = "rl"))
  expect_no_error(plot_ggplot(vt, layout = "proportional"))
  expect_no_error(plot_ggplot(vt, layout = "proportional", dir = "bt"))
  expect_no_error(plot_ggplot(vt, layout = "proportional", dir = "tb"))
  expect_no_error(plot_ggplot(vt, layout = "proportional", dir = "rl"))
  expect_no_error(plot_ggplot(vt, lfontsize = 11))
  expect_no_error(plot_ggplot(vt, lheight = .1))
  expect_no_error(plot_ggplot(vt, lwidth = .1))
  expect_no_error(plot_ggplot(vt, lwidth = .1, layout = "proportional"))
  expect_no_error(plot_ggplot(vt, show_root = FALSE))
  expect_no_error(plot_ggplot(vt, var_labels = FALSE))
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
