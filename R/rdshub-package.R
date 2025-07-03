#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL

#' DSHub Sources
#'
#' Various methods for returning URLs for DSHub sources. Each function returns
#' value of user-customizable R options, with a fallback to the current public
#' default value.
#' @returns `dsh_s3_base_url()`: _character_. URL for public DSHub S3 bucket. When set,
#' the value of R option `rdshub.s3_base_url` is returned instead of the
#' hard-coded default.
#' @export
#' @rdname rdshub-sources
#' @examples
#' # URL for public DSHub S3 bucket
#' dsh_s3_base_url()
dsh_s3_base_url <- function() {
  o <- getOption("rdshub.s3_base_url", default = NULL)
  if (is.null(o) || length(o) == 0)
    return("https://s3-fpac-nrcs-dshub-public.s3.us-gov-west-1.amazonaws.com")
  o
}
