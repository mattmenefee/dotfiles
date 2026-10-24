#!/usr/bin/env bash
#
# Prints the files both the branch and the new base changed since they diverged, one per line. A
# rebase can merge these cleanly and still break them, so their specs run even without a conflict.
#
# Usage: overlap.sh <old_base> <old_head> <new_base>

set -euo pipefail

(($# == 3)) || { echo "Usage: overlap.sh <old_base> <old_head> <new_base>" >&2; exit 2; }

# Assigned first so a failed diff stops the script instead of reading as no overlap
branch_side=$(git diff --name-only "$1" "$2")
base_side=$(git diff --name-only "$1" "$3")
comm -12 <(sort <<<"$branch_side") <(sort <<<"$base_side") | sed '/^$/d'
