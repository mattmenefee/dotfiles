#!/usr/bin/env bash
#
# Asserts the HTML teams-copy renders for small drafts. Run it after any change to the converter:
#
#   bash test/test-teams-copy.sh
#
# Every case runs with --print-html, which skips the macOS clipboard, so the conversion runs on any
# platform. HOME points at a private directory, so the real people file is never read and the
# mention cases decide whether one exists and what it holds.

# The drafts hold literal Markdown backticks, which must not expand
# shellcheck disable=SC2016

helper="$(cd "$(dirname "$0")/.." && pwd)/home/.local/bin/teams-copy"
dir=$(mktemp -d) || exit 2
trap 'rm -rf "${dir}"' EXIT
people="${dir}/.config/teams-copy/people.json"
mkdir -p "$(dirname "${people}")" || exit 2

mri=8:orgid:00000000-0000-0000-0000-000000000000
readonly_tag='<readonly class="skipProofing" itemtype="http://schema.skype.com/Mention"'
readonly_tag+=' spellcheck="false">'

failed=0
n=0

fail() {
  echo "FAIL: $1"
  echo "  expected: $2"
  echo "  actual:   $3"
  failed=1
}

# The markup Teams uses for a mention of <name>, already HTML-escaped
mention() {
  printf '%s<mention mri="%s" type="person" aria-label="%s">%s</mention></readonly>' \
    "${readonly_tag}" "${mri}" "$1" "$1"
}

# run <draft, with printf %b escapes> [argument...]
run() {
  printf '%b' "$1" | HOME="${dir}" python3 -I "${helper}" --print-html "${@:2}" 2>"${dir}/stderr"
}

# expect <description> <expected markup inside the Teams wrapper> <draft> [argument...]
expect() {
  n=$((n + 1))
  actual=$(run "$3" "${@:4}")
  rc=$?
  expected="<html><body><span data-teams=\"true\">$2</span></body></html>"
  if [ "${rc}" != 0 ] || [ "${actual}" != "${expected}" ]; then
    fail "$1 (exit status ${rc})" "${expected}" "${actual}"
    sed 's/^/  stderr:   /' "${dir}/stderr"
  fi
}

# expect_error <description> <expected stderr substring> <draft> [argument...]
expect_error() {
  n=$((n + 1))
  actual=$(run "$3" "${@:4}")
  rc=$?
  [ "${rc}" = 1 ] || fail "$1 (exit status)" 1 "${rc}"
  [ -z "${actual}" ] || fail "$1 (stdout)" "nothing" "${actual}"
  grep -qF -- "$2" "${dir}/stderr" || fail "$1 (stderr)" "$2" "$(cat "${dir}/stderr")"
  ! grep -q Traceback "${dir}/stderr" || fail "$1 (stderr)" "no traceback" "a traceback"
}

# Blocks and spacers
expect "a blank line between paragraphs becomes a spacer" '<p>One</p><p>&nbsp;</p><p>Two</p>' \
  'One\n\nTwo\n'
expect "a single newline becomes a line break" '<p>one<br>two</p>' 'one\ntwo\n'
expect "a heading's following lines become a paragraph" \
  '<h1>Title</h1><p>&nbsp;</p><p>line one<br>line two</p>' '# Title\nline one\nline two\n'
expect "## to ###### set the heading level" '<h2>T</h2><p>&nbsp;</p><h6>U</h6>' '## T\n\n###### U\n'
expect "seven #s are not a heading" '<p>####### T</p>' '####### T\n'
expect "a list gets no spacer on either side" '<p>Before</p><ul><li>item</li></ul><p>After</p>' \
  'Before\n\n- item\n\nAfter\n'

# Lists
expect "a list directly after its lead-in line is still a list" \
  '<p>Lead-in:</p><ul><li>one</li><li>two</li></ul>' 'Lead-in:\n- one\n- two\n'
expect "+ and * also start bulleted items" '<ul><li>a</li><li>b</li></ul>' '+ a\n* b\n'
expect "numbering continues across a blank line" '<ol><li>one</li><li>two</li></ol>' \
  '1. one\n\n2. two\n'
expect "a ) after the number starts a numbered item" '<ol><li>a</li><li>b</li></ol>' '1) a\n2) b\n'
expect "an indented line continues the item above it" '<ul><li>item<br>continued</li></ul>' \
  '- item\n  continued\n'
expect "a change of list kind starts a new list" '<ul><li>a</li></ul><ol><li>b</li></ol>' \
  '- a\n1. b\n'

# Inline markup
expect "bold and italics" '<p><i>it</i> and <b>bold</b></p>' '*it* and **bold**\n'
expect "spaced asterisks are not italics" '<p>2 * 3 * 4</p>' '2 * 3 * 4\n'
expect "HTML is escaped" '<p>a &lt; b &amp; "c"</p>' 'a < b & "c"\n'
expect "a code span protects the markup inside it" '<p>Run <code>**x**</code> here</p>' \
  'Run `**x**` here\n'
expect "a mention inside a code span stays literal" '<p><code>@[Sam]</code></p>' '`@[Sam]`\n'
expect "a NUL in the draft cannot inject kept markup" '<p><code>x</code> 0</p>' '`x` \00000\0000\n'
expect "asterisks in a link address are not italics" \
  '<p>See <a href="https://x.y/*a*/b">docs</a> now</p>' 'See [docs](https://x.y/*a*/b) now\n'
expect "an & in a link address is escaped once" '<p><a href="https://x.y/?a=1&amp;b=2">l</a></p>' \
  '[l](https://x.y/?a=1&b=2)\n'

# Mentions
expect_error "a mention without a people file stops" 'which does not exist' 'Hi @[Alex]\n'
printf '{"Alex": "%s", "A&B": "%s"}\n' "${mri}" "${mri}" >"${people}"
expect "a mention in the people file becomes a Teams mention" "<p>Hi $(mention Alex)</p>" \
  'Hi @[Alex]\n'
expect "a mention name with an & is looked up unescaped" "<p>Hi $(mention 'A&amp;B')</p>" \
  'Hi @[A&B]\n'
expect_error "a mention missing from the people file stops" 'no entry for @[Sam]' 'Hi @[Sam]\n'
printf '{"Alex": 1}\n' >"${people}"
expect_error "a people file with a non-string id stops" 'must be a JSON object' 'Hi @[Alex]\n'
printf '{"Alex": \n' >"${people}"
expect_error "a malformed people file stops" 'is not valid JSON' 'Hi @[Alex]\n'
expect "a draft without mentions ignores a malformed people file" '<p>Plain</p>' 'Plain\n'
rm -f -- "${people}"

# Input
printf 'From a file\n' >"${dir}/draft.md"
expect "a draft is read from a path" '<p>From a file</p>' '' "${dir}/draft.md"
expect_error "a draft that does not exist stops" 'No such file or directory' '' "${dir}/missing.md"
expect_error "an empty draft stops" 'nothing to copy' '\n\n'

if [ "${failed}" -eq 0 ]; then
  echo "test-teams-copy: ${n} cases passed"
fi
exit "${failed}"
