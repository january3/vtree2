
vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")
vt_na <- vtree(titanicNA, Class, Sex, Survived)

test_that("margins work", {

  p <- plot(vt, margins = c(0.4, 0.4, 0.4, 0.4))
  expect_all_true(abs(unlist(p$params$mar) - 
                      c(0.4, 0.4, 0.4, 0.4)) < 1e-12)
  p <- plot(vt, margins = c(0.1, 0.2, 0.3, 0.4))
  expect_all_true(
        abs(unlist(p$params$mar[c("top", "right", "bottom", "left")]) - 
        c(0.1, 0.2, 0.3, 0.4)) < 1e-12)

  expect_error(plot(vt, margins = c(0.1, 0.2, 0.3)),
               "numeric vector with four elements")
  expect_error(plot(vt, margins = rep("foo", 4)),
               "numeric vector with four elements")
  expect_error(plot(vt, margins = 1:4),
               "all margins must be values in the range \\[0,1\\]")

})

    
test_that("plot returns a gTree object", {
  p1 <- plot(vt)
  expect_s3_class(p1, "vtree_plot")
  expect_s3_class(p1, "gTree")

  expect_setequal(c("edges", "nodes", "legend"), names(p1$children))
  expect_named(p1$children$legend$children, c("titles"))

  expect_named(p1$children$nodes$children, c("rect", "text"))
  expect_true("spec" %in% names(p1$params))
  expect_true("fs" %in% names(p1$params$spec))
  expect_true("lwd" %in% names(p1$params$spec))
  expect_true("labels" %in% names(p1$params$spec$fs))

  p2 <- plot(vt, legend = TRUE)
  expect_s3_class(p2, "vtree_plot")
  expect_s3_class(p2, "gTree")
  expect_setequal(c("edges", "nodes", "legend"), names(p2$children))
  expect_setequal(names(p2$children$legend$children), c("titles", "levels"))

  p3 <- plot(vt, legend_tiny = FALSE)
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
  expect_no_error(plot(vt, layout = "flushed_right"))
  expect_no_error(plot(vt, layout = "flushed_right", dir = "bt"))
  expect_no_error(plot(vt, layout = "flushed_right", dir = "tb"))
  expect_no_error(plot(vt, layout = "flushed_right", dir = "rl"))
  expect_no_error(plot(vt, layout = "flushed_left"))
  expect_no_error(plot(vt, layout = "flushed_left", dir = "bt"))
  expect_no_error(plot(vt, layout = "flushed_left", dir = "tb"))
  expect_no_error(plot(vt, layout = "flushed_left", dir = "rl"))
  expect_no_error(plot(vt, lheight = .1))
  expect_no_error(plot(vt, lwidth = .1))
  expect_no_error(plot(vt, lwidth = .1, layout = "proportional"))
  expect_no_error(plot(vt, lwidth = .1, layout = "flushed_left"))
  expect_no_error(plot(vt, lwidth = .1, layout = "flushed_right"))
  expect_no_error(plot(vt, show_root = FALSE))
  expect_no_error(plot(vt, legend_tiny = FALSE))
  expect_no_error(plot(vt, fontsizes = list(nodes=9, var_labels=10,
                                            legend_labels=11)))
  expect_no_error(plot(vt, fontsizes = list(nodes="adaptive", var_labels=10,
                                            legend_labels="adaptive")))
  vt2 <- vtree(titanicNA)
  expect_no_error(plot(vt2))
  expect_no_error(plot(vt2, legend=TRUE))
})

test_that("plotting with richtext=TRUE works (smoke tests)", {
  vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")

  tempfile <- tempfile(fileext = ".pdf")
  dev.new <- grDevices::pdf(tempfile, width=5, height=5)
  expect_no_error(plot(vt, richtext=TRUE))
  p <- plot(vt, richtext=TRUE)
  cl <- unlist(map(p$children$nodes$children$text$children, \(x) class(x)[1]))
  expect_all_equal(cl, "richtext_grob")

  expect_no_error(plot(vt, layout="proportional", richtext=TRUE))
  vt2 <- vt |> mutate(label = paste0("**node-<sup>", node_id, "</sup>**"))
  expect_no_error(plot(vt2, richtext=TRUE))
  expect_no_error(plot(vt2, richtext=TRUE, legend = TRUE))
  expect_no_error(plot(vt2, layout="proportional", richtext=TRUE))
  dev.off()
})

