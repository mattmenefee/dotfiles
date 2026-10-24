#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
#
# Posts a finished review file to its pull request as one or more collapsible comments, behind every
# gate in PR Comment Format (../posting.md): no open finding, a clean scan of the artifacts, a
# withheld Sensitive Information finding absent from every part and a clean scan of exactly what is
# posted. Nothing is posted unless every part passes.
#
# Usage: post.sh --review FILE --repo OWNER/NAME --status TEXT --stats TEXT
#                [--post FILE] [--cleared FILE] [--cleared-findings FILE]
#
#   --review            the review file in the repository root
#   --repo              the repository the pull request is in, passed to gh as --repo
#   --status            the heading's status summary, e.g. "all clear"
#   --stats             the bold stats line, e.g.
#                       "24 findings — 14 fixed, 2 refuted, 8 observations"
#   --post              the withheld copy to post in place of the review file (default: the file)
#   --cleared           lines the user cleared as not credentials (default: /dev/null)
#   --cleared-findings  Sensitive Information finding numbers the user cleared (default: /dev/null)
#
# Run it from the pull request's branch. On success it deletes the withheld copy and both cleared
# files; the review file itself is left for the caller.

review_file='' post_file='' repo='' status='' stats='' cleared=/dev/null cleared_findings=/dev/null
while [ $# -gt 0 ]; do
  case "$1" in
    --review) review_file=$2 ;;
    --post) post_file=$2 ;;
    --repo) repo=$2 ;;
    --status) status=$2 ;;
    --stats) stats=$2 ;;
    --cleared) cleared=$2 ;;
    --cleared-findings) cleared_findings=$2 ;;
    *) echo "post: unknown argument $1 — do not post" >&2; exit 1 ;;
  esac
  [ $# -ge 2 ] || { echo "post: $1 needs a value — do not post" >&2; exit 1; }
  # An empty value would silently fall back to a default, and a flag would be taken as the value
  case $2 in
    '' | --*) echo "post: $1 needs a value, not '$2' — do not post" >&2; exit 1 ;;
  esac
  shift 2
done
post_file=${post_file:-$review_file}
[ -n "$review_file" ] && [ -n "$repo" ] && [ -n "$status" ] && [ -n "$stats" ] \
  || { echo "post: --review, --repo, --status and --stats are required — do not post" >&2; exit 1; }
case "$status$stats" in
  *'['*']'* | *'<'*'>'*)
    echo "post: --status or --stats still holds a [placeholder] or <placeholder> — do not post" >&2
    exit 1 ;;
esac
for list in "$cleared" "$cleared_findings"; do
  [ -f "$list" ] || [ "$list" = /dev/null ] \
    || { echo "post: $list is not a regular file — do not post" >&2; exit 1; }
done
[ -r "$review_file" ] && [ -r "$post_file" ] && [ -r "$cleared_findings" ] \
  || {
    echo "post: cannot read the review, post or cleared-findings file — do not post" >&2; exit 1
  }

root="$(git rev-parse --show-toplevel)" || exit 1
# The open-findings check and the withheld numbers must come from the full review in the root, not
# from a copy whose withheld findings are already gone
[ "$(dirname -- "$review_file")" -ef "$root" ] \
  || { echo "post: --review must be the review file in $root — do not post" >&2; exit 1; }
case "$(basename -- "$review_file")" in
  *-DOC-REVIEW*.md | *local-review*.md) ;;
  *) echo "post: --review is not a review artifact — do not post" >&2; exit 1 ;;
