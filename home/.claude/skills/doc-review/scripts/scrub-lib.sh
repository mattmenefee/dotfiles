# shellcheck shell=bash
#
# Shared by scrub.sh and post.sh, so the scan a user runs before rewriting and the scan the post
# runs as its gate are one pattern set and cannot drift apart. Source it from bash; it defines the
# patterns and functions and runs nothing.
#
# The caller sets two variables first:
#   root     the repository root whose top-level artifacts are scanned
#   cleared  a file of lines the user cleared, verbatim as grep printed them after the
#            "<file>:<line>:" prefix, or /dev/null
#
# PR Comment Format in ../posting.md is the normative description of every term and why it is
# bounded as it is; change a pattern there and here together.

[ -n "${root-}" ] || { echo "scrub: root is not set" >&2; return 2; }
[ -r "${cleared-}" ] || { echo "scrub: cannot read ${cleared-<unset>}" >&2; return 2; }
! command grep -qx '[[:space:]]*' "$cleared" \
  || { echo "scrub: $cleared has a blank line" >&2; return 2; }

me="$(id -un | sed 's/[][\.*^$+?(){}|/]/\\&/g')"

paths='(^|[^a-z0-9._/~-])(/users/([^<]|$)|/home/([^<]|$)|/private/tmp/|/private/var/'
paths="$paths"'|/var/folders/|/volumes/|/root/)|file:/+(users|home)/([^<]|$)'
paths="$paths"'|(^|[^a-z0-9])-users-([^<]|$)|[a-z]:\\users|\\wsl'
paths="$paths"'|\$\{?home|~[a-z_][a-z0-9_-]*/'
paths="$paths"'|[a-z0-9-]\.(internal|corp|lan)([^a-z0-9_-]|$)|[a-z0-9-]\.local(:[0-9]+)?/'
hosts='(^|[^0-9.])(10(\.[0-9]{1,3}){3}|127(\.[0-9]{1,3}){3}|192\.168(\.[0-9]{1,3}){2}'
hosts="$hosts"'|172\.(1[6-9]|2[0-9]|3[01])(\.[0-9]{1,3}){2})([^0-9]|$)'
ident="$paths|$hosts|/$me(/|\$)|<$me>|(^|[^a-z0-9._%+-])$me@"
ident="$ident"'|[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}'
keys='api\\?[_-]?key|access\\?[_-]?(key|id)|(secret|master|private)\\?[_-]?key(\\?_base)?'
keys="$keys"'|secret|token|passw(or)?d|pwd|credential|auth|bearer|pepper'
schemes='postgres(ql)?|mysql2?|rediss?|amqps?|mongodb(\+srv)?'
secrets='-----begin [a-z ]*private key-----'
secrets="$secrets|($keys)[\"'\`\\\\]*[[:space:]]*[:=]"
secrets="$secrets|\\|[[:space:]]*[a-z0-9_.-]*($keys)[a-z0-9_.-]*[[:space:]]*\\|"
secrets="$secrets"'[[:space:]]*[^|[:space:]]'
secrets="$secrets"'|authorization:[[:space:]]*(basic|bearer|token|apikey)[[:space:]]'
secrets="$secrets"'|[a-z][a-z0-9+.-]*://[^[:space:]/@:]*:[^[:space:]/@]+@'
secrets="$secrets|($schemes)://[^[:space:]@/]*:[^[:space:]@]+@"
secrets="$secrets"'|gh[pousr]_[a-z0-9]{30,}|github_pat_[a-z0-9_]{20,}|hrku-[a-z0-9_-]{20,}'
secrets="$secrets"'|(^|[^a-z0-9])(akia|asia)[0-9a-z]{16}([^0-9a-z]|$)|xox[abprs]-[a-z0-9-]{10,}'
secrets="$secrets"'|[sr]k_live_[a-z0-9]{10,}|(^|[^a-z0-9])sk-(ant-|proj-)?[a-z0-9_-]{20,}'
secrets="$secrets"'|(^|[^a-z0-9])aiza[0-9a-z_-]{35}|glpat-[a-z0-9_-]{20,}|npm_[a-z0-9]{36}'
secrets="$secrets"'|sg\.[a-z0-9_-]{16,}\.[a-z0-9_-]{16,}|ccipat_[a-z0-9_]{20,}'
secrets="$secrets"'|do[opr]_v1_[a-f0-9]{64}|lin_(api|oauth)_[a-z0-9]{32,}'
secrets="$secrets"'|eyj[a-z0-9_-]{8,}\.[a-z0-9_-]{8,}\.|bearer[[:space:]]+[a-z0-9._~+/=-]{16,}'

artifacts() {
  find "$root" -maxdepth 1 \
    \( -name '*local-review*.md' -o -name '*-DOC-REVIEW*.md' \
       -o -name '*-HANDOFF.md' -o -name '*PLAN.md' \) "$@"
}

# Drop a hit only when its text after `<file>:<line>:` is exactly a line the user cleared.
uncleared() {
  awk 'FILENAME == ARGV[1] { ok[$(0)]; next }
       { c = $(0); sub(/^[^:]*:[0-9]+:/, "", c) } !(c in ok)' "$cleared" -
}

# grep runs under sh so that find fails only on a failed read (above 1), never on a clean file (1).
grep_artifacts() {
  artifacts -exec sh -c 'LC_ALL=C grep -inE "$@"; [ $? -le 1 ]' sh "$@" /dev/null {} +
}

# Secret hits pass through uncleared; identifying hits never do, since only a secret is cleared.
scan() {
  if ! secret_hits="$(grep_artifacts -e "$secrets")" || ! ident_hits="$(grep_artifacts -e "$ident")"
  then
    echo "scrub FAILED (grep could not read an artifact) — do not post" >&2
    return 2
  fi
  [ -z "$secret_hits" ] || printf '%s\n' "$secret_hits" | uncleared || return 2
  [ -z "$ident_hits" ] || printf '%s\n' "$ident_hits"
}
