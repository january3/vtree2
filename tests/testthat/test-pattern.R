test_that("pattern creates one row per leaf path", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  pat <- pattern(vt)

  expect_s3_class(pat, "vtree_pattern")
  expect_equal(attr(pat, "cols"), c("Class", "Sex"))
  expect_equal(attr(pat, "N"), 2201)
  expect_true(attr(pat, "vp"))

  expect_equal(nrow(pat), 8)
  expect_in(c("path", "node_id",
              "Class", "Class_n", "Class_freq", "Class_tot_n",
              "Class_missing", "Class_denom",
              "Sex", "Sex_n", "Sex_freq", "Sex_tot_n",
              "Sex_missing", "Sex_denom"), colnames(pat))

  first <- pat[1, ]
  expect_equal(as.character(first$Class), "1st")
  expect_equal(first$Class_n, 325)
  expect_equal(as.character(first$Sex), "Male")
  expect_equal(first$Sex_n, 180)
  expect_equal(first$Sex_freq, 180 / 325)
})



test_that("print.vtree_pattern returns the input invisibly", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  pat <- pattern(vt)

  printed <- capture.output(ret <- print(pat))

  expect_match(printed[1], "vtree pattern object", fixed = TRUE)
  expect_identical(ret, pat)
})

test_that("plotting vtree patterns works", {
  vt <- vtree_from_freqtable(Titanic, Class, Sex)
  pat <- pattern(vt)
  expect_no_error(plot(pat))
  expect_no_error(plot(pat, dir="tb"))
  expect_no_error(plot(pat, pattern_fill = "white"))
  #expect_error(plot(pat, layout = "proportional"))
  expect_error(plot(pat, show_tree = TRUE))
  expect_no_error(plot(pat, legend = TRUE))

})
