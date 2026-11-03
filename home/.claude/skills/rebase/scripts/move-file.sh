#!/usr/bin/env bash
#
# Moves a file git placed during a rebase conflict to the path the user chose, leaving it for
# stage-resolved.sh. mv alone replaces whatever is at the destination, so this refuses that.
#
# Usage: move-file.sh <path> <new path>
#
# Run it from the repository root. Exits 0 when moved, 2 when <path> is not conflicted or the usage
# is wrong and 3 when <new path> is occupied, on disk or in the index, so another name is needed.

set -euo pipefail

(($# == 2)) || { echo "Usage: move-file.sh <path> <new path>" >&2; exit 2; }
[[ -z $(git rev-parse --show-prefix) ]] || { echo "Run from the repository root." >&2; exit 2; }
path=$1 new=$2
# A path is a name here, never a pattern
export GIT_LITERAL_PATHSPECS=1

[[ -n $(git ls-files -u -- "$path") ]] || { echo "$path is not a conflicted path." >&2; exit 2; }
if [[ -e $new || -L $new ]] || git ls-files -s -- "$new" | grep -q $'^[0-9]* [0-9a-f]* 0\t'; then
  echo "$new is occupied, so nothing was moved. Ask for another name." >&2
  exit 3
fi
mkdir -p -- "$(dirname -- "$new")"
mv -- "$path" "$new"
git rm --quiet --cached -- "$path"
