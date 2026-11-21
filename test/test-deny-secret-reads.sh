#!/usr/bin/env bash
#
# Asserts which Bash commands the deny-secret-reads hook denies. Run it after any change to the
# hook:
#
#   bash test/test-deny-secret-reads.sh
#
# Every case runs against a private directory whose infra/ holds empty secret files, so no real
# Terraform file is ever read. repo/ is a git repository that ignores its secret file, and skipped/
# holds one only under node_modules. app/dump.rb is a script whose code reads Rails credentials, and
# no command here runs it.

# The commands hold literal shell syntax, which must not expand
# shellcheck disable=SC2016

hook="$(cd "$(dirname "$0")/.." && pwd)/home/.claude/hooks/deny-secret-reads.py"
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
echo 'puts Rails.application.credentials.config' >"${dir}/app/dump.rb"

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
expect deny "${dir}" 'terraform -chdir=infra console'
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

# Ruby that reads Rails credentials, however the command runs it
expect deny "${dir}" "bin/rails runner 'puts Rails.application.credentials.config'"
expect deny "${dir}" 'bundle exec rails r "p Rails.application.credentials.aws"'
expect deny "${dir}" "bin/rails runner -e production 'pp Rails.application.credentials.to_h'"
expect deny "${dir}" "bin/spring rails runner 'p Rails.application.secret_key_base'"
expect deny "${dir}" "ruby -e 'puts ActiveSupport::EncryptedFile.new(**opts).read'"
expect deny "${dir}" "ruby -e 'puts File.read(%q(config/master.key))'"
expect deny "${dir}" "ruby -e 'puts File.read(%q(config/credentials/production.key))'"
expect deny "${dir}" "echo 'puts Rails.application.credentials.config' | bin/rails c"
expect deny "${dir}" $'bin/rails runner - <<\'EOF\'\nputs Rails.application.credentials.config\nEOF'
expect deny "${dir}" $'bin/rails console <<\'EOF\'\nRails.application.encrypted("x.enc").read\nEOF'
expect deny "${dir}" "bash -c \"bin/rails runner 'p Rails.application.credentials.config'\""
expect deny "${dir}" "ssh app1 'bin/rails runner \"p Rails.application.credentials\"'"
expect deny "${dir}" $'irb <<\'EOF\'\np Rails.application.credentials\nEOF'
expect deny "${dir}" "jruby -e 'p Rails.application.credentials'"
expect deny "${dir}" 'bin/rails runner "p Rails.application.credentials'

# Code sent to another host or a container, in arguments, on stdin or by heredoc
expect deny "${dir}" "ssh app1 'bin/rails runner \"p Rails.application.credentials\"'"
expect deny "${dir}" $'ssh app1 bin/rails c <<\'EOF\'\np Rails.application.credentials\nEOF'
expect deny "${dir}" "echo 'p Rails.application.credentials' | ssh app1 'bin/rails c'"
expect deny "${dir}" $'kubectl exec -i web -- bin/rails r - <<\'EOF\'\np Rails.application.credentials\nEOF'
expect deny "${dir}" "docker exec web bin/rails runner 'p Rails.application.credentials'"
expect deny "${dir}" "docker-compose exec web bin/rails runner 'p Rails.application.credentials'"
expect deny "${dir}" "podman exec web ruby -e 'p Rails.application.credentials'"
expect deny "${dir}" $'bash -lc \'bin/rails runner -\' <<\'EOF\'\np Rails.application.credentials\nEOF'
expect deny "${dir}" "echo 'p Rails.application.credentials' | bash -c 'bin/rails c'"

# A file holding such code, however the command hands it to Ruby
expect deny "${dir}" 'bin/rails runner app/dump.rb'
expect deny "${dir}" 'ruby app/dump.rb'
expect deny "${dir}" 'cd app && bin/rails runner dump.rb'
expect deny "${dir}" 'bin/rails c < app/dump.rb'
expect deny "${dir}" 'cat app/dump.rb | bin/rails c'
expect deny "${dir}" 'bin/rails runner "$(cat app/dump.rb)"'
expect deny "${dir}" 'ruby -r./app/dump.rb -e 1'

# A command that reads a key file, whatever runs it
expect deny "${dir}" 'base64 config/master.key'
expect deny "${dir}" 'xxd config/credentials/production.key'
expect deny "${dir}" "python3 -c \"print(open('config/master.key').read())\""

# Accepted false positive: unrelated Ruby in a command that mentions the API
expect deny "${dir}" "grep -rn 'Rails.application.credentials' app && bin/rails runner 'puts 1'"

# Mentions that run no Ruby, and Ruby that reads no credentials
expect allow "${dir}" "grep -rn 'Rails.application.credentials' app"
expect allow "${dir}" "git log -S 'Rails.application.credentials' --oneline"
expect allow "${dir}" 'git commit -m "Read Rails.application.credentials lazily"'
expect allow "${dir}" $'cat > app/token.rb <<\'EOF\'\nT = Rails.application.credentials.token\nEOF'
expect allow "${dir}" "bin/rails runner 'puts User.count'"
expect allow "${dir}" "ruby -e 'puts 1'"
expect allow "${dir}" 'ruby app/models/user.rb'
expect allow "${dir}" 'bin/rails credentials:help'
expect allow "${dir}" 'bin/rails runner app/missing.rb'
expect allow "${dir}" $'# Check Rails.application.credentials use\nbin/rails runner \'puts User.count\''
expect allow "${dir}" "docker exec web bin/rails runner 'puts User.count'"
expect allow "${dir}" 'ls config/*.key'
expect allow "${dir}" 'git check-ignore -v config/master.key'
expect allow "${dir}" "echo '/config/master.key' >> .gitignore"
expect allow "${dir}" 'grep -n master.key .gitignore'

# Input the hook cannot use fails open
n=$((n + 1))
if [ -n "$(echo 'not json' | "${hook}")" ]; then
  echo "FAIL: invalid JSON produced output"
  failed=1
fi

if [ "${failed}" -eq 0 ]; then
  echo "test-deny-secret-reads: ${n} cases passed"
fi
exit "${failed}"
