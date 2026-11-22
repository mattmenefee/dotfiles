#!/usr/bin/env bash
# PreCompact hook: hold a manual compaction until the repository root has a `*-HANDOFF.md` newer
# than HEAD's last move, so what only the conversation knows is written down before it is summarized
# away. Automatic compaction is never held.
#
# HEAD's newest reflog entry dates its last move: a switch to another branch makes a handoff written
# for the old one stale, and the local clock stamps the entry, so a future-dated commit pulled from
# elsewhere cannot hold compaction. Without a reflog the last commit's date stands in. Every git
# read passes --no-show-signature, so a repository's own config cannot make it run a signature
# verifier.
#
# It fails open: any error, a missing jq, a directory outside a git repository or a repository with
# no commits lets the compaction go ahead.

blocked_root=

compaction_allowed() {
  local input trigger cwd top last newest stamp file
  input=$(cat) || return 0
  command -v jq >/dev/null || return 0

  trigger=$(jq -r '.trigger // empty' <<<"$input") || return 0
  [[ $trigger == manual ]] || return 0

  cwd=$(jq -r '.cwd // empty' <<<"$input") || return 0
  [[ -n $cwd && -d $cwd ]] || return 0
  top=$(git -C "$cwd" rev-parse --show-toplevel) || return 0
  last=$(git -C "$top" log -g -1 --no-show-signature --date=unix --format=%gd HEAD)
  last=${last//[!0-9]/}
  [[ -n $last ]] || last=$(git -C "$top" log -1 --no-show-signature --format=%ct) || return 0
  [[ $last =~ ^[0-9]+$ ]] || return 0

  newest=0
  for file in "$top"/*-HANDOFF.md; do
    [[ -f $file ]] || continue
    # GNU stat first: on Linux `stat -f` reports the file system, not the file
    stamp=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file") || return 0
    [[ $stamp =~ ^[0-9]+$ ]] || return 0
    ((stamp > newest)) && newest=$stamp
  done
  ((newest > last)) && return 0

  blocked_root=$top
  return 1
}

if ! compaction_allowed 2>/dev/null; then
  # A directory name can hold control characters, which would reach the terminal as-is
  printf '%s %s %s\n' 'Run /handoff before compacting: no *-HANDOFF.md in' \
    "${blocked_root//[[:cntrl:]]/?}" 'is newer than its last commit or branch switch.' >&2
  exit 2
fi
exit 0
