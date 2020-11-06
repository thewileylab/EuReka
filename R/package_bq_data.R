#' Package BigQuery Data
#'
#' @param con An EuReka::eureka_dbConnect object
#' @param google_account_type Google account type or GSuite domain
#' @param path Where to create the data package
#'
#' @return
#' @export
#' @importFrom bigrquery bq_dataset_tables bq_project_datasets
#' @importFrom dplyr mutate
#' @importFrom glue glue glue_collapse
#' @importFrom magrittr %>% %<>%
#' @importFrom purrr map
#' @importFrom usethis create_package
#' @examples
package_bq_data <- function(con, google_account_type, path) {
  ## Gather Info ----
  project <- con@project
  project_info <- bigrquery::bq_project_datasets(project) %>%
    tibble::enframe(name = NULL, value = 'bq_dataset') %>%
    mutate(bq_tables = map(.data$bq_dataset,
                           ~bigrquery::bq_dataset_tables(.x)
                           )
           )

  ## Create Package ----
  ### Description
  package_path <- fs::fs_path(glue::glue('{path}/{project}'))
  description_fields <- list(
    Title = glue::glue('Easy Eureka Access to `{project}` Project Datasets from Google BigQuery'),
    Description = glue::glue('This is a meta package, providing functions and documentation pertaining to the `{project}` project on Google BigQuery.'),
    `Authors@R` = 'person("EuReka::package_bq_data()", role = c("aut", "cre")',
    License = "MIT + file LICENSE",
    Language =  "en-US",
    Imports = 'dplyr, EuReka'
    )
  ### Initial File Structure
  usethis::create_package(path = package_path,
                          fields = description_fields,
                          rstudio = TRUE,
                          roxygen = TRUE,
                          check_name = FALSE,
                          open = FALSE
                          )
  ### Add license file
  cat(EuReka::license,
      sep='\n',
      file = glue::glue('{package_path}/LICENSE.md')
      )
  ## Create Package Functions ----
  ### Connection Function
  cat(glue::glue_collapse(x = map(EuReka::connect_template,
                                  ~glue::glue(.x)),
                          sep = '\n'
                          ),
      file = glue::glue('{package_path}/R/project_connect.R')
      )
  ### Table Functions
  message('Retrieving Project Dataset Information')
  project_info %<>%
      tidyr::unnest(cols = c(bq_tables)) %>%
      mutate(dataset_name = map_chr(.data$bq_dataset,
                                    ~ .x$dataset),
             table_name = map_chr(.data$bq_tables,
                                  ~ .x$table),
             tbl = map2(.data$dataset_name,
                        .data$table_name,
                        ~ tbl(con, glue::glue('{.x}.{.y}'))
                        ),
             nrow = map_int(.data$tbl,
                            ~ .x  %>% count() %>% pull(n)
                            ),
             nvar = map_int(.data$tbl,
                            ~ ncol(.x)
                            )
             )
  message('Complete')
}
