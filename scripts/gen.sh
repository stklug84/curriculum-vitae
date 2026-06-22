#!/usr/bin/env bash
# @author:
#	Steffen Klug <45033201+stklug84@users.noreply.github.com>
# @description:
#	Regenerate the committed per-section .tex snapshot for every CV
#	variant from the single source of truth data/cv.yml, using the
#	cv/parse emitter (scripts/parse.py from stklug84/actions). The
#	generated files (cv-*.tex + personal-info.tex) are committed as a
#	local-build fallback so the repo builds without CI regeneration;
#	run this whenever data/cv.yml changes and commit the result.
#
#	Each variant is declared in the VARIANTS array as a colon-separated
#	dir:style:lang triple (e.g. cvs/databricks-en:sidebar:en). The third
#	field selects that variant's output language; when omitted (a
#	two-field dir:style entry) it falls back to the global LANG_OUT
#	(CV_LANG, default de) for backward compatibility.
#
#	With --check, validate data/cv.yml against the cv/parse schema
#	instead of generating (no files are written).
# @dependencies:
#	python3 (>= 3.9), PyYAML, Jinja2
#	The cv/parse action checkout. Point PARSE_PY at its parse.py, or
#	set ACTION_DIR to the action root. Defaults assume a sibling
#	checkout at ../actions/cv/parse relative to this repo.
# @usage:
#	scripts/gen.sh                 # regenerate section files
#	scripts/gen.sh --check         # validate data/cv.yml only
#	ACTION_DIR=/path/to/actions/cv/parse scripts/gen.sh
#	PARSE_PY=/path/to/parse.py scripts/gen.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SOURCE="${SOURCE:-data/cv.yml}"
LANG_OUT="${CV_LANG:-de}"

# Parse arguments. --check validates the source against the cv/parse
# schema and exits without generating anything.
CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --check) CHECK_ONLY=1 ;;
    -h|--help)
      sed -n '2,29p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      echo "       usage: scripts/gen.sh [--check]" >&2
      exit 2
      ;;
  esac
done

# Resolve the cv/parse emitter.
if [ -n "${PARSE_PY:-}" ]; then
  :
elif [ -n "${ACTION_DIR:-}" ]; then
  PARSE_PY="$ACTION_DIR/scripts/parse.py"
else
  PARSE_PY="$REPO_ROOT/../actions/cv/parse/scripts/parse.py"
fi

if [ ! -f "$PARSE_PY" ]; then
  echo "error: cv/parse emitter not found at: $PARSE_PY" >&2
  echo "       set ACTION_DIR or PARSE_PY (see header)." >&2
  exit 1
fi

# Validate-only mode: check the source against the cv/parse schema and
# exit without writing any files.
if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "Checking ${SOURCE} against the cv/parse schema"
  exec python3 "$PARSE_PY" --source "$SOURCE" --check
fi

# variant-dir:style:lang triples. The optional third field selects the
# output language for that variant; if omitted, it falls back to the
# global $LANG_OUT (CV_LANG, default de) for backward compatibility.
VARIANTS=(
  "cvs/photo-2page:plain:de"
  "cvs/sidebar:sidebar:de"
  "cvs/databricks-en:sidebar:en"
  "cvs/databricks-de:sidebar:de"
  # Example-CV showcase variants (styles in styles/cv-{sidebar-pw,sidebar-dh,
  # sidebar-vs,banking-fs,tagged-ia}.sty). Each builds today from its
  # committed fallback section bodies; the entries below are STAGED and
  # commented out because they need new cv/parse --style emitters in
  # stklug84/actions (pw/dh/vs alias the sidebar emitter; fs/ia get their
  # own templates). Uncomment once cv/parse ships those styles and the pin
  # in .github/workflows/build.yml is bumped. See README "Known caveats".
  # "cvs/pw:pw:de"   # PENDING cv/parse style support
  # "cvs/dh:dh:de"   # PENDING cv/parse style support
  # "cvs/vs:vs:en"   # PENDING cv/parse style support
  # "cvs/fs:fs:en"   # PENDING cv/parse style support
  # "cvs/ia:ia:de"   # PENDING cv/parse style support
)

for entry in "${VARIANTS[@]}"; do
  # Split on ':' into fields: dir=1, style=2, lang=3 (optional).
  IFS=':' read -r dir style lang <<<"$entry"
  # Backward-compat: a two-field entry (no lang) falls back to $LANG_OUT.
  lang="${lang:-$LANG_OUT}"
  echo "Generating ${style} (lang=${lang}) into ${dir}/"
  python3 "$PARSE_PY" \
    --source "$SOURCE" \
    --mode latex \
    --style "$style" \
    --lang "$lang" \
    --out-dir "$dir"
done

echo "Done. Review and commit the regenerated cv-*.tex + personal-info.tex."
