# This Dockerfile is the single source of truth for the TeX Live container
# image used by the build workflow. It is never built into an image of its
# own: the discover job extracts the FROM reference below and feeds it to
# `jobs.build.container.image`. Pinning by digest makes builds reproducible,
# and Dependabot's docker ecosystem keeps the digest current automatically.
# Please see the documentation for all configuration options:
# https://docs.github.com/code-security/dependabot/dependabot-version-updates/configuration-options-for-the-dependabot.yml-file

FROM texlive/texlive:latest@sha256:2f9918a156cfc6c7527590e06f69bfb4fbc827278e4736c90e567382855d7cd1
