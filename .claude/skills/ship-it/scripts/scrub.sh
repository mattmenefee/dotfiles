#!/usr/bin/env bash
#
# Checks a file for anything that must not reach a public pull request.
#
# Usage: scrub.sh [--narrow] <file> [cleared-lines-file]
#
# Exit 0: clean. Exit 1: hits, printed to stderr. Exit 2: the check itself failed, so nothing was
# checked; treat it as a block, never as clean.
#
# Secret-shaped hits block the post and go to the user, never rewritten: rewriting a credential
# hides the evidence without rotating it. Identifying hits (home and temp paths, private hosts and
# addresses, email addresses, the account name as a path segment or address) are rewritten in the
# file and the script is run again.
#
# --narrow runs the secret pass and the path terms only. It is for text written in the session from
# the diff (a pull request title or body, a commit message), where email addresses and hostnames
# are routine and a home path or a credential is still never acceptable.
#
# The cleared file holds lines the user said are not credentials, one per line, verbatim as grep
# printed them after the "<file>:<line>:" prefix. A hit is cleared only by an exact match, so an
# edited or appended line is put back in front of the user. Only secret hits can be cleared.
#
# These patterns derive from the PR Comment Format section of home/.claude/commands/doc-review.md.
# They differ from it on purpose, and a sync in either direction keeps these differences:
#   - Paths and hosts are bounded on the left and right, so this repository's own home/ directory,
#     ~/.local, settings.local.json and version numbers do not fire.
#   - Only /private/tmp/ and /var/folders/ are temp roots; a bare /tmp/ path names no machine.
#   - The account name fires only as a path segment or the local part of an address, never as a
#     word: in prose it is the author's name, which the pull request already shows.
#   - The shell's home variable is not a term. It names nobody, and rewriting it breaks quoted code.
#   - Placeholders are exempt only in the fixed forms /Users/<user>, <name> or <username>, removed
#     per match before scanning rather than by dropping the whole line.
#   - git@ remotes and example.com, .org and .net addresses are exempt.
#   - The secret set adds provider token formats and tolerates a quote, backtick, backslash or table
#     pipe between a keyword and its value.

narrow=
if [ "${1-}" = --narrow ]; then
  narrow=1
  shift
fi
[ -n "${1-}" ] || {
  echo 'usage: scrub.sh [--narrow] <file> [cleared-lines-file]' >&2
  exit 2
}
file=$1
cleared=${2:-/dev/null}

# Bytes, not characters: in a UTF-8 locale grep silently skips a line holding invalid UTF-8.
export LC_ALL=C

[ -r "${file}" ] || {
  echo "scrub: cannot read ${file}" >&2
  exit 2
}
[ -r "${cleared}" ] || {
  echo "scrub: cannot read ${cleared}" >&2
  exit 2
}
if [ "${file}" -ef "${cleared}" ]; then
  echo "scrub: the cleared file is the file being checked" >&2
  exit 2
fi
if command grep -qx '[[:space:]]*' "${cleared}"; then
  echo "scrub: ${cleared} has a blank line, so it was written wrong" >&2
  exit 2
fi

# Escaped before it enters the pattern, since an account name can hold regex metacharacters.
me=$(id -un | sed 's/[][\.*^$+?(){}|/]/\\&/g')

paths='(^|[^a-z0-9._/~-])(/users/|/home/|/private/tmp/|/private/var/|/var/folders/'
paths="${paths}"'|/volumes/|/root/)'
paths="${paths}"'|file:/+(users|home)/|(^|[^a-z0-9])-users-|[a-z]:\\users|\\wsl'
paths="${paths}"'|~[a-z_][a-z0-9_-]*/|[a-z0-9-]\.(internal|corp|lan)([^a-z0-9_-]|$)'
paths="${paths}"'|[a-z0-9-]\.local(:[0-9]+|[^a-z0-9_.-]|\.([^a-z]|$)|$)'
hosts='(^|[^0-9.])(10(\.[0-9]{1,3}){3}|127(\.[0-9]{1,3}){3}|192\.168(\.[0-9]{1,3}){2}'
hosts="${hosts}"'|172\.(1[6-9]|2[0-9]|3[01])(\.[0-9]{1,3}){2})([^0-9]|$)'
ident="${paths}|${hosts}|/${me}(/|\$)|(^|[^a-z0-9._%+-])${me}@"
ident="${ident}|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}"
[ -z "${narrow}" ] || ident=${paths}

