# Convenience targets for the CV repository.
#
# `make gen`   regenerate the committed per-section .tex snapshot from
#              data/cv.yml for every variant (see scripts/gen.sh).
# `make check` validate data/cv.yml against the cv/parse schema.
#
# Both delegate to the cv/parse emitter (scripts/parse.py from
# stklug84/actions). Point at it with ACTION_DIR or PARSE_PY; the
# default assumes a sibling checkout at ../actions/cv/parse.

SHELL := /usr/bin/env bash
PARSE_PY ?= ../actions/cv/parse/scripts/parse.py
SOURCE   ?= data/cv.yml

.PHONY: gen check

gen:
	scripts/gen.sh

check:
	python3 "$(PARSE_PY)" --source "$(SOURCE)" --check
