#' Package BigQuery Data
#'
#' @param con An EuReka::eureka_dbConnect object
#' @param google_account_type Google account type or GSuite domain
#' @param path Where to create the data package
#'
#' @return
#' @export
#' @importFrom bigrquery bq_dataset_tables bq_project_datasets
#' @importFrom devtools build document
#' @importFrom dplyr count mutate pull tbl
#' @importFrom glue glue glue_collapse
#' @importFrom magrittr %>% %<>%
#' @importFrom purrr imap map map2 map_chr map_int
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
    `Authors@R` = 'c(person("EuReka::package_bq_data()", role = c("aut")),
                    person("David", "Mayer", email = "david.mayer@cuanschutz.edu", role = c("cre", "aut")),
                    person(given = "The Wiley Lab", role = c("cph", "fnd"))
                    )',
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
      mutate(bq_fields = map(.data$bq_tables,
                             ~bigrquery::bq_table_fields(.x)
                             ),
             dataset_name = map_chr(.data$bq_dataset,
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
                            ),
             variable = map(.data$bq_fields,
                            ~map(.x,
                                 ~.x$name)
                            ),
             class = map(.data$bq_fields,
                            ~map(.x,
                                 ~.x$type)
                         ),
             items = imap(.data$table_name,
                          ~{variable <- .data$variable[[.y]]
                            class <- .data$class[[.y]]
                            glue::glue_collapse(x = map(EuReka::item_template,
                                                       ~glue::glue(.x))[[1]],
                                               sep = '\n'
                                               )}
                          )
             )
  message('Complete')

  ## Write Functions ----
  imap(project_info$table_name,
       ~{dataset <- project_info$dataset_name[[.y]]
         table <- project_info$table_name[[.y]]
         nrow <- project_info$nrow[[.y]]
         nvar <- project_info$nvar[[.y]]
         items <- project_info$items[[.y]]
         cat(glue::glue_collapse(x = map(EuReka::table_template,
                                         ~glue::glue(.x)),
                                 sep = '\n'
                                 ),
             file = glue::glue('{package_path}/R/{dataset}.{table}.R')
             )
         })

  ## Document New Package ----
  document(pkg = package_path)

  ## Build New Package ----
  build(pkg = package_path)

}


