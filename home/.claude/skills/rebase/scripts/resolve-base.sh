#!/usr/bin/env bash
#
# Resolves what a branch rebases onto and prints it as key=value lines:
#
#   branch          the branch resolved for
#   remote          the remote holding the base: upstream when there is one, as in a fork
#   repo            that remote's GitHub slug, or empty when gh cannot reach it
#   default         the repository's default branch
#   base, source    the branch to rebase onto and what chose it: argument, pull-request, default or
#                   merged-parent
#   pr, draft       the branch's open pull request and whether it is a draft, or empty
#   parent          the branch this one was stacked on, when that branch has since merged and its
#                   commits must be dropped with git rebase --onto; empty otherwise
#   parent_pr       the merged parent's pull request
#   old_parent_tip  the merged parent's head when it merged, which this branch contains: the
#                   upstream argument for --onto
#
# Usage: resolve-base.sh [--branch <name>] [<base>]
#
# --branch defaults to the current branch or, mid-rebase while HEAD is detached, the branch being
# rebased. Ancestry is checked against refs/heads/<branch>, which git leaves at the pre-rebase tip
# until the rebase finishes. A parent counts as merged only when GitHub has a merged pull request
# from it whose head this branch contains; a base missing from the remote without that evidence
# exits 1 rather than guess, since rebasing past an unmerged parent drops its commits.

set -euo pipefail
# shellcheck source=SCRIPTDIR/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

usage="Usage: resolve-base.sh [--branch <name>] [<base>]"
branch='' argument=''
while (($#)); do
  case $1 in
    --branch)
      (($# >= 2)) || { echo "$usage" >&2; exit 2; }
      branch=$2
      shift 2
      ;;
    -*) echo "$usage" >&2; exit 2 ;;
    *)
      [[ -z $argument ]] || { echo "$usage" >&2; exit 2; }
      argument=$1
      shift
      ;;
  esac
done

if [[ -z $branch ]]; then
  branch=$(git branch --show-current)
  for dir in rebase-merge rebase-apply; do
    head_name=$(git rev-parse --git-path "$dir/head-name")
    [[ -z $branch && -f $head_name ]] && branch=$(sed 's#^refs/heads/##' "$head_name")
  done
fi
[[ -n $branch ]] || { echo "No branch: HEAD is detached and no rebase names one." >&2; exit 1; }
require_plain_names "$branch" ${argument:+"$argument"}
tip=refs/heads/$branch

remote=origin
git remote get-url upstream >/dev/null 2>&1 && remote=upstream
slug=$(git remote get-url "$remote" | sed -E 's#\.git$##; s#^.*[:/]([^/]+/[^/]+)$#\1#')

repo='' default=''
if default=$(gh repo view "$slug" --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null) \
  && [[ -n $default ]]; then
  repo=$slug
else
  default=$(git rev-parse --abbrev-ref "$remote/HEAD" 2>/dev/null) || {
    echo "No default branch: gh cannot reach $slug and $remote/HEAD is unset. Name a base." >&2
    exit 1
  }
  default=${default#"$remote/"}
fi
require_plain_names "$default"

# Listing by head name and author rather than viewing by name, since a fork's pull request has the
# head label <owner>:<branch> and an upstream pull request may share the bare name
pr='' draft='' pr_base=''
if [[ -n $repo ]]; then
  row=$(gh pr list --repo "$repo" --head "$branch" --author @me --state open --limit 1 \
    --json number,baseRefName,isDraft \
    --jq '.[0] | select(. != null) | [.number, .baseRefName, .isDraft] | @tsv' 2>/dev/null) || row=
  [[ -n $row ]] && IFS=$'\t' read -r pr pr_base draft <<<"$row"
fi

if [[ -n $argument ]]; then
  base=$argument source=argument
elif [[ -n $pr_base ]]; then
  base=$pr_base source=pull-request
else
  base=$default source=default
fi
require_plain_names "$base"

# Prints "<number> <headRefOid> <baseRefName>", tab-separated, for the newest merged pull request
# from <branch> whose head this branch contains, or nothing. Requiring the head rejects an older
# pull request from a reused branch name.
merged_from() {
  local number head_oid base_ref
  while IFS=$'\t' read -r number head_oid base_ref; do
    [[ -n $number ]] || continue
    if git merge-base --is-ancestor "$head_oid" "$tip" 2>/dev/null; then
      printf '%s\t%s\t%s\n' "$number" "$head_oid" "$base_ref"
      return
    fi
  done < <(gh pr list --repo "$repo" --head "$1" --state merged --limit 10 \
    --json number,headRefOid,baseRefName \
    --jq '.[] | [.number, .headRefOid, .baseRefName] | @tsv' 2>/dev/null || true)
}

parent='' parent_pr='' old_parent_tip=''

rc=0
git ls-remote --exit-code "$remote" "refs/heads/$base" >/dev/null || rc=$?
if ((rc != 0 && rc != 2)); then
  echo "Cannot read $remote (git ls-remote exited $rc)." >&2
  exit 1
fi

if ((rc == 2)) || [[ $source == pull-request && $base != "$default" ]]; then
  # A base gone from the remote, or a pull request's base whose own pull request may have merged
  # with its branch kept, since GitHub retargets the child only when that branch is deleted
  row=''
  [[ -n $repo ]] && row=$(merged_from "$base")
  if [[ -n $row ]]; then
    parent=$base source=merged-parent
    IFS=$'\t' read -r parent_pr old_parent_tip base <<<"$row"
    require_plain_names "$base"
  elif ((rc == 2)); then
    why="gh cannot reach the repository to show that it merged"
    [[ -n $repo ]] \
      && why="GitHub has no merged pull request from it whose head this branch contains"
    echo "$base is not a branch on $remote, and $why. Push it, or name the base to rebase onto." >&2
    exit 1
  fi
elif [[ $base == "$default" && -n $repo ]] \
  && git rev-parse --verify --quiet "refs/remotes/$remote/$default" >/dev/null; then
  # GitHub retargets a child pull request to the default branch when its parent merges and the
  # parent's branch is deleted. The parent's commits are then still in this branch but were squashed
  # into the base, so look for a recently merged head this branch contains and the base does not.
  while IFS=$'\t' read -r number head_name head_oid; do
    [[ -n $number && $head_name != "$branch" ]] || continue
    git merge-base --is-ancestor "$head_oid" "$tip" 2>/dev/null || continue
    in_base=0
    git merge-base --is-ancestor "$head_oid" "refs/remotes/$remote/$default" || in_base=$?
    if ((in_base == 1)); then
      require_plain_names "$head_name"
      parent=$head_name parent_pr=$number old_parent_tip=$head_oid
      break
    fi
  done < <(gh pr list --repo "$repo" --base "$default" --state merged --limit 30 \
    --json number,headRefName,headRefOid \
    --jq '.[] | [.number, .headRefName, .headRefOid] | @tsv' 2>/dev/null || true)
fi

printf '%s\n' "branch=$branch" "remote=$remote" "repo=$repo" "default=$default" "base=$base" \
  "source=$source" "pr=$pr" "draft=$draft" "parent=$parent" "parent_pr=$parent_pr" \
  "old_parent_tip=$old_parent_tip"
