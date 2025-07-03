library(tinytest)

if (!requireNamespace("terra") ||
    as.logical(Sys.getenv("R_RDSHUB_RUN_LONG_EXAMPLES", unset = "FALSE"))) {
  exit_file("R_RDSHUB_RUN_LONG_EXAMPLES is FALSE")
}

# basic test
x <- dsh_soil_properties(
  variables = c("claytotal", "sandtotal", "silttotal", "drainagecl"),
  top_depth = 0,
  bottom_depth = c(0, 25, 200),
  aggregations = c("wtdavg", "domcond"),
  resolutions = c(30, 900)
)

vars <- x |>
  terra::metags(seq_len(terra::nlyr(x))) |>
  subset(name == "variable")

tops <- x |>
  terra::metags(seq_len(terra::nlyr(x))) |>
  subset(name == "top")

bots <- x |>
  terra::metags(seq_len(terra::nlyr(x))) |>
  subset(name == "bottom")

names(x) <- paste0(vars$value, "_", tops$value, "to", bots$value)

expect_equal(terra::nlyr(x), 7L)
expect_true(all(grepl("^[a-z]+_0to\\d+$", names(x))))
