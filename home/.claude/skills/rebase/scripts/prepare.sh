#!/usr/bin/env bash
#
# Fetches the base and the branch, fast-forwards the local default branch when that is safe and
# prints what the rebase needs as key=value lines:
#
#   target            the remote-tracking ref to rebase onto
#   push_remote       the remote the branch pushes to, in git's order of precedence
#   behind, ahead     commits the branch lacks from the target, and has beyond it
#   old_head          the branch's tip now: the recovery point
#   old_base          the merge base with the target, for git range-diff afterwards
#   remote_head       the branch's tip on push_remote, or empty when it has never been pushed
#   remote_integrated yes when this clone had remote_head on the branch, so a push loses nothing;
#                     no when push_remote holds commits this clone never had
#   ff_default        yes, up-to-date, not-the-base or skipped:<reason> for the local default
#
# Usage: prepare.sh <branch> <base> <default> <remote>

set -euo pipefail
# shellcheck source=SCRIPTDIR/lib.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

(($# == 4)) || { echo "Usage: prepare.sh <branch> <base> <default> <remote>" >&2; exit 2; }
branch=$1 base=$2 default=$3 remote=$4
require_plain_names "$branch" "$base" "$default"
target=$remote/$base

git fetch --quiet "$remote" "$base"
git rev-parse --verify --quiet "refs/remotes/$target" >/dev/null || {
  echo "Fetching $base did not update $target; check the remote's fetch refspec." >&2
  exit 1
}

push_remote=$(push_remote_of "$branch")
remote_head=$(remote_sha "$push_remote" "$branch")
[[ -n $remote_head ]] && git fetch --quiet "$push_remote" "$branch"

integrated=yes
if [[ -n $remote_head ]] && ! reachable_from_reflog "refs/heads/$branch" "$remote_head"; then
  integrated=no
fi

ff_default=not-the-base
if [[ $base == "$default" && $branch != "$default" ]]; then
  if ! git rev-parse --verify --quiet "refs/heads/$default" >/dev/null; then
    ff_default=skipped:no-local-branch
  elif git worktree list --porcelain | grep -qxF "branch refs/heads/$default"; then
    # git fetch would refuse this anyway; checking first reports the reason instead of an error
    ff_default=skipped:checked-out
  elif [[ $(git rev-parse "refs/heads/$default") == $(git rev-parse "refs/remotes/$target") ]]; then
    ff_default=up-to-date
  elif git merge-base --is-ancestor "refs/heads/$default" "refs/remotes/$target"; then
    if git fetch --quiet "$remote" "$default:$default"; then
      ff_default=yes
    else
      ff_default=skipped:fetch-failed
    fi
  else
    ff_default=skipped:diverged
  fi
fi

# Each value is assigned on its own line so a failing git command stops the script under errexit
behind=$(git rev-list --count "refs/heads/$branch..refs/remotes/$target")
ahead=$(git rev-list --count "refs/remotes/$target..refs/heads/$branch")
old_head=$(git rev-parse "refs/heads/$branch")
old_base=$(git merge-base "refs/heads/$branch" "refs/remotes/$target")

printf '%s\n' "target=$target" "push_remote=$push_remote" "behind=$behind" "ahead=$ahead" \
  "old_head=$old_head" "old_base=$old_base" "remote_head=$remote_head" \
  "remote_integrated=$integrated" "ff_default=$ff_default"
