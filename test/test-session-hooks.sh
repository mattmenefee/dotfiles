#!/usr/bin/env bash
#
# Asserts what the session-naming and handoff-before-compact hooks print and when they block. Run it
# after any change to either hook:
#
#   bash test/test-session-hooks.sh
#
# Every case runs against git repositories in a private temporary directory.

# The branch names hold literal shell syntax, which must not expand
# shellcheck disable=SC2016

hooks="$(cd "$(dirname "$0")/.." && pwd)/home/.claude/hooks"
name_hook="${hooks}/name-session.sh"
compact_hook="${hooks}/require-handoff-before-compact.sh"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }
dir=$(mktemp -d) || exit 2
trap 'rm -rf "${dir}"' EXIT

repo="${dir}/my-checkout"
git init -q -b main "${repo}" || exit 2
git -C "${repo}" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init \
  || exit 2

failed=0
n=0

fail() {
  echo "FAIL: $1"
  echo "  expected: $2"
  echo "  actual:   $3"
  failed=1
}

# title <cwd> [session title]: prints the sessionTitle the naming hook sets, or "none"
title() {
  local output
  output=$(jq -cn --arg cwd "$1" --arg t "${2:-}" '{cwd: $cwd, session_title: $t, prompt: "x"}' |
    "${name_hook}") || { echo "error"; return; }
  if [ -z "${output}" ]; then
    echo "none"
  else
    jq -r '.hookSpecificOutput
      | if .hookEventName == "UserPromptSubmit" then .sessionTitle else "wrong event" end' \
      <<<"${output}"
  fi
}

# expect_title <branch or -> <expected> [session title]: checks out the branch, then the title
expect_title() {
  local actual
  n=$((n + 1))
  if [ "$1" != "-" ]; then
    git -C "${repo}" switch -q -C "$1" 2>/dev/null \
      || { fail "switch to $1" "a branch" "refused"; return; }
  fi
  actual=$(title "${repo}" "${3:-}")
  [ "${actual}" = "$2" ] || fail "title on ${1}" "$2" "${actual}"
}

expect_title 'feature-x' 'my-checkout-feature-x'
expect_title 'q"uote;semi$(id)' 'my-checkout-q-uote-semi--id-'
expect_title 'feat/slash' 'my-checkout-feat-slash'
expect_title 'feature-x' 'none' 'already named'
expect_title 'main' 'none'
expect_title 'temp9' 'none'
expect_title 'temp' 'none'
expect_title 'temp-x' 'none'
expect_title 'template-x' 'my-checkout-template-x'

# The title names the checkout's root, not the session's subdirectory
mkdir -p "${repo}/sub"
n=$((n + 1))
actual=$(title "${repo}/sub")
[ "${actual}" = my-checkout-template-x ] \
  || fail "title from a subdirectory" my-checkout-template-x "${actual}"

# A linked worktree is named after its own directory
git -C "${repo}" worktree add -q -b wt-branch "${dir}/wt" 2>/dev/null || exit 2
n=$((n + 1))
actual=$(title "${dir}/wt")
[ "${actual}" = wt-wt-branch ] || fail "title in a linked worktree" wt-wt-branch "${actual}"

git -C "${repo}" switch -q --detach
expect_title - 'none'
long=$(printf 'b%.0s' $(seq 120))
expect_title "${long}" "$(printf 'my-checkout-%s' "${long}" | cut -c1-80)"

n=$((n + 1))
actual=$(title "${dir}")
[ "${actual}" = none ] || fail "title outside a repository" none "${actual}"

n=$((n + 1))
if [ -n "$(echo 'not json' | "${name_hook}")" ]; then
  fail "naming hook on invalid JSON" "no output" "output"
fi

# compact <cwd> <trigger>: prints the hook's exit status
compact() {
  jq -cn --arg cwd "$1" --arg t "$2" \
    '{cwd: $cwd, trigger: $t, hook_event_name: "PreCompact", custom_instructions: null}' |
    "${compact_hook}" 2>/dev/null
  echo "$?"
}

# expect_compact <label> <expected status> <cwd> <trigger>
expect_compact() {
  local actual
  n=$((n + 1))
  actual=$(compact "$3" "$4")
  [ "${actual}" = "$2" ] || fail "compact: $1" "$2" "${actual}"
}

