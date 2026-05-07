# Organization-level configuration for aletheia-works.
#
# All org-scoped resources live here: org settings, Actions policy,
# memberships, and the security-managers team. Consolidated into a
# single file because the total surface is small enough that splitting
# by resource type costs more in navigation than it saves in focus.
# variables.tf, providers.tf, and versions.tf stay separate per the
# OpenTofu convention.
#
# `.github` repository-scoped resources (branch protection, repo
# settings, CODEOWNERS) deliberately live in the sibling
# `infra/dotgithub/` module so org and repo state evolve independently.


# ─── Org settings ────────────────────────────────────────────────────
#
# Import (one-time) before the first apply if the live org pre-existed
# this module — dispatch the seed-state.yml workflow:
#   gh workflow run seed-state.yml --repo aletheia-works/.github \
#     -f import_address=github_organization_settings.this \
#     -f import_id=aletheia-works
#
# Values declared here must match the live UI state at import time;
# otherwise the first apply will silently overwrite live settings. The
# `org-terraform-plan` PR comment shows any drift before apply.

resource "github_organization_settings" "this" {
  billing_email = var.billing_email
  email         = var.billing_email
  description   = var.org_description

  # ─── Member permissions ──────────────────────────────────────
  # Only admins (organization owners) can create repositories. Members
  # cannot create repos of any visibility and cannot fork private repos.
  # The org is currently solo-developed so the practical blast radius is
  # zero, but these defaults are the right ones to hand off to a future
  # team and avoid accidental public creation.
  default_repository_permission            = "read"
  members_can_create_repositories          = false
  members_can_create_public_repositories   = false
  members_can_create_private_repositories  = false
  members_can_create_internal_repositories = false
  members_can_fork_private_repositories    = false

  # ─── GitHub Pages ────────────────────────────────────────────
  # Enable public Pages so repositories (vivarium, future sub-projects)
  # can publish docs sites. This is an *organization-level* gate: even
  # org owners cannot enable Pages on a repo while the org toggle is off.
  #
  # NOTE: GitHub couples `members_can_create_private_pages` to the
  # parent `members_can_create_pages` toggle — enabling the parent flips
  # private_pages to true on the API side even if the API request set it
  # to false. Keeping all three aligned at `true` to avoid infinite
  # drift. Private Pages are unreachable in practice on the Free plan
  # (private repos can't host Pages), so this is cosmetic.
  members_can_create_pages         = true
  members_can_create_public_pages  = true
  members_can_create_private_pages = true

  # ─── Projects (classic) / Project boards ─────────────────────
  # Org-level Projects classic board is enabled so the "vivarium roadmap"
  # GitHub Projects v2 board surfaces under the org. Repository-level
  # classic Projects stay on as well — `vivarium` uses them for some
  # views.
  has_organization_projects = true
  has_repository_projects   = true

  # ─── Commit integrity ────────────────────────────────────────
  # Enforce sign-off for every commit across every repo in the org. Repos
  # inherit this and cannot turn it off. The provider used to spuriously
  # send web_commit_signoff_required=false in repo PATCH bodies and trip a
  # 422; integrations/github v6.12.0 fixed that, so downstream repo
  # resources no longer need the lifecycle.ignore_changes workaround.
  web_commit_signoff_required = true

  # ─── Default security hardening for new repos ────────────────
  # These only affect repositories created *after* the setting flips. For
  # existing repos, enable at the repo level. GitHub Advanced Security is
  # a paid add-on and stays off.
  advanced_security_enabled_for_new_repositories               = false
  dependabot_alerts_enabled_for_new_repositories               = true
  dependabot_security_updates_enabled_for_new_repositories     = true
  dependency_graph_enabled_for_new_repositories                = true
  secret_scanning_enabled_for_new_repositories                 = true
  secret_scanning_push_protection_enabled_for_new_repositories = true
}


# ─── Actions policy ──────────────────────────────────────────────────
#
# Import via seed-state.yml:
#   gh workflow run seed-state.yml --repo aletheia-works/.github \
#     -f import_address=github_actions_organization_permissions.this \
#     -f import_id=aletheia-works

resource "github_actions_organization_permissions" "this" {
  # Actions run in every repo in the org. (The only alternative value is
  # "selected", which would require enumerating repos; unnecessary here.)
  enabled_repositories = "all"

  # "selected" means third-party actions are restricted to the explicit
  # allowlist in allowed_actions_config. GitHub-owned and verified-creator
  # actions remain automatically allowed via the booleans below.
  allowed_actions = "selected"

  # Force every third-party action invocation to be pinned by commit SHA
  # (Actions → General → Policies). This was set in the GitHub UI before
  # the provider exposed it; integrations/github v6.12.0 added the
  # attribute, so we can manage it as code now.
  sha_pinning_required = true

  allowed_actions_config {
    github_owned_allowed = true
    verified_allowed     = true
    patterns_allowed     = var.allowed_action_patterns
  }
}


