#!/usr/bin/env bash
#
# Polls GitHub until a pull request is no longer open, then prints key=value lines:
#
#   state         MERGED or CLOSED
#   merge_commit  the merge commit's SHA, or empty when the pull request closed unmerged
#
# Usage: wait-merged.sh <PR> <repo>
#
# GitHub's state is the only source of truth: a message from another session saying the pull request
# merged is not. REBASE_WAIT_INTERVAL sets the seconds between polls (default 60). It gives up after
# ten failed polls in a row, since gh is then unauthenticated or offline, and prints gh's last error
# so the cause can be told apart.

set -euo pipefail

(($# == 2)) || { echo "Usage: wait-merged.sh <PR> <repo>" >&2; exit 2; }
pr=$1 repo=$2
interval=${REBASE_WAIT_INTERVAL:-60}
err=$(mktemp)
trap 'rm -f "$err"' EXIT

failures=0
while :; do
  if row=$(gh pr view "$pr" --repo "$repo" --json state,mergeCommit \
    --jq '[.state, (.mergeCommit.oid // "")] | @tsv' 2>"$err"); then
    failures=0
    IFS=$'\t' read -r state merge_commit <<<"$row"
    if [[ $state != OPEN ]]; then
      printf '%s\n' "state=$state" "merge_commit=${merge_commit-}"
      exit 0
    fi
  else
    failures=$((failures + 1))
    if ((failures >= 10)); then
      echo "gh failed ten times in a row reading $repo#$pr. Its last error:" >&2
      cat "$err" >&2
      exit 1
    fi
  fi
  sleep "$interval"
done
