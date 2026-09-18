# aletheia-works/.github

This repository holds **org-wide defaults and shared CI** for [aletheia-works](https://github.com/aletheia-works).

| Path | Purpose |
|---|---|
| `profile/README.md` | Shown on the org landing page |
| `CODE_OF_CONDUCT.md` | Contributor Covenant 2.1 — inherited by every repo in the org |
| `SECURITY.md` | Vulnerability reporting policy |
| `CONTRIBUTING.md` | Shared contribution expectations |
| `.github/ISSUE_TEMPLATE/*.yml` | Default issue forms for new repos |
| `.github/PULL_REQUEST_TEMPLATE.md` | Default PR template |
| `.github/workflows/*.yml` | Reusable workflows (`workflow_call`) — `terraform-plan`, `terraform-apply`, `terraform-autofix`, `commitlint` — plus repo-local automations (thin callers, `seed-state`, `terraform-state-backup`, `labeler`, `assign`, `ghqr-weekly`) |
| `infra/github-org/` | OpenTofu config for org-level GitHub settings |
| `infra/dotgithub/` | OpenTofu config for this `.github` repository's own settings |
| `brand/` | Org icon and shared brand assets |
| `mise.toml` | Tool versions for ad-hoc local authoring (`opentofu` for `tofu fmt`/`validate`); plan/apply runs in CI |

Individual repositories may override any of the org-wide health files (`SECURITY.md`, `CODE_OF_CONDUCT.md`, `CONTRIBUTING.md`, issue/PR templates) by placing their own versions in the repo root or `.github/`.

## Reusable workflows

Repos under `aletheia-works/` consume the workflows in `.github/workflows/` via `workflow_call`. Notable callers and patterns:

- `terraform-plan.yml` / `terraform-apply.yml` / `terraform-autofix.yml` — used by both this repo's `infra/github-org/` and `infra/dotgithub/`, and by per-repo `infra/github/` (e.g. [vivarium/infra/github/](https://github.com/aletheia-works/vivarium/tree/main/infra/github)). Caller repos pass a thin wrapper; state and secrets stay in the caller's context.
- `commitlint.yml` — Conventional Commits enforcement, called from each repo's CI.

The reusables are versioned. `release.yml` cuts a `vX.Y.Z` tag and a GitHub release whenever one of them changes on `main`, bumping major for a breaking change, minor for `feat`, patch for anything else. Callers pin `uses: aletheia-works/.github/.github/workflows/<name>.yml@<sha> # vX.Y.Z`; Dependabot follows the tag and moves the SHA and the comment together. A `# main` comment beside a SHA is one Dependabot can never update.

`labeler.yml` and `assign.yml` in this repo's `.github/workflows/` are intentionally **not** reusable — they run only against this `.github` repo. Each consumer repo has its own copy of the labeler/assign workflows alongside its own `.github/labeler.yml` rules.

See [`infra/github-org/README.md`](./infra/github-org/README.md) for the org-state Terraform layout, [`infra/dotgithub/README.md`](./infra/dotgithub/README.md) for this `.github` repo's own settings, and each repo's own `infra/github/README.md` for per-repo settings.

## License

Apache License 2.0.
