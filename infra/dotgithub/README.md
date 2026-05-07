# `infra/dotgithub/` — `.github` repository settings as code

OpenTofu configuration that manages the
[`aletheia-works/.github`](https://github.com/aletheia-works/.github)
repository itself (settings, topics, branch protection) declaratively.

This module is intentionally separate from
[`infra/github-org/`](../github-org/) so that organization-level state
(org settings, security manager team, Actions permissions) and
repository-level state evolve independently and reviewers can tell at a
glance which surface a change touches. Each module has its own state
artifact and `LATEST_APPLY_RUN_ID*` repo variable so the two never
overwrite each other.

For per-repository settings of *other* repos in the org (vivarium etc.)
see each repo's own `infra/github/`.

## Managed resources

All resources live in `main.tf`.

| Resource | Notes |
|---|---|
| `github_repository` (`this`) | The `.github` repo itself — description, topics, feature toggles, merge strategy, `delete_branch_on_merge`, `web_commit_signoff_required`. Carries `lifecycle { prevent_destroy = true }` |
| `github_branch_protection` (`main`) | Phase 1 baseline mirrored from vivarium — required reviews, required `Commitlint` status check, signed commits, linear history, no force pushes |

CODEOWNERS lives at `.github/CODEOWNERS` as a regular committed file,
**not** managed via `github_repository_file`. Plain repo content stays
out of state and contributors can edit it through normal PRs without
needing the tofu apply pipeline.

## CI workflows

This module is operated **exclusively from GitHub Actions** — there is
no local `tofu` workflow. Plan / apply / autofix all go through thin
callers of the reusable workflows in `.github/workflows/`.

| File | Purpose |
|---|---|
| `.github/workflows/dotgithub-terraform-plan.yml` | Thin caller — `tofu plan` + PR comment for changes under `infra/dotgithub/` |
| `.github/workflows/dotgithub-terraform-apply.yml` | Thin caller — `tofu apply` on push to `main` |
| `.github/workflows/dotgithub-terraform-autofix.yml` | Thin caller — `tofu fmt -recursive` and pushes fixes back to the PR branch |
| `.github/workflows/seed-state.yml` | `workflow_dispatch` — one-off state bootstrap / recovery via `tofu import` (target this module by passing `working_directory=infra/dotgithub`) |

State is shipped as the `terraform-state-dotgithub` artifact and the
latest run id is tracked in the `LATEST_APPLY_RUN_ID_DOTGITHUB` repo
variable. The reusable plan/apply/autofix logic itself lives in
`terraform-plan.yml` / `terraform-apply.yml` / `terraform-autofix.yml`
— see [`infra/github-org/README.md`](../github-org/README.md#why-reusable-workflows-and-does-opentofu-care)
for the isolation rationale.

## How to run

### Routine changes

Edit the `.tf` files on a branch and open a PR. CI runs `tofu plan` and
posts the diff as a PR comment; merging to `main` triggers
`tofu apply` automatically.

### First-time bootstrap (import existing repo)

The `.github` repository pre-existed this module, so
`github_repository.this` and `github_branch_protection.main` have to
be imported into state once before the first apply. Run
`seed-state.yml`, passing `working_directory`, `state_artifact_name`,
and `state_run_id_variable` so the import lands in this module's state
rather than the org module's:

```bash
gh workflow run seed-state.yml --repo aletheia-works/.github \
  -f working_directory=infra/dotgithub \
  -f state_artifact_name=terraform-state-dotgithub \
  -f state_run_id_variable=LATEST_APPLY_RUN_ID_DOTGITHUB \
  -f import_address=github_repository.this \
  -f import_id=.github

gh workflow run seed-state.yml --repo aletheia-works/.github \
  -f working_directory=infra/dotgithub \
  -f state_artifact_name=terraform-state-dotgithub \
  -f state_run_id_variable=LATEST_APPLY_RUN_ID_DOTGITHUB \
  -f import_address=github_branch_protection.main \
  -f import_id=.github:main
```

Each run uploads the updated state artifact and points
`LATEST_APPLY_RUN_ID_DOTGITHUB` at it, so the next
`dotgithub-terraform-apply` run picks up where the previous import
left off.

### Recovery (apply failed mid-run, state out of sync)

When an apply errors out part-way and a resource exists live but is
absent from state, the next apply will 422 on a uniqueness collision.
Dispatch `seed-state.yml` for that one resource (same form as the
bootstrap example above) to import it into state, then re-run the
apply.

## State management

State lives as the `terraform-state-dotgithub` GitHub Actions artifact
(90-day retention) and is mirrored to Release Assets weekly for
long-term retention. A `concurrency` group keyed on the state artifact
name serializes plan / apply / seed-state runs against this module so
the artifact and the `LATEST_APPLY_RUN_ID_DOTGITHUB` repo variable can
never be updated by two runs at once.

## File layout

```
infra/dotgithub/
├── versions.tf                 # OpenTofu and provider versions
├── providers.tf                # GitHub provider config
├── variables.tf                # Input variables (just github_owner)
├── main.tf                     # github_repository + github_branch_protection
└── README.md
```