esac
# A side file inside the repository may be another working document or a tracked file, which would
# be posted under the review's heading and then deleted
real_root="$(cd -P -- "$root" && pwd -P)" || exit 1
for side in "$post_file" "$cleared" "$cleared_findings"; do
  { [ "$side" = /dev/null ] || [ "$side" -ef "$review_file" ]; } && continue
  side_dir="$(cd -P -- "$(dirname -- "$side")" && pwd -P)" \
    || { echo "post: cannot resolve the directory of $side — do not post" >&2; exit 1; }
  case "$side_dir/" in
    "$real_root"/*)
      echo "post: $side must be a temporary file outside the repository — do not post" >&2
      exit 1 ;;
  esac
done
# shellcheck source=scrub-lib.sh
. "$(dirname "$0")/scrub-lib.sh" || { echo "scrub setup failed — do not post" >&2; exit 1; }
scanned="$(artifacts -print)"
[ -n "$scanned" ] || { echo "scrub: no artifacts under $root — do not post" >&2; exit 1; }
printf 'scrub: scanned these files\n%s\n' "$scanned" >&2

LC_ALL=C command grep -vxE 'F[0-9]+' "$cleared_findings"; rc=$?
[ "$rc" -eq 1 ] \
  || { echo "cleared findings must be one finding number per line — do not post" >&2; exit 1; }
LC_ALL=C command grep -nE '^\|[[:space:]]*F[0-9]+[[:space:]]*\|.*\|[[:space:]]*❓[[:space:]]*\|' \
  /dev/null "$review_file"; a=$?
LC_ALL=C command grep -n '^- \[ \]' /dev/null "$review_file"; b=$?
[ "$a" -eq 1 ] && [ "$b" -eq 1 ] \
  || { echo "open findings above, or $review_file unreadable — do not post" >&2; exit 1; }
work_dir="$(mktemp -d "${TMPDIR:-/tmp}/pr-comment.XXXXXX")" && [ -d "$work_dir" ] \
  || { echo "cannot create a work directory — do not post" >&2; exit 1; }
trap 'rm -rf "$work_dir"' EXIT

# Gate 1 — the artifacts, after any rewrites. Nothing may remain.
remaining="$(scan)" || { echo "scrub FAILED — do not post" >&2; exit 1; }
[ -z "$remaining" ] || { echo "scrub: unresolved hits — do not post" >&2
                         printf '%s\n' "$remaining" >&2; exit 1; }

body="$(cat "$post_file")" || { echo "cannot read $post_file" >&2; exit 1; }
[ -n "$body" ] || { echo "review body is empty — refusing to post" >&2; exit 1; }
title="$(LC_ALL=C sed -n '1s/^# //p' "$review_file")"
[ -n "$title" ] || { echo "review file has no title on its first line — refusing to post" >&2
                     exit 1; }

# Resolve the destination once, show it and post to exactly that pull request
pr_url="$(gh pr view "$(git branch --show-current)" --repo "$repo" --json url --jq .url)" \
  || { echo "no pull request found for this branch in $repo — do not post" >&2; exit 1; }
echo "posting to $pr_url" >&2

# Split at headings so no comment exceeds GitHub's 65,536-character body limit
limit=60000
printf '%s\n' "$body" | LC_ALL=C awk -v limit="$limit" -v dir="$work_dir" '
  function flush() {
    if (buf == "") return
    if (size > 0 && size + blen > limit) { part++; size = 0 }
    printf "%s", buf > (dir "/part-" sprintf("%03d", part))
    size += blen; buf = ""; blen = 0
  }
  !fence && /^##+ / { flush() }
  /^(```|~~~)/ { fence = !fence }
  { buf = buf $(0) "\n"; blen += length($(0)) + 1 }
  END { flush() }' \
  || { echo "could not split the review — do not post" >&2; exit 1; }

set -- "$work_dir"/part-*
total=$#
i=0
for part in "$work_dir"/part-*; do
  i=$((i + 1))
  [ "$(wc -c < "$part")" -le "$limit" ] \
    || { echo "one section of the review is over the limit on its own — split it by hand" >&2
         exit 1; }
  label=""
  [ "$total" -eq 1 ] || label=" (part $i of $total)"
  {
    if [ "$i" -eq 1 ]; then
      # shellcheck disable=SC2016 # the backticks are Markdown, not a command substitution
      printf '## %s (`%s`) — %s\n' "$title" "$(basename "$review_file")" "$status"
      echo ""
      printf '**%s**\n' "$stats"
      echo ""
    fi
    echo "<details>"
    echo "<summary>Click to expand full review details$label</summary>"
    echo ""
    cat "$part"
    echo ""
    echo "</details>"
  } > "$work_dir/comment-$(printf '%03d' "$i")"
done

# Gate 2 — what is actually posted: the withheld copy and the heading, which Gate 1 never reads.
# Check every part first.

# A fenced `## ` line is quoted text, so only an unfenced one ends the section. Headings and rows
# inside a fence still count, since withholding too much fails safe.
ids="$(LC_ALL=C awk 'FILENAME == ARGV[1] { ok[$(0)]; next }
            { id = "" }
            !fence && /^## / { s = /^## Sensitive Information/ }
            /^(```|~~~)/ { fence = !fence }
            s && /^### F[0-9]+ / { id = $(2) }
            /^\|[[:space:]]*F[0-9]+[[:space:]]*\|/ {
              n = split($(0), c, /[[:space:]]*\|[[:space:]]*/)
              if (n > 4 && c[4] == "Sensitive Information") id = c[2] }
            id != "" && !(id in ok) && !(id in seen) { seen[id]; print id }' \
  "$cleared_findings" - < "$review_file")" \
  || { echo "cannot read $review_file — do not post" >&2; exit 1; }