test_that("plot preserves user-provided labels and colors", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex) |>
    mutate(label = paste0("node-", node_id),
      fill = "pink",
      color = "blue")

  p <- plot(vt, legend_tiny = FALSE)
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

  tmpfile <- tempfile(fileext = ".pdf")
  dev.new <- grDevices::pdf(tmpfile, width=3, height=3)
  expect_no_error(plot(vt))
  expect_no_error(plot(vt, layout="proportional"))
  expect_no_error(plot(vt, fontsizes = list(nodes = "adaptive")))
  expect_no_error(plot(vt, richtext = TRUE))

  # on a small device, fontsizes should decrease
  p <- plot(vt, fontsizes = list(nodes = "adaptive"),
            show_root = FALSE,
            legend_tiny = FALSE)
  fs <- unlist(map(p$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  p2 <- grid::makeContent(p)
  fs2 <- unlist(map(p2$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  expect_all_true(fs2 < fs)

  p <- plot(vt, fontsizes = list(nodes = "fixed"),
            show_root = FALSE,
            legend_tiny = FALSE)
  fs <- unlist(map(p$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  p2 <- grid::makeContent(p)
  fs2 <- unlist(map(p2$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  expect_all_true(fs2 < fs)
  expect_length(unique(fs2), 1)
  dev.off()

  # on a large device, fontsizes should increase
  dev.new <- grDevices::pdf(tmpfile, width=12, height=12)
  p <- plot(vt, fontsizes = list(nodes = "adaptive"),
            show_root = FALSE,
            legend_tiny = FALSE)
  fs <- unlist(map(p$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  p2 <- grid::makeContent(p)
  fs2 <- unlist(map(p2$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  expect_all_true(fs2 > fs)

  p <- plot(vt, fontsizes = list(nodes = "fixed"),
            show_root = FALSE,
            legend_tiny = FALSE)
  fs <- unlist(map(p$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  p2 <- grid::makeContent(p)
  fs2 <- unlist(map(p2$children$nodes$children$text$children,
                   \(x) x$gp$fontsize))
  expect_all_true(fs2 > fs)
  expect_length(unique(fs2), 1)
  dev.off()

  dev.new <- grDevices::pdf(tmpfile, width=5, height=5)
  # fontsizes set directly should not change
  p <- plot(vt, fontsizes = list(nodes = 8), legend_tiny = FALSE)

  p2 <- grid::makeContent(p)

  labels <- grid::getGrob(p2, grid::gPath("nodes", "text"))$children
  sizes <- sapply(labels, \(g) g$gp$fontsize)

  expect_all_equal(sizes, 8)
  dev.off()
})


test_that("grob injection works", {

  box <- grid::gTree(name = "test_box",
                     children = gList(
    grid::rectGrob(name = "test_rect",
                   x = .5, y = .5, width = 1, height = 1,
                   gp = grid::gpar(fill = "steelblue", col = NA)),
    grid::textGrob("Hello", name = "test_text", x = .5, y = .5,
                   gp = grid::gpar(col = "white", fontsize = 32))
  ))


  #grid.draw(box)

  vt <- vtree_from_freqtable(Titanic, Class, Sex) |>
    mutate(grob = NA) |>
    mark(path == "Class:1st/Sex:Female") |>
    mutate(grob = ifelse(mark, list(box), grob))

  p <- plot(vt)

  tempfile <- tempfile(fileext = ".pdf")
  dev.new <- grDevices::pdf(tempfile, width=5, height=5)
  expect_no_error(grid.draw(p))
  expect_no_error(print(p))
  dev.off()

  expect_in("plots", names(p$children))
  plots <- p$children$plots
  expect_in("plot_obj", names(plots$children))
  expect_in("test_box", names(plots$children$plot_obj$children))
  tb <- plots$children$plot_obj$children$test_box
  expect_in(c("test_rect", "test_text"), names(tb$children))
  expect_equal(tb$children$test_text$label, "Hello")

  vt <- vtree_from_freqtable(Titanic, Class, Sex) |>
    mutate(grob = NA) |>
    mark(leaf) |>
    mutate(grob = ifelse(mark, list(box), grob))

  p <- plot(vt)

  tempfile <- tempfile(fileext = ".pdf")
  dev.new <- grDevices::pdf(tempfile, width=5, height=5)
  expect_no_error(grid.draw(p))
  expect_no_error(print(p))
  dev.off()

  expect_in("plots", names(p$children))
  plots <- p$children$plots
  expect_in("plot_obj", names(plots$children))
  expect_setequal(paste0("grob_node_", 6:13),
                  names(plots$children$plot_obj$children))
  tb <- plots$children$plot_obj$children$grob_node_6
  expect_in(c("test_rect", "test_text"), names(tb$children))
  expect_equal(tb$children$test_text$label, "Hello")
})
