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
