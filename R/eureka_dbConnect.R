#' eureka_dbConnect
#'
#' This function will assist in creating a DBI connection object by allowing
#' you to specify which cached Google credentials to use.
#'
#' @param project_id A Google Cloud Project ID
#' @param dataset_id A Google BigQuery Dataset ID
#' @param bigint_type CAST large integers to this type \itemize{
#' \item integer
#' \item integer64
#' \item numeric
#' \item character (usually the best choice)
#' }
#' @param google_account_type Google account type or GSuite domain
#'
#' @return A DBI connection object
#' @importFrom DBI dbConnect
#' @importFrom bigrquery bq_auth
#' @export eureka_dbConnect
#'
#' @examples
#' # Create a DBI connection object with user credentials tagged with 'hdcuser'
#' \dontrun{
#' eureka_dbConnect(project_id = "sandbox-nlp",
#'   dataset_id = "MIMIC3",
#'   bigint_type = "character",
#'   google_account_type = "hdcuser")
#'   }

eureka_dbConnect <- function(project_id, dataset_id = NULL, bigint_type = "character", google_account_type) {
  user <- system("id -un", intern = TRUE)
  token <- paste0(user,"_", google_account_type, ".httr-oauth")
  if(file.exists(file.path(path.expand('~'),token)) == TRUE){
    oauth_data <- readRDS(file.path(path.expand('~'), token))
    bigrquery::bq_auth(token = oauth_data[[1]])
    DBI::dbConnect(drv = bigrquery::bigquery(), project = project_id, dataset = dataset_id, bigint = bigint_type)
  } else {
    EuReka::eureka_dbCreateToken(google_account_type = google_account_type)
    oauth_data <- readRDS(file.path(path.expand('~'), token))
    bigrquery::bq_auth(token = oauth_data[[1]])
    DBI::dbConnect(drv = bigrquery::bigquery(), project = project_id, dataset = dataset_id, bigint = bigint_type)
    }
}
