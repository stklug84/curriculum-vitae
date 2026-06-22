# `data/cv.yml` — single source of truth

`data/cv.yml` is the **canonical, bilingual** source of every CV in this
repository. The LaTeX section files under `cvs/<variant>/` and (elsewhere)
the web `cv.yml` are all *generated* from it by the
[`stklug84/actions` `cv/parse`](https://github.com/stklug84/actions) action
(major alias `v2`). Edit `cv.yml`, regenerate, commit.

## Generate → build flow

```text
data/cv.yml ──(cv/parse --mode latex --style plain  --lang de)──▶ cvs/photo-2page/cv-*.tex + personal-info.tex
            └──(cv/parse --mode latex --style sidebar --lang de)──▶ cvs/sidebar/cv-*.tex     + personal-info.tex
```

In CI the `generate` job in `.github/workflows/build.yml` runs `cv/parse`
once per variant and uploads the `cvs/**/*.tex` tree as the
`cv-generated-tex` artifact. The reusable `latex-build-cv` workflow then
downloads that artifact at the repo root (`prebuild-artifact`) **before**
the TeX Live build, so the freshly generated files override the committed
fallback (below).

Locally, regenerate with the committed helper (see the repo `Makefile` and
`scripts/gen.sh`):

```sh
make gen     # regenerate cvs/<variant>/cv-*.tex + personal-info.tex
make check   # validate data/cv.yml against the cv/parse schema
```

Both default to a sibling checkout of the action at `../actions/cv/parse`;
override with `ACTION_DIR=/path/to/actions/cv/parse` or `PARSE_PY=...`.

## Committed fallback

The generated section files (`cv-experience.tex`, `cv-education.tex`,
`cv-conferences.tex`, `cv-skills.tex`, `cv-languages.tex`,
`cv-interests.tex`, `cv-certifications.tex`) and the generated
`personal-info.tex` are **committed** under each `cvs/<variant>/` directory.
They are *not* gitignored. This snapshot lets the repo build locally (plain
`pdflatex`/`xelatex`) and keeps history reviewable without requiring the
action to run first. CI regenerates them anyway via the prebuild artifact,
so the committed copy is a convenience fallback — keep it in sync with
`make gen` whenever `cv.yml` changes.

> Each variant's local `personal-info.tex` (resolved first via
> `TEXINPUTS=.:...`) shadows the legacy repo-root `personal-info.tex`.

## Emitted section files (LaTeX mode)

| File | plain (`L!{\VRule}…`) emits | sidebar emits |
| --- | --- | --- |
| `personal-info.tex` | `\newcommand{\cv…}` macros | same (style-agnostic) |
| `cv-experience.tex` | longtable row bodies (`L!{\VRule}H`) | `\cventry` / `\cvsubentry` |
| `cv-education.tex` | longtable row bodies (`L!{\VRule}H`) | `\cventry` |
| `cv-conferences.tex` | longtable row bodies (`L!{\VRule}H`) | `\cventry` |
| `cv-skills.tex` | longtable row bodies (`L!{\VRule}R`) | `\cvskillgroup` |
| `cv-languages.tex` | longtable row bodies (`L!{\VRule}R`) | `\cvlanguage` |
| `cv-interests.tex` | one `L!{\VRule}R` row | `\cvsidelist` |
| `cv-certifications.tex` | numbered `L!{\VRule}R` rows | `\cvsidelist` |

The variant main `.tex` keeps the document scaffolding and wraps each plain
body in its own `\subsection*{…}\begin{longtable}{<cols>} … \input{…} …
\end{longtable}`. The sidebar main `\input`s the bodies directly under its
section headers inside the `paracol` layout.

> **Do not** put LaTeX escapes (`\&`, `\LaTeX`, `\"a`, …) in `cv.yml`.
> Write plain UTF-8 text (`&`, `LaTeX`, `ä`); the action escapes LaTeX
> specials for you and preserves `---`/`--` dashes and `\href{url}{name}`.

## Schema contract

`targets` selects which consumers an entry feeds. **Absent ⇒
`[latex, web]`.** Allowed values: `latex`, `web`. Bilingual text fields are
`{de, en}` (both required, non-empty). Neutral fields are scalars. `kind ∈
{work, study, cert}`; `level` is an int `1..5`; `year` is an int.

Top-level required keys: `meta`, `contact`, `experience`, `education`,
`conferences`, `skills`, `languages`, `certifications`, `interests`.

| Key | Shape (✱ = bilingual `{de,en}`) |
| --- | --- |
| `meta` | `display_name`, `author`, `pdf_author`, `lang_default`, `title`✱, `location`✱, `summary`✱ |
| `contact` | `birthdate`, `birthplace`, `address` (list 1–3), `phone`, `email`, `location_signature`, `photo_path`, `signature_path` (all neutral) |
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

## Known inline exceptions (sidebar)

`cv-sidebar.sty` exposes a few presentational commands the action does not
generate, so a small amount of literal text stays inline in
`cvs/sidebar/lebenslauf-sidebar.tex`:

- **`\cvname{…}{…}`** — the name maps to `\cvdisplayname` (generated); the
  role line is literal and mirrors `meta.title.de`.
- **`\cvsummary{…}`** — literal paragraph mirroring `meta.summary.de`
  (no summary macro is emitted). Keep the two in sync by hand.
- **`\cvchiprow{…}` (Tech-Stack)** and **`\cvchip{…}` (Schlüsselkonzepte)**
  — decorative chip rows with no schema counterpart; kept inline.

Everything else in both variants is generated from `cv.yml`.
