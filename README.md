# quality

One quality gate for all my repos: a container image with pinned lint tools, the
`lint` script that runs them, central default configs, and a reusable GitHub
workflow. CI and local runs use the same image, so they agree.

## Checks

Always: editorconfig-checker, typos, gitleaks.

Switched on when git tracks matching files:

| Files | Check |
| --- | --- |
| `*.yaml`, `*.yml` | yamllint |
| `.github/workflows/*` | actionlint (with shellcheck on `run:` blocks) |
| `*.sh`, or a `sh`/`bash`/`dash`/`ksh` shebang | shellcheck, shfmt (indent from `.editorconfig`) |
| `Dockerfile`, `Dockerfile.*`, `*.Dockerfile` | hadolint |
| `*.py` | ruff check, ruff format --check |
| `compose.yaml`, `*compose.yml` | docker compose config |

Only tracked files count, so `git add` new files first. Language-specific build
gates (compiling with warnings as errors, tests, smoke tests) stay in each project:
they are about the project, not about shared rules.

## Use

In a project's CI:

```yaml
jobs:
  lint:
    uses: simonplattner/quality/.github/workflows/lint.yaml@v1
```

Locally, from the project root:

```bash
docker run --rm -v "$PWD:/work" ghcr.io/simonplattner/quality:v1
```

## Config

Central defaults live in `config/` and are baked into the image at
`/etc/quality`. A repo's own config file for a tool replaces the default:
`.yamllint(.yaml)`, `.editorconfig-checker.json`, `.hadolint.yaml`,
`ruff.toml` / `pyproject.toml` with `[tool.ruff]`. To change a single rule rather
than replace everything, extend the default:

```yaml
# .yamllint.yaml
extends: /etc/quality/yamllint.yaml
rules:
  line-length:
    max: 160
```

```toml
# ruff.toml
extend = "/etc/quality/ruff.toml"
```

editorconfig-checker skips indent size and max line length by default:
formatters own indentation (yamllint, ruff format, shfmt, and per language in
each project), and its indent check misfires on Markdown list continuations and
aligned continuation lines. Line length is enforced where it matters, by yamllint
and ruff format; tables, URLs and digests cannot wrap.

typos, gitleaks, shellcheck and actionlint have no central config; their native
repo files (`_typos.toml`, `.gitleaks.toml`, `.gitleaksignore`, `.shellcheckrc`,
`.github/actionlint.yaml`) apply as usual.

## Release

Projects pin a release, so a new rule shows up as a red Renovate PR per repo
instead of breaking every `main` at once.

1. Set the image tag in `.github/workflows/lint.yaml` to the new version, commit.
2. Push tag `vN`. `release.yaml` checks the tag matches `lint.yaml`, runs the
   tests and publishes `ghcr.io/simonplattner/quality:vN`. Release tags are
   immutable: it refuses a tag whose image already exists.

Callers that bump to `vN` in the few minutes before the image is published fail
once; rerun them.

## Development

```bash
docker build -t quality .
docker run --rm -v "$PWD/tests:/tests:ro" quality /tests/run   # tests for lint
docker run --rm -v "$PWD:/work" quality                        # lint this repo
```

Renovate opens weekly PRs for tool and action updates, each at least 14 days old.
Minor and patch updates automerge once `ci` passes. The image ships them with the
next release.
