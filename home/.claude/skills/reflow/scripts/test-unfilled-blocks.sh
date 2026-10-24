#!/usr/bin/env bash
#
# Asserts what unfilled-blocks.py reports for small fixtures. Run it after any change to the helper:
#
#   bash home/.claude/skills/reflow/scripts/test-unfilled-blocks.sh
#
# Each fixture is written to a private directory and fed to the helper the way /reflow does, as a
# row naming every line of the file, so the cases also cover the helper's path and exit handling.

# The fixtures hold literal Markdown backticks, which must not expand
# shellcheck disable=SC2016

helper="$(cd "$(dirname "$0")" && pwd)/unfilled-blocks.py"
dir=$(mktemp -d) || exit 2
trap 'rm -rf "${dir}"' EXIT
cd "${dir}" || exit 2

failed=0
n=0

fail() {
  echo "FAIL: $1"
  echo "  expected: $2"
  echo "  actual:   $3"
  failed=1
}

# expect <description> <file> <limit> <expected stdout> <content, with printf %b escapes>
expect() {
  n=$((n + 1))
  printf '%b' "$5" >"$2"
  rows=$(awk 'END { print NR }' "$2")
  actual=$(printf '%s\t1-%s\n' "$2" "${rows}" | python3 -I "${helper}" --limit "$3" 2>/dev/null)
  [ "${actual}" = "$4" ] || fail "$1" "$4" "${actual}"
  rm -f -- "$2"
}

# expect_run <description> <expected exit status> <expected stdout> <rows> [path...]
expect_run() {
  n=$((n + 1))
  actual=$(printf '%b' "$4" | python3 -I "${helper}" --limit 80 "${@:5}" 2>"${dir}/stderr")
  rc=$?
  [ "${rc}" = "$2" ] || fail "$1 (exit status)" "$2" "${rc}"
  [ "${actual}" = "$3" ] || fail "$1 (stdout)" "$3" "${actual}"
  ! grep -q Traceback "${dir}/stderr" || fail "$1 (stderr)" "no traceback" "a traceback"
}

# Markdown paragraphs, openers and widths
expect "a short paragraph line takes the next word" p.md 80 \
  "p.md:1-2: line 1 can take 'two' from line 2" 'one\ntwo\n'
expect "bold text may start a continuation line" p.md 80 \
  "p.md:1-2: line 1 can take '**bold**' from line 2" 'Para line\n**bold** word\n'
expect "a word that would leave a list marker first stays down" p.md 80 \
  "" 'Para line one\nfoo - bar\n'
expect "Markdown is measured in UTF-16 code units" p.md 10 \
  "" '🟠 abcdef\nx\n'
expect "a hard break ends the block" p.md 80 \
  "" 'one  \ntwo\n'
expect "indented code is never a block" p.md 80 \
  "" '    code\n    more\n'
expect "a fence closes only on a bare fence line" p.md 80 \
  "p.md:7-8: line 7 can take 'line.' from line 8" \
  '```\ncode\n```bash\nmore code\n```\n\nShort\nline.\n'
expect "a setext underline makes the line above a heading" p.md 80 \
  "" 'Title\n=====\n'
expect "a flush-left HTML comment is never prose" p.md 80 \
  "" '<!-- A comment that\nspans several\nshort lines -->\n'
expect "front matter after a byte-order mark is still front matter" p.md 80 \
  "p.md:5-6: line 5 can take 'line.' from line 6" '\357\273\277---\nname: x\n---\n\nShort\nline.\n'
expect "a working document is skipped" x-HANDOFF.md 80 \
  "" 'one\ntwo\n'
expect "an ad hoc review report is skipped" x-REVIEW.md 80 "" 'one\ntwo\n'

# Block quotes
expect "a bare > separates quoted paragraphs" p.md 80 \
  "" '> First paragraph.\n>\n> Second paragraph.\n'
expect "a list inside a quote keeps its items apart" p.md 80 \
  "" '> - one\n> - two\n'
