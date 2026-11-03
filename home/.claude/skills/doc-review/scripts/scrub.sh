#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
#
# Scans this repository's top-level review artifacts (*local-review*.md, *-DOC-REVIEW*.md,
# *-HANDOFF.md, *PLAN.md) for anything that must not reach a pull request comment.
#
# Usage: scrub.sh [cleared-lines-file]
#
# Exit 0: clean. Exit 1: hits, printed after the list of files scanned. Exit 2: the scan itself
# failed or found nothing to scan; treat it as a block, never as clean.
#
# Rewrite identifying hits in the review file and run it again. Secret-shaped hits go to the user,
# who may clear lines that are not credentials (see PR Comment Format in ../posting.md).

root="$(git rev-parse --show-toplevel)" || exit 2
cleared="${1:-/dev/null}"
# shellcheck source=scrub-lib.sh
. "$(dirname "$0")/scrub-lib.sh" || exit 2

scanned="$(artifacts -print)"
[ -n "$scanned" ] || { echo "scrub: no artifacts under $root — nothing was scanned" >&2; exit 2; }
printf 'scrub: scanned these files\n%s\n' "$scanned"
hits="$(scan)" || { echo "scrub FAILED — do not post" >&2; exit 2; }
if [ -n "$hits" ]; then
  printf '%s\n' "$hits"
  exit 1
fi
echo "scrub: clean"
