#!/usr/bin/env bash
#
# Asserts which Bash commands the deny-terraform-secret-reads hook denies. Run it after any change
# to the hook:
#
#   bash test/test-deny-terraform-secret-reads.sh
#
# Every case runs against a private directory whose infra/ holds empty secret files, so no real
# Terraform file is ever read. repo/ is a git repository that ignores its secret file, and skipped/
# holds one only under node_modules.

# The commands hold literal shell syntax, which must not expand
# shellcheck disable=SC2016

hook="$(cd "$(dirname "$0")/.." && pwd)/home/.claude/hooks/deny-terraform-secret-reads.py"
command -v jq >/dev/null || { echo "jq is required" >&2; exit 2; }
dir=$(mktemp -d) || exit 2
trap 'rm -rf "${dir}"' EXIT
mkdir -p "${dir}/infra" "${dir}/app/models" "${dir}/repo/infra" \
  "${dir}/skipped/node_modules/module" || exit 2
: >"${dir}/infra/prod.tfvars"
: >"${dir}/infra/terraform.tfstate"
: >"${dir}/infra/main.tf"
: >"${dir}/app/models/user.rb"
: >"${dir}/repo/infra/prod.tfvars"
: >"${dir}/skipped/node_modules/module/example.tfvars"
git -C "${dir}/repo" init -q || exit 2
echo '*.tfvars' >"${dir}/repo/.gitignore"

failed=0
n=0

# run <cwd> <command>: prints the hook's decision, "deny" or "allow"
run() {
  local output
  output=$(jq -n --arg cwd "$1" --arg command "$2" '{cwd: $cwd, tool_input: {command: $command}}' |
    "${hook}") || { echo "error"; return; }
  if [ -z "${output}" ]; then
    echo "allow"
  else
    jq -r '.hookSpecificOutput.permissionDecision' <<<"${output}"
  fi
}

# expect <decision> <cwd> <command>
expect() {
  local actual
  n=$((n + 1))
  actual=$(run "$2" "$3")
  if [ "${actual}" != "$1" ]; then
    echo "FAIL: ${3}"
    echo "  cwd:      ${2}"
    echo "  expected: ${1}"
    echo "  actual:   ${actual}"
    failed=1
  fi
}

infra="${dir}/infra"
repo="${dir}/repo"

# A command that names a secret file, or a glob or variable that reaches one
expect deny "${infra}" "python3 -c \"print(open('prod.tfvars').read())\""
expect deny "${infra}" "node -e \"require('fs').readFileSync('terraform.tfstate')\""
expect deny "${infra}" 'awk 1 prod.tfvars.json'
expect deny "${infra}" 'cp terraform.tfstate.backup /tmp/x'
expect deny "${infra}" 'cat terraform.tfstate.1700000000.backup'
expect deny "${infra}" 'echo start && FOO=1 env BAR=2 ruby -e "puts File.read(%q(prod.tfvars))"'
expect deny "${infra}" 'jq . ~/.terraform.d/credentials.tfrc.json'
expect deny "${infra}" "python3 -c \"open('/home/x/.terraformrc')\""
expect deny "${dir}" 'cat infra/*'
expect deny "${dir}" 'grep -n key infra/*'
expect deny "${dir}" 'f=infra/prod.tfvars; python3 x.py "$f"'
expect deny "${infra}" 'cat "prod.tfvars'
expect deny "${infra}" 'git show HEAD:prod.tfvars'
expect deny "${infra}" 'git diff --no-index /dev/null prod.tfvars'
expect deny "${dir}" "find infra -name '*.tfvars' -exec cat {} +"

# Commands that print only names or their own arguments
expect allow "${infra}" 'ls *.tfvars'
expect allow "${infra}" '[ -f prod.tfvars ] && test -f prod.tfvars && stat prod.tfvars'
expect allow "${infra}" 'wc -l prod.tfvars'
expect allow "${infra}" 'cat terraform.tfvars.example'
expect allow "${infra}" 'git check-ignore -v prod.tfvars'
expect allow "${infra}" "git -C . ls-files '*.tfvars'"
expect allow "${dir}" "echo '*.tfvars' >> .gitignore"
expect allow "${dir}" "grep -n '\\.tfvars' .gitignore"
expect allow "${dir}" "find infra -name '*.tfvars'"
expect allow "${dir}" 'echo "unterminated'

