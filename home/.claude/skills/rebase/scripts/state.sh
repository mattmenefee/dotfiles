#!/usr/bin/env bash
#
# Prints the checkout's state as key=value lines, so a session that starts mid-rebase can resume
# rather than restart:
#
#   op             rebase-merge, rebase-apply, am, merge, cherry-pick, revert, bisect or none
#   branch         the branch being rebased, or the current branch; empty when HEAD is detached
#   onto           during a rebase, the commit it replays onto
#   onto_refs      during a rebase, the refs pointing at that commit, comma-separated
#   orig_head      during a rebase, the branch's tip before it began: the recovery point
#   step           during a rebase, the commit it is on, as <done>/<total>
#   dirty_tracked  the number of changed tracked paths, conflicted ones included
#   conflict       one line per conflicted path, unquoted unless it holds a control character, a
#                  quote or a backslash
#
# Usage: state.sh

set -euo pipefail

(($# == 0)) || { echo "Usage: state.sh" >&2; exit 2; }

git_path() { git rev-parse --git-path "$1"; }

op=none
if [[ -d $(git_path rebase-merge) ]]; then
  op=rebase-merge
elif [[ -d $(git_path rebase-apply) ]]; then
  op=rebase-apply
  [[ -e $(git_path rebase-apply)/applying ]] && op=am
elif [[ -e $(git_path MERGE_HEAD) ]]; then
  op=merge
elif [[ -e $(git_path CHERRY_PICK_HEAD) ]]; then
  op=cherry-pick
elif [[ -e $(git_path REVERT_HEAD) ]]; then
  op=revert
elif [[ -e $(git_path BISECT_LOG) ]]; then
  op=bisect
fi
echo "op=$op"

case $op in
  rebase-merge | rebase-apply)
    dir=$(git_path "$op")
    head_name=$(cat "$dir/head-name")
    [[ $head_name == refs/heads/* ]] && echo "branch=${head_name#refs/heads/}" || echo "branch="
    onto=$(cat "$dir/onto")
    echo "onto=$onto"
    refs=$(git for-each-ref --points-at "$onto" --format='%(refname:short)' | paste -sd, -)
    echo "onto_refs=$refs"
    echo "orig_head=$(cat "$dir/orig-head")"
    if [[ $op == rebase-merge ]]; then
      echo "step=$(cat "$dir/msgnum" 2>/dev/null || echo 0)/$(cat "$dir/end")"
    else
      echo "step=$(cat "$dir/next")/$(cat "$dir/last")"
    fi
    ;;
  *) echo "branch=$(git branch --show-current)" ;;
esac

echo "dirty_tracked=$(git status --porcelain --untracked-files=no | wc -l | tr -d ' ')"
git -c core.quotePath=false diff --name-only --diff-filter=U | sed 's/^/conflict=/'