for comment in "$work_dir"/comment-*; do
  # Mentions notify an account and cross-repository references leave a backlink, but quoted prose
  # makes both common and harmless enough that they warn rather than block
  refs="$(LC_ALL=C awk '/^(```|~~~)/ { fence = !fence; next }
                        !fence { line = $(0); gsub(/`[^`]*`/, "", line); print FNR ":" line }' \
            "$comment" | LC_ALL=C command grep -iE \
            -e '(^|[^a-z0-9_`/.-])@[a-z0-9-]+' -e '[a-z0-9_.-]+/[a-z0-9_.-]+#[0-9]+')"
  [ -z "$refs" ] || { echo "warning: $(basename "$comment") has a mention or cross-repository" \
                        "reference outside code spans; GitHub will notify or backlink it:" >&2
                      printf '%s\n' "$refs" >&2; }
  for id in $(printf '%s\n' "$ids"); do
    ! LC_ALL=C command grep -qE "(^|[^0-9a-z])$id([^0-9]|\$)" "$comment" \
      || { echo "withhold: $id is still in the comment — do not post" >&2; exit 1; }
  done
  found="$(LC_ALL=C command grep -inE -e "$secrets" /dev/null "$comment")"
  [ $? -le 1 ] || { echo "scrub FAILED (grep could not read $comment) — do not post" >&2; exit 1; }
  found="$(printf '%s\n' "$found" | uncleared)"
  [ $? -le 1 ] || { echo "scrub FAILED (could not read $cleared) — do not post" >&2; exit 1; }
  posted="$(LC_ALL=C command grep -inE -e "$ident" /dev/null "$comment")"
  [ $? -le 1 ] || { echo "scrub FAILED (grep could not read $comment) — do not post" >&2; exit 1; }
  [ -z "$found$posted" ] || { echo "scrub: assembled comment still has hits — do not post" >&2
                              printf '%s\n' "$found" "$posted" | command grep . >&2; exit 1; }
done

i=0
for comment in "$work_dir"/comment-*; do
  i=$((i + 1))
  gh pr comment "$pr_url" --body-file "$comment" \
    || { echo "posting stopped at part $i of $total; earlier parts are already posted" >&2
         exit 1; }
done
# Compare files, not strings, so another spelling of the review file's path never deletes it
[ "$post_file" -ef "$review_file" ] || rm -f -- "$post_file"
for list in "$cleared" "$cleared_findings"; do
  [ "$list" = /dev/null ] || [ "$list" -ef "$review_file" ] || rm -f -- "$list"
done