# ─── Default workflow permissions (Actions → General) ────────────────
#
# Least-privilege GITHUB_TOKEN for every workflow run in the org. Repos
# inherit these unless they explicitly override at the repo level.
# Managed via the dedicated `github_actions_organization_workflow_permissions`
# resource (added in integrations/github v6.12) — these attributes are NOT
# part of `github_actions_organization_permissions` above.
#
# Import via seed-state.yml:
#   gh workflow run seed-state.yml --repo aletheia-works/.github \
#     -f import_address=github_actions_organization_workflow_permissions.this \
#     -f import_id=aletheia-works

resource "github_actions_organization_workflow_permissions" "this" {
  organization_slug = var.github_owner

  # "read" gives the GITHUB_TOKEN read-only access to repository contents
  # by default; workflows that need write must opt in via `permissions:`
  # in the workflow YAML.
  default_workflow_permissions = "read"

  # Block GitHub Actions runs from approving PR reviews — review approval
  # must come from a human identity, never an automation token.
  can_approve_pull_request_reviews = false
}


# ─── Memberships ─────────────────────────────────────────────────────
#
# Only owners (admins) are pinned in code; regular members can be added
# via the UI without requiring a Tofu round-trip. If/when the project
# grows past solo development, convert the members list into its own
# variable and add a `github_membership` per member with role="member".
#
# Import via seed-state.yml:
#   gh workflow run seed-state.yml --repo aletheia-works/.github \
#     -f import_address='github_membership.owners["JamBalaya56562"]' \
#     -f import_id=aletheia-works:JamBalaya56562

resource "github_membership" "owners" {
  for_each = toset(var.org_owners)

  username = each.key
  role     = "admin"
}


# ─── Security managers ───────────────────────────────────────────────
#
# Designating a team as "security manager" gives its members:
#   - Read access to security alerts (Dependabot, code scanning,
#     secret scanning) across every repository in the org
#   - Write access to security configurations
# without making them org admins. Closes the ghqr finding `org-sec-005`
# ("No security manager team assigned").
#
# Implemented via the predefined `security_manager` organization role
# attached to a team through `github_organization_role_team`. The legacy
# `github_organization_security_manager` resource is deprecated upstream.
# The role_id is resolved dynamically from the org's role registry rather
# than hardcoded, so a future GitHub-side renumbering does not break us.

data "github_organization_roles" "all" {}

resource "github_team" "security_managers" {
  name        = "security-managers"
  description = "Reviews security alerts and configurations across the org. Managed by OpenTofu."
  privacy     = "closed"
}

resource "github_organization_role_team" "security_managers" {
  team_slug = github_team.security_managers.slug
  role_id = one([
    for role in data.github_organization_roles.all.roles :
    role.role_id if role.name == "security_manager"
  ])
}

resource "github_team_membership" "security_managers" {
  for_each = toset(var.security_manager_members)

  team_id  = github_team.security_managers.id
  username = each.value
  # `maintainer` lets the sole member manage the team itself (add/remove
  # future members) without going through the org-admin path. Switch to
  # `member` for additional non-leading members once the team grows.
  role = "maintainer"
}


# ── Settings that are NOT managed here ──────────────────────────────────
#
# The integrations/github provider (as of v6.12) does not expose the
# following org attributes. They are set via the GitHub UI / REST and
# documented here so the source of truth is still discoverable:
#
# • two_factor_requirement_enabled = true
#     Org-level 2FA enforcement. Set at /organizations/<org>/settings/security.
#     Exposed read-only via the `github_organization` data source but not
#     settable on any resource.
#
# • members_can_delete_repositories = true                 (Repo policies)
# • members_can_change_repo_visibility = true
# • members_can_invite_outside_collaborators = true
# • members_can_delete_issues = false
# • display_commenter_full_name_setting_enabled = false
# • readers_can_create_discussions = true
# • members_can_create_teams = true
# • members_can_view_dependency_insights = true
# • deploy_keys_enabled_for_repositories = false
# • members_allowed_repository_creation_type = "none"
#     (Legacy aggregate field; practically covered by the per-visibility
#     members_can_create_*_repositories booleans set above.)
#
# Team / Enterprise-plan-only and therefore out of scope on Free:
# • Organization Rulesets
# • Custom repository roles
#
# When the provider adds coverage for any of the above, migrate it into
# this file and drop the corresponding line from this block.
