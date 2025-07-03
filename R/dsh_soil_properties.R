#' 'Dynamic Soils Hub' Soil Property Grids
#'
#' Create a 'terra' _SpatRaster_ object referencing soil property grids from the
#' ['Dynamic Soils Hub' Public S3 bucket](https://s3-fpac-nrcs-dshub-public.s3.us-gov-west-1.amazonaws.com/SoilProperties/_README.txt)
#'
#' @param x An R spatial object (such as a _SpatVector_, _SpatRaster_, or _sf_
#'   object). Default: `NULL` returns a virtual raster. If `x` is a _SpatRaster_
#'   the coordinate reference system, extent, and resolution are used as a
#'   template for the output raster.
#' @param variables _character_. One or more variables corresponding to grid file names
#' (without .tif extension). See
#' \url{https://s3-fpac-nrcs-dshub-public.s3.us-gov-west-1.amazonaws.com/SoilProperties/_README.txt}
#' for details.
#' @param resolutions integer. One or more of: `30`, `900`. Use `NULL` for no filter on
#'   resolution.
#' @param aggregations _character_. One or more of: `"domcond"`, `"wtdavg"`, `"minmax"`. Use
#'   `NULL` for no filter on aggregation method.
#' @param locations _character_. One or more of: `"conus"`, `"oconus"`. Use `NULL` for no
#'   filter on location.
#' @param territories _character_. One or more of: `"conus"`, `"pr"`, `"ak"`, `"as"`, `"fm"`,
#'  `"gu"`, `"hi"`, `"mh"`, `"mp"`, `"pw"`
#' @param filename character. Path to write output raster file. Default: `NULL`
#'   will keep result in memory (or store in temporary file if memory threshold
#'   is exceeded)
#' @param overwrite logical. Overwrite `filename` if it exists? Default: `FALSE`
#' @param ... Additional arguments passed to `writeRaster()` via `terra::crop()`
#'   or `terra::project()`. Ignored when `x` is `NULL`.
#' @param top_depth integer. Top depth. Default: `0` (includes all grids that have no depth)
#' @param bottom_depth integer. Bottom depth. Default: `200`
#' @param vrt logical. Use `terra::vrt()` for result SpatRaster? Default: `FALSE`
#'
#' @return A _SpatRaster_ object.
#' @export
#' @importFrom methods as
#' @importFrom terra ext rast sprc vrt metags metags<- depth depthUnit crop project relate
#' @examplesIf requireNamespace("terra") && as.logical(Sys.getenv("R_RDSHUB_RUN_LONG_EXAMPLES", unset = "FALSE"))
#' library(rdshub)
#' library(terra)
#'
#' x <- dsh_soil_properties(
#'   # variables = c("claytotal", "sandtotal", "silttotal", "drainagecl"),
#'   top_depth = 0,
#'   bottom_depth = c(0, 200),
#'   aggregations = c("wtdavg", "domcond"),
#'   resolutions = 900
#' )
#'
#' terra::sources(x)
#'
#' terra::metags(x, layer = 1)
#'
#' vars <- x |>
#'   terra::metags(seq_len(terra::nlyr(x))) |>
#'   subset(name == "variable")
#' names(x) <- vars$value
#'
#' terra::plot(x)
#'
#' terra::plot(x$sandtotal + x$claytotal + x$silttotal)
#'
#' y <- dsh_soil_properties(variables = "mukey",
#'                          aggregation = "domcond",
#'                          bottom_depth = 0)
#' y
#' terra::plot(y[2])
#'
dsh_soil_properties <-
  function(x = NULL,
           variables = NULL,
           resolutions = NULL,
           aggregations = NULL,
           top_depth = 0,
           bottom_depth = 200,
           locations = "conus",
           territories = "conus",
           filename = NULL,
           overwrite = FALSE,
           vrt = FALSE,
           ...) {

  ind <- .get_DSHUB_soil_properties_ssurgo_index()

  .subset_index <- function(x, y, n) {
    if (!is.null(y)) {
      x <- x[which(x[[n]] %in% tolower(trimws(y))), ]
    }
    x
  }

  # grid, method, and variable subsetting
  ind <- ind |>
    .subset_index(locations, "location") |>
    .subset_index(territories, "territory") |>
    .subset_index(aggregations, "aggregation") |>
    .subset_index(resolutions, "resolution") |>
    .subset_index(variables, "variable")

  # depth subsetting
  ind$top <- as.integer(ind$top)
  ind$bottom <- as.integer(ind$bottom)
  ind <- ind[which(ind$top %in% top_depth & ind$bottom %in% bottom_depth), ]

  funargs <- list()
  if (isTRUE(vrt)) {
    FUN <- terra::vrt
    if (!missing(vrt_separate) &&
        isTRUE(vrt_separate)) {
      funargs <- list(options = "-separate")
    }
  } else {
    if (length(unique(ind$resolution)) > 1) {
      FUN <- terra::sprc
    } else {
      FUN <- terra::rast
    }
  }

  r <- do.call(FUN, list(x = paste0("/vsicurl/", ind$url), funargs)) |>
    .dsh_raster_extent(x, filename = filename, overwrite = overwrite, ...)

  if (inherits(r, 'SpatRaster')) {
    n <- seq_len(terra::nlyr(r))
    terra::depthUnit(r) <- "cm"
    terra::depth(r) <- (as.integer(ind$top) + as.integer(ind$bottom)) / 2
    terra::metags(r, layer = n, domain = "depth") <- paste0("depth:bottom=", ind$bottom)
    terra::metags(r, layer = n, domain = "depth") <- paste0("depth:top=", ind$top)
    terra::metags(r, layer = n) <- "endpoint=SoilProperties"
    terra::metags(r, layer = n) <- paste0("variable=", ind$variable)
    terra::metags(r, layer = n) <- paste0("location=", ind$location)
    terra::metags(r, layer = n) <- paste0("territory=", ind$territory)
    terra::metags(r, layer = n) <- paste0("aggregation=", ind$aggregation)
    terra::metags(r, layer = n) <- paste0("version=", ind$version)
  }

  r
}