keys='api\\?[_-]?key|access\\?[_-]?key|secret|token|passw(or)?d|pwd|credential|auth'
secrets='-----begin [a-z ]*private key-----'
secrets="${secrets}|(${keys})[\"'\`\\\\]*[[:space:]]*(\\|[[:space:]]*[^|[:space:]]|[:=])"
secrets="${secrets}"'|authorization:[[:space:]]*(basic|bearer|token)[[:space:]]'
secrets="${secrets}"'|[a-z][a-z0-9+.-]*://[^[:space:]/]+:[^[:space:]@]+@'
secrets="${secrets}"'|gh[pousr]_[a-z0-9]{30,}|github_pat_[a-z0-9_]{20,}'
secrets="${secrets}"'|(^|[^a-z0-9])(akia|asia)[0-9a-z]{16}([^0-9a-z]|$)|xox[abprs]-[a-z0-9-]{10,}'
secrets="${secrets}"'|[sr]k_live_[a-z0-9]{10,}|(^|[^a-z0-9])sk-(ant-|proj-)?[a-z0-9_-]{20,}'
secrets="${secrets}"'|(^|[^a-z0-9])aiza[0-9a-z_-]{35}|glpat-[a-z0-9_-]{20,}|npm_[a-z0-9]{36}'
secrets="${secrets}"'|sg\.[a-z0-9_-]{16,}\.[a-z0-9_-]{16,}'
secrets="${secrets}"'|eyj[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.|bearer[[:space:]]+[a-z0-9._~+/=-]{16,}'

# `command grep` bypasses a wrapper that might honor ignore files, and these artifacts are
# untracked. Branch on grep's own status: 1 is clean, above 1 is a failed read.
found=$(command grep -inE -e "${secrets}" /dev/null "${file}")
[ $? -le 1 ] || {
  echo "scrub FAILED: grep could not read ${file}" >&2
  exit 2
}
found=$(printf '%s\n' "${found}" |
  awk 'FILENAME == ARGV[1] { ok[$0]; next }
       NF { c = $0; sub(/^[^:]*:[0-9]+:/, "", c) } NF && !(c in ok)' "${cleared}" -) || {
  echo "scrub FAILED: could not read ${cleared}" >&2
  exit 2
}
if [ -n "${found}" ]; then
  printf '%s\n' "${found}" >&2
  echo "scrub: secret-shaped hits above; show them to the user and do not post" >&2
  exit 1
fi

# The exempt forms are removed from a copy of each line before the identifying pass, so a real path
# beside a placeholder on the same line still fires. Line numbers are unchanged.
exempt=$(perl -pe 's{/(users|home)/<(user|name|username)>}{<home>}gi;
                   s{-users-<(user|name|username)>}{<home>}gi;
                   s{(^|[^a-z0-9._%+-])git\@}{$1<git>}gi;
                   s{[a-z0-9._%+-]+\@example\.(com|org|net)\b}{<example>}gi' "${file}") || {
  echo "scrub FAILED: could not prepare ${file}" >&2
  exit 2
}
hits=$(printf '%s\n' "${exempt}" | command grep -inE -e "${ident}")
[ $? -le 1 ] || {
  echo "scrub FAILED: grep could not read ${file}" >&2
  exit 2
}
if [ -n "${hits}" ]; then
  printf '%s\n' "${hits}" | awk -v f="${file}" '{ print f ":" $0 }' >&2
  echo "scrub: rewrite the hits above in ${file} and run again" >&2
  exit 1
fi

echo "scrub: clean (${file})"
