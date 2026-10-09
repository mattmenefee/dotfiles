#!/usr/bin/env bash
#
# Asserts what scrub.sh blocks and what it lets through. Run it after any change to the patterns:
#
#   bash .claude/skills/ship-it/scripts/test-scrub.sh
#
# Every secret below is fake and assembled from pieces at runtime, so no token-shaped literal sits
# in this file for gitleaks to flag, and no real path or account name is written into it.

scrub="$(cd "$(dirname "$0")" && pwd)/scrub.sh"
dir=$(mktemp -d) || exit 2
trap 'rm -rf "${dir}"' EXIT

me=$(id -un)
home_root="/$(printf 'Us')ers"
failed=0
n=0

# expect <exit code> <description> <line> [--narrow]
expect() {
  n=$((n + 1))
  printf '%s\n' "$3" >"${dir}/case-${n}"
  if [ "${4-}" = --narrow ]; then
    bash "${scrub}" --narrow "${dir}/case-${n}" >/dev/null 2>&1
  else
    bash "${scrub}" "${dir}/case-${n}" >/dev/null 2>&1
  fi
  rc=$?
  if [ "${rc}" -ne "$1" ]; then
    echo "FAIL: $2 (expected $1, got ${rc})"
    failed=1
  fi
}

x16=AAAABBBBCCCCDDDD
x36="${x16}${x16}EEEE"

# Secrets block.
expect 1 'quoted JSON token key' "\"POSTMARK_SERVER_$(printf 'TO')KEN\": \"abc123\""
expect 1 'backticked key' "\`api_$(printf 'ke')y\`: abc123"
expect 1 'table cell' "| pass$(printf 'wo')rd | hunter2 |"
expect 1 'escaped underscore' "api\\_$(printf 'ke')y: abc123"
expect 1 'PASSWD assignment' "PASS$(printf 'WD')=abc123"
expect 1 'AWS secret key' "aws_secret_access_$(printf 'ke')y = abc123"
expect 1 'basic auth header' "Authorization: $(printf 'Ba')sic dXNlcjpwYXNz"
expect 1 'Anthropic key' "$(printf 'sk')-ant-api03-${x36}"
expect 1 'OpenAI project key' "$(printf 'sk')-proj-${x36}"
expect 1 'Google key' "$(printf 'AI')za${x36}"
expect 1 'GitLab token' "$(printf 'gl')pat-${x36}"
expect 1 'npm token' "$(printf 'np')m_${x36}"
expect 1 'AWS temporary key id' "$(printf 'AS')IA${x16}"
expect 1 'AWS key id' "$(printf 'AK')IA${x16}"
expect 1 'SendGrid key' "$(printf 'S')G.${x16}.${x16}"
expect 1 'GitHub token' "$(printf 'gh')p_${x36}"
expect 1 'Slack token' "$(printf 'xo')xb-${x16}"
expect 1 'JWT' "$(printf 'ey')J${x16}.${x16}.sig"
expect 1 'private key header' "-----BEGIN RSA $(printf 'PRI')VATE KEY-----"
expect 1 'password in a URL' "postgres://app:$(printf 'hu')nter2@db.example.com/app"

# Identifying text blocks.
expect 1 'home path' "${home_root}/someone/code"
expect 1 'account name as path' "/${me}/code"
expect 1 'file URL to a home path' "file://${home_root}/someone/x"
expect 1 'private var folders' '/private/var/folders/ab/T/x'
expect 1 'Bonjour hostname' 'Someones-MacBook-Pro.local'
expect 1 'local host with port' 'http://devbox.local:3000'
expect 1 'unlisted placeholder' "${home_root}/<${me}>/x"
expect 1 'real path beside a placeholder' "${home_root}/<name>/x and ${home_root}/someone/y"
expect 1 'private IP' 'thing at 192.168.1.4 here'
expect 1 'email address' 'someone@company.io'
expect 1 'home path in narrow mode' "${home_root}/someone/code" --narrow
expect 1 'secret in narrow mode' "\"$(printf 'TO')KEN\": \"abc123\"" --narrow

# Ordinary text passes.
expect 0 'Rails users path' 'app/views/users/index'
expect 0 'this repository home dir' 'dotfiles/home/.zshrc'
# shellcheck disable=SC2088 # the tilde is the text under test, not a path to expand
expect 0 'XDG local dir' '~/.local/share'
expect 0 'local settings file' 'settings.local.json'
expect 0 'home variable' "\$$(printf 'HO')ME/.zshrc"
expect 0 'Homebrew prefix variable' "\$$(printf 'HO')MEBREW_PREFIX/bin"
expect 0 'SSH remote' 'git@github.com:owner/repo.git'
expect 0 'example address' 'you@example.com'
expect 0 'listed placeholder' "${home_root}/<name>/x"
expect 0 'version number' 'version 10.2'
expect 0 'word containing sk-' 'task-management-improvements-for-everyone'
expect 0 'author label' 'the author: someone'
expect 0 'email in narrow mode' 'someone@company.io' --narrow

# Usage errors are failures to check, never hits.
bash "${scrub}" >/dev/null 2>&1
[ $? -eq 2 ] || {
  echo 'FAIL: missing argument should exit 2'
  failed=1
}
printf 'x\n' >"${dir}/same"
bash "${scrub}" "${dir}/same" "${dir}/same" >/dev/null 2>&1
[ $? -eq 2 ] || {
  echo 'FAIL: cleared file equal to the checked file should exit 2'
  failed=1
}

[ "${failed}" -eq 0 ] && echo "test-scrub: all ${n} cases passed"
exit "${failed}"
