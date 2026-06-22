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
- Do not commit personal data other than what `data/cv.yml` (and the
  `personal-info.tex` generated from it) already exposes intentionally.

## Repository layout

| Path | Purpose |
| --- | --- |
| `cvs/<name>/` | One directory per CV variant (one main `.tex` + `.engine` + generated `personal-info.tex` / `cv-*.tex`) |
| `data/cv.yml` | Single source of truth; section files are generated from it (`scripts/gen.sh`) |
| `styles/*.sty`, `images/` | Shared assets, resolved via `TEXINPUTS` |
| `.github/workflows/build.yml` | Orchestration only: discover → build (matrix) → package |
| `.github/docker/texlive/Dockerfile` | Digest pin for the TeX Live container (tracked by Dependabot) |

The composite actions (`texlive/discover-variants`, `texlive/build-pdf`,
`texlive/upload-build-logs`) live in the central
[`stklug84/actions`](https://github.com/stklug84/actions) repository and
are consumed SHA-pinned from the workflow.

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
  composite actions of the central
  [`stklug84/actions`](https://github.com/stklug84/actions) repository.
  New engines or aux tools belong in `texlive/build-pdf`, new discovery
  rules in `texlive/discover-variants` — over there, not in this
  workflow. Bump the SHA pins here after a release.
- **Workflows** must pass `actionlint`.
- **Dependencies** are managed by Dependabot (`.github/dependabot.yml`):
  GitHub Actions in workflows (including the SHA-pinned
  `stklug84/actions` references), plus the TeX Live image digest in
  `.github/docker/texlive/Dockerfile`. Do not hand-bump pinned versions
  in a feature PR; let Dependabot do it, or open a dedicated PR.

## Checklist before opening a PR

- [ ] `actionlint` clean on any touched workflow YAML
- [ ] Variant builds locally (direct or via `gh act`)
- [ ] No build byproducts or unrelated changes staged
- [ ] README updated if behavior, layout, or conventions changed
