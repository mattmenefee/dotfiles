#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
#
# End-to-end cases for header.sh, scrub.sh and post.sh, run in a throwaway repository with a stub gh
# that records what would have been posted, plus a direct check of scrub-lib.sh's pattern set. Run
# it after changing any of the four scripts.
#
# Usage: test-post.sh
#
# Every secret below is fake and assembled from pieces at runtime, so no token-shaped literal sits
# in this file for gitleaks to flag.

here="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"
trap 'chmod -R u+rw "$T" 2>/dev/null; rm -rf "$T"' EXIT
repo="$T/repo" bin="$T/bin"
mkdir -p "$repo/sub" "$bin"
git -C "$repo" init -q -b main
home_root="/$(printf 'Us')ers"
x16=AAAABBBBCCCCDDDD
x36="${x16}${x16}EEEE"

# The stub records each call's arguments, prints a pull request URL, saves each comment body it is
# asked to post and fails on demand: GH_FAIL_VIEW fails `pr view`, GH_FAIL_AT=<n> fails the nth
# comment. Any other gh call fails, so a new one in post.sh cannot pass unnoticed.
cat > "$bin/gh" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GH_STUB_DIR/argv"
case "$1 $2" in
  "pr view") [ -z "${GH_FAIL_VIEW-}" ] || exit 1
             echo https://example.invalid/pull/1 ;;
  "pr comment")
    n=$(find "$GH_STUB_DIR" -maxdepth 1 -name 'posted-*' | wc -l | tr -d ' ')
    [ "$((n + 1))" != "${GH_FAIL_AT-}" ] || exit 1
    while [ $# -gt 0 ] && [ "$1" != --body-file ]; do shift; done
    [ $# -ge 2 ] || exit 1
    cp "$2" "$GH_STUB_DIR/posted-$n" ;;
  *) exit 1 ;;
esac
STUB
chmod 755 "$bin/gh"
export GH_STUB_DIR="$T"

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

# not_in <text> <file> succeeds when the file does not contain the text
not_in() { ! grep -qF -- "$1" "$2"; }

# review <extra line> writes three fixtures: the review file, with <extra line> after its summary
# table; the withheld copy $T/copy, which is the review without F2; and $T/cf, which clears F3
review() {
  cat > "$repo/t-DOC-REVIEW.md" <<EOF
# Document Review: t

## Overall Assessment

Fine.

## Sensitive Information

### F2 🟠 High Priority - The value at line 4 is live
### F3 🟢 Low Priority - The heading publishes a file name

## Consolidated Summary

| F2 | x | ✅ |
| F3 | x | ✅ |
$1
EOF
  grep -v 'F2' "$repo/t-DOC-REVIEW.md" > "$T/copy"
  printf 'F3\n' > "$T/cf"
}

# plain_review <extra line> writes a review with no Sensitive Information section, which posts whole
# with no withheld copy
plain_review() {
  printf '# Document Review: t\n\n## Overall Assessment\n\nFine.\n%s\n' "$1" \
    > "$repo/t-DOC-REVIEW.md"
}

# exit_matches <ok|refuse> <status>: ok wants 0, refuse wants anything else
exit_matches() {
  case $1 in
    ok) [ "$2" -eq 0 ] ;;
    refuse) [ "$2" -ne 0 ] ;;
    *) return 1 ;;
  esac
}

# check <label> <ok|refuse> <expected posts> <expected message or ""> <post.sh arguments>...
#
# Runs from $repo, or from $from when it is set
check() {
  local label=$1 want_rc=$2 want_posts=$3 want_msg=$4 rc posts
  shift 4
  find "$T" -maxdepth 1 -name 'posted-*' -delete
  : > "$T/argv"
  (cd "${from:-$repo}" && PATH="$bin:$PATH" "$here/post.sh" "$@") > "$T/out" 2>&1
  rc=$?
  posts=$(find "$T" -maxdepth 1 -name 'posted-*' | wc -l | tr -d ' ')
  if [ "$posts" = "$want_posts" ] && exit_matches "$want_rc" "$rc" \
     && { [ -z "$want_msg" ] || grep -qF -- "$want_msg" "$T/out"; }; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL %s: exit %s, wanted %s; posted %s, wanted %s; output:\n' \
      "$label" "$rc" "$want_rc" "$posts" "$want_posts"
    sed 's/^/  /' "$T/out"
  fi
}

