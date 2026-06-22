# `data/` — CV sources and the build matrix

This directory holds everything that drives CV generation:

| File | Role |
| --- | --- |
| [`variants.yml`](variants.yml) | **Build matrix control plane** — declares every style, language and `(yaml × style × lang)` leaf the repo generates and builds. |
| [`cv-academics.yml`](cv-academics.yml) | Canonical, bilingual (`de`/`en`) CV source — academic-leaning content. |
| [`cv-databricks.yml`](cv-databricks.yml) | Canonical, bilingual (`de`/`en`) CV source — Databricks/industry-leaning content. |

Both `cv-*.yml` files follow the **same schema** (below). Each is a
self-contained source of truth; the per-section LaTeX files under
`cvs/<yaml>-<lang>/<style>/` are *generated* from them by the
[`stklug84/actions` `cv/parse`](https://github.com/stklug84/actions)
emitter (major alias `v2`). Edit the YAML, regenerate (CI does this
automatically), commit.

## The build matrix: `variants.yml`

`variants.yml` is the **only** place that decides which CV is rendered in
which style and language. It has three registries:

- **`styles`** — one entry per LaTeX style, mapping it to a TeX `engine`
  (written to each leaf's `.engine` dotfile) and a `parse_style` (the
  `cv/parse` body emitter the style consumes; presentation styles share
  the style-agnostic `sidebar`/`plain` emitters).
- **`langs`** — centralized per-language tokens: the `babel` language
  (passed as a `\documentclass` option for pdflatex), the `polyglossia`
  language (passed to `\setdefaultlanguage` for xelatex), and the
  localized `label_*` section headings used by the main templates.
- **`cvs`** — the matrix itself: under each source YAML name, a list of
  `{ style, lang }` leaves to generate.

For every `cvs.<yaml>` entry a leaf directory is produced:

```text
cvs/<yaml>-<lang>/<style>/sklug-cv.tex   # leaf main (from templates/<style>.tex.j2)
                          /.engine        # engine for this leaf
                          /personal-info.tex
                          /cv-*.tex        # cv/parse section bodies
```

The leaf main is always named `sklug-cv.tex`. Adding a variant means
adding one `{ style, lang }` entry; adding a style or language means
extending `styles` / `langs`. **No code or workflow change is required**
— any combination of a registered style and a registered language is
valid and will be generated and built correctly.

## Generate → build flow

Generation lives entirely in the
[`stklug84/actions/cv/generate`](https://github.com/stklug84/actions)
composite action, driven by the `latex-build-cv` reusable workflow with
`generate: 'true'`:

```text
data/variants.yml ─┐
data/cv-*.yml      ├─▶ cv/generate ─▶ cvs/<yaml>-<lang>/<style>/{sklug-cv.tex,.engine,cv-*.tex,personal-info.tex}
templates/*.tex.j2 ┘        │
                            ├─ leaf main : Jinja2 render of templates/<style>.tex.j2
                            │              (engine + babel/polyglossia + label_* from the manifest)
                            └─ section bodies + personal-info.tex : cv/parse emitter
```

In CI the reusable workflow's `generate` job runs `cv/generate`, uploads
the whole tree as an internal artifact, and lays it down at the repo root
before discovery and the TeX Live build — so the freshly generated files
override the committed fallback (below). The matrix is read only from
`variants.yml`; nothing about variant wiring is hardcoded in the workflow.

Validate the sources against the `cv/parse` schema with the action's
`check` mode (`check: 'true'`); it writes nothing and exits non-zero on
the first violation.

## Committed fallback

The generated section files (`cv-experience.tex`, `cv-education.tex`,
`cv-conferences.tex`, `cv-skills.tex`, `cv-languages.tex`,
`cv-interests.tex`, `cv-certifications.tex`), `personal-info.tex`, the
leaf `sklug-cv.tex` and the `.engine` dotfile are **committed** under each
`cvs/<yaml>-<lang>/<style>/` directory. They are *not* gitignored. This
snapshot keeps the tree reviewable in history and buildable without
running the action first. CI regenerates the whole tree anyway, so the
committed copy is a convenience fallback — it is refreshed automatically
on every CI build.

> Each leaf's local `personal-info.tex` is resolved first via
> `TEXINPUTS=.:...` from inside `cvs/<yaml>-<lang>/<style>/`.

## Emitted section files (LaTeX mode)

| File | `plain` emitter | `sidebar` emitter |
| --- | --- | --- |
| `personal-info.tex` | `\newcommand{\cv…}` macros | same (style-agnostic) |
| `cv-experience.tex` | longtable row bodies (`L!{\VRule}H`) | `\cventry` / `\cvsubentry` |
| `cv-education.tex` | longtable row bodies (`L!{\VRule}H`) | `\cventry` |
| `cv-conferences.tex` | longtable row bodies (`L!{\VRule}H`) | `\cventry` |
| `cv-skills.tex` | longtable row bodies (`L!{\VRule}R`) | `\cvskillgroup` |
| `cv-languages.tex` | longtable row bodies (`L!{\VRule}R`) | `\cvlanguage` |
| `cv-interests.tex` | one `L!{\VRule}R` row | `\cvsidelist` |
| `cv-certifications.tex` | numbered `L!{\VRule}R` rows | `\cvsidelist` |

The leaf main (`sklug-cv.tex`, rendered from `templates/<style>.tex.j2`)
keeps the document scaffolding, selects the language/encoding packages per
engine, and `\input`s the generated bodies under localized section
headings.

> **Do not** put LaTeX escapes (`\&`, `\LaTeX`, `\"a`, …) in the YAML.
> Write plain UTF-8 text (`&`, `LaTeX`, `ä`); the action escapes LaTeX
> specials for you and preserves `---`/`--` dashes and `\href{url}{name}`.

## Schema contract

`targets` selects which consumers an entry feeds. **Absent ⇒
`[latex, web]`.** Allowed values: `latex`, `web`. Bilingual text fields are
`{de, en}` (both required, non-empty). Neutral fields are scalars. `kind ∈
{work, study, cert}`; `level` is an int `1..5`; `year` is an int.

Top-level required keys: `meta`, `contact`, `experience`, `education`,
`conferences`, `skills`, `languages`, `certifications`, `interests`.

`contact` additionally supports **optional** profile links — `linkedin`,
`github` and `website` — each a `{url, label}` mapping (`url` required and
non-empty; `label` optional and derived from the URL when omitted). When
present they are emitted into `personal-info.tex` as `\cv<key>url` /
`\cv<key>label` macros (plus `\cvemailurl` for the email); absence of all
three remains valid.

| Key | Shape (✱ = bilingual `{de,en}`) |
| --- | --- |
| `meta` | `display_name`, `author`, `pdf_author`, `lang_default`, `title`✱, `location`✱, `summary`✱ |
| `contact` | `birthdate`, `birthplace`, `address` (list 1–3), `phone`, `email`, `location_signature`, `photo_path`, `signature_path` (all neutral); optional `linkedin`/`github`/`website` link mappings `{url, label}` (label optional/derived from the URL) |
| `experience[]` | `id` (unique), `targets`, `period`✱, `year` (int), `role`✱, `org`, `location`✱, `kind`, `monogram`, `bg`, `logo` (optional/null), `summary`✱, `tags` (list), `bullets[{de,en}]`, `subentries[{date, title✱, bullets[{de,en}]}]` (optional) |
| `education[]` | `id` (unique), `targets`, `period`, `degree`✱, `institution`✱, `grade` (optional), `details[{de,en}]` |
| `conferences[]` | `targets`, `year` (int), `name`, `location`, `date`, `url` (optional) |
| `skills[]` | `targets`, `group`✱, `items` (list) |
| `languages[]` | `targets`, `name`✱, `level_label`✱, `level` (1–5) |
| `certifications[]` | `targets`, `text`✱ — empty list `[]` when none |
| `interests[]` | `targets`, `de`, `en` |

### `targets` used in this repo

| Section | Targets | Rationale |
| --- | --- | --- |
| `experience` | `[latex, web]` | Roles appear in the PDF and feed the web timeline (`monogram`/`bg` set) |
| `skills` | `[latex, web]` | Shared between the PDF qualifications table and web skill chips |
| `languages` | `[latex, web]` | Shown in both the PDF and the sidebar/web |
| `certifications` | `[]` | None today (empty list) |
| `education` | `[latex]` | Detailed academic record is PDF-only |
| `conferences` | `[latex]` | Conference list is PDF-only |
| `interests` | `[latex]` | Personal interests are PDF-only |

## Role line and summary

The leaf main templates declare empty `\providecommand` fallbacks for the
role line and profile summary, so every document compiles even though the
`cv/parse` emitter does not yet emit those macros. Populating them from
`meta.title` / `meta.summary` is a pending `cv/parse` enhancement in
[`stklug84/actions`](https://github.com/stklug84/actions); until it ships,
those two lines render blank.
