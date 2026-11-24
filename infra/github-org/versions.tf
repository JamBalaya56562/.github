terraform {
  # Require OpenTofu 1.6+ (also Terraform 1.6+ compatible).
  required_version = ">= 1.6.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.12"
    }
    # Generic REST client for org APIs the github provider does not cover
    # yet — currently Actions policies (workflow execution protections).
    # Drop it once integrations/github ships an org-level policy resource
    # (tracked in integrations/terraform-provider-github#3724).
    restapi = {
      source  = "Mastercard/restapi"
      version = "~> 3.0"
    }
  }

  # State is stored as a GitHub Actions artifact (same pseudo-remote pattern
  # used by the vivarium repository). Workflows download/upload the artifact
  # on every run.
  backend "local" {
    path = "terraform.tfstate"
  }
}
