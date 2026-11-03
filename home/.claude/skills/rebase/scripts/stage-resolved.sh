#!/usr/bin/env bash
#
# Stages a path a rebase conflict left, and is the only way the skill stages one. It never stages a
# result identical to one side without an answer: git can settle a conflict for one side with no
# markers, for reasons no list can cover, and a marker check alone reads that as resolved.
#
# Usage: stage-resolved.sh [--side-chosen=base|branch] [--hits-read] -- <path>
#
#   --side-chosen  the side the user chose, or a row says to take: the base is "ours" in a rebase
#                  and the branch is "theirs". A file holding the other side is refused.
#   --hits-read    each marker hit was read and is not a marker
#
# Run it from the repository root, since state.sh prints root-relative paths. Exits 0 when staged
# and changes nothing otherwise: 1 on conflict markers, 2 when the path cannot be read or the usage
# is wrong and 3 when the result needs an answer.

set -uo pipefail

usage="Usage: stage-resolved.sh [--side-chosen=base|branch] [--hits-read] -- <path>"
chosen='' hits_read=0
while (($#)); do
  case $1 in
    --side-chosen=base) chosen=2; shift ;;
    --side-chosen=branch) chosen=3; shift ;;
    --hits-read) hits_read=1; shift ;;
    --) shift; break ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
done
(($# == 1)) || { echo "$usage" >&2; exit 2; }
path=$1
[[ -z $(git rev-parse --show-prefix) ]] || { echo "Run from the repository root." >&2; exit 2; }
# A path is a name here, never a pattern
export GIT_LITERAL_PATHSPECS=1

if [[ ! -e $path && ! -L $path ]]; then
  echo "$path does not exist, so nothing was staged. Remove a path with git rm." >&2
  exit 2
fi

# The stages of exactly this path: a directory's pathspec also lists what is under it
mode1='' sha1='' mode2='' sha2='' mode3='' sha3='' listed=0
while IFS= read -r -d '' entry; do
  listed=1
  [[ ${entry#*$'\t'} == "$path" ]] || continue
  read -r mode sha stage <<<"${entry%%$'\t'*}"
  printf -v "mode${stage}" '%s' "$mode"
  printf -v "sha${stage}" '%s' "$sha"
done < <(git ls-files -u -z -- "$path")

is_link() { [[ $1 == 160000 ]]; }
if [[ -d $path && ! -L $path ]] && ! is_link "$mode2" && ! is_link "$mode3"; then
  echo "$path is a directory; name the files in it." >&2
  exit 2
fi

# Another spelling of a conflicted path, such as ./f, would otherwise find no stages to check
if ((listed)) && [[ -z $sha1$sha2$sha3 && ! -d $path ]]; then
  echo "Name $path exactly as state.sh prints it; nothing was staged." >&2
  exit 2
fi

has_nul() {
  [[ -n $1 ]] && ! is_link "$2" \
    && (($(git cat-file blob "$1" | head -c 8000 | LC_ALL=C tr -dc '\000' | wc -c) > 0))
}
# The blob this path would stage, with the project's filters applied, or a submodule's commit
current=''
if [[ -d $path && ! -L $path ]]; then
  current=$(git -C "$path" rev-parse HEAD 2>/dev/null)
elif [[ -L $path ]]; then
  current=$(readlink -- "$path" | tr -d '\n' | git hash-object --stdin)
elif ! current=$(git hash-object -w --path="$path" -- "$path" 2>/dev/null); then
  echo "Cannot read $path; nothing was staged." >&2
  exit 2
fi

# Prints why the result needs an answer, or nothing. A second line of "must-match" says a chosen
# result has to be one side, since this conflict cannot be merged by hand.
needs_answer() {
  if [[ -z $sha2 && -z $sha3 ]]; then return; fi
  if [[ -z $sha2 || -z $sha3 ]]; then echo "only one side has this path"; return; fi
  case "$mode2 $mode3" in
    100644\ 100644 | 100644\ 100755 | 100755\ 100644 | 100755\ 100755) ;;
    *) echo 'a symlink or submodule'; echo must-match; return ;;
  esac
  if has_nul "$sha1" "$mode1" || has_nul "$sha2" "$mode2" || has_nul "$sha3" "$mode3"; then
    echo 'a binary file'; echo must-match; return
  fi
  local merge
  merge=$(git check-attr merge -- "$path" | sed 's/^.*: //')
  if [[ $merge == unset || $merge == binary ]]; then echo "merge=$merge"; return; fi
  if [[ $current == "$sha2" || $current == "$sha3" ]]; then echo 'it matches one side exactly'; fi
}

answer=$(needs_answer)
why=${answer%%$'\n'*}
if [[ -n $why ]]; then
  if [[ -z $chosen ]]; then
    echo "$path needs an answer ($why). Show both sides and ask:" >&2
    git ls-files -u -- "$path" >&2
    exit 3
  fi
  named=sha$chosen other=sha$((5 - chosen))
  if [[ -z ${!named} ]]; then
    echo "$path does not exist on the side named, so nothing was staged." >&2
    exit 3
  fi
  if [[ $current == "${!other}" && $current != "${!named}" ]]; then
    echo "$path holds the other side. Take the one the user chose first; nothing was staged." >&2
    exit 3
  fi
  if [[ $answer == *must-match* && $current != "${!named}" ]]; then
    echo "$path does not hold the side named ($why), so take it first; nothing was staged." >&2
    exit 3
  fi
fi

if [[ -f $path && ! -L $path ]]; then
  # A project can shrink its markers below git's usual seven. The blob rather than the file, so an
  # encoding filter cannot hide them.
  size=$(git check-attr conflict-marker-size -- "$path" | sed 's/^.*: //')
  [[ $size =~ ^[0-9]+$ ]] && ((size < 7)) || size=7
  hits=$(git cat-file blob "$current" | LC_ALL=C command grep -a -nE \
    -e "^(<{$size,}|={$size,}|>{$size,}|[|]{$size,})([[:space:]]|\$)")
  case $? in
    0)
      if ((!hits_read)); then
        printf '%s\n' "$hits" >&2
        echo "$path has lines that look like conflict markers; nothing was staged." >&2
        exit 1
      fi
      ;;
    1) ;;
    *) echo "Cannot read $path; nothing was staged." >&2; exit 2 ;;
  esac
fi

git add -- "$path" || { echo "git add failed for $path." >&2; exit 2; }
# A case-insensitive filesystem can add another spelling and leave this name unmerged
while IFS= read -r -d '' entry; do
  if [[ ${entry#*$'\t'} == "$path" ]]; then
    echo "$path is still unmerged after git add: remove any name differing only by case first." >&2
    exit 2
  fi
done < <(git ls-files -u -z -- "$path")
# Only shown: whitespace either side already carried belongs in the explanation
git diff --cached --check -- "$path" >&2
exit 0
