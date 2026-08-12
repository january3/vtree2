vt <- vtree_from_freqtable(Titanic, Class, Sex, Age, Survived)
vtNA <- vtree(titanicNA, Class, Sex, Survived)

nodes <- vt |> as_tibble()

test_that("Adding labels works", {

  vt2 <- add_labels(vt, fmt="{node_col}")
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
  vt4 <- add_labels(vtNA, fmt_na="{node_col} IS MISSING")
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

  vt4 <- add_labels(vtNA)
  expect_s3_class(vt4, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt3)))
  expect_equal(sum(is.na(as_tibble(vt4)$label)), 0)
  expect_snapshot(as_tibble(vt4)$label)

  vt5 <- add_labels(vtNA, fmt = "foo", fmt_na = "bar")
  expect_s3_class(vt5, "vtree")
  expect_true("label" %in% colnames(as_tibble(vt5)))
  expect_equal(sum(is.na(as_tibble(vt5)$label)), 0)
  expect_setequal(as_tibble(vt5)$label, c("foo", "bar"))

})

test_that("prefix/suffix works", {

  vt1 <- add_labels(vt)
  nd1 <- as_tibble(vt1)
  vt2 <- add_labels(vt, prefix = "PRE", suffix = "SUF")
  nd2 <- as_tibble(vt2)

  expect_all_true(nd2$label == paste0("PRE\n", nd1$label, "\nSUF"))

  vt2 <- add_labels(vt, prefix = "PRE", suffix = "SUF", sep="-")
  nd2 <- as_tibble(vt2)
  expect_all_true(nd2$label == paste0("PRE-", nd1$label, "-SUF"))
})


test_that("expr works", {
  vt1 <- add_labels(vt, expr = sprintf("%s\n%d (%.0f%%)", node_val, n, freq * 100))
  nd1 <- as_tibble(vt1)
  expect_all_true(nd1$label ==
                  sprintf("%s\n%d (%.0f%%)",
                          nd1$node_val,
                          nd1$n,
                          nd1$freq * 100))
})
