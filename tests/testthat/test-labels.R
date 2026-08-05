vt <- vtree_from_freqtable(Titanic, Class, Sex, Age, Survived)
vtNA <- vtree(titanicNA, Class, Sex, Survived)

nodes <- vt |> as_tibble()

test_that("Adding labels works", {

  vt2 <- add_labels(vt, fmt=node_col)
  nd2 <- as_tibble(vt2)
  expect_in("label", names(nd2))
  expect_all_true(nd2$node_col == nd2$label)

  vt3 <- add_labels(vt)
  nd3 <- as_tibble(vt3)
  expect_in("label", names(nd3))
  expect_all_true(nd3$label[-1] ==
                  sprintf("%s\n%d (%.0f%%)", 
                          nd3$node_val,
                          nd3$n,
                          nd3$freq * 100)[-1])
  vt4 <- add_labels(vtNA, fmt_na=paste0(node_col, " IS MISSING"))
  nd4 <- as_tibble(vt4)
  expect_in("label", names(nd4))
  nas <- is.na(nd4$node_val)
  expect_all_true(nd4$label[nas] ==
                 paste0(nd4$node_col[nas], " IS MISSING"))
})

test_that("Aliases work", {

  expect_null(attr(vt, "alias"))

  vt2 <- add_aliases(vt)
  alias2 <- attr(vt2, "alias")
  expect_type(alias2, "list")
  expect_setequal(names(alias2), c("col", "val"))
  expect_setequal(names(alias2$col), c("root", names(vt2)))
  nd2 <- as_tibble(vt2)
  expect_in(c("col_alias", "val_alias"), names(nd2))


  vt3 <- add_aliases(vt, col_alias = list(Class = "Klass"),
                     val_alias = list(Class = c("1st" = "First")))
  alias3 <- attr(vt3, "alias")
  expect_type(alias3, "list")
  expect_setequal(names(alias3), c("col", "val"))
  expect_setequal(names(alias3$col), c("root", names(vt3)))
  nd3 <- as_tibble(vt3)
  expect_in(c("col_alias", "val_alias"), names(nd3))
  expect_all_equal(nd3$col_alias[ nd3$node_col == "Class" ], "Klass")
  expect_all_equal(nd3$val_alias[ nd3$node_col == "Class" 
                                & !is.na(nd3$node_val) 
                                & nd3$node_val == "1st" ], "First")

  vt4 <- add_labels(vt3)
  nd4 <- as_tibble(vt4)
  expect_in("label", names(nd4))
  expect_all_true(nd4$label[-1] ==
                  sprintf("%s\n%d (%.0f%%)", 
                          nd4$val_alias,
                          nd4$n,
                          nd4$freq * 100)[-1])
})
