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

# expect <exit code> <description> <line> [--narrow | --cleared <cleared-lines file content>]
expect() {
  n=$((n + 1))
  printf '%s\n' "$3" >"${dir}/case-${n}"
  case "${4-}" in
    --narrow) bash "${scrub}" --narrow "${dir}/case-${n}" >/dev/null 2>"${dir}/err-${n}" ;;
    --cleared)
      printf '%s\n' "$5" >"${dir}/cleared-${n}"
      bash "${scrub}" "${dir}/case-${n}" "${dir}/cleared-${n}" >/dev/null 2>"${dir}/err-${n}" ;;
    *) bash "${scrub}" "${dir}/case-${n}" >/dev/null 2>"${dir}/err-${n}" ;;
  esac
  rc=$?
  if [ "${rc}" -ne "$1" ]; then
    echo "FAIL: $2 (expected $1, got ${rc})"
    failed=1
  fi
}

# secret <description> <line> [--narrow]: exit 1 from the secret pass, not the identifying one, so a
# case cannot pass through an email or host term that happens to match the same line
secret() {
  expect 1 "$@"
  command grep -q 'secret-shaped hits above' "${dir}/err-${n}" || {
    echo "FAIL: $1 (not caught by the secret pass)"
    failed=1
  }
}

x16=AAAABBBBCCCCDDDD
x36="${x16}${x16}EEEE"

# Secrets block.
secret 'quoted JSON token key' "\"POSTMARK_SERVER_$(printf 'TO')KEN\": \"abc123\""
secret 'backticked key' "\`api_$(printf 'ke')y\`: abc123"
secret 'table cell' "| pass$(printf 'wo')rd | hunter2 |"
secret 'escaped underscore' "api\\_$(printf 'ke')y: abc123"
secret 'PASSWD assignment' "PASS$(printf 'WD')=abc123"
secret 'AWS secret key' "aws_secret_access_$(printf 'ke')y = abc123"
secret 'basic auth header' "Authorization: $(printf 'Ba')sic dXNlcjpwYXNz"
secret 'Anthropic key' "$(printf 'sk')-ant-api03-${x36}"
secret 'OpenAI project key' "$(printf 'sk')-proj-${x36}"
secret 'Google key' "$(printf 'AI')za${x36}"
secret 'GitLab token' "$(printf 'gl')pat-${x36}"
secret 'npm token' "$(printf 'np')m_${x36}"
secret 'AWS temporary key id' "$(printf 'AS')IA${x16}"
secret 'AWS key id' "$(printf 'AK')IA${x16}"
secret 'SendGrid key' "$(printf 'S')G.${x16}.${x16}"
secret 'GitHub token' "$(printf 'gh')p_${x36}"
secret 'Slack token' "$(printf 'xo')xb-${x16}"
secret 'JWT' "$(printf 'ey')J${x16}.${x16}.sig"
secret 'private key header' "-----BEGIN RSA $(printf 'PRI')VATE KEY-----"
secret 'password in a URL' "postgres://app:$(printf 'hu')nter2@db.example.com/app"
secret 'password in an HTTPS URL' "https://deploy:$(printf 'hu')nter2@git.example.com/x"
secret 'Rails secret key base' "SECRET_$(printf 'KE')Y_BASE=${x36}"
secret 'Rails master key' "RAILS_MASTER_$(printf 'KE')Y=${x36}"
secret 'table cell naming a password' "| DATABASE_PASS$(printf 'WO')RD | hunter2 |"
secret 'table cell naming a master key' "| RAILS_MASTER_$(printf 'KE')Y | ${x36} |"
secret 'backticked table key cell' "| \`SECRET_KEY_$(printf 'BA')SE\` | ${x36} |"
secret 'bold table key cell' "| **Pass$(printf 'wo')rd** | hunter2x |"
secret 'double-quoted table key cell' "| \"pass$(printf 'wo')rd\" | hunter2x |"
secret 'single-quoted table key cell' "| 'PASS$(printf 'WO')RD' | hunter2x |"
# Accepted false positive: a bare backticked file name holding a key word reads as a key cell
secret 'summary row locating a key-named file' "| F4 | Low | Accuracy | d | \`au$(printf 'th').md\` | open |"
secret 'credential after an invalid byte' "x $(printf '\377') api_$(printf 'ke')y: abc123"
secret 'empty-user Redis URL' "$(printf 're')diss://:${x16}@host.example:6380"
secret 'slash in a database password' "$(printf 'pos')tgres://u:pa/${x16}@db.example/app"
secret 'Heroku token' "$(printf 'HR')KU-${x36}"
secret 'DigitalOcean token' "$(printf 'do')p_v1_$(printf 'a1%.0s' $(seq 1 32))"
secret 'Linear key' "$(printf 'li')n_api_${x36}"
secret 'CircleCI token' "$(printf 'CC')IPAT_${x36}"
secret 'ApiKey authorization header' "Authorization: $(printf 'Api')Key ${x16}"
secret 'pepper assignment' "$(printf 'pep')per: ${x16}"
secret 'access id assignment' "spaces_access_$(printf 'i')d = ${x16}"
secret 'bearer key with a colon' "$(printf 'bea')rer: ${x16}"
secret 'PGP private key block' "-----BEGIN PGP $(printf 'PRI')VATE KEY BLOCK-----"
secret 'Slack webhook URL' "https://$(printf 'ho')oks.slack.com/services/T0/B0/${x16}"
secret 'Discord webhook URL' "$(printf 'dis')cord.com/api/$(printf 'web')hooks/1/${x16}"
secret 'Slack app-level token' "$(printf 'xa')pp-1-${x16}"
secret 'Stripe webhook signing secret' "$(printf 'wh')sec_${x16}${x16}"

