#!/usr/bin/env bash
#
# Fetches, then prints the state a handoff's claims are checked against: the base branch and where
# it came from, the branch's tip and where that came from, the current checkout, stashes,
# worktrees, the pull request and the commit ranges. It reads; it never checks a branch out.
#
# Usage: gather-state.sh <branch> <updated YYYY-MM-DD> [file the handoff names]...
#
# Set REMOTE to use a remote other than origin. Each part opens with a "== <name>" line, and the
# tip line is the revision every later check uses (see Resolve the Branch and Its Base in SKILL.md).

[ $# -ge 2 ] || { echo "usage: gather-state.sh <branch> <updated> [file]..." >&2; exit 2; }
branch=$1 updated=$2
shift 2
remote=${REMOTE:-origin}

echo "== fetch"
git fetch --quiet "$remote" && echo "fetched $remote" \
  || echo "fetch failed — remote-tracking refs may be stale"

echo "== gh"
if gh api user --jq .login >/dev/null 2>&1; then
  echo "gh available"
else
  echo "gh unavailable — pull request, CI and issue state not checked"
fi

echo "== base"
if base=$(gh pr view "$branch" --json baseRefName --jq .baseRefName 2>/dev/null); then
  base_source="pull request"
elif base=$(gh repo view --json defaultBranchRef --jq .defaultBranchRef.name 2>/dev/null); then
  base_source="repository default"
else
  base=main base_source="assumed"
fi
echo "base: $base ($base_source)"
range_base=$(git rev-parse --verify --quiet "refs/remotes/$remote/$base") \
  || range_base=$(git rev-parse --verify --quiet "$base") \
  || echo "base $base not found locally or on $remote — commit range not checked"

echo "== tip"
if tip=$(git rev-parse --verify --quiet "refs/heads/$branch"); then
  tip_source="local branch"
elif tip=$(git rev-parse --verify --quiet "refs/remotes/$remote/$branch"); then
  tip_source="$remote"
elif tip=$(gh pr view "$branch" --json headRefOid --jq .headRefOid 2>/dev/null); then
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
gh pr view "$branch" --json \
  number,url,state,isDraft,mergedAt,reviewDecision,statusCheckRollup,closingIssuesReferences \
  2>/dev/null || echo "no pull request found, or gh unavailable"
echo "== pull request comments and reviews"
gh pr view "$branch" --json comments,reviews,latestReviews 2>/dev/null || echo "not checked"

if [ -n "$range_base" ] && [ -n "$tip" ]; then
  echo "== commits on $branch since $base"
  git --no-pager log --oneline "$range_base".."$tip"
  if [ $# -gt 0 ]; then
    echo "== commits on $base since $updated touching the files the handoff names"
    git --no-pager log --oneline --since="$updated 00:00" "$range_base" -- "$@"
  fi
fi
