vt <- vtree_from_freqtable(Titanic, "Class", "Sex", "Survived")

test_that("adding palettes works", {

  vtp <- add_palette(vt)
  nd <- as_tibble(vtp)

  expect_in(c("fill", "color"), nodecols(vtp))
  expect_in(nd$color, c("black", "white"))

  pal <- attr(vtp, "palette")
  expect_true(!is.null(pal))
  expect_in(c("fill", "color"), names(pal))
  expect_in(names(vtp), names(pal$fill))
  expect_in(names(vtp), names(pal$color))
  expect_in(unlist(pal$color), c("black", "white"))

  expect_setequal(nd$fill, c("white", unlist(pal$fill)))

  vtp <- add_palette(vt, what="color")
  nd <- as_tibble(vtp)
  expect_in(nd$fill, c("black", "white"))
  pal <- attr(vtp, "palette")
  expect_in(unlist(pal$fill), c("black", "white"))
  expect_setequal(nd$color, c("white", unlist(pal$color)))

  vtp <- add_palette(vt, var_palette= 
                     list(Class = c("1st" = "red", "2nd" = "blue",
                                    "3rd" = "green", "Crew" = "yellow")))
  nd <- as_tibble(vtp)
  expect_in(nd$color, c("black", "white"))
  expect_setequal(nd$fill[nd$node_col == "Class"],
                  c("red", "blue", "green", "yellow"))
  pal <- attr(vtp, "palette")
  expect_setequal(pal$fill$Class, c("red", "blue", "green", "yellow"))
  expect_setequal(pal$color$Class, c("black", "white"))

  vtp <- add_palette(vt, what="color", var_palette= 
                     list(Class = c("1st" = "red", "2nd" = "blue",
                                    "3rd" = "green", "Crew" = "yellow")))
  nd <- as_tibble(vtp)
  expect_in(nd$fill, c("black", "white"))
  expect_setequal(nd$color[nd$node_col == "Class"],
                  c("red", "blue", "green", "yellow"))
  pal <- attr(vtp, "palette")
  expect_setequal(pal$color$Class, c("red", "blue", "green", "yellow"))
  expect_setequal(pal$fill$Class, c("black", "white"))
})

test_that("edge cases work", {

  vtp <- add_palette(vt)
  attr(vtp, "palette") <- NULL

  expect_message(plot(vtp), "palette attribute is NULL")
  expect_message(plot(vtp, legend=TRUE), "palette attribute is NULL")
  expect_no_message(plot(vtp, legend_tiny = FALSE))

  vtp <- add_palette(vt)
  attr(vtp, "palette")$fill <- NULL
  expect_no_error(plot(vtp, legend = TRUE))
  attr(vtp, "palette")$color <- NULL
  expect_no_error(plot(vtp, legend = TRUE))
  attr(vtp, "palette")$vars <- NULL
  expect_no_error(plot(vtp, legend = TRUE))
})

test_that("plotting works without a palette assigned", {    
  vt_na <- vtree(titanicNA, Class, Sex, Survived)
  vt2 <- vt_na |> add_labels() |>
  mutate(label = ifelse(path == "Class:1st", "First class", label)) |>
  mutate(fill = ifelse(path == "Class:1st", "red", "white"))

  expect_message(plot(vt2), "palette attribute is NULL")

  vt2 <- vt |> prune(path == "Class:2nd/Sex:NA", mark_only=TRUE) |>
  mutate(fill = ifelse(!mark, "white", "red"))
  
  expect_message(plot(vt2), "palette attribute is NULL")
})


