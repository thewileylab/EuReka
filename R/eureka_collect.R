#' eureka_collect
#'
#' This version of collect will actually honor the bigint variable passed by a DBI connection object
#'
#' @param .data A tbl containing connection information
#'
#' @return A local data frame
#'
#' @importFrom bigrquery bq_table_download
#' @importFrom dplyr mutate_if compute
#' @importFrom magrittr %>%
#' @importFrom rlang .data
#' @export eureka_collect
#'
#' @usage
#' eureka_collect(.data)

eureka_collect <- function(.data) {
    bq_temp <- .data %>% dplyr::compute()
    table_ref <- bigrquery::as_bq_table(bq_temp$ops$x)
    bigrquery::bq_table_download(table_ref, max_connections = 6L, bigint = .data$src$con@bigint)
    }
