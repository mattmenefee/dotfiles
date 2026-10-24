#!/usr/bin/env bash
#
# Compares a rewritten handoff with its backup and deletes the backup only when nothing was lost: no
# heading went missing, and no line of a section a reconciliation must preserve was dropped.
#
# Usage: check-loss.sh <handoff>
#
# Exit 0: nothing lost, backup deleted. Exit 1: a loss, printed; the backup is kept. Exit 2: not
# given exactly one handoff, the handoff or its <handoff>.bak cannot be read, a comparison failed or
# the backup cannot be deleted; the backup is kept. Run test-check-loss.sh beside it after changing
# it.

[ $# -eq 1 ] || { echo "usage: check-loss.sh <handoff>" >&2; exit 2; }
handoff=$1
backup="$handoff.bak"
[ -r "$handoff" ] && [ -r "$backup" ] \
  || { echo "check-loss: cannot read $handoff or $backup" >&2; exit 2; }

# Headings outside fenced blocks, so an edited shell comment is not mistaken for one
headings() { awk '/^(```|~~~)/ { fence = !fence; next } !fence && /^#/' "$1"; }
# One level-two section, from its heading to the next
section() {
  awk -v h="## $2" '/^(```|~~~)/ { fence = !fence } !fence && /^## / { on = ($0 == h) } on' "$1"
}

# A comparison that fails says nothing about loss, so it keeps the backup like a failed read.
# command grep, so a grep function exported by a bash parent cannot change the match.
changes=$(diff <(headings "$backup") <(headings "$handoff"))
[ $? -le 1 ] || { echo "check-loss: could not compare the headings" >&2; exit 2; }
lost=$(printf '%s\n' "$changes" | command grep '^<')
[ $? -le 1 ] || { echo "check-loss: could not compare the headings" >&2; exit 2; }
for name in 'Objective' 'Scope' 'Constraints & Preferences' 'Decisions & Rationale' \
  'Insights & Learnings' 'Dead Ends'; do
  missing=$(section "$backup" "$name" | command grep -vxF -f <(section "$handoff" "$name"))
  [ $? -le 1 ] || { echo "check-loss: could not compare the $name section" >&2; exit 2; }
  [ -z "$missing" ] || lost="$lost
$name: $missing"
done

if [ -n "$lost" ]; then
  printf 'kept the backup — lost:%s\n' "$lost"
  exit 1
fi
rm -- "$backup" || exit 2
echo "nothing lost; removed $backup"
