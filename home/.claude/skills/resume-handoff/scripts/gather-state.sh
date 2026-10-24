#!/usr/bin/env bash
#
# Fetches, then prints the state a handoff's claims are checked against: the base branch and where
# it came from, the branch's tip and where that came from, the current checkout, stashes, worktrees,
# the pull request and the commit ranges. It reads; it never checks a branch out.
#
# Usage: gather-state.sh <branch> <updated YYYY-MM-DD> [file the handoff names]...
#
# Set REMOTE to use a remote other than origin. Each part opens with a "== <name>" line, and the tip
# line is the revision every later check uses (see Resolve the Branch and Its Base in SKILL.md).

usage="usage: gather-state.sh <branch> <updated YYYY-MM-DD> [file]..."
[ $# -ge 2 ] || { echo "$usage" >&2; exit 2; }
branch=$1 updated=$2
shift 2
# A malformed date would make the base-absorbed part report nothing rather than fail
case $updated in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
git rev-parse --git-dir >/dev/null 2>&1 \
  || { echo "gather-state: not in a git repository" >&2; exit 2; }
remote=${REMOTE:-origin}

echo "== fetch"
git fetch --quiet "$remote" && echo "fetched $remote" \
  || echo "fetch failed — remote-tracking refs may be stale"

# ---- shared block: keep identical in handoff/ and resume-handoff/scripts/gather-state.sh ----

# gh is pointed at the remote's repository, so its pull request and the git ranges come from the
# same place even in a clone with an upstream remote; HOST/OWNER/NAME keeps an enterprise host
repo=$(git remote get-url "$remote" 2>/dev/null \
  | sed -E -e 's#^[a-z+]+://([^@/]*@)?([^/:]+)(:[0-9]+)?/#\2/#' \
    -e 's#^([^@/]*@)?([^/:]+):#\2/#; s#\.git$##; s#/$##')
# A local-path remote names no host, so gh is left to resolve the repository itself
[[ $repo =~ ^[^./][^/]*/[^/]+/[^/]+$ ]] || repo=""
repo_args=()
[ -n "$repo" ] && repo_args=(--repo "$repo")

echo "== gh"
if gh api user --jq .login >/dev/null 2>&1; then
  echo "gh available${repo:+, reading $repo}"
else
  echo "gh unavailable — pull request, CI and issue state not checked"
fi

# pr_json <fields>: the branch's pull request as JSON, "none" when gh finds no pull request for the
# branch and "not checked" when gh could not answer
pr_json() {
  local out
  [ -n "$branch" ] || { echo "not checked (no branch)"; return; }
  if out=$(gh pr view "$branch" "${repo_args[@]}" --json "$1" 2>&1); then
    printf '%s\n' "$out"
  elif [[ $out == *"no pull requests found"* ]]; then
    echo "none"
  else
    echo "not checked"
  fi
}

echo "== base"
if [ -n "$branch" ] \
  && base=$(gh pr view "$branch" "${repo_args[@]}" --json baseRefName --jq .baseRefName 2>/dev/null)
then
  base_source="pull request"
elif base=$(gh repo view ${repo:+"$repo"} --json defaultBranchRef --jq .defaultBranchRef.name \
  2>/dev/null)
then
  base_source="repository default"
else
  base=main base_source="assumed"
fi
echo "base: $base ($base_source)"
range_base=$(git rev-parse --verify --quiet "refs/remotes/$remote/$base") \
  || range_base=$(git rev-parse --verify --quiet "$base") \
  || echo "base $base not found locally or on $remote — commit range not checked"
# ---- end of shared block ----

echo "== tip"
if tip=$(git rev-parse --verify --quiet "refs/heads/$branch"); then
  tip_source="local branch"
elif tip=$(git rev-parse --verify --quiet "refs/remotes/$remote/$branch"); then
  tip_source="$remote"
elif tip=$(gh pr view "$branch" "${repo_args[@]}" --json headRefOid --jq .headRefOid 2>/dev/null)
then
  tip_source="pull request head"
else
  tip="" tip_source="not found"
fi
echo "tip: ${tip:-none} ($tip_source)"
if remote_tip=$(git rev-parse --verify --quiet "refs/remotes/$remote/$branch") \
  && [ "$remote_tip" != "$tip" ]; then
  echo "local and $remote differ: $remote is at $remote_tip"
fi

echo "== current checkout"
git --no-pager status --short --branch
echo "== stashes"
git --no-pager stash list
echo "== worktrees"
git --no-pager worktree list

echo "== pull request"
pr_json number,url,state,isDraft,mergedAt,reviewDecision,statusCheckRollup,closingIssuesReferences
echo "== pull request comments and reviews"
pr_json comments,reviews,latestReviews

if [ -n "$range_base" ] && [ -n "$tip" ]; then
  echo "== commits on $branch since $base"
  git --no-pager log --oneline "$range_base".."$tip"
  if [ $# -gt 0 ]; then
    echo "== commits on $base since $updated touching the files the handoff names"
    # A bare date means that date at the current time of day, dropping whatever landed earlier on it
    git --no-pager log --oneline --since="$updated 00:00" "$range_base" -- "$@"
  fi
fi
