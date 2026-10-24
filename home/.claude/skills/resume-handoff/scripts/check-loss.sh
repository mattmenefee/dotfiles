#!/usr/bin/env bash
#
# Compares a rewritten handoff with its backup and deletes the backup only when nothing was lost:
# no heading went missing, and no line of a section a reconciliation must preserve was dropped.
#
# Usage: check-loss.sh <handoff>
#
# Exit 0: nothing lost, backup deleted. Exit 1: a loss, printed; the backup is kept. Exit 2: the
# handoff or its <handoff>.bak cannot be read.

handoff=${1-}
backup="$handoff.bak"
[ -r "$handoff" ] && [ -r "$backup" ] \
  || { echo "check-loss: cannot read $handoff or $backup" >&2; exit 2; }

# Headings outside fenced blocks, so an edited shell comment is not mistaken for one
headings() { awk '/^(```|~~~)/ { fence = !fence; next } !fence && /^#/' "$1"; }
# One level-two section, from its heading to the next
section() { awk -v h="## $2" '/^## / { on = ($0 == h) } on' "$1"; }

# command grep: a session's grep can be a function running another grep, which lets blank lines
# through -vxF -f and into the report
lost=$(diff <(headings "$backup") <(headings "$handoff") | command grep '^<')
for name in 'Objective' 'Scope' 'Constraints & Preferences' 'Decisions & Rationale' \
  'Insights & Learnings' 'Dead Ends'; do
  missing=$(section "$backup" "$name" | command grep -vxF -f <(section "$handoff" "$name"))
  [ -z "$missing" ] || lost="$lost
$name: $missing"
done

if [ -n "$lost" ]; then
  printf 'kept the backup — lost:%s\n' "$lost"
  exit 1
fi
rm -- "$backup" && echo "nothing lost; removed $backup"