# fresh <name> copies a fixture to <name>-run, so post.sh may delete the copy and the next case
# still has the original
fresh() { cp "$T/$1" "$T/$1-run" && printf '%s' "$T/$1-run"; }

# The skill files run these by path, so a lost execute bit breaks them
for script in header.sh scrub.sh post.sh; do
  expect "$script is executable" test -x "$here/$script"
done

base=(--review "$repo/t-DOC-REVIEW.md" --repo o/r
  --status "all clear" --stats "2 findings — 2 fixed")

review ""
check "A withheld copy, F3 cleared" ok 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
# shellcheck disable=SC2016 # the backticks are Markdown, not a command substitution
expect "A heading" grep -qxF -- '## Document Review: t (`t-DOC-REVIEW.md`) — all clear' \
  "$T/posted-0"
expect "A stats line" grep -qxF -- '**2 findings — 2 fixed**' "$T/posted-0"
expect "A deleted its working files" test ! -e "$T/copy-run" -a ! -e "$T/cf-run"
expect "A kept the review file" test -e "$repo/t-DOC-REVIEW.md"
expect "A resolves the PR in o/r" grep -qx 'pr view main --repo o/r --json url --jq .url' "$T/argv"
expect "A posts to that URL" grep -q '^pr comment https://example.invalid/pull/1 --body-file ' \
  "$T/argv"

plain_review ""
check "A2 no withheld copy" ok 1 "" "${base[@]}"
expect "A2 kept the review file" test -e "$repo/t-DOC-REVIEW.md"

review ""
check "B F2 left in the post file" refuse 0 "withhold: F2 is still in the comment" "${base[@]}" \
  --cleared-findings "$(fresh cf)"

review "see /Users/<name>/app and /Users/realperson/app"
check "C real path beside placeholder" refuse 0 "unresolved hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)" --cleared "$(fresh cf)"
expect "C kept its working files on a Gate 1 refusal" test -e "$T/copy-run" -a -e "$T/cf-run"

review "api_key: "
printf 'api_key: realvalue1234567890\n' >> "$repo/t-DOC-REVIEW.md"
grep -v 'F2' "$repo/t-DOC-REVIEW.md" > "$T/copy"
printf 'api_key: \n' > "$T/cl"
check "D cleared key, later value" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)" --cleared "$(fresh cl)"

review "api_key: "
printf 'api_key: \n' > "$T/cl"
check "D2 only the cleared bare key" ok 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)" --cleared "$(fresh cl)"
expect "D2 deleted the cleared lines" test ! -e "$T/cl-run"

review ""
check "E status still a placeholder" refuse 0 "[placeholder]" --review "$repo/t-DOC-REVIEW.md" \
  --repo o/r --status "[status summary]" --stats "x" --post "$(fresh copy)"
check "E2 stats missing" refuse 0 "are required" --review "$repo/t-DOC-REVIEW.md" --repo o/r \
  --status "all clear" --post "$(fresh copy)"
check "E3 stats still a placeholder" refuse 0 "[placeholder]" --review "$repo/t-DOC-REVIEW.md" \
  --repo o/r --status "all clear" --stats "[stats line]"
check "E4 unknown argument" refuse 0 "unknown argument" "${base[@]}" --bogus x
check "E5 flag without a value" refuse 0 "--stats needs a value" --review "$repo/t-DOC-REVIEW.md" \
  --repo o/r --status "all clear" --stats

printf 'three\n' > "$T/cfbad"
check "F malformed cleared findings" refuse 0 "one finding number per line" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cfbad)"

review "| F4 | x | ❓ |"
check "G open finding in the review" refuse 0 "open findings above" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
review "- [ ] F4 still to do"
check "G2 open checklist item" refuse 0 "open findings above" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review "see file:///Users/someone/f"
check "H file URL home path" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
review "see /private/var/folders/ab/cd/T/tmp.1/f"
check "H2 resolved temp path" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"

review "api_key: x /Users/realperson/app"
printf 'api_key: x /Users/realperson/app\n' > "$T/cl2"
check "I cleared line with a path" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)" --cleared "$(fresh cl2)"

review "| F5 | 🟡 Medium | Sensitive Information | d | ✅ |
### F5 elsewhere"
check "J SI finding filed elsewhere" refuse 0 "withhold: F5 is still in the comment" \
  "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
