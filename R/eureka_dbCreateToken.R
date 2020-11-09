# Helpers ----
#' Installed App
#'
#' Invisibly returns an OAuth app
#'
#' @return An Invisible OAuth consumer application, produced by [httr::oauth_app()]
#'
#' @export
#' @keywords internal
#' @rdname internal-assets
installed_app <- function() {
  eoa()
}
#' @export
#' @keywords internal
#' @rdname internal-assets
#' @noRd
print.hidden_fn <- function(x, ...) {
  x <- 'Nope'
  NextMethod('print')
}

#' eureka_dbCreateToken
#'
#' This function authenticates with Google using a Wiley Lab OAuth Consent Screen. Credentials are
#' cached in a user's home directory and labeled according to the currently connected
#' linux user account and the specified Google Account Type.
#'
#' @param google_account_type Google account type or GSuite domain.
#'
#' @return Saves an authenticated Google OAuth token to current user's home directory
#' @importFrom httr oauth2.0_token oauth_endpoints oauth_app
#' @export eureka_dbCreateToken
#'
#' @examples
#' \dontrun{
#' eureka_dbCreateToken(google_account_type = "hdcuser")
#' }
eureka_dbCreateToken <- function(google_account_type) {
  user <- system("id -un", intern = TRUE)
  token <- paste0(user,"_",google_account_type,".httr-oauth")
  if(file.exists(file.path(path.expand('~'),token)) == TRUE){
    message(paste0('Token for ', google_account_type, ' already exists!'))
    } else {
      scopes <- "https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/bigquery https://www.googleapis.com/auth/cloud-platform"
      invisible(
        httr::oauth2.0_token(
          endpoint = httr::oauth_endpoints("google"),
          app = installed_app(),
          scope = scopes,
          use_oob = TRUE,
          cache = file.path(path.expand("~"),token)
          )
        )
      message('Success')
      }
  }
