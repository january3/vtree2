## code to prepare `titanicNA` dataset

set.seed(123)
# create a new data set with NAs
titanicNA <- cases_from_freqtable(Titanic) |>
  # change all classes to character
  mutate(across(everything(), as.character)) |>
  # add some random NAs to each column
  mutate(Class = ifelse(runif(n()) < 0.1, NA, Class)) |>
  mutate(Sex = ifelse(runif(n()) < 0.1, NA, Sex)) |>
  mutate(Age = ifelse(runif(n()) < 0.1, NA, Age))

usethis::use_data(titanicNA, overwrite = TRUE)
