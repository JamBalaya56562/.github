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
  # Intentionally has no default — supplied at runtime via the
  # `BILLING_EMAIL` repo variable, threaded through CI as
  # `tfvar_assignments` (plan/apply) or `TF_VAR_billing_email` (seed-state),
  # so the value never lands in VCS.
}

variable "org_owners" {
  description = "GitHub logins that should hold the 'admin' role in the org"
  type        = list(string)
  default     = ["JamBalaya56562"]
}

variable "security_manager_members" {
  description = <<-EOT
    GitHub logins added to the `security-managers` team. Members get
    read access to org-wide security alerts (Dependabot, code scanning,
    secret scanning) and write access to security configurations
    without being granted org-admin. While solo, this is a single entry
    that mirrors `org_owners`; expand the list as the maintainer team
    grows.
  EOT
  type        = list(string)
  default     = ["JamBalaya56562"]
}

variable "allowed_action_patterns" {
  description = <<-EOT
    Additional third-party actions permitted org-wide, as `<owner>/<repo>@*`
    patterns. GitHub-owned and verified-creator actions are allowed
    unconditionally (see `github_actions_organization_permissions` in
    main.tf). Keep this list minimal — every entry widens the supply-chain
    surface.
  EOT
  type        = list(string)
  default = [
    "jdx/mise-action@*",
    "opentofu/setup-opentofu@*",
    "oven-sh/setup-bun@*",
  ]
}
