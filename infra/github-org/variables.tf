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
  default     = "jambalaya.pyoncafe@outlook.jp"
}

variable "org_owners" {
  description = "GitHub logins that should hold the 'admin' role in the org"
  type        = list(string)
  default     = ["JamBalaya56562", "Marukome0743"]
}

variable "security_manager_members" {
  description = <<-EOT
    GitHub logins added to the `security-managers` team. Members get
    read access to org-wide security alerts (Dependabot, code scanning,
    secret scanning) and write access to security configurations
    without being granted org-admin.
  EOT
  type        = list(string)
  default     = ["JamBalaya56562", "Marukome0743"]
}

variable "maintainer_members" {
  description = "GitHub logins added to the `maintainers` team, each with the team-maintainer role."
  type        = list(string)
  default     = ["JamBalaya56562", "Marukome0743"]
}

variable "maintainer_repositories" {
  description = "Repositories (names within the org) the `maintainers` team gets write access to, so their CODEOWNERS can request its review."
  type        = list(string)
  default     = [".github", "coi-serviceworker", "formicarium", "paludarium", "vivarium"]
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
    "dependabot/fetch-metadata@*",
    "jdx/mise-action@*",
    "opentofu/setup-opentofu@*",
    "oven-sh/setup-bun@*",
    "rust-lang/crates-io-auth-action@*",
    "sourcemeta/jsonschema@*",
    "Swatinem/rust-cache@*",
  ]
}

variable "pull_request_target_repositories" {
  description = <<-EOT
    Public repositories whose `pull_request_target` workflows are allowed
    by the org Actions policies in main.tf. GitHub blocks
    `pull_request_target` in public repositories by default from
    2026-12-02 unless an Actions policy allows it; private and internal
    repositories are not affected and need not be listed.
  EOT
  type        = list(string)
  default     = [".github", "coi-serviceworker", "formicarium", "paludarium", "vivarium"]
}
