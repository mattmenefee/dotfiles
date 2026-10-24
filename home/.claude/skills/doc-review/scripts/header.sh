#!/usr/bin/env bash
#
# Prints each document's path, branch and commit, tab-separated, for the review file's header.
#
# Usage: header.sh <document>...
#
# The commit is the document's own last commit, marked -dirty when the working copy differs, or
# "untracked"; a document outside any repository gets "not in a repository" for both fields. A
# detached HEAD reports the commit it is detached at as the branch. See Document Header in
# ../review-file.md for why HEAD alone is not used.

[ $# -gt 0 ] || { echo "usage: header.sh <document>..." >&2; exit 2; }
for doc in "$@"; do
  dir="$(dirname "$doc")" name="$(basename "$doc")"
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch="$(git -C "$dir" branch --show-current)"
    [ -n "$branch" ] || branch="detached at $(git -C "$dir" rev-parse --short HEAD)"
    commit="$(git -C "$dir" log -1 --format=%h -- "$name")"
    if [ -z "$commit" ]; then
      commit="untracked"
    elif [ -n "$(git -C "$dir" status --porcelain -- "$name")" ]; then
      commit="$commit-dirty"
    fi
  else
    branch="not in a repository" commit="not in a repository"
  fi
  printf '%s\t%s\t%s\n' "$doc" "$branch" "$commit"
done
