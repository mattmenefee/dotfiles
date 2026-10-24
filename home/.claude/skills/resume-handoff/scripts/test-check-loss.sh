#!/usr/bin/env bash
#
# Cases for check-loss.sh: its usage and read errors, a clean rewrite, a lost heading, a lost line
# in a preserved section, a fenced heading that is not a section and a backup it cannot delete. It
# also checks both gather-state.sh scripts are executable and share an identical marked block. Run
# it after changing check-loss.sh or either gather-state.sh.
#
# Usage: test-check-loss.sh

here="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"
trap 'chmod -R u+rwx "$T" 2>/dev/null; rm -rf "$T"' EXIT
h="$T/t-HANDOFF.md"
pass=0 fail=0

# expect <label> <command>...: count a pass when the command succeeds, else report the label
expect() {
  local label=$1
  shift
  if "$@"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL $label"
  fi
}

# handoff <file> writes a small handoff with every section check-loss.sh preserves
handoff() {
  cat > "$1" <<'EOF'
# Handoff: t

## Objective

Ship it.

## Scope

- In: everything

## Constraints & Preferences

- Ask first

## Decisions & Rationale

- Chose A over B

## Insights & Learnings

- A is faster

## Dead Ends

- B was slow

## Next Steps

- [ ] 1. Finish
EOF
}

# case_rc <label> <code> <expect backup: kept|gone> <check-loss.sh arguments>...
case_rc() {
  local label=$1 want=$2 backup=$3 rc
  shift 3
  "$here/check-loss.sh" "$@" > "$T/out" 2>&1
  rc=$?
  if [ "$rc" -eq "$want" ] && { [ "$backup" = kept ] && [ -e "$h.bak" ] \
       || { [ "$backup" = gone ] && [ ! -e "$h.bak" ]; }; }; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL %s: exit %s, wanted %s; backup should be %s; output:\n' "$label" "$rc" "$want" \
      "$backup"
    sed 's/^/  /' "$T/out"
  fi
}

# The skill runs both of its scripts by path, so a lost execute bit breaks them
for script in check-loss.sh gather-state.sh; do
  expect "$script is executable" test -x "$here/$script"
done

# /handoff runs its own gather-state.sh by path too, and the two copies share a block marked to stay
# identical, which nothing else compares
handoff_gather="$here/../../handoff/scripts/gather-state.sh"
expect "handoff's gather-state.sh is executable" test -x "$handoff_gather"
block() { sed -n '/^# ---- shared block/,/^# ---- end of shared block/p' "$1"; }
block "$here/gather-state.sh" > "$T/block-resume"
block "$handoff_gather" > "$T/block-handoff"
expect "the shared block is present" test -s "$T/block-resume"
expect "the gather-state shared blocks are identical" cmp -s "$T/block-resume" "$T/block-handoff"

handoff "$h"
case_rc "no arguments" 2 gone
case_rc "two arguments" 2 gone "$h" "$h"
case_rc "missing backup" 2 gone "$h"
printf 'x\n' > "$T/missing-HANDOFF.md.bak"
case_rc "missing handoff" 2 gone "$T/missing-HANDOFF.md"
expect "missing handoff keeps its backup" test -e "$T/missing-HANDOFF.md.bak"

handoff "$h"; cp "$h" "$h.bak"
case_rc "unchanged" 0 gone "$h"

handoff "$h"; cp "$h" "$h.bak"
printf '\n## Handoff History\n\n- Reconciled\n' >> "$h"
case_rc "a section added" 0 gone "$h"

handoff "$h"; cp "$h" "$h.bak"
grep -v '^## Next Steps' "$h.bak" > "$h"
case_rc "a heading lost" 1 kept "$h"
expect "a heading lost names the heading" grep -q 'Next Steps' "$T/out"
rm -f "$h.bak"

# Each preserved section holds one body line; dropping it is a loss named by section and line
for pair in 'Objective|Ship it.' 'Scope|- In: everything' 'Constraints & Preferences|- Ask first' \
  'Decisions & Rationale|- Chose A over B' 'Insights & Learnings|- A is faster' \
  'Dead Ends|- B was slow'; do
  name=${pair%%|*} line=${pair#*|}
  handoff "$h"; cp "$h" "$h.bak"
  grep -vxF -- "$line" "$h.bak" > "$h"
  case_rc "a line lost from $name" 1 kept "$h"
  expect "a line lost from $name is named" grep -qF "$name: $line" "$T/out"
  rm -f "$h.bak"
done

# A fenced comment line is code, not a heading, so editing it loses nothing
handoff "$h"
# shellcheck disable=SC2016 # the backticks are a Markdown fence, not a command substitution
printf '\n```bash\n# old comment\n```\n' >> "$h"
cp "$h" "$h.bak"
sed 's/# old comment/# new comment/' "$h.bak" > "$h"
case_rc "a fenced comment edited" 0 gone "$h"

# A comparison that fails keeps the backup and exits 2, never reporting nothing lost
mkdir -p "$T/stub"
printf '#!/bin/sh\nexit 2\n' > "$T/stub/diff"
chmod 755 "$T/stub/diff"
handoff "$h"; cp "$h" "$h.bak"
PATH="$T/stub:$PATH" case_rc "a failed comparison" 2 kept "$h"
rm -f "$h.bak"

# A fenced "## Dead Ends" inside another section is quoted text, not the start of that section
handoff "$h"
# shellcheck disable=SC2016 # the backticks are a Markdown fence, not a command substitution
printf '\n## Notes\n\n```markdown\n## Dead Ends\n- quoted only\n```\n' >> "$h"
cp "$h" "$h.bak"
python3 -I -c 'import sys; p = sys.argv[1]; s = open(p).read()
open(p, "w").write(s.replace("- quoted only\n", ""))' "$h"
case_rc "a fenced heading is not a section" 0 gone "$h"

handoff "$h"; cp "$h" "$h.bak"
chmod 555 "$T"
case_rc "backup cannot be deleted" 2 kept "$h"
chmod 755 "$T"

if [ "$fail" -eq 0 ]; then
  echo "test-check-loss: all $pass checks passed"
else
  echo "test-check-loss: $fail of $((pass + fail)) checks failed"
  exit 1
fi
