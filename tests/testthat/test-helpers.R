test_that("dev helpers work", {
  vt <- vtree(titanicNA, Class, Sex)

  expect_no_error(foo <- v(vt))
  expect_s3_class(foo, "tbl_df")
  expect_all_true(colnames(foo) == nodecols(vt))

  expect_no_error(foo <- ve(vt))
  expect_s3_class(foo, "tbl_df")
  expect_all_true(colnames(foo) == edgecols(vt))

})