expect "J kept its working files on a Gate 2 refusal" test -e "$T/copy-run" -a -e "$T/cf-run"

review ""
printf 'x\n' > "$repo/z-HANDOFF.md"
chmod 000 "$repo/z-HANDOFF.md"
check "K unreadable artifact" refuse 0 "could not read an artifact" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
chmod 600 "$repo/z-HANDOFF.md"
rm -f "$repo/z-HANDOFF.md"

# Each artifact name pattern is scanned, not only the review's
for artifact in z-local-review.md z-PLAN.md z-HANDOFF.md z-IMPACT.md z-REVIEW.md; do
  review ""
  printf 'see %s/someone/app\n' "$home_root" > "$repo/$artifact"
  check "K2 home path in $artifact" refuse 0 "unresolved hits" "${base[@]}" \
    --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
  rm -f "$repo/$artifact"
done

review "x $(printf '\377') api_$(printf 'ke')y: abc123"
check "L credential after a bad byte" refuse 0 "unresolved hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review "see /Users/<$(id -un)>/app"
check "M login in angle brackets" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
review "see /Users/<name>/app"
check "M2 placeholder alone" ok 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"

review "| DATABASE_PASS$(printf 'WO')RD | hunter2 |"
check "N table cell naming a password" refuse 0 "unresolved hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review "| \`SECRET_KEY_$(printf 'BA')SE\` | abc123def456 |"
check "O backticked key cell" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"

review "| **Pass$(printf 'wo')rd** | hunter2x |"
check "P bold key cell" refuse 0 "unresolved hits" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"

review "| F4 | 🟢 Low | Accuracy | Rotate the cred$(printf 'en')tial note | \`a.md\` | x | Implement | G1 | ✅ |"
check "Q summary row naming a credential" ok 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"

# A bare backticked file name holding a key word blocks as a key cell: accepted, and cleared
review "| F4 | 🟢 Low | Accuracy | d | \`au$(printf 'th').md\` | x | Implement | G1 | ✅ |"
check "Q2 summary row locating a key-named file" refuse 0 "unresolved hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
review "connect to db.local:5432 first"
check "Q3 local host with a port alone" refuse 0 "unresolved hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review ""
check "R withheld copy passed as --review" refuse 0 "must be the review file in" \
  --review "$T/copy" --repo o/r --status "all clear" --stats "x" --cleared-findings "$(fresh cf)"
git -C "$T" init -q -b main other
from="$T/other" check "S run from another repository" refuse 0 \
  "must be the review file in" "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
printf '# Notes\n\nFine.\n' > "$repo/notes.md"
check "S2 --review not named as a review artifact" refuse 0 "is not a review artifact" \
  --review "$repo/notes.md" --repo o/r --status "all clear" --stats "x" \
  --cleared-findings "$(fresh cf)"
rm -f "$repo/notes.md"

review "|  F4    | x |  ❓   |"
check "T aligned open row" refuse 0 "open findings above" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
review "|  F5    | 🟡 Medium   | Sensitive Information   | d | ✅ |"
check "T2 aligned SI row" refuse 0 "withhold: F5 is still in the comment" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review ""
check "U status an angle-bracket placeholder" refuse 0 "<placeholder>" \
  --review "$repo/t-DOC-REVIEW.md" --repo o/r --status "<status summary>" --stats "x" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review ""
printf 'F2\nF3\n' > "$T/cf23"
check "V relative --post naming the review file" ok 1 "" "${base[@]}" --post t-DOC-REVIEW.md \
  --cleared-findings "$(fresh cf23)"
expect "V kept the review file" test -e "$repo/t-DOC-REVIEW.md"

review ""
printf '# Plan\n' > "$repo/t-PLAN.md"
check "V2 --post naming another root artifact" refuse 0 "must be a temporary file outside" \
  "${base[@]}" --post "$repo/t-PLAN.md" --cleared-findings "$(fresh cf)"
expect "V2 kept the root artifact" test -e "$repo/t-PLAN.md"
printf 'api_key: x\n' > "$repo/sub/cleared"
check "V3 --cleared inside the repository" refuse 0 "must be a temporary file outside" \
  "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)" --cleared "$repo/sub/cleared"
expect "V3 kept the cleared file" test -e "$repo/sub/cleared"
rm -f "$repo/t-PLAN.md" "$repo/sub/cleared"

review ""
check "W empty --post" refuse 0 "needs a value" "${base[@]}" --post "" \
  --cleared-findings "$(fresh cf)"
check "W2 flag as a value" refuse 0 "needs a value" --review "$repo/t-DOC-REVIEW.md" --repo \
  --status "all clear" --stats "x"
check "X directory as cleared findings" refuse 0 "not a regular file" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$T"

printf 'x\n' > "$T/unreadable"
chmod 000 "$T/unreadable"
check "X2 unreadable --post" refuse 0 "cannot read the review, post or cleared-findings file" \
  "${base[@]}" --post "$T/unreadable" --cleared-findings "$(fresh cf)"
printf 'api_key: \n\n' > "$T/clblank"
check "X3 blank line in --cleared" refuse 0 "has a blank line" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)" --cleared "$(fresh clblank)"
check "X4 unreadable --cleared" refuse 0 "cannot read" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)" --cleared "$T/unreadable"
: > "$T/empty"
check "X5 empty --post" refuse 0 "review body is empty" "${base[@]}" --post "$(fresh empty)" \
  --cleared-findings "$(fresh cf)"
review ""
sed -i.bak '1d' "$repo/t-DOC-REVIEW.md" && rm -f "$repo/t-DOC-REVIEW.md.bak"
check "X6 review without a title" refuse 0 "has no title on its first line" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
review ""
GH_FAIL_VIEW=1 check "X7 no pull request for the branch" refuse 0 "no pull request found" \
  "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

cat > "$repo/t-DOC-REVIEW.md" <<'EOF'
# Document Review: t

## Sensitive Information

### F2 🟠 High Priority - Quotes a heading

```markdown
## Example
```

### F6 🟢 Low Priority - Comes after the fence
EOF
grep -v 'F2' "$repo/t-DOC-REVIEW.md" > "$T/copy"
check "Y SI finding after a fenced heading" refuse 0 "withhold: F6 is still in the comment" \
  "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

review "ping @octocat, not \`@types/node\`"
check "Z mention warns but posts" ok 1 "warning:" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
expect "Z warning skips code spans" not_in "types/node" "$T/out"
review "see o/r#3"
check "Z2 cross-repository reference warns but posts" ok 1 "warning:" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
# shellcheck disable=SC2016 # the backticks are Markdown, not a command substitution
review "$(printf '```text\n@octocat\n```')"
check "Z3 mention in a fenced block posts" ok 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
expect "Z3 no warning" not_in "warning:" "$T/out"

# Gate 2 is the only gate on the withheld copy and the heading's text, which Gate 1 never reads
review ""
check "AA home path in --stats" refuse 0 "assembled comment still has hits" \
  --review "$repo/t-DOC-REVIEW.md" --repo o/r --status "all clear" \
  --stats "see $home_root/someone/app" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
printf 'see %s/someone/app\n' "$home_root" >> "$T/copy"
check "AA2 home path only in the copy" refuse 0 "assembled comment still has hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
review ""
printf '%s\n' "$(printf 'gh')p_${x36}" >> "$T/copy"
check "AA3 secret only in the copy" refuse 0 "assembled comment still has hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

# A withheld number counts only as a whole number, but anywhere, a group heading included
review ""
printf 'see F20 and F12\n' >> "$T/copy"
check "AB longer numbers pass" ok 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
review ""
printf '### G1 — Fix F2\n' >> "$T/copy"
check "AB2 withheld number in a group heading" refuse 0 "withhold: F2 is still in the comment" \
  "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"

# The scan is anchored to the repository root, not the working directory
review ""
printf 'see %s/someone/app\n' "$home_root" > "$repo/z-HANDOFF.md"
from="$repo/sub" check "AC run from a subdirectory" refuse 0 "unresolved hits" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
rm -f "$repo/z-HANDOFF.md"

# Multi-part posting: two 40,000-byte sections post as two labeled parts
big="$(head -c 40000 /dev/zero | tr '\0' a)"
plain_review "$(printf '## Part one\n\n%s\n\n## Part two\n\n%s' "$big" "$big")"
check "AD two parts" ok 2 "" "${base[@]}"
expect "AD first part label" grep -qF '(part 1 of 2)' "$T/posted-0"
expect "AD second part label" grep -qF '(part 2 of 2)' "$T/posted-1"
expect "AD heading only in the first part" not_in '## Document Review: t (' "$T/posted-1"
expect "AD part one in the first comment" grep -qxF '## Part one' "$T/posted-0"
expect "AD part two in the second comment" grep -qxF '## Part two' "$T/posted-1"
expect "AD part two not in the first comment" not_in '## Part two' "$T/posted-0"
review ""
printf '## Part one\n\n%s\n\n## Part two\n\nF2 %s\n' "$big" "$big" >> "$T/copy"
check "AD2 withheld number only in the second part" refuse 0 "withhold: F2" "${base[@]}" \
  --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
plain_review "$(printf '## One section\n\n%s%s' "$big" "$big")"
check "AD3 one section over the limit" refuse 0 "over the limit on its own" "${base[@]}"
# A fenced `## ` line is quoted text, so it never ends a section: this one stays a single section
# over the limit, where splitting at the quoted line would post two comments with unbalanced fences
half="$(head -c 35000 /dev/zero | tr '\0' b)" third="$(head -c 30000 /dev/zero | tr '\0' c)"
# shellcheck disable=SC2016 # the backticks are Markdown, not a command substitution
plain_review "$(printf '## One section\n\n%s\n\n```text\n## Quoted\n%s\n```' "$half" "$third")"
check "AD5 fenced heading does not split a section" refuse 0 "over the limit on its own" \
  "${base[@]}"
