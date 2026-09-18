# `.github` repository — managed via OpenTofu.
#
# This module manages the `aletheia-works/.github` repository itself
# (repo settings, branch protection, CODEOWNERS). It is intentionally
# separate from `infra/github-org/` so that organization-level state
# (org settings, security manager team, Actions permissions) and
# repository-level state evolve independently and reviewers can tell
# at a glance which surface a change touches.
#
# Convention: keep this module small; everything fits in main.tf until
# it grows past a few hundred lines, then split by feature.

# ─── Repository ──────────────────────────────────────────────────────
#
resource "github_repository" "this" {
  name        = ".github"
  description = "Org-wide defaults for aletheia-works: Code of Conduct, Security Policy, and templates"
  visibility  = "public"

  # Topics — surface this repo as the org's infrastructure / template hub
  # and resolve the ghqr `repo-meta-002` finding ("no topics").
  topics = [
    "github",
    "github-actions",
    "infrastructure-as-code",
    "opentofu",
    "org-management",
  ]

  # Feature toggles — match current live state.
  has_issues      = true
  has_discussions = false
  has_projects    = true
  has_wiki        = true

  # Merge strategy — current settings preserved; tightening is a separate
  # decision once contributor flow stabilises. Auto-merge is on for
  # dependabot-auto-merge.yml, which enables it on Dependabot's PRs.
  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true
  allow_auto_merge   = true

  # Resolve ghqr `repo-feat-002` ("auto-delete branches not enabled").
  delete_branch_on_merge = true

  # Inherit web commit signoff from the org-level setting.
  web_commit_signoff_required = true

  archived = false

  lifecycle {
    prevent_destroy = true
  }
}

# ─── Branch ruleset ──────────────────────────────────────────────────
#
# Mirrors vivarium/infra/github/main.tf so contributor expectations are
# uniform across repos. No approving review is required: the sole
# maintainer is the only reviewer, and the rule only ever gated
# Dependabot, whose pull requests dependabot-auto-merge.yml now merges
# once the checks pass. The repository admin role can bypass the ruleset
# so the maintainer can self-merge while solo; drop the bypass and put
# the review count back once a second reviewer is available.

resource "github_repository_ruleset" "main" {
  name        = "main"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = "always"
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
    required_signatures     = true

    pull_request {
      required_approving_review_count   = 0
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
    }

    # `Commitlint` runs on every pull_request via this repo's own
    # .github/workflows/commitlint.yml (executed directly, not via a
    # caller), so the context name is the bare job display name. The
    # branch need not be up to date: with several Dependabot pull
    # requests open, each merge would otherwise invalidate the rest.
    required_status_checks {
      strict_required_status_checks_policy = false

      required_check {
        context        = "Commitlint"
        integration_id = 15368
      }
    }
  }
}

# CODEOWNERS lives at .github/CODEOWNERS as a regular committed file
# (not managed via tofu's github_repository_file). Plain repo content
# stays out of state and contributors can edit it through normal PRs
# without needing the tofu apply pipeline. See `.github/CODEOWNERS`.

# ─── Labels ──────────────────────────────────────────────────────────
#
# The label taxonomy is vivarium's (see vivarium/infra/github/main.tf):
# `type:` from the Conventional Commits type in the PR title, `scope:`
# from the paths a PR touches, and the labels terraform-apply.yml files
# its failure issue with. Colours and descriptions match vivarium's so a
# label means the same thing in both repositories.

locals {
  labels = {
    "type: bug" = {
      color       = "d73a4a"
      description = "Something isn't working"
    }
    "type: feature" = {
      color       = "a2eeef"
      description = "New feature or capability"
    }
    "type: docs" = {
      color       = "0075ca"
      description = "Documentation improvements"
    }
    "type: refactor" = {
      color       = "cfd3d7"
      description = "Code refactoring without behavior change"
    }
    "type: test" = {
      color       = "bfdadc"
      description = "Test additions or improvements"
    }
    "type: chore" = {
      color       = "fef2c0"
      description = "Maintenance tasks"
    }

    "scope: ci" = {
      color       = "ededed"
      description = "CI/CD pipeline"
    }
    "scope: infra" = {
      color       = "5319e7"
      description = "Infrastructure as Code"
    }
    "scope: templates" = {
      color       = "5319e7"
      description = "Issue/PR templates and org profile"
    }

    "priority: p0" = {
      color       = "b60205"
      description = "Critical - must fix immediately"
    }
    "status: apply-failure" = {
      color       = "b60205"
      description = "Auto-filed when Terraform Apply fails on main; auto-closed on recovery"
    }

    "ai: generated" = {
      color       = "00d4aa"
      description = "Created or modified by AI"
    }
  }
}

resource "github_issue_label" "labels" {
  for_each = local.labels

  repository  = github_repository.this.name
  name        = each.key
  color       = each.value.color
  description = each.value.description
}
