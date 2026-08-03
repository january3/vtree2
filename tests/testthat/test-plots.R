
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

test_that("plotting works without a palette assigned", {    
  vt2 <- vt_na |> add_labels() |>
  mutate(label = ifelse(path == "Class:1st", "First class", label)) |>
  mutate(fill = ifelse(path == "Class:1st", "red", "white"))

  expect_no_error(plot(vt2))

  vt2 <- vt |> prune(path == "Class:2nd/Sex:NA", mark_only=TRUE) |>
  mutate(fill = ifelse(!mark, "white", "red"))
  
  expect_no_error(plot(vt2))
})

    
test_that("plot returns a gTree object", {
  p1 <- plot(vt)
  expect_s3_class(p1, "vtree_plot")
  expect_s3_class(p1, "gTree")

  expect_setequal(c("edges", "nodes", "legend"), names(p1$children))
  expect_named(p1$children$legend$children, c("titles"))

  expect_named(p1$children$nodes$children, c("rect", "text"))
  expect_true("spec_fontsize" %in% names(p1$params))
  expect_true("labels" %in% names(p1$params$spec_fontsize))

  p2 <- plot(vt, legend = TRUE)
  expect_s3_class(p2, "vtree_plot")
  expect_s3_class(p2, "gTree")
  expect_setequal(c("edges", "nodes", "legend"), names(p2$children))
  expect_setequal(names(p2$children$legend$children), c("titles", "levels"))

  p3 <- plot(vt, var_labels = FALSE)
  expect_setequal(c("edges", "nodes"), names(p3$children))
})
    
test_that("plot creates normalized layout columns", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  p <- plot(vt, layout = "regular")

  nodes <- as_tibble(p$layout)
  edges <- activate(p$layout, "edges") |> as_tibble()

  expect_true(all(c("x", "y", "width", "height") %in% names(nodes)))
  expect_true(all(c("x1", "y1", "x2", "y2") %in% names(edges)))

  expect_true(all(!is.na(nodes$x)))
  expect_true(all(!is.na(nodes$y)))
})


test_that("plotting works (smoke tests)", {

  expect_no_error(plot(vt))
  expect_no_error(plot(vt, legend=TRUE))
  expect_no_error(plot(vt, dir = "bt"))
  expect_no_error(plot(vt, dir = "bt", legend=TRUE))
  expect_no_error(plot(vt, dir = "tb"))
  expect_no_error(plot(vt, dir = "tb", legend=TRUE))
  expect_no_error(plot(vt, dir = "rl"))
  expect_no_error(plot(vt, dir = "rl", legend=TRUE))
  expect_no_error(plot(vt, layout = "proportional"))
  expect_no_error(plot(vt, layout = "proportional", show_root = FALSE))
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

  expect_no_error(plot(vt, var_labels=c(Sex="S")))
  expect_error(plot(vt, var_labels=c(foo="bar")),
    "incorrect var_labels - no such variable\\(s\\): foo")

})

test_that("plot preserves user-provided labels and colors", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex) |>
    mutate(label = paste0("node-", node_id),
      fill = "pink",
      color = "blue")

  p <- plot(vt)
  nodes <- as_tibble(p$layout)

  expect_equal(nodes$label, paste0("node-", nodes$node_id))
  expect_equal(unique(nodes$fill), "pink")
  expect_equal(unique(nodes$color), "blue")

  # check that the grobs preserve the user-provided labels and colors
  labels <- sapply(p$children$nodes$children$text$children, \(x) x$label)
  expect_all_true(nodes$label == labels)
  colors <- sapply(p$children$nodes$children$text$children, \(x) x$gp$col)
  expect_all_equal(colors, "blue")
  fills <- sapply(p$children$nodes$children$rect$children, \(x) x$gp$fill)
  expect_all_equal(fills, "pink")
})

test_that("makeContent applies fixed font size to node labels", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  p <- plot(vt, fontsizes = list(nodes = 8), var_labels = FALSE)

  p2 <- grid::makeContent(p)

  labels <- grid::getGrob(p2, grid::gPath("nodes", "text"))$children
  sizes <- sapply(labels, \(g) g$gp$fontsize)

  expect_all_equal(sizes, 8)
})


test_that("precomputed layouts work", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  vt <- add_layout(vt, layout = "regular")
  expect_no_error(plot(vt))
  vt <- add_layout(vt, layout = "proportional")
  expect_no_error(plot(vt))
  vt <- add_layout(vt, layout = "flushed")
  expect_no_error(plot(vt))
})
