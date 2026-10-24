#!/usr/bin/env bash
#
# Lists the branches stacked on a branch, breadth-first, so each can be restacked after its parent.
# Prints one tab-separated row per candidate child:
#
#   parent  parent_old  child  child_old  pr  worktree  remote  note
#
# parent_old and child_old are the tips before any restack: run git rebase --onto with the parent's
# new tip, parent_old and the child. pr is the child's open pull request. worktree is the path of
# another worktree that has the child checked out, which git rebase refuses to touch. remote is yes
# when the child exists on its push remote and no when restacking would be its first push. An empty
# field prints as -, since read with a tab IFS would collapse two tabs into one.
#
# note is ok for a child that can be restacked: one whose open pull request is based on the parent
# or, with no pull request, whose commits since parent_old include no merge. Only ok rows have their
# own children listed. The others are reported, never restacked:
#
#   other-base     its open pull request targets another branch
#   has-merges     no pull request, and it merged parent_old in, as a long-lived branch does
#   not-on-parent  its open pull request targets the parent, but it lacks parent_old
#   not-local      an open pull request based on the parent, with no local branch
#
# Usage: stack.sh <branch> <old_tip> <default> [<repo>]
#
# Run it after rebasing <branch> but before restacking anything, with <old_tip> the branch's tip
# from before its rebase. Without <repo>, no pull request is consulted, so every child is judged by
# its history alone.

set -euo pipefail
# shellcheck source=SCRIPTDIR/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage="Usage: stack.sh <branch> <old_tip> <default> [<repo>]"
(($# == 3 || $# == 4)) || { echo "$usage" >&2; exit 2; }
root=$1 default=$3 repo=${4-}
require_plain_names "$root" "$default"
root_old=$(git rev-parse --verify "$2^{commit}")

worktree_of() {
  git worktree list --porcelain | awk -v want="branch refs/heads/$1" '
    /^worktree / { path = substr($0, 10) }
    $0 == want { found = path }
    END { print (found == "" ? "-" : found) }'
}

on_remote() {
  if [[ -n $(remote_sha "$(push_remote_of "$1")" "$1") ]]; then echo yes; else echo no; fi
}

# Prints "<number> <baseRefName>", tab-separated, for <branch>'s open pull request, or nothing
open_pr_of() {
  [[ -n $repo ]] || return 0
  gh pr list --repo "$repo" --head "$1" --state open --limit 1 --json number,baseRefName \
    --jq '.[0] | select(. != null) | [.number, .baseRefName] | @tsv' 2>/dev/null || true
}

tip() { git rev-parse "refs/heads/$1"; }

queue=("$root") queue_old=("$root_old") seen=" $root $default "
i=0
while ((i < ${#queue[@]})); do
  parent=${queue[i]} parent_old=${queue_old[i]}
  i=$((i + 1))

  candidates=()
  while IFS= read -r name; do
    [[ $seen == *" $name "* || $(tip "$name") == "$parent_old" ]] && continue
    require_plain_names "$name"
    candidates+=("$name")
  done < <(git for-each-ref --contains "$parent_old" --format='%(refname:lstrip=2)' refs/heads)

  # A candidate that contains another candidate's tip is stacked on that one, not on the parent
  children=()
  for child in ${candidates[@]+"${candidates[@]}"}; do
    direct=1
    for other in "${candidates[@]}"; do
      if [[ $other != "$child" && $(tip "$other") != $(tip "$child") ]] \
        && git merge-base --is-ancestor "refs/heads/$other" "refs/heads/$child"; then
        direct=0
        break
      fi
    done
    ((direct)) && children+=("$child")
  done

  for child in ${children[@]+"${children[@]}"}; do
    old=$(tip "$child")
    number='' pr_base=''
    row=$(open_pr_of "$child")
    [[ -n $row ]] && IFS=$'\t' read -r number pr_base <<<"$row"
    if [[ -n $number && $pr_base != "$parent" ]]; then
      note='other-base'
    elif [[ -z $number && -n $(git rev-list --merges "$parent_old..$old") ]]; then
      note='has-merges'
    else
      note=ok
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$parent" "$parent_old" "$child" "$old" \
      "${number:--}" "$(worktree_of "$child")" "$(on_remote "$child")" "$note"
    seen+="$child "
    if [[ $note == ok ]]; then
      queue+=("$child") queue_old+=("$old")
    fi
  done

  if [[ -n $repo ]]; then
    while IFS=$'\t' read -r child number; do
      [[ -n $child && $seen != *" $child "* && " ${candidates[*]-} " != *" $child "* ]] || continue
      require_plain_names "$child"
      if git rev-parse --verify --quiet "refs/heads/$child" >/dev/null; then
        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\tnot-on-parent\n' "$parent" "$parent_old" "$child" \
          "$(tip "$child")" "$number" "$(worktree_of "$child")" "$(on_remote "$child")"
      else
        printf '%s\t%s\t%s\t-\t%s\t-\t-\tnot-local\n' "$parent" "$parent_old" "$child" "$number"
      fi
      seen+="$child "
    done < <(gh pr list --repo "$repo" --base "$parent" --state open --json number,headRefName \
      --jq '.[] | [.headRefName, .number] | @tsv' 2>/dev/null || true)
  fi
done