git -C "${repo}" switch -q main
expect_compact 'no handoff, manual' 2 "${repo}" manual
expect_compact 'no handoff, automatic' 0 "${repo}" auto
expect_compact 'no handoff, from a subdirectory' 2 "${repo}/sub" manual
touch -t 202001010000 "${repo}/old-HANDOFF.md"
expect_compact 'handoff older than the last commit' 2 "${repo}" manual
touch -t 209901010000 "${repo}/new-HANDOFF.md"
expect_compact 'handoff newer than the last commit' 0 "${repo}" manual
expect_compact 'outside a repository' 0 "${dir}" manual
git init -q "${dir}/empty"
expect_compact 'repository with no commits' 0 "${dir}/empty" manual

n=$((n + 1))
rm -f "${repo}/new-HANDOFF.md"
message=$(jq -cn --arg cwd "${repo}" '{cwd: $cwd, trigger: "manual"}' | "${compact_hook}" 2>&1)
case "${message}" in
  'Run /handoff before compacting:'*) ;;
  *) fail "compact block message" "Run /handoff before compacting: …" "${message}" ;;
esac

n=$((n + 1))
echo 'not json' | "${compact_hook}" 2>/dev/null
rc=$?
[ "${rc}" -eq 0 ] || fail "compact hook on invalid JSON" 0 "${rc}"

# A handoff written on one branch is stale after a switch to another; the reflog dates the switch
old="${dir}/old-commit"
git init -q -b main "${old}" || exit 2
GIT_COMMITTER_DATE='2020-01-01T00:00:00Z' git -C "${old}" -c user.name=t \
  -c user.email=t@example.com commit -q --allow-empty -m init || exit 2
touch -t 202101010000 "${old}/first-HANDOFF.md"
expect_compact 'handoff newer than an old commit' 0 "${old}" manual
git -C "${old}" switch -q -c other-work
expect_compact 'handoff older than a branch switch' 2 "${old}" manual

# A future-dated commit pulled from elsewhere does not hold compaction past a fresh handoff
future_src="${dir}/future-src"
git init -q -b main "${future_src}" || exit 2
GIT_COMMITTER_DATE='2099-01-01T00:00:00Z' git -C "${future_src}" -c user.name=t \
  -c user.email=t@example.com commit -q --allow-empty -m init || exit 2
git clone -q "${future_src}" "${dir}/future" || exit 2
touch -t 209801010000 "${dir}/future/fresh-HANDOFF.md"
expect_compact 'handoff newer than the clone, older than a future commit' 0 "${dir}/future" manual

# A repository's own config must not make the hook run a signature verifier
signed="${dir}/signed"
git init -q -b main "${signed}" || exit 2
marker="${dir}/verifier-ran"
printf '#!/bin/sh\ntouch %s\n' "${marker}" >"${dir}/verifier.sh"
chmod +x "${dir}/verifier.sh"
git -C "${signed}" config log.showSignature true
git -C "${signed}" config gpg.program "${dir}/verifier.sh"
tree=$(git -C "${signed}" mktree </dev/null)
sha=$(printf '%s\n' "tree ${tree}" 'author t <t@example.com> 1700000000 +0000' \
  'committer t <t@example.com> 1700000000 +0000' 'gpgsig -----BEGIN PGP SIGNATURE-----' ' ' \
  ' -----END PGP SIGNATURE-----' '' 'signed' |
  git -C "${signed}" hash-object -t commit -w --stdin) || exit 2
git -C "${signed}" update-ref HEAD "${sha}"
compact "${signed}" manual >/dev/null
n=$((n + 1))
[ ! -e "${marker}" ] || fail "compact hook with log.showSignature" "no verifier run" "verifier ran"

# Control characters in the checkout's name do not reach the terminal
ctl="${dir}/ctl$(printf '\033')[31mred"
git init -q -b main "${ctl}" || exit 2
git -C "${ctl}" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init \
  || exit 2
n=$((n + 1))
message=$(jq -cn --arg cwd "${ctl}" '{cwd: $cwd, trigger: "manual"}' | "${compact_hook}" 2>&1)
case "${message}" in
  *$'\033'*) fail "compact block message" "no control characters" "an escape sequence" ;;
  *'ctl?[31mred'*) ;;
  *) fail "compact block message" "the path with ? for the escape" "${message}" ;;
esac

if [ "${failed}" -eq 0 ]; then
  echo "test-session-hooks: ${n} cases passed"
fi
exit "${failed}"
