#!/usr/bin/env bash
#
# Prints the lines this branch adds or modifies in tracked files, one "path<TAB>first-last" row per
# hunk, measured against the merge base with the branch's base. Committed, staged and unstaged
# changes all count; untracked files do not, and each named path that is untracked or missing is
# reported on stderr rather than skipped silently.
#
# Usage: changed-lines.sh [--base <ref>] [path...]
#
# Without --base, the base is the pull request's base branch, then the repository default, then
# origin/HEAD, and stderr names the ref with whichever of these chose it. A hunk that only deletes
# lines is reported as the two lines either side of the gap, since the deletion can leave the
# paragraph around it short.

set -euo pipefail

usage="Usage: changed-lines.sh [--base <ref>] [path...]"
base='' chosen_by=--base paths=()
while (($#)); do
  case $1 in
    --base)
      (($# >= 2)) || { echo "--base needs a ref. $usage" >&2; exit 2; }
      base=$2
      shift 2
      ;;
    --base=?*) base=${1#--base=}; shift ;;
    --base=) echo "--base needs a ref. $usage" >&2; exit 2 ;;
    --) shift; paths+=("$@"); break ;;
    -*) echo "Unknown option $1. $usage" >&2; exit 2 ;;
    *) paths+=("$1"); shift ;;
  esac
done

# The guarded expansion keeps an empty array from tripping set -u under the bash 3.2 in /bin/bash
for path in ${paths[@]+"${paths[@]}"}; do
  if git ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
    continue
  elif [[ -e $path ]]; then
    echo "untracked, so not diffed: $path" >&2
  else
    echo "no such path: $path" >&2
  fi
done

if [[ -z $base ]]; then
  if name=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null); then
    chosen_by="pull request"
  elif name=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null); then
    chosen_by="repository default"
  else
    name=
  fi

  if [[ -n $name ]]; then
    base=$name
    # In a fork, gh names the parent's branch, which upstream tracks and origin's copy may lag
    for remote in upstream origin; do
      if git rev-parse --verify --quiet "refs/remotes/$remote/$name" >/dev/null; then
        base=$remote/$name
        break
      fi
    done
  else
    base=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null) || {
      echo "No base found: gh is unavailable and origin/HEAD is unset. Pass --base <ref>." >&2
      exit 1
    }
    chosen_by=origin/HEAD
  fi
fi

git rev-parse --verify --quiet "$base^{commit}" >/dev/null || {
  echo "Not a commit: $base. $usage" >&2
  exit 1
}
merge_base=$(git merge-base HEAD "$base") || {
  echo "No merge base between HEAD and $base; fetch more history or pass --base <ref>." >&2
  exit 1
}
echo "base: $base ($chosen_by; merge base $merge_base)" >&2

# --default-prefix keeps every header "+++ b/<path>" whatever the diff prefix settings say. A
# "+++" line is a header only before its file's first "@@", since an added line beginning "++ b/"
# reads the same. Git ends a header with a tab when the path holds a space, and C-quotes a path
# holding a quote, backslash or control character, which is reported rather than misread.
git -c core.quotePath=false diff --no-color --no-ext-diff --default-prefix --ignore-submodules \
  --unified=0 --diff-filter=d "$merge_base" -- ${paths[@]+"${paths[@]}"} \
  | awk '
    /^diff --git / { header = 1; path = ""; next }
    header && /^\+\+\+ / {
      if ($0 ~ /^\+\+\+ b\//) {
        path = substr($0, 7)
        sub(/\t$/, "", path)
      } else {
        print "skipped a quoted path; rename it to reflow it: " substr($0, 5) > "/dev/stderr"
      }
      next
    }
    /^@@ / {
      header = 0
      if (path == "") next
      split(substr($3, 2), hunk, ",")
      start = hunk[1] + 0
      count = (2 in hunk) ? hunk[2] + 0 : 1
      if (count == 0) {
        first = start > 0 ? start : 1
        last = start + 1
      } else {
        first = start
        last = start + count - 1
      }
      printf "%s\t%d-%d\n", path, first, last
    }
  '
