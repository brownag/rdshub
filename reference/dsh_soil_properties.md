# 'Dynamic Soils Hub' Soil Property Grids

Create a 'terra' *SpatRaster* object referencing soil property grids
from the ['Dynamic Soils Hub' Public S3
bucket](https://s3-fpac-nrcs-dshub-public.s3.us-east-1.amazonaws.com/SoilProperties/_README.txt)

## Usage

``` r
dsh_soil_properties(
  x = NULL,
  variables = NULL,
  resolutions = NULL,
  aggregations = NULL,
  top_depth = 0,
  bottom_depth = 200,
  region = "conus",
  subregion = "conus",
  filename = NULL,
  overwrite = FALSE,
  vrt = FALSE,
  ...
)
```

## Arguments

- x:

  An R spatial object (such as a *SpatVector*, *SpatRaster*, or *sf*
  object). Default: `NULL` returns a virtual raster. If `x` is a
  *SpatRaster* the coordinate reference system, extent, and resolution
  are used as a template for the output raster.

- variables:

  *character*. One or more variables corresponding to grid file names
  (without .tif extension). See
  <https://s3-fpac-nrcs-dshub-public.s3.us-east-1.amazonaws.com/SoilProperties/_README.txt>
  for details.

- resolutions:

  integer. One or more of: `30`, `900`. Use `NULL` for no filter on
  resolution.

- aggregations:

  *character*. One or more of: `"domcond"`, `"wtdavg"`, `"minmax"`. Use
  `NULL` for no filter on aggregation method.

- top_depth:

  integer. Top depth. Default: `0` (includes all grids that have no
  depth)

- bottom_depth:

  integer. Bottom depth. Default: `200`

- region:

  *character*. One or more of: `"conus"`, `"oconus"`. Use `NULL` for no
  filter on location.

- subregion:

  *character*. One or more of: `"conus"`, `"pr"`, `"ak"`, `"as"`,
  `"fm"`, `"gu"`, `"hi"`, `"mh"`, `"mp"`, `"pw"`

- filename:

  character. Path to write output raster file. Default: `NULL` will keep
  result in memory (or store in temporary file if memory threshold is
  exceeded)

- overwrite:

  logical. Overwrite `filename` if it exists? Default: `FALSE`

- vrt:

  logical. Use
  [`terra::vrt()`](https://rspatial.github.io/terra/reference/vrt.html)
  for result SpatRaster? Default: `FALSE`

- ...:

  Additional arguments passed to
  [`writeRaster()`](https://rspatial.github.io/terra/reference/writeRaster.html)
  via
  [`terra::crop()`](https://rspatial.github.io/terra/reference/crop.html)
  or
  [`terra::project()`](https://rspatial.github.io/terra/reference/project.html).
  Ignored when `x` is `NULL`.

## Value

A *SpatRaster* object.

## Examples

``` r
if (FALSE) { # requireNamespace("terra") && as.logical(Sys.getenv("R_RDSHUB_RUN_LONG_EXAMPLES", unset = "FALSE"))
library(rdshub)
library(terra)

x <- dsh_soil_properties(
  # variables = c("claytotal", "sandtotal", "silttotal", "drainagecl"),
  top_depth = 0,
  bottom_depth = c(0, 200),
  aggregations = c("wtdavg", "domcond"),
  resolutions = 900
)

terra::sources(x)

terra::metags(x, layer = 1)

vars <- x |>
  terra::metags(seq_len(terra::nlyr(x))) |>
  subset(name == "variable")
names(x) <- vars$value

terra::plot(x)

terra::plot(x$sandtotal + x$claytotal + x$silttotal)

y <- dsh_soil_properties(variables = "mukey",
                         aggregation = "domcond",
                         bottom_depth = 0)
y
terra::plot(y[2])
}
```
