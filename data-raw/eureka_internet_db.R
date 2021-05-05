## code to prepare `eureka_internet_db` dataset goes here
library(tidyverse)
eureka_internet_db <- tibble(service = c('Bioconductor', 'CRAN', 'GitHub', 'REDCap'),
                             cmd = c('eureka-internet-CRAN-Bioconductor', 'eureka-internet-CRAN-Bioconductor','eureka-internet-GitHub.com', 'eureka-internet-RedCap'),
                             url = c('https://bioconductor.org', 'https://cran.r-project.org','https://github.com', 'https://redcap.ucdenver.edu')
                             )

usethis::use_data(eureka_internet_db, overwrite = TRUE)