# Heredocs and comments: a body counts only when a shell or interpreter runs it
expect deny "${infra}" $'python3 - <<\'EOF\'\nprint(open("prod.tfvars").read())\nEOF'
expect deny "${infra}" $'python3 - <<\'EOF\' | head -50\nprint(open("prod.tfvars").read())\nEOF'
expect deny "${infra}" $'python3 - <<\'EOF\' && echo done\nprint(open("prod.tfvars").read())\nEOF'
expect deny "${infra}" $'python3 - <<-EOF\n\tprint(open("prod.tfvars").read())\n\tEOF'
expect deny "${infra}" $'ruby <<\'EOF\'\nputs File.read("prod.tfvars")\nEOF'
expect deny "${infra}" $'bash <<\'EOF\'\ngrep -rn key .\nEOF'
expect deny "${infra}" "bash -c 'cat prod.tfvars'"
expect deny "${infra}" "zsh -c 'cat prod.tfvars'"
expect allow "${infra}" $'bash <<\'EOF\'\nls *.tfvars\nEOF'
expect allow "${dir}" $'git commit -F - <<\'EOF\'\nDeny reads of *.tfvars files\nEOF'
expect allow "${dir}" $'msg=$(mktemp)\ncat > "$msg" <<\'MSG\'\nDeny *.tfvars reads\nMSG\ngit commit -F "$msg"'
expect allow "${dir}" $'gh pr create --title T --body "$(cat <<\'EOF\'\nDeny "*.tfvars" reads\nEOF\n)"'
expect allow "${dir}" $'# Read the prod.tfvars layout from the docs\nls infra'

# Terraform subcommands
expect deny "${infra}" 'terraform fmt -diff'
expect deny "${dir}" 'terraform -chdir=infra fmt -check -diff -recursive'
expect deny "${infra}" 'terraform fmt -diff prod.tfvars'
expect deny "${dir}" 'terraform -chdir=infra show'
expect deny "${dir}" 'terraform -chdir=infra state pull'
expect deny "${infra}" 'terraform output -json'
expect allow "${infra}" 'terraform fmt -diff main.tf'
expect allow "${infra}" 'terraform fmt -check'
expect allow "${infra}" 'terraform plan -var-file=prod.tfvars'
expect allow "${infra}" 'terraform state list'

# Recursive searches whose directories hold a secret file they would read
expect deny "${infra}" 'grep -r password .'
expect deny "${infra}" 'grep -rn password'
expect deny "${infra}" 'grep -rnA3 password .'
expect deny "${infra}" 'egrep -r password .'
expect deny "${dir}" 'grep --recursive password infra'
expect deny "${dir}" 'grep -r -e key infra'
expect deny "${dir}" 'env FOO=1 grep -R key infra'
expect deny "${dir}" 'timeout 5 grep -r key infra'
expect deny "${dir}" $'grep -r \\\nkey infra'
expect deny "${dir}" 'cd infra && rg secret'
expect deny "${dir}" 'pushd infra && grep -r key .'
HOME="${infra}" expect deny "${dir}" 'cd && grep -r key .'
expect deny "${dir}" 'rg secret'
expect deny "${infra}" 'ag secret'
expect deny "${infra}" 'ack secret'
expect deny "${repo}" 'rg -u key'
expect deny "${dir}" "bash -lc 'grep -rn key infra'"
expect allow "${dir}" 'grep -rn key app/models'
expect allow "${dir}" 'grep -r -e key app'
expect allow "${dir}" "rg -g '*.rb' key app"
expect allow "${dir}" 'cd app && grep -r key .'
expect allow "${dir}/app" 'cd - && grep -rn key .'
expect allow "${dir}" 'grep -n key app/models/user.rb'
expect allow "${dir}" 'grep -r key app/models/user.rb'
expect allow "${dir}" "grep -rn --include='*.rb' key ."
expect allow "${dir}" 'grep -r key skipped'
expect allow "${dir}" 'git grep -n key'
expect allow "${repo}" 'rg --files'
expect allow "${repo}" 'rg -t ruby key'

# Input the hook cannot use fails open
n=$((n + 1))
if [ -n "$(echo 'not json' | "${hook}")" ]; then
  echo "FAIL: invalid JSON produced output"
  failed=1
fi

if [ "${failed}" -eq 0 ]; then
  echo "test-deny-terraform-secret-reads: ${n} cases passed"
fi
exit "${failed}"