review ""
printf '## Part one\n\n%s\n\n## Part two\n\n%s\n' "$big" "$big" >> "$T/copy"
GH_FAIL_AT=2 check "AD4 gh fails at part 2" refuse 1 "posting stopped at part 2 of 2" \
  "${base[@]}" --post "$(fresh copy)" --cleared-findings "$(fresh cf)"
expect "AD4 kept the withheld copy" test -e "$T/copy-run"

# scrub.sh on its own. scrub_exits <code> [cleared file] runs it and checks its exit status; its
# output is left in $T/out. Runs from $repo, or from $from when it is set.
scrub_exits() {
  local rc
  (cd "${from:-$repo}" && "$here/scrub.sh" "${@:2}") > "$T/out" 2>&1
  rc=$?
  [ "$rc" -eq "$1" ] || { cat "$T/out"; return 1; }
}
review ""
expect "scrub.sh clean exits 0" scrub_exits 0
expect "scrub.sh clean says so" grep -q 'scrub: clean' "$T/out"
expect "scrub.sh lists the review" grep -q 't-DOC-REVIEW.md$' "$T/out"
review "see /Users/realperson/app"
expect "scrub.sh hit exits 1" scrub_exits 1
expect "scrub.sh hit is printed" grep -q 'realperson' "$T/out"
from="$repo/sub" expect "scrub.sh from a subdirectory exits 1" scrub_exits 1
review "api_key: abc123"
printf 'api_key: abc123\n' > "$T/clok"
expect "scrub.sh with the hit cleared exits 0" scrub_exits 0 "$T/clok"
expect "scrub.sh with a blank cleared line exits 2" scrub_exits 2 "$T/clblank"
expect "scrub.sh with a missing cleared file exits 2" scrub_exits 2 "$T/missing"
rm -f "$repo/t-DOC-REVIEW.md"
expect "scrub.sh with nothing to scan exits 2" scrub_exits 2

