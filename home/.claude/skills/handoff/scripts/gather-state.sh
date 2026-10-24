#!/usr/bin/env bash
#
# Prints the mechanical state a handoff records: the base branch and where it came from, HEAD, the
# working tree, stashes, worktrees, recent branches, the pull request and the branch's commits with
# their messages. Run it from the checkout being handed off.
#
# Usage: gather-state.sh [remote]
#
# The remote defaults to origin. Each part opens with a "== <name>" line. A "not checked" line means
# that part could not be read, which is never the same as "none" (see Gathering State in SKILL.md).

remote=${1:-origin}

echo "== gh"
if gh api user --jq .login >/dev/null 2>&1; then
  echo "gh available"
else
  echo "gh unavailable — pull request, CI and issue state not checked"
fi

echo "== base"
if base=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null); then
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

echo "== head"
git rev-parse --short HEAD
echo "== status"
git --no-pager status --short --branch
echo "== diff (unstaged)"
git --no-pager diff --stat
echo "== diff (staged)"
git --no-pager diff --stat --cached
echo "== stashes"
git --no-pager stash list
echo "== worktrees"
git --no-pager worktree list
echo "== recent branches"
git --no-pager branch --sort=-committerdate | head -10

echo "== pull request"
gh pr view --json \
  number,url,state,isDraft,reviewDecision,statusCheckRollup,body,closingIssuesReferences 2>/dev/null \
  || echo "no pull request found, or gh unavailable"
echo "== pull request comments and reviews"
gh pr view --json comments,reviews,latestReviews 2>/dev/null || echo "not checked"

if [ -n "$range_base" ]; then
  echo "== commits since $base"
  git --no-pager log --oneline "$range_base"..HEAD
  echo "== commit messages since $base (issue references in trailers)"
  git --no-pager log --format=%B "$range_base"..HEAD
fi
