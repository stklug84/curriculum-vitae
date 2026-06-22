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
# @dependencies:
#	python3 (>= 3.9), PyYAML, Jinja2
#	The cv/parse action checkout. Point PARSE_PY at its parse.py, or
#	set ACTION_DIR to the action root. Defaults assume a sibling
#	checkout at ../actions/cv/parse relative to this repo.
# @usage:
#	scripts/gen.sh
#	ACTION_DIR=/path/to/actions/cv/parse scripts/gen.sh
#	PARSE_PY=/path/to/parse.py scripts/gen.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SOURCE="${SOURCE:-data/cv.yml}"
LANG_OUT="${CV_LANG:-de}"

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

# variant-dir:style pairs.
VARIANTS=(
  "cvs/photo-2page:plain"
  "cvs/sidebar:sidebar"
)

for pair in "${VARIANTS[@]}"; do
  dir="${pair%%:*}"
  style="${pair##*:}"
  echo "Generating ${style} (lang=${LANG_OUT}) into ${dir}/"
  python3 "$PARSE_PY" \
    --source "$SOURCE" \
    --mode latex \
    --style "$style" \
    --lang "$LANG_OUT" \
    --out-dir "$dir"
done

echo "Done. Review and commit the regenerated cv-*.tex + personal-info.tex."
