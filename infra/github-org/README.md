# `infra/github-org/` — Org settings as code

OpenTofu configuration that manages the **organization-level** settings of
`aletheia-works` declaratively.

For per-repository settings (labels, branch protection, milestones) see each
repo's own `infra/github/` — e.g.
[vivarium/infra/github/](https://github.com/aletheia-works/vivarium/tree/main/infra/github).

## Managed resources

All resources live in `main.tf`; the module is small enough that
splitting by resource type costs more in navigation than it saves.

| Resource | Notes |
|---|---|
| `github_organization_settings` | Profile, member permissions, Pages, Projects, security defaults |
| `github_actions_organization_permissions` | Allowed-actions policy and SHA-pinning enforcement |
| `github_actions_organization_workflow_permissions` | Default `GITHUB_TOKEN` scope and PR-review-approval block |
| `github_membership` (admin role) | Org owners (`for_each` over `var.org_owners`) |
| `github_team` + `github_organization_role_team` (`security_managers`) | `security-managers` team bound to the predefined `security_manager` org role |
| `github_team_membership` (`security_managers`) | Members of the security-managers team |

A short list of org attributes that the provider does **not** cover yet
(2FA enforcement, several Repo-policy toggles, Organization Rulesets,
Custom repository roles) is documented in the trailing comment block
of `main.tf` — those are managed via the GitHub UI until the provider
catches up.

## CI workflows

Shared plan/apply logic lives in `.github/workflows/terraform-plan.yml` and
`.github/workflows/terraform-apply.yml` as **reusable workflows** (`on:
workflow_call`). Each consumer repo calls them through a thin wrapper.

| File | Purpose |
|---|---|
| `.github/workflows/terraform-plan.yml` | Reusable — `tofu plan` + PR comment |
| `.github/workflows/terraform-apply.yml` | Reusable — `tofu apply` + auto-filed failure issue |
| `.github/workflows/terraform-autofix.yml` | Reusable — `tofu fmt -recursive` and pushes fixes back to the PR branch |
| `.github/workflows/org-terraform-plan.yml` | Thin caller for this repo's `infra/github-org/` |
| `.github/workflows/org-terraform-apply.yml` | Thin caller for this repo's `infra/github-org/` |
| `.github/workflows/org-terraform-autofix.yml` | Thin caller — runs `terraform-autofix` against `infra/github-org/` |
| `.github/workflows/seed-state.yml` | `workflow_dispatch` — one-off state bootstrap / recovery via `tofu import` |
| `.github/workflows/terraform-state-backup.yml` | Weekly + post-apply backup to Release assets |

### Why reusable workflows, and does OpenTofu care?

**Short answer:** OpenTofu doesn't care — the reusable workflow just
orchestrates the `tofu` binary — and sharing the workflow logic removes
~300 duplicated lines from every new repo that needs an `infra/` directory.

**Isolation guarantees that matter for state:**

- **State artifact** (`terraform-state`) and **repo variable**
  (`LATEST_APPLY_RUN_ID`) are evaluated in the *caller's* repo context,
  so the org's state and vivarium's state never intersect.
- **Concurrency group** (`terraform-state`) is scoped to the caller
  workflow run, so a plan in the org repo cannot serialize behind a plan
  in vivarium.
- **Secrets** flow via `secrets: inherit` — `TF_TOKEN_GITHUB` is resolved
  in the caller repo. Reusable workflows never see each other's secrets
  store.
- **`workflow_run` listeners** (e.g. `terraform-state-backup.yml`) stay
  per-repo because `workflow_run` fires in the repo where the completed
  workflow ran, not in the reusable workflow's home repo.

The only coupling is the shared `.github` repo commit the caller pins —
updating `terraform-plan.yml@main` immediately affects every caller.
Pin to a SHA in production-critical repos if that's undesirable.

## How to run

This module is operated **exclusively from GitHub Actions** — there is
no local `tofu` workflow. Plan/apply runs are triggered by pushes and
PRs through `org-terraform-plan.yml` / `org-terraform-apply.yml`, and
state-affecting operations (initial bootstrap, post-failure recovery)
go through the `seed-state.yml` dispatch workflow.

### Routine changes

Edit the `.tf` files on a branch and open a PR. CI runs `tofu plan` and
posts the diff as a PR comment; merging to `main` triggers
`tofu apply` automatically.

### First-time bootstrap (import existing org)

When the live org pre-existed this module, each org-scoped resource has
to be imported into state once before the first apply. Run
`seed-state.yml` once per resource:

```bash
gh workflow run seed-state.yml --repo aletheia-works/.github \
  -f import_address=github_organization_settings.this \
  -f import_id=aletheia-works

gh workflow run seed-state.yml --repo aletheia-works/.github \
  -f import_address=github_actions_organization_permissions.this \
  -f import_id=aletheia-works

gh workflow run seed-state.yml --repo aletheia-works/.github \
  -f import_address=github_actions_organization_workflow_permissions.this \
  -f import_id=aletheia-works

gh workflow run seed-state.yml --repo aletheia-works/.github \
  -f import_address='github_membership.owners["JamBalaya56562"]' \
  -f import_id=aletheia-works:JamBalaya56562
```

The `security-managers` team and its role binding were created from
scratch by this module, so they do not need to be imported.

Each run uploads the updated state artifact and points
`LATEST_APPLY_RUN_ID` at it, so the next `org-terraform-apply` run
picks up where the previous import left off.

### Recovery (apply failed mid-run, state out of sync)

When an apply errors out part-way and a resource exists live but is
absent from state, the next apply will 422 on a uniqueness collision.
Dispatch `seed-state.yml` for that one resource (same form as the
bootstrap example above) to import it into state, then re-run the
apply.

## State management

State lives as a GitHub Actions artifact in this repo (90-day retention) and
is mirrored to Release Assets weekly for long-term retention. A
`concurrency` group keyed on the state artifact name serializes
plan / apply / seed-state runs against this module so the artifact and
the `LATEST_APPLY_RUN_ID` repo variable can never be updated by two runs
at once.

## File layout

```
infra/github-org/
├── versions.tf                 # OpenTofu and provider versions
├── providers.tf                # GitHub provider config
├── variables.tf                # Input variables
├── main.tf                     # All resources (org settings, Actions, memberships, security-managers)
├── .gitignore                  # Excludes state and any local tfvars
├── .terraform.lock.hcl         # Provider version lock (committed)
└── README.md
```