expect "a fence inside a quote is not prose" p.md 80 \
  "" '> ```bash\n> echo hi\n> ```\n'
expect "a change of quote depth ends the block" p.md 80 \
  "" '> outer\n> > inner\n'
expect "a quoted paragraph still refills" p.md 80 \
  "p.md:1-2: line 1 can take 'two' from line 2" '> one\n> two\n'

# Link text and code spans
expect "link text too long to move is not reported as split" p.md 30 \
  "p.md:1-2: line 1 is over 30; line 2 is over 30" \
  'See [a very long link text that cannot\nfit on one line at all](https://x.y) ok.\n'
expect "link text that fits on the next line is reported as split" p.md 80 \
  "p.md:1-2: line 1 splits link text or a code span" 'See [Step\n6](https://x.y) for more.\n'

# YAML
expect "a folded scalar refills" y.yml 80 \
  "y.yml:2-3: line 2 can take 'words' from line 3" 'key: >-\n  short\n  words here\n'
expect "a list item's next key is not scalar text" y.yml 80 \
  "" 'steps:\n  - name: >-\n      Run the thing\n    run: echo hi\n'
expect "a comment after a folded scalar is not scalar text" y.yml 80 \
  "" '# heading comment\nkey: >\n  folded text\n# another comment\n'
expect "a blank line keeps the folded scalar going" y.yml 80 \
  "y.yml:4-5: line 4 can take 'and' from line 5" \
  'desc: >\n  First para.\n\n  Second para that is short\n  and continues.\n'

# Comments
expect "a short comment block refills" x.sh 80 \
  "x.sh:1-2: line 1 can take 'two' from line 2" '# one\n# two\n'
expect "prose that names a tool is still prose" x.sh 80 \
  "x.sh:1-3: line 1 can take 'shellcheck' from line 2; line 2 can take 'reports' from line 3" \
  '# This script runs\n# shellcheck over every file and\n# reports the result.\n'
expect "a real directive is an edge" x.sh 80 \
  "" '# shellcheck disable=SC2034\n# short\n'
expect "a list item does not take the unindented line after it" x.sh 80 \
  "" '# - a list item\n# A plain paragraph line that follows\n'
expect "a list item refills with its continuation" x.sh 80 \
  "x.sh:1-2: line 1 can take 'two' from line 2" '# - one\n#   two\n'
expect "a doc tag refills with its hanging indent" x.rb 80 \
  "x.rb:1-2: line 1 can take 'indented' from line 2" \
  '# @param name [String] short\n#   indented continuation\n'
expect "an unindented line ends a doc tag" x.rb 80 \
  "" '# @param name [String] short\n# Unindented prose after the tag\n'
expect "an @example body is never refilled" x.rb 80 \
  "" '# @example\n#   foo(1,\n#     2)\n'
expect "Lisp ;; comments are comments" x.el 80 \
  "x.el:1-2: line 1 can take 'two' from line 2" ';; one\n;; two\n'
expect "Markdown headings in a shell heredoc are not comments" x.sh 80 \
  "" "cat <<'MD'\n### F2 A heading\n### F3 Another\nMD\n"
expect "Rust /// doc comments are comments" x.rs 80 \
  "x.rs:1-2: line 1 can take 'two' from line 2" '/// one\n/// two\n'

# Paths, rows and exit status
printf 'one\ntwo\n' >p.md
expect_run "a named path written with ./ still matches" 0 \
  "p.md:1-2: line 1 can take 'two' from line 2" 'p.md\t1-2\n' ./p.md
expect_run "a named directory selects the files under it" 0 \
  "" 'p.md\t1-2\n' sub
expect_run "a file that cannot be read fails the run" 1 \
  "" 'missing.md\t1-2\n'
expect_run "a malformed row fails the run without a traceback" 1 \
  "" 'p.md\tx-y\n'

if [ "${failed}" -eq 0 ]; then
  echo "test-unfilled-blocks: ${n} cases passed"
fi
exit "${failed}"
