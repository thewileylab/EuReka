# Datasets ----
#' Connect Template
#'
#' A character vector containing a connection function template
#'
#' @docType data
#'
#' @format A character vector with 16 elements
"connect_template"

#' Item Template
#'
#' A character vector containing a description ITEM template
#'
#' @docType data
#'
#' @format A character vector with 1 element
"item_template"

#' License Template
#'
#' A character vector containing a LICENSE file template
#'
#' @docType data
#'
#' @format A character vector with 2 elements
"license"

#' License Md Template
#'
#' A character vector containing a LICENSE.md template
#'
#' @docType data
#'
#' @format A character vector with 21 elements
"license_md"

#' Table Function Template
#'
#' A character vector containing a table function template
#'
#' @docType data
#'
#' @format A character vector with 19 elements
"table_template"

# Functions ----
#' Package BigQuery Data
#'
#' This function will package your HDC BigQuery project datasets allowing you to
#' access all tables with functions. Each table is examined and relevant schema
#' information is added to the package documentation. This allows for quick
#' reference without having to open the BigQuery web interface. Additionally,
#' RStudio's auto-complete feature may be used to accelerate table access.
#'
#' @param con An EuReka::eureka_dbConnect object
#' @param google_account_type Google account type or GSuite domain
#' @param path Where to create the package
#' @param build Should the package be built? TRUE/FALSE
#'
#' @export
#' @importFrom bigrquery bq_dataset_tables bq_project_datasets
#' @importFrom devtools build document
#' @importFrom dplyr count mutate pull tbl
#' @importFrom fs fs_path
#' @importFrom glue glue glue_collapse
#' @importFrom magrittr %>% %<>%
#' @importFrom purrr imap map map2 map_chr map_int
#' @importFrom tibble enframe
#' @importFrom tidyr unnest
#' @importFrom usethis create_package
#' @examples
#' \dontrun{
#' con <- eureka_dbConnect(project_id = 'your_project_id',
#'   google_account_type = 'your_account_credential_tag')
#' EuReka::package_bq_data(con = con,
#'   google_account_type = 'your_account_credential_tag',
#'   path = '~/Desktop',
#'   build = T)
#' }
package_bq_data <- function(con, google_account_type, path = '~/', build = TRUE) {
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
  ### Add license files
  cat('^LICENSE\\.md$',
      sep = '\n',
      file = glue::glue('{package_path}/.Rbuildignore'),
      append = T)
  cat(EuReka::license,
      sep='\n',
      file = glue::glue('{package_path}/LICENSE')
      )
  cat(EuReka::license_md,
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
      tidyr::unnest(cols = c(.data$bq_tables)) %>%
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
  if(build == TRUE) {
    build(pkg = package_path)
    }

  ## Finish
  message('Package complete!')

}


