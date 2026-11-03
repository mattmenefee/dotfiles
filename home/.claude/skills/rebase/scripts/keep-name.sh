#!/usr/bin/env bash
#
# Applies the answer to a rename on both sides: removes every other name and leaves the kept one in
# the worktree, still unmerged for stage-resolved.sh. It removes names from the index and the disk
# in separate steps because a case-insensitive filesystem holds foo and FOO as one file, so a plain
# git rm of the other name deletes the file being kept.
#
# Usage: keep-name.sh <kept name> <other name>...
#
# Run it from the repository root. It checks every name before changing anything. Exits 0 when done,
# 2 when the kept name is not a name from such a conflict or the usage is wrong and 3 when an other
# name holds anything else: a path both sides added, or one not in the conflict at all.

set -euo pipefail

(($# >= 2)) || { echo "Usage: keep-name.sh <kept name> <other name>..." >&2; exit 2; }
[[ -z $(git rev-parse --show-prefix) ]] || { echo "Run from the repository root." >&2; exit 2; }
kept=$1
shift
# A path is a name here, never a pattern
export GIT_LITERAL_PATHSPECS=1

# Prints the stages of exactly this path, space-separated
stages_of() {
  local entry meta found=''
  while IFS= read -r -d '' entry; do
    [[ ${entry#*$'\t'} == "$1" ]] || continue
    meta=${entry%%$'\t'*}
    found+="${meta##* } "
  done < <(git ls-files -u -z -- "$1")
  printf '%s' "${found% }"
}
on_disk() { [[ -e $1 || -L $1 ]]; }

kept_stages=$(stages_of "$kept")
case $kept_stages in
  2 | 3 | '2 3') ;;
  *) echo "$kept is not a new name from a rename on both sides." >&2; exit 2 ;;
esac
if [[ $kept_stages == '2 3' ]] && ! on_disk "$kept"; then
  echo "$kept is missing and a path both sides added cannot be restored from one side." >&2
  exit 2
fi
for name in "$@"; do
  [[ $name != "$kept" ]] || { echo "$kept is the name being kept." >&2; exit 2; }
  stages=$(stages_of "$name")
  if [[ $stages == *2*3* ]]; then
    echo "$name is a path both sides added, so it holds another file: resolve it instead." >&2
    exit 3
  fi
  # Stage 1 alone is the old name and a lone stage is another new name. Anything else here, such as
  # stages 1 and 2, is a different conflict, whose edit removing it would lose.
  case $stages in
    '' | 1 | 2 | 3) ;;
    *) echo "$name is another conflict, so nothing was changed." >&2; exit 3 ;;
  esac
  if [[ -z $stages ]] && { [[ -n $(git ls-files -- "$name") ]] || on_disk "$name"; } \
    && ! [[ $name -ef $kept ]]; then
    echo "$name is not part of this conflict, so nothing was changed." >&2
    exit 3
  fi
done

for name in "$@"; do
  stages=$(stages_of "$name")
  # Already answered on a case-insensitive filesystem: this is the kept file, which may be edited
  if [[ -z $stages && $name -ef $kept ]]; then continue; fi
  [[ -z $stages ]] || git rm --quiet --cached -- "$name"
  # The same file on a case-insensitive filesystem. A name both sides added cannot be restored from
  # one stage, so it stays.
  if [[ $name -ef $kept && $kept_stages == '2 3' ]]; then continue; fi
  rm -f -- "$name"
done
# Restores the file under the kept name's exact spelling, with that side's own content
on_disk "$kept" || git checkout-index --force --stage="$kept_stages" -- "$kept"