# A cleared line is skipped only as an exact match, and only in the secret pass.
api_line="api_$(printf 'ke')y: abc123"
expect 0 'cleared secret line' "${api_line}" --cleared "${api_line}"
secret 'secret line beside a cleared one' "${api_line}
pass$(printf 'wo')rd: other" --cleared "${api_line}"
expect 2 'blank line in the cleared file' "${api_line}" --cleared "${api_line}

"
expect 1 'cleared identifying line still blocks' "${home_root}/someone/code" \
  --cleared "${home_root}/someone/code"

# Identifying text blocks.
expect 1 'home path' "${home_root}/someone/code"
expect 1 'account name as path' "/${me}/code"
expect 1 'file URL to a home path' "file://${home_root}/someone/x"
expect 1 'private var folders' '/private/var/folders/ab/T/x'
expect 1 'Bonjour hostname' 'Someones-MacBook-Pro.local'
expect 1 'local host with port' 'http://devbox.local:3000'
expect 1 'local host in prose' 'ssh to devbox.local now'
expect 1 'local host whose last label before .local is env' 'a build.env.local host'
expect 1 'local host beside a dotenv local file' 'load .env.local and ssh to devbox.local'
expect 1 'machine name as a dotenv environment' 'copy .env.devbox.local over'
expect 1 'unlisted dotenv environment' 'load .env.qa.local first'
expect 1 'corp host after a dotenv local file' 'see .env.local.corp'
expect 1 'address after a dotenv local file' '.env.local@acme-private.com'
expect 1 'local host named zone' 'ssh to zone.local now'
expect 1 'local host whose name ends in time.zone' 'a mytime.zone.local host'
expect 1 'unlisted placeholder' "${home_root}/<${me}>/x"
expect 1 'real path beside a placeholder' "${home_root}/<name>/x and ${home_root}/someone/y"
expect 1 'private IP' 'thing at 192.168.1.4 here'
expect 1 'email address' 'someone@company.io'
expect 1 'home path in narrow mode' "${home_root}/someone/code" --narrow
secret 'secret in narrow mode' "\"$(printf 'TO')KEN\": \"abc123\"" --narrow
expect 1 'Linux home path' '/home/someone/code'
expect 1 'private tmp path' '/private/tmp/x'
expect 1 'mounted volume path' '/Volumes/Data/x'
expect 1 'root home path' '/root/x'
expect 1 'WSL path' '\\wsl$\Ubuntu\x'
expect 1 'LAN host' 'ssh to nas.lan now'
expect 1 'ten-dot address' 'thing at 10.0.0.5 here'
expect 1 'one-seventy-two address' 'thing at 172.16.4.2 here'
expect 1 'account name before an @' "${me}@devbox"
expect 0 'private IP in narrow mode' 'thing at 192.168.1.4 here' --narrow

# Ordinary text passes.
expect 0 'Rails users path' 'app/views/users/index'
expect 0 'this repository home dir' 'dotfiles/home/.zshrc'
# shellcheck disable=SC2088 # the tilde is the text under test, not a path to expand
expect 0 'XDG local dir' '~/.local/share'
expect 0 'local settings file' 'settings.local.json'
expect 0 'dotenv local file for one environment' 'load .env.test.local first'
expect 0 'dotenv local file with no environment' 'see .env.local'
expect 0 'dotenv local file at the start of a line' '.env.local is loaded last'
# shellcheck disable=SC2016 # the backticks are the text under test
expect 0 'backticked dotenv local file' 'see `.env.test.local`'
expect 0 'dotenv local file in a path' 'copy config/.env.development.local'
expect 0 'dotenv local file ending a sentence' 'see .env.local.'
expect 0 'dotenv local file before a colon' 'edit .env.local: add X'
expect 0 'uppercase dotenv local file' 'LOAD .ENV.TEST.LOCAL FIRST'
expect 0 'dotenv local file in narrow mode' 'load .env.test.local first' --narrow
expect 0 'Rails duration' 'expire in 10.years'
expect 0 'Rails time zone call' 'use Time.zone.local(2026, 1, 1)'
expect 0 'Rails time zone call in narrow mode' 'call Time.zone.local' --narrow
expect 0 'home variable' "\$$(printf 'HO')ME/.zshrc"
expect 0 'Homebrew prefix variable' "\$$(printf 'HO')MEBREW_PREFIX/bin"
expect 0 'SSH remote' 'git@github.com:owner/repo.git'
expect 0 'example address' 'you@example.com'
expect 0 'summary row with a key word in a description' "| F3 | 🟠 High | Security | Token handling is unclear | ✅ |"
expect 0 'table header row' "| Finding | Type | Category | Description | Status |"
expect 0 'listed placeholder' "${home_root}/<name>/x"
expect 0 'version number' 'version 10.2'
expect 0 'word containing sk-' 'task-management-improvements-for-everyone'
expect 0 'author label' 'the author: someone'
expect 0 'npm registry URL with a port' 'https://registry.npmjs.org:443/@scope/pkg'
expect 0 'Rails foreign key option' 'foreign_key: :user_id'
expect 0 'Redis URL with no password' 'redis://localhost:6379/1'
expect 0 'review table row naming a credential' '| F4 | High | Security | Rotate the OAuth token | open |'
expect 0 'prose about a pepper grinder' 'a pepper grinder'
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
bash "${scrub}" "${dir}/same" "${dir}/no-such-cleared-file" >/dev/null 2>&1
[ $? -eq 2 ] || {
  echo 'FAIL: unreadable cleared file should exit 2'
  failed=1
}

[ "${failed}" -eq 0 ] && echo "test-scrub: all ${n} cases passed"
exit "${failed}"
