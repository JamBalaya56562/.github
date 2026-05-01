variable "github_owner" {
  description = "GitHub organization whose settings are being managed"
  type        = string
  default     = "aletheia-works"
}

variable "org_description" {
  description = "One-line description shown on the org profile"
  type        = string
  default     = "Universal bug reproduction in the AI era"
}

variable "billing_email" {
  description = "Org billing email. Also used as the contact email on the public profile."
  type        = string
  # Intentionally has no default — must be set via terraform.tfvars locally or
  # as TF_VAR_billing_email in CI so it never leaks into VCS.
}

variable "org_owners" {
  description = "GitHub logins that should hold the 'admin' role in the org"
  type        = list(string)
  default     = ["JamBalaya56562"]
}

variable "allowed_action_patterns" {
  description = <<-EOT
    Additional third-party actions permitted org-wide, as `<owner>/<repo>@*`
    patterns. GitHub-owned and verified-creator actions are allowed
    unconditionally (see actions.tf). Keep this list minimal — every entry
    widens the supply-chain surface.
  EOT
  type        = list(string)
  default = [
    "jdx/mise-action@*",
    "opentofu/setup-opentofu@*",
    "oven-sh/setup-bun@*",
  ]
}
