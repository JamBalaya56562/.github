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
  # decision once contributor flow stabilises.
  allow_merge_commit = true
  allow_squash_merge = true
  allow_rebase_merge = true
  allow_auto_merge   = false

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
# Phase 1 baseline. Mirrors vivarium/infra/github/main.tf so contributor
# expectations are uniform across repos. The repository admin role can
# bypass the ruleset so the sole maintainer can self-merge while solo;
# drop the bypass once a second reviewer is available.

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
      required_approving_review_count   = 1
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = true
      require_last_push_approval        = false
      required_review_thread_resolution = true
    }

    # `Commitlint` runs on every pull_request via this repo's own
    # .github/workflows/commitlint.yml (executed directly, not via a
    # caller), so the context name is the bare job display name.
    required_status_checks {
      strict_required_status_checks_policy = true

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
