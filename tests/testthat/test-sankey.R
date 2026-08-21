test_that("Sankey plots work", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)

  sk <- sankey(vt)
  nd <- as_tibble(sk)

  expect_equal(nrow(nd), 7)
  eg <- as_tibble(activate(sk, "edges"))
  expect_equal(nrow(eg), 12)

  skl <- add_layout(vt, layout = "sankey")
  expect_all_true(c("x", "y", "full_w", "full_h", "width", "height")
                  %in% nodecols(skl))

  nd <- as_tibble(skl)
  eg <- as_tibble(activate(skl, "edges"))

  expect_all_true(nd$x >= 0 & nd$x <= 1)
  expect_all_true(nd$y >= 0 & nd$y <= 1)
  expect_all_true(eg$x1 >= 0 & eg$x1 <= 1)
  expect_all_true(eg$y1 >= 0 & eg$y1 <= 1)
  expect_all_true(eg$x2 >= 0 & eg$x2 <= 1)
  expect_all_true(eg$y2 >= 0 & eg$y2 <= 1)

  expect_no_error(plot(sk))
  expect_no_error(plot(sk, dir="tb"))

})

test_that("Sankey layout works", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  expect_no_error(add_layout(vt, layout = "sankey"))
  vt <- add_palette(vt)
  expect_no_error(vtl <- add_layout(vt, layout = "sankey"))
  nd <- as_tibble(vtl)

  expect_in(c("x", "y", "full_w", "full_h", "width", "height"),
            nodecols(vtl))
  eg <- activate(vtl, "edges") |> as_tibble()
  expect_in(c("x1", "y1", "x2", "y2", "height", "width"), colnames(eg))
})
