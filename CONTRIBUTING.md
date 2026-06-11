# Contributing

Thanks for your interest in improving this repository. It is primarily a
personal CV project, but its build infrastructure (auto-discovered matrix
builds, composite actions, digest-pinned TeX Live container) is designed to
be reusable — contributions to either are welcome.

## Ground rules

- Open a pull request from a feature branch; there is no `push` build, CI
  runs on every PR and builds **all** CV variants.
- Keep PRs focused: one logical change (a variant, a style tweak, a CI
  improvement) per PR.
- Do not commit build byproducts (`*.aux`, `*.log`, `*.pdf`,
  `*.synctex.gz`, …). They are gitignored; keep it that way.
- Do not commit personal data other than what `personal-info.tex` already
  exposes intentionally.

## Repository layout

| Path | Purpose |
| --- | --- |
| `cvs/<name>/` | One directory per CV variant (one main `.tex` + `.engine`) |
| `styles/*.sty`, `personal-info.tex`, `images/` | Shared assets, resolved via `TEXINPUTS` |
| `.github/workflows/build.yml` | Orchestration only: discover → build (matrix) → package |
| `.github/actions/discover-variants/` | Composite action: scans `cvs/*/`, emits the build matrix |
| `.github/actions/build-latex/` | Composite action: engine dispatch, aux tools, PDF verification |
| `.github/actions/upload-build-logs/` | Composite action: log artifacts on failure |
| `.github/docker/texlive/Dockerfile` | Digest pin for the TeX Live container (tracked by Dependabot) |

## Adding or changing a CV variant

1. `mkdir cvs/<name>` and add exactly **one** `*.tex` containing
   `\documentclass`. Reference shared assets normally
   (`\input{personal-info}`, `\usepackage{cv-sidebar}`,
   `\includegraphics{images/photo.jpg}`).
2. Declare the engine: `echo <engine> > cvs/<name>/.engine` — one of
   `latexmk` (default if the file is absent), `pdflatex`, `xelatex`,
   `latex-chain`. Use `latex-chain` whenever the document uses `psfrag`;
   CI fails fast otherwise.
3. Build locally before pushing (see below). CI discovers the variant
   automatically — never edit the workflow to register a variant.

## Building locally

Direct, with a host TeX Live install:

```sh
cd cvs/<variant>
TEXINPUTS=.:../..:../../styles:../../images: <engine> -interaction=nonstopmode -halt-on-error <main>.tex
```

Or replay the full CI matrix in the pinned container (no host TeX Live
needed):

```sh
gh act workflow_dispatch -W .github/workflows/build.yml --input local=true
```

## Working on the CI infrastructure

- **Keep the separation of concerns**: the matrix entry is pure data
  (`name`, `dir`, `main`, `engine`, `has_*` flags); behavior lives in the
  composite actions. New engines or aux tools belong in
  `.github/actions/build-latex/scripts/build.sh`, new discovery rules in
  `.github/actions/discover-variants/scripts/scan.sh` — not in the
  workflow.
- **Shell scripts** must pass `shellcheck`, run with
  `set -euo pipefail`, stay bash-3.2-compatible (macOS) for local
  testability, and carry the repository's header convention
  (`@author` / `@dependencies` / `@description` / `@arguments` /
  `## Usage:` / `### Example:`).
- **Workflows and actions** must pass `actionlint`.
- **Test discovery locally** without CI:

  ```sh
  .github/actions/discover-variants/scripts/scan.sh cvs latexmk | jq .
  ```

- **Dependencies** are managed by Dependabot (`.github/dependabot.yml`):
  GitHub Actions in workflows and composite actions, plus the TeX Live
  image digest in `.github/docker/texlive/Dockerfile`. Do not hand-bump
  pinned versions in a feature PR; let Dependabot do it, or open a
  dedicated PR.

## Checklist before opening a PR

- [ ] `shellcheck` clean on any touched `*.sh`
- [ ] `actionlint` clean on any touched workflow/action YAML
- [ ] Variant builds locally (direct or via `gh act`)
- [ ] No build byproducts or unrelated changes staged
- [ ] README updated if behavior, layout, or conventions changed
