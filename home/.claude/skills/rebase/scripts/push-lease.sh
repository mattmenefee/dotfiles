#!/usr/bin/env bash
#
# Force-pushes a local branch under a lease pinned to the SHA the remote holds right now, then
# confirms the remote matches. Prints key=value lines:
#
#   pushed     the SHA pushed
#   confirmed  yes when git ls-remote then reports that SHA
#
# Usage: push-lease.sh <branch> [<remote>]
#
# <remote> defaults to the branch's push remote. The lease SHA is read with git ls-remote, never
# from the remote-tracking ref, which a background fetch can advance and so satisfy a lease it
# should fail. The push goes ahead only when that SHA is reachable from the branch's reflog since
# the branch was last created or reset, so commits this clone never had are never overwritten.
#
# Exits 3 when the remote holds commits this clone never had, 4 when the push could not be confirmed
# and 5 when the remote rejected it (a lease lost to a concurrent push, a hook or branch
# protection). It pushes refs/heads/<branch> by name, so it works for a branch not checked out.

set -euo pipefail
# shellcheck source=SCRIPTDIR/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

(($# == 1 || $# == 2)) || { echo "Usage: push-lease.sh <branch> [<remote>]" >&2; exit 2; }
branch=$1
require_plain_names "$branch"
remote=${2-$(push_remote_of "$branch")}

local_sha=$(git rev-parse --verify "refs/heads/$branch^{commit}")
before=$(remote_sha "$remote" "$branch")

if [[ $before == "$local_sha" ]]; then
  printf '%s\n' "pushed=$local_sha" "confirmed=yes"
  echo "$remote already has $branch at $local_sha; nothing to push." >&2
  exit 0
fi

if [[ -n $before ]] && ! reachable_from_reflog "refs/heads/$branch" "$before"; then
  echo "$remote has $branch at $before, which this clone never had on the branch." >&2
  echo "Fetch and inspect it before pushing: git fetch $remote $branch" \
    "&& git log --left-right --oneline $branch...$remote/$branch" >&2
  exit 3
fi

# An empty expected value means the branch must not exist on the remote yet
if ! git push --quiet "$remote" "--force-with-lease=refs/heads/$branch:$before" \
  "refs/heads/$branch:refs/heads/$branch"; then
  now=$(remote_sha "$remote" "$branch" || true)
  echo "$remote rejected the push of $branch: the lease expected ${before:-no branch} and the" \
    "remote now holds ${now:-no branch}." >&2
  exit 5
fi

after=$(remote_sha "$remote" "$branch")
echo "pushed=$local_sha"
if [[ $after == "$local_sha" ]]; then
  echo "confirmed=yes"
else
  echo "confirmed=no"
  echo "$remote reports $branch at ${after:-nothing}, not $local_sha." >&2
  exit 4
fi