# header.sh: tracked, dirty, untracked, outside a repository, missing and symlinked documents, a
# detached HEAD and no arguments
printf 'x\n' > "$repo/doc.md"
git -C "$repo" add doc.md
git -C "$repo" -c user.name=t -c user.email=t@example.invalid commit -q -m doc
sha="$(git -C "$repo" log -1 --format=%h)"
header() { (cd "$repo" && "$here/header.sh" "$@") > "$T/out" 2> "$T/err"; }
expect "header.sh tracked" header doc.md
expect "header.sh tracked line" grep -qxF "$(printf 'doc.md\tmain\t%s' "$sha")" "$T/out"
printf 'y\n' >> "$repo/doc.md"
header doc.md
expect "header.sh dirty" grep -qxF "$(printf 'doc.md\tmain\t%s-dirty' "$sha")" "$T/out"
printf 'x\n' > "$repo/new.md"
header new.md
expect "header.sh untracked" grep -qxF "$(printf 'new.md\tmain\tuntracked')" "$T/out"
printf 'x\n' > "$T/outside.md"
header "$T/outside.md"
expect "header.sh outside a repository" \
  grep -qF "$(printf '\tnot in a repository\tnot in a repository')" "$T/out"
header missing.md doc.md
expect "header.sh missing exits 2" test $? -eq 2
expect "header.sh missing is named" grep -qF 'missing.md does not exist' "$T/err"
expect "header.sh still prints the rest" grep -qF 'doc.md' "$T/out"
mkdir -p "$T/links"
ln -s "$repo/doc.md" "$T/links/doc.md"
header "$T/links/doc.md"
expect "header.sh follows a symlinked document" \
  grep -qxF "$(printf '%s\tmain\t%s-dirty' "$T/links/doc.md" "$sha")" "$T/out"
