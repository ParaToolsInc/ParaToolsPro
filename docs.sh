#!/usr/bin/env bash
# Convenience wrapper for building/serving the ParaTools Pro for E4S docs.
#
# Uses `uv run --with-requirements` so no virtualenv or global install is
# needed - dependencies are resolved and cached per invocation.
#
# Usage:
#   ./docs.sh build [--strict]
#   ./docs.sh serve
#   ./docs.sh gh-deploy --force
#   ./docs.sh linkcheck                  # runs mkdocs-linkcheck over site/
set -euo pipefail

cd "$(dirname "$0")"
export DISABLE_MKDOCS_2_WARNING=true

if [[ $# -eq 0 ]]; then
    set -- serve
fi

case "$1" in
    linkcheck)
        shift
        exec uv run --with-requirements requirements.txt \
            mkdocs-linkcheck -r docs \
                -m get \
                --exclude "console.cloud.google.com" \
                --exclude "\.md$" \
                --exclude "\.yaml$" \
                "$@"
        ;;
    *)
        exec uv run --with-requirements requirements.txt properdocs "$@"
        ;;
esac
