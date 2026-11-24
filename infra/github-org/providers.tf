# GitHub provider configuration.
#
# Authentication:
# - Reads a Personal Access Token from GITHUB_TOKEN.
# - This module is operated exclusively from GitHub Actions; CI injects
#   secrets.TF_TOKEN_GITHUB as GITHUB_TOKEN for plan/apply and
#   seed-state runs.

provider "github" {
  owner = var.github_owner
}

# REST client for the Actions policies API (see main.tf).
#
# Authentication: the bearer token is read from REST_API_BEARER, which CI
# sets to the same secrets.TF_TOKEN_GITHUB as GITHUB_TOKEN above. Keeping
# it out of a variable means the token never reaches plan files or state.
provider "restapi" {
  uri                  = "https://api.github.com"
  write_returns_object = true

  headers = {
    Accept                 = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2026-03-10"
  }
}
