#!/usr/bin/env bash
#
# End-to-end cases for scrub.sh and post.sh, run in a throwaway repository with a stub gh that
# records what would have been posted. Run it after changing either script or scrub-lib.sh.
#
# Usage: test-post.sh

here="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d)"
trap 'chmod -R u+rw "$T" 2>/dev/null; rm -rf "$T"' EXIT
repo="$T/repo" bin="$T/bin"
mkdir -p "$repo" "$bin"
git -C "$repo" init -q -b main

# The stub prints a pull request URL and saves each comment body it is asked to post
cat > "$bin/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "pr view") echo https://example.invalid/pull/1 ;;
  "pr comment") n=$(find "$GH_STUB_DIR" -name 'posted-*' | wc -l | tr -d ' ')
                cp "$5" "$GH_STUB_DIR/posted-$n" ;;
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
}

# check <label> <expected posts> <expected message or ""> <post.sh arguments>...
check() {
  local label=$1 want_posts=$2 want_msg=$3
  shift 3
  find "$T" -maxdepth 1 -name 'posted-*' -delete
  # A broken post.sh that posts also deletes its inputs, so restore the shared one for later cases
  printf 'F3\n' > "$T/cf"
  (cd "$repo" && PATH="$bin:$PATH" bash "$here/post.sh" "$@") > "$T/out" 2>&1
  local posts
  posts=$(find "$T" -maxdepth 1 -name 'posted-*' | wc -l | tr -d ' ')
  if [ "$posts" = "$want_posts" ] && { [ -z "$want_msg" ] || grep -qF -- "$want_msg" "$T/out"; }; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    printf 'FAIL %s: posted %s, wanted %s; output:\n' "$label" "$posts" "$want_posts"
    sed 's/^/  /' "$T/out"
  fi
}

# fresh <name> copies a fixture so post.sh may delete it on success
fresh() { cp "$T/$1" "$T/$1-run" && printf '%s' "$T/$1-run"; }

base=(--review "$repo/t-DOC-REVIEW.md" --repo o/r --status "all clear" --stats "2 findings — 2 fixed")
printf 'F3\n' > "$T/cf"

review ""
check "A withheld copy, F3 cleared" 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)"
heading='^## Document Review: t (.t-DOC-REVIEW.md.) — all clear$'
expect "A heading" grep -q "$heading" "$T/posted-0"
expect "A stats line" grep -q '^\*\*2 findings — 2 fixed\*\*$' "$T/posted-0"
expect "A deleted its working files" test ! -e "$T/copy-run" -a ! -e "$T/cf-run"

check "B F2 left in the post file" 0 "withhold: F2 is still in the comment" "${base[@]}" \
  --cleared-findings "$T/cf"

review "see /Users/<name>/app and /Users/realperson/app"
check "C real path beside placeholder" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"

review "api_key: "
printf 'api_key: realvalue1234567890\n' >> "$repo/t-DOC-REVIEW.md"
grep -v 'F2' "$repo/t-DOC-REVIEW.md" > "$T/copy"
printf 'api_key: \n' > "$T/cl"
check "D cleared key, later value" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf" --cleared "$T/cl"

review "api_key: "
check "D2 only the cleared bare key" 1 "" "${base[@]}" --post "$(fresh copy)" \
  --cleared-findings "$(fresh cf)" --cleared "$(fresh cl)"

review ""
check "E status still a placeholder" 0 "[placeholder]" --review "$repo/t-DOC-REVIEW.md" --repo o/r \
  --status "[status summary]" --stats "x" --post "$T/copy" --cleared-findings "$T/cf"
check "E2 stats missing" 0 "are required" --review "$repo/t-DOC-REVIEW.md" --repo o/r \
  --status "all clear" --post "$T/copy" --cleared-findings "$T/cf"

printf 'three\n' > "$T/cfbad"
check "F malformed cleared findings" 0 "one finding number per line" "${base[@]}" \
  --post "$T/copy" --cleared-findings "$T/cfbad"

review "| F4 | x | ❓ |"
check "G open finding in the review" 0 "open findings above" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"

review "see file:///Users/someone/f"
check "H file URL home path" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"
review "see /private/var/folders/ab/cd/T/tmp.1/f"
check "H2 resolved temp path" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"

review "api_key: x /Users/realperson/app"
printf 'api_key: x /Users/realperson/app\n' > "$T/cl2"
check "I cleared line with a path" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf" --cleared "$T/cl2"

review "| F5 | 🟡 Medium | Sensitive Information | d | ✅ |
### F5 elsewhere"
check "J SI finding filed elsewhere" 0 "withhold: F5 is still in the comment" "${base[@]}" \
  --post "$T/copy" --cleared-findings "$T/cf"

review ""
printf 'x\n' > "$repo/z-HANDOFF.md"
chmod 000 "$repo/z-HANDOFF.md"
check "K unreadable artifact" 0 "could not read an artifact" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"
chmod 600 "$repo/z-HANDOFF.md"
rm -f "$repo/z-HANDOFF.md"

review "x $(printf '\377') api_$(printf 'ke')y: abc123"
check "L credential after a bad byte" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"

review "see /Users/<$(id -un)>/app"
check "M login in angle brackets" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"

review "| DATABASE_PASS$(printf 'WO')RD | hunter2 |"
check "N table cell naming a password" 0 "unresolved hits" "${base[@]}" --post "$T/copy" \
  --cleared-findings "$T/cf"

# scrub.sh on its own: clean, a hit and nothing to scan. scrub_exits <code> runs it and checks its
# exit status; its output is left in $T/out
scrub_exits() {
  local rc
  (cd "$repo" && bash "$here/scrub.sh") > "$T/out" 2>&1
  rc=$?
  [ "$rc" -eq "$1" ] || { cat "$T/out"; return 1; }
}
review ""
expect "scrub.sh clean exits 0" scrub_exits 0
expect "scrub.sh clean says so" grep -q 'scrub: clean' "$T/out"
review "see /Users/realperson/app"
expect "scrub.sh hit exits 1" scrub_exits 1
expect "scrub.sh hit is printed" grep -q 'realperson' "$T/out"
rm -f "$repo/t-DOC-REVIEW.md"
expect "scrub.sh with nothing to scan exits 2" scrub_exits 2

if [ "$fail" -eq 0 ]; then
  echo "test-post: all $pass checks passed"
else
  echo "test-post: $fail of $((pass + fail)) checks failed"
  exit 1
fi
