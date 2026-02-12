# DSHub Sources

Various methods for returning URLs for DSHub sources. Each function
returns value of user-customizable R options, with a fallback to the
current public default value.

## Usage

``` r
dsh_s3_base_url()
```

## Value

`dsh_s3_base_url()`: *character*. URL for public DSHub S3 bucket. When
set, the value of R option `rdshub.s3_base_url` is returned instead of
the hard-coded default.

## Examples

``` r
# URL for public DSHub S3 bucket
dsh_s3_base_url()
#> [1] "https://s3-fpac-nrcs-dshub-public.s3.us-east-1.amazonaws.com"
```