git -C "$repo" checkout -q --detach
header doc.md
expect "header.sh detached HEAD" \
  grep -qxF "$(printf 'doc.md\tdetached at %s\t%s-dirty' "$sha" "$sha")" "$T/out"
git -C "$repo" checkout -q main
header
expect "header.sh with no arguments exits 2" test $? -eq 2
expect "header.sh usage" grep -qF 'usage:' "$T/err"

# scrub-lib.sh's pattern set, term by term. Kept as this script's own list, not shared with
# ship-it's test-scrub.sh, since each publisher carries its own copy of the check; the cases differ
# where ship-it/scripts/scrub.sh documents an intentional difference.
patterns_dir="$T/patterns"
mkdir -p "$patterns_dir"
# lib <secrets|ident> <hit|pass> <label> <line>
lib() {
  local set=$1 want=$2 label=$3 line=$4
  if (root="$patterns_dir" cleared=/dev/null
      # shellcheck source=scrub-lib.sh
      . "$here/scrub-lib.sh" || exit 2
      [ "$set" = secrets ] && pattern=$secrets || pattern=$ident
      printf '%s\n' "$line" | LC_ALL=C grep -iqE -e "$pattern"); then
    [ "$want" = hit ]
  else
    [ "$want" = pass ]
  fi || { fail=$((fail + 1)); echo "FAIL pattern $label: wanted $want"; return; }
  pass=$((pass + 1))
}
lib secrets hit 'quoted JSON token key' "\"POSTMARK_SERVER_$(printf 'TO')KEN\": \"abc123\""
lib secrets hit 'escaped underscore' "api\\_$(printf 'ke')y: abc123"
lib secrets hit 'basic auth header' "Authorization: $(printf 'Ba')sic dXNlcjpwYXNz"
lib secrets hit 'ApiKey authorization header' "Authorization: $(printf 'Api')Key ${x16}"
lib secrets hit 'private key header' "-----BEGIN RSA $(printf 'PRI')VATE KEY-----"
lib secrets hit 'password in a URL' "postgres://app:$(printf 'hu')nter2@db.example.com/app"
lib secrets hit 'empty-user Redis URL' "$(printf 're')diss://:${x16}@host.example:6380"
lib secrets hit 'GitHub token' "$(printf 'gh')p_${x36}"
lib secrets hit 'GitHub fine-grained token' "$(printf 'gi')thub_pat_${x36}"
lib secrets hit 'Heroku token' "$(printf 'HR')KU-${x36}"
lib secrets hit 'AWS key id' "$(printf 'AK')IA${x16}"
lib secrets hit 'AWS temporary key id' "$(printf 'AS')IA${x16}"
lib secrets hit 'Slack token' "$(printf 'xo')xb-${x16}"
lib secrets hit 'Stripe live key' "$(printf 'sk')_live_${x16}"
lib secrets hit 'Anthropic key' "$(printf 'sk')-ant-api03-${x36}"
lib secrets hit 'OpenAI project key' "$(printf 'sk')-proj-${x36}"
lib secrets hit 'Google key' "$(printf 'AI')za${x36}"
lib secrets hit 'GitLab token' "$(printf 'gl')pat-${x36}"
lib secrets hit 'npm token' "$(printf 'np')m_${x36}"
lib secrets hit 'SendGrid key' "$(printf 'S')G.${x16}.${x16}"
lib secrets hit 'CircleCI token' "$(printf 'CC')IPAT_${x36}"
lib secrets hit 'DigitalOcean token' "$(printf 'do')p_v1_$(printf 'a1%.0s' $(seq 1 32))"
lib secrets hit 'Linear key' "$(printf 'li')n_api_${x36}"
lib secrets hit 'JWT' "$(printf 'ey')J${x16}.${x16}.sig"
lib secrets hit 'bearer token' "$(printf 'Bea')rer ${x16}"
lib secrets hit 'double-quoted key cell' "| \"pass$(printf 'wo')rd\" | x |"
lib secrets hit 'single-quoted key cell' "| 'PASS$(printf 'WO')RD' | x |"
lib secrets pass 'key cell of several words' "| Rollbar access to$(printf 'ke')n | x |"
lib secrets hit 'pepper assignment' "$(printf 'pep')per: ${x16}"
lib secrets hit 'PGP private key block' "-----BEGIN PGP $(printf 'PRI')VATE KEY BLOCK-----"
lib secrets hit 'Slack webhook URL' "https://$(printf 'ho')oks.slack.com/services/T0/B0/${x16}"
lib secrets hit 'Discord webhook URL' "$(printf 'dis')cord.com/api/$(printf 'web')hooks/1/${x16}"
lib secrets hit 'Slack app-level token' "$(printf 'xa')pp-1-${x16}"
lib secrets hit 'Stripe webhook signing secret' "$(printf 'wh')sec_${x16}${x16}"
lib ident hit 'home path' "${home_root}/someone/code"
lib ident hit 'account name as path' "/$(id -un)/code"
lib ident hit 'file URL to a home path' "file://${home_root}/someone/x"
lib ident hit 'dash-encoded home path' "-$(printf 'Us')ers-someone-code"
lib ident hit 'Windows home path' "C:\\$(printf 'Us')ers\\someone"
lib ident hit 'user-relative path' '~someone/code'
lib ident hit 'home variable' "\$$(printf 'HO')ME/.zshrc"
lib ident hit 'private var folders' '/private/var/folders/ab/T/x'
lib ident hit 'local host with a path' 'http://devbox.local/x'
lib ident hit 'local host with a port' 'http://devbox.local:3000/x'
lib ident hit 'local host with a port alone' 'db at myhost.local:5432 now'
lib ident hit 'internal host' 'db.internal'
lib ident hit 'private IP' 'thing at 192.168.1.4 here'
lib ident hit 'loopback address' 'on 127.0.0.1 here'
lib ident hit 'email address' 'someone@company.io'
lib ident hit 'unlisted placeholder' "${home_root}/<$(id -un)>/x"
lib secrets pass 'review table row naming a credential' '| F4 | High | Security | Rotate the OAuth token | open |'
lib secrets pass 'table header row' '| Finding | Type | Category | Description | Status |'
lib secrets pass 'author label' 'the author: someone'
lib secrets pass 'prose about a pepper grinder' 'a pepper grinder'
lib secrets pass 'Rails foreign key option' 'foreign_key: :user_id'
lib secrets pass 'Redis URL with no password' 'redis://localhost:6379/1'
lib secrets pass 'npm registry URL with a port' 'https://registry.npmjs.org:443/@scope/pkg'
lib secrets pass 'word containing sk-' 'task-management-improvements-for-everyone'
lib ident pass 'Rails users path' 'app/views/users/index'
lib ident pass 'this repository home dir' 'dotfiles/home/.zshrc'
# shellcheck disable=SC2088 # the tilde is the text under test, not a path to expand
lib ident pass 'XDG local dir' '~/.local/share'
lib ident pass 'local settings file' 'settings.local.json'
lib ident pass 'bare local host in prose' 'ssh to devbox.local now'
lib ident pass 'dotenv local file' 'load .env.test.local first'
lib ident pass 'Rails time zone call' 'use Time.zone.local(2026, 1, 1)'
lib ident pass 'listed placeholder' "${home_root}/<name>/x"
lib ident pass 'any angle-bracketed placeholder' "${home_root}/<someone>/x"
lib ident pass 'version number' 'version 10.2'
lib ident pass 'public address' 'resolves to 8.8.8.8'

if [ "$fail" -eq 0 ]; then
  echo "test-post: all $pass checks passed"
else
  echo "test-post: $fail of $((pass + fail)) checks failed"
  exit 1
fi