.get_DSHUB_soil_properties_ssurgo_index <-
  function(base_url = dsh_s3_base_url(),
           endpoint = "SoilProperties",
           index_file = "_index.txt") {

  # pkg_cache <- normalizePath(
  #   tools::R_user_dir("rdshub", which = "cache"),
  #   winslash = "/",
  #   mustWork = FALSE
  # )

  res <- try(readLines(url(file.path(base_url, endpoint, index_file, fsep = "/"))))

  if (inherits(res, "try-error")) {
    return(res)
  }

  urls <- res[grepl("\\.tif$", res)]
  df <- data.frame(url = urls, filename = basename(urls))

  dat <- as.data.frame(do.call("rbind", strsplit(gsub(
    "\\.tif$", "", df$filename
  ), "_")))

  colnames(dat) <- c(
    "location",
    "srs_id",
    "territory",
    "resolution",
    "version",
    "top",
    "bottom",
    "variable",
    "aggregation"
  )

  cbind(df, dat)
}

#' Crop or Warp a SpatRaster to Conform with a Spatial Object
#'
#' If `x` is a raster object, it is used as a template to warp `r` to match `x`.
#' Otherwise, if `x` is a vector object, the extent of `x` is used to crop `r`.
#'
#' This is useful for supporting various user input types when extracting
#' subsets from large grids.
#'
#' @param r A _SpatRaster_ Object
#' @param x A _SpatRaster_, _SpatVector_, _SoilProfileCollection_, _sf_, or
#'   _Raster*_ object.
#' @param filename Optional: File name to write intermediate file. If `NULL`
#'   (default) a temporary file is used if result does not fit in memory.
#' @seealso [fetchSOLUS()], [fetchSTEDUS()]
#' @return A _SpatRaster_ Object
#' @noRd
.dsh_raster_extent <- function(r, x, filename = NULL, overwrite = FALSE, ...) {
  # do conversion of input spatial object
  if (!missing(x) && !is.null(x)) {

    # convert various input types to SpatVector
    if (inherits(x, 'SoilProfileCollection')) {
      x <- as(x, 'sf')
    }

    if (inherits(x, c('RasterLayer', 'RasterStack'))) {
      x <- terra::rast(x)
    }

    if (!inherits(x, 'SpatExtent') &&
        !inherits(x, c('SpatRaster', 'SpatVector'))) {
      x <- terra::vect(x)
    }

    if (inherits(x, 'SpatVector')) {
      # project any input vector object to CRS of SOLUS
      x <- terra::project(x, terra::crs(r))
    }

    if (inherits(x, 'SpatExtent')) {
      # user is responsible for providing SpatExtent in correct CRS
      xe <- x
    } else {
      xe <- terra::ext(terra::project(terra::as.polygons(x, ext = TRUE), r))
    }

    # handle requests out-of-bounds
    if (!(terra::relate(terra::ext(r), xe, relation = "contains")[1] ||
          terra::relate(terra::ext(r), xe, relation = "overlaps")[1])) {
      stop("Extent of `x` is outside the boundaries of the source data extent.", call. = FALSE)
    }

    if (!inherits(x, 'SpatRaster')) {
      # crop to target extent (written to temp file if needed)
      r <- terra::crop(
        r,
        x,
        filename = filename,
        overwrite = overwrite,
        ...
      )
    } else {
      # if x is a SpatRaster, use it as a template for GDAL warp
      r <- terra::project(
        r,
        x,
        filename = filename,
        overwrite = overwrite,
        align_only = FALSE,
        mask = TRUE,
        threads = TRUE,
        ...
      )
    }
  }
  r
}
