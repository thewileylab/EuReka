#' BigQuery Cloud Table Import
#'
#' @param bq_temp A computed temporary (or otherwise) BigQuery Table
#' @param gcs_mount A gcsfuse mount on the destination
#' @param cleanup Should exported table be removed from cloud bucket automatically: TRUE/FALSE
#'
#' @importFrom bigrquery as_bq_table bq_table_save
#' @importFrom glue glue
#' @importFrom fs as_fs_path dir_copy dir_delete dir_ls
#' @importFrom purrr map_dfr
#' @importFrom jsonlite stream_in
#'
#' @return A dataframe
#' @keywords internal
#' @export
#'
bq_cloud_table_import <- function(bq_temp, gcs_mount, cleanup = F) {
  table_ref <- bigrquery::as_bq_table(bq_temp$ops$x)
  ## Create a temporary directory name for GCS and Local Storage
  temp_dir <- tempdir()
  temp_gcsfuse <- fs::as_fs_path(glue::glue("{gcs_mount}{temp_dir}"))
  ## Create a destination uri, indicating where to save the temporary bigquery table. Use * to create as many files as needed.
  destination <-  glue::glue('gs://{bq_temp$src$con@project}{fs::as_fs_path(temp_dir)}/{bq_temp$ops$x[1]}*.json')
  ## Save table to GCS Bucket
  bq_table_save(x = table_ref, destination_uris = destination)
  ## Copy GCS directory to local tmp storage
  fs::dir_copy(path = temp_gcsfuse, new_path = temp_dir, overwrite = T)
  ## List individual JSON files
  file_list <- fs::dir_ls(temp_dir, regexp = '\\.json$')
  ## Read JSON file(s) into a single dataframe
  output <- purrr::map_dfr(.x = file_list,
                           ~ jsonlite::stream_in(file(.x) )
                           ) %>%
    dplyr::as_tibble()
  ## Remove temporary files from GCS Bucket, if asked
  if(cleanup == T) {
    try(fs::dir_delete(temp_gcsfuse), silent = T) ## GCS Fuse
    }
  return(output)
}

#' Eureka Collect 2
#'
#' @param .data A tbl containing connection information
#' @param use_bucket Yes/No If you know the result is too large, select 'Yes'
#' @param gcs_mount A gcsfuse mount on the destination
#' @param cleanup Should exported table be removed from cloud bucket automatically: TRUE/FALSE
#'
#' @return A dataframe
#' @export
#'
#' @importFrom bigrquery as_bq_table bq_table_size bq_table_download
#' @importFrom dplyr compute
#' @importFrom utils menu
#'
#' @usage
#' eureka_collect2(.data, use_bucket = 'no', gcs_mount, cleanup = F)
eureka_collect2 <- function(.data, use_bucket = 'no', gcs_mount, cleanup = F) {
  bq_temp <- .data %>% dplyr::compute()
  table_ref <- bigrquery::as_bq_table(bq_temp$ops$x)
  table_size <- bigrquery::bq_table_size(table_ref)[1]/1000000
  ## Determine if table is too large to download
  if(table_size < 10) { ### Note: This is set arbitrarily low for testing!!!
    bigrquery::bq_table_download(table_ref, max_connections = 6L, bigint = .data$src$con@bigint)
    } else if (use_bucket == 'yes') {
      bq_cloud_table_import(bq_temp, gcs_mount)
      } else {
        user_selection <- menu(choices = c('Yes','No'),
                               title = glue::glue("The requested table is {round(table_size, digits = 2)} MB and is likely too large to
                                                  collect.
                                                  This table can be imported into R by exporting the result to temporary JSON(s) in the
                                                  {bq_temp$src$con@project} project's Google Cloud Storage bucket. Would you like to
                                                  proceed?")
                               )
        if(user_selection == 1) {
          bq_cloud_table_import(bq_temp, gcs_mount)
          } else{message('nothing to do') }
        }
  }
