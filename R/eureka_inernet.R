# Datasets ----
#' Eureka Internet Database
#'
#' @description
#' A dataset containing a directory of Health Data Compass approved web-services,
#' their corresponding Eureka firewall access commands, and the URL where the
#' service may be accessed.
#'
#' Currently implemented services include:
#' \itemize{
#' \item{"Bioconductor"}
#' \item{"CRAN"}
#' \item{"GitHub"}
#' \item{"REDCap"}
#' }
#'
#' @docType data
#'
#' @format A data frame with 4 rows and 3 variables:
#' \describe{
#'   \item{service}{The name of the HDC approved web-service.}
#'   \item{cmd}{The Eureka system command used to initiate the request to open the Eureka firewall to the desired web-service.}
#'   \item{url}{The URL corresponding to the HDC approved web-service.}
#'   ...
#' }
"eureka_internet_db"

# Functions ----
#' Eureka Internet Status
#'
#' @description
#' This function will check the Eureka firewall status (open/closed) to Health
#' Data Compass approved web-services from within R.
#'
#' @param service A case-insensitive character vector, containing the name of the requested
#' Health Data Compass approved web-service.
#' Currently implemented services include:
#' \itemize{
#' \item{"Bioconductor"}
#' \item{"CRAN"}
#' \item{"GitHub"}
#' \item{"REDCap"}
#' }
#'
#' @return Invisibly return a list containing the url of the tested service, the returned HTTP
#' status code, the time the status was checked, and additional information if url is
#' successfully queried.
#' @export
#'
#' @importFrom dplyr filter pull
#' @importFrom glue glue
#' @importFrom httr HEAD timeout
#' @importFrom rlang .data abort format_error_bullets inform
#' @importFrom stringr regex str_detect
#'
#' @examples
#' \dontrun{
#' eureka_internet_status('github')
#' }

eureka_internet_status <- function(service) {
  # Define Service ----
  service_filter <- service
  selected_service <- EuReka::eureka_internet_db %>%
    filter(str_detect(.data$service, regex(service_filter, ignore_case = T, dotall = T)))
  # Initial Firewall Status ----
  if(nrow(selected_service) == 1) {
    firewall_status <- tryCatch({
      httr::HEAD(selected_service %>% pull(url), httr::timeout(2))
    },
    error=function(err) {
      list(url = selected_service %>% pull(url), status_code = as.integer(500), last_checked = Sys.time()) ## 500 akin to HTTP response code for "Server error"
    })
  } else{
    rlang::abort(rlang::format_error_bullets(c("x" = glue::glue('"{service_filter}" is an unrecognized service. Check EuReka::eureka_internet_db for a list of supported web-services.'))) )
  }

  if(firewall_status$status_code >= 500 & firewall_status$status_code <= 599) {
    rlang::inform(rlang::format_error_bullets(c("x" = glue::glue('The way is shut to {selected_service %>% pull(url)}. It was made by those who are Dead, and the Dead keep it, until the time comes.'))) )
  } else if (firewall_status$status_code >= 200 & firewall_status$status_code <= 299) {
    rlang::inform(rlang::format_error_bullets(c("i" = glue::glue('{selected_service %>% pull(url)} is open for business!'))) )
  } else {
    rlang::inform(rlang::format_error_bullets(c(glue::glue('The Eureka firewall may be considered simultaneously both open and closed to {selected_service %>% pull(url)} as a result of being linked to a random subatomic event that may or may not occur.'))) )
  }

  return(invisible(firewall_status))
}

#' Eureka Internet Request
#'
#' @description
#' This function will submit a request the Eureka firewall to allow access to select
#' Health Data Compass (HDC) approved web-services. It leverages the HDC provided
#' `eureka-internet-*` flavor of system commands to submit requests only after and
#' verifying that a live human being is submitting the request.
#'
#' @inheritParams eureka_internet_status
#'
#' @return Invisibly return a `tibble` containing the Health Data Compass generated
#' firewall request messageId, the requested service, and the time the request was
#' submitted.
#' @export
#'
#' @importFrom dplyr mutate
#' @importFrom stats na.omit
#' @importFrom stringr str_extract
#' @importFrom tibble enframe
#'
#' @examples
#' \dontrun{
#' eureka_internet_request('github')
#' }
eureka_internet_request <- function(service) {
  # Hooman Verification ----
  ## per Eureka User Agreement
  cat('Internet access requests must be manually initiated by a human user. Automated use of this program violates the Eureka user agreement.')
  continue <- readline(prompt = 'Continue? y/N: ')

  if (continue == 'y') {
    # Define Service ----
    service_filter <- service
    selected_service <- EuReka::eureka_internet_db %>%
      filter(str_detect(.data$service, regex(service_filter, ignore_case = T, dotall = T)))
    # Run system command ----
    cmd_status <- system2(selected_service %>% pull(.data$cmd), input = 'y', stdout = TRUE, stderr = NULL) %>%
      str_extract(pattern = '[[:digit:]]+') %>%             ## Extract the HDC messageId from the system cmd return
      na.omit() %>%                                         ## Remove empty values from character vector
      tibble::enframe(name = NULL,value = 'messageId') %>%  ## Create more informative return, including dttm and requested service
      mutate(request_time = Sys.time(), service = selected_service %>% pull(service))
    rlang::inform(rlang::format_error_bullets(c("i" = glue::glue('Your request to open the firewall to {selected_service %>% pull(url)} has been submitted @ {Sys.time()}!'))) )
    return(invisible(cmd_status))
  }
}
