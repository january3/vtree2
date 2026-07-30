
vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")
vt_na <- vtree(titanicNA, Class, Sex, Survived)

test_that("add_labels works", {
  vt1 <- add_labels(vt)
  expect_s3_class(vt1, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt1)))
  expect_equal(sum(is.na(as_tibble(vt1)$label)), 0)
  expect_snapshot(as_tibble(vt1)$label)

  vt2 <- add_labels(vt, template = "long")
  expect_s3_class(vt2, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt2)))
  expect_equal(sum(is.na(as_tibble(vt2)$label)), 0)
  expect_snapshot(as_tibble(vt2)$label)

  vt3 <- add_labels(vt, fmt = "foo", fmt_na = "bar")
  expect_s3_class(vt3, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt3)))
  expect_equal(sum(is.na(as_tibble(vt3)$label)), 0)
  expect_equal(unique(as_tibble(vt3)$label), "foo")

  vt4 <- add_labels(vt_na)
  expect_s3_class(vt4, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt3)))
  expect_equal(sum(is.na(as_tibble(vt4)$label)), 0)
  expect_snapshot(as_tibble(vt4)$label)

  vt5 <- add_labels(vt_na, fmt = "foo", fmt_na = "bar")
  expect_s3_class(vt5, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt5)))
  expect_equal(sum(is.na(as_tibble(vt5)$label)), 0)
  expect_setequal(as_tibble(vt5)$label, c("foo", "bar"))

})

test_that("plotting works", {

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
  expect_no_error(plot(vt, layout = "flushed"))
  expect_no_error(plot(vt, layout = "flushed", dir = "bt"))
  expect_no_error(plot(vt, layout = "flushed", dir = "tb"))
  expect_no_error(plot(vt, layout = "flushed", dir = "rl"))
  expect_no_error(plot(vt, lheight = .1))
  expect_no_error(plot(vt, lwidth = .1))
  expect_no_error(plot(vt, lwidth = .1, layout = "proportional"))
  expect_no_error(plot(vt, lwidth = .1, layout = "flushed"))
  expect_no_error(plot(vt, show_root = FALSE))
  expect_no_error(plot(vt, var_labels = FALSE))
  expect_no_error(plot(vt, fontsizes = list(nodes=9, var_labels=10,
                                            legend_labels=11)))
  expect_no_error(plot(vt, fontsizes = list(nodes="adaptive", var_labels=10,
                                            legend_labels="adaptive")))
})

test_that("var_labels argument works", {

  expect_no_error(plot(vt, var_labels=FALSE))
  expect_no_error(plot(vt, var_labels=NULL))
  expect_no_error(plot(vt, var_labels=
                       c(Class="C",
                         Sex="G",
                         Survived="S")))

  expect_error(plot(vt, var_labels=c(foo="bar")),
    "var_labels is missing names for variables: Class, Sex, and Survived")

})

test_that("ggplot plotting works", {

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
