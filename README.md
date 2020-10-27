
<!-- README.md is generated from README.Rmd. Please edit that file -->

# EuReka

<!-- badges: start -->

[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://www.tidyverse.org/lifecycle/#maturing)
<!-- badges: end -->

## Overview

A suite of tools for working in the University of Colorado Eureka
environment in R.

## Installation

You can install the development version of `EuReka` from
[GitHub](https://github.com/thewileylab/euReka/) with:

``` r
# install.packages("devtools")
devtools::install_github("thewileylab/EuReka")
```

## Example

### Authenticate with Google BigQuery

In some cases, users may have multiple Google accounts provided by their
institution in addition to their personal Gmail account. Each of these
accounts will need their own set of credentials to access Google
BigQuery through R. `EuReka` allows users to cache their credentials
with a “google\_account\_type” tag in their home directory.

``` r
library(EuReka)
eureka_dbCreateToken(google_account_type = 'hdcuser')
```

This will initiate the OAuth flow, wherein users may log in with the
desired Google account. Credentials will be associated with the user
supplied tag when the process is complete.

### Connect to BigQuery Dataset

To access these credentials when creating a connection object, reference
the “google\_account\_type” tag in your Eureka connection object:

``` r
con <- eureka_dbConnect(project_id = 'your-project-id',
                        dataset_id = 'your-dataset-id',
                        bigint_type = 'character',
                        google_account_type = 'hdcuser')
```

### Download data to R Environment

Often, the `bigrquery` package will have trouble parsing very large
integer values. In order to read and manipulate these values in R, these
values must first be CAST as strings so that R will properly interpret
the values as characters.

`eureka_collect()` wraps a low level `bigrquery` function that accepts a
“bigint” variable, allowing data containing large integer values to be
downloaded as characters. Non integer fields in the dataset will be
parsed according to the BigQuery schema.

``` r
interesting_data <- tbl(con, 'table-name') %>% 
  eureka_collect()
```

## Code of Conduct

Please note that the EuReka project is released with a [Contributor Code
of
Conduct](https://contributor-covenant.org/version/2/0/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
