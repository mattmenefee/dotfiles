#!/usr/bin/env bash
#
# Exercises the /rebase scripts against throwaway repositories: a bare origin, a clone that runs the
# scripts and a colleague's clone that pushes behind its back. Run it after any change to them:
#
#   bash home/.claude/skills/rebase/scripts/test-rebase.sh
#
# A fake gh on PATH answers from JSON fixtures under $FAKE_GH and runs each call's --jq filter
# through jq, as gh does, so the scripts' filters are exercised too; it logs every call to
# calls.log. Conflicts are made at runtime, so no conflict marker sits in this file for CI's marker
# check to flag.

set -uo pipefail

scripts="$(cd "$(dirname "$0")" && pwd)"
dir=$(mktemp -d) || exit 2
trap 'rm -rf "${dir}"' EXIT

# Inherited git variables, as a hook exports, would point every command below at another repository
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY \
  GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_NAMESPACE
# Keep the user's git configuration (autosquash, rerere, editor, prune) out of the fixtures
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_EDITOR=true
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.com
export REBASE_WAIT_INTERVAL=0
real_git=$(command -v git)
mkdir -p "${dir}/bin"
export PATH="${dir}/bin:${PATH}"

cat >"${dir}/bin/gh" <<'FAKE'
#!/usr/bin/env bash
# Answers only the gh calls the /rebase scripts make, from JSON fixtures named after the request
f=$FAKE_GH
printf '%s\n' "$*" >>"$f/calls.log"
[[ -e $f/offline ]] && { echo "error connecting to api.github.com" >&2; exit 1; }
filter=. state='' key='' author=''
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case ${args[i]} in
    --jq) filter=${args[i + 1]} ;;
    --state) state=${args[i + 1]} ;;
    --head | --base) key="${args[i]#--}-${args[i + 1]}" ;;
    --author) author=${args[i + 1]} ;;
  esac
done
if [[ "$1 $2" == 'pr list' && (-e $f/fail-list-$state || -e $f/fail-list-$state-${key%%-*}) ]]; then
  echo "HTTP 401: Bad credentials" >&2
  exit 1
fi
case "$1 $2" in
  "repo view") jq -r "$filter" "$f/repo.json" ;;
  "pr view")
    count=$(($(cat "$f/count-$3" 2>/dev/null || echo 0) + 1))
    echo "$count" >"$f/count-$3"
    if [[ -e $f/pr-$3.failall || -e $f/pr-$3.fail.$count ]]; then
      echo "HTTP 401: Bad credentials" >&2
      exit 1
    fi
    file=$f/pr-$3.json.$count
    [[ -e $file ]] || file=$f/pr-$3.json
    [[ -e $file ]] || { echo "no pull requests found" >&2; exit 1; }
    jq -r "$filter" "$file"
    ;;
  "pr list")
    file=$f/list-$state-$key.json
    [[ -e $file ]] || file=/dev/null
    rows=$(jq -s 'add // []' "$file")
    [[ $author == @me ]] && rows=$(jq '[.[] | select(.author.login == "me")]' <<<"$rows")
    jq -r "$filter" <<<"$rows"
    ;;
  *) exit 1 ;;
esac
FAKE
chmod +x "${dir}/bin/gh"

failed=0

# check <description> <expected> <actual>
check() {
  if [[ $2 != "$3" ]]; then
    echo "FAIL: $1 (expected '$2', got '$3')"
    failed=1
  fi
}

# run <expected exit> <description> <command...>: leaves stdout in $out and stderr in $err
run() {
  local want=$1 what=$2
  shift 2
  out=$("$@" 2>"${dir}/stderr")
  local rc=$?
  err=$(cat "${dir}/stderr")
  if [[ $rc != "$want" ]]; then
    echo "FAIL: $what (exited $rc, expected $want) ${err}"
    failed=1
  fi
}

# kv <key> [<output>]: a key's value from script output, $out by default
kv() { sed -n "s/^$1=//p" <<<"${2-${out}}" | head -n 1; }

# contains <description> <needle> <haystack>
contains() {
  if [[ $3 != *"$2"* ]]; then
    echo "FAIL: $1 (no '$2' in '$3')"
    failed=1
  fi
}

# fixtures <name> [<default branch>]: a fresh fake-gh directory, so no fixture leaks between cases
fixtures() {
  export FAKE_GH="${dir}/gh-$1"
  mkdir -p "${FAKE_GH}"
  printf '{"defaultBranchRef": {"name": "%s"}}\n' "${2-main}" >"${FAKE_GH}/repo.json"
}

# commit <file> <content> <message>, in the current directory
commit() { printf '%b\n' "$2" >"$1" && git add -- "$1" && git commit --quiet -m "$3"; }

# them <command...>: run in the colleague's clone
them() { (cd "${dir}/them" && "$@"); }

# init_origin <bare path> <clone path> <default branch>: an origin with one commit, cloned
init_origin() {
  git init --quiet --bare -b "$3" "$1"
  git clone --quiet "$1" "$2" 2>/dev/null
  (cd "$2" && git symbolic-ref HEAD "refs/heads/$3" && commit base.txt base 'Add base' \
    && git push --quiet origin "$3" && git remote set-head origin "$3")
}

skill="${scripts}/../SKILL.md"
check 'SKILL.md exists' yes "$([[ -f ${skill} ]] && echo yes)"
# Claude Code would substitute an argument for each dollar sign followed by a digit
check 'SKILL.md: no dollar-digit placeholders' '' "$(grep -nE '\$[0-9]' "${skill}")"
# Only an agent reads these rules, so no script failure would show that one was lost
contains 'SKILL.md: stops on an unconfirmed base' "- \`github=failed\`, unless" "$(cat "${skill}")"
contains 'SKILL.md: resume keeps that stop' "Apply
step 3's \`github=failed\` stop" "$(cat "${skill}")"
# Only an agent reads the rows, so no script failure would show that one was lost or moved. The
# first row that fits wins, so every stop row must stay ahead of every file-type row.
stop_rows=('A path holding' 'Both sides changed the path' 'One side deleted the file'
  'Both sides renamed the file' 'Any other')
type_rows=('Lock files' 'Generated schema dumps' 'Stylesheets' 'Hunks that change'
  'Everything else')
first_type=$(for row in "${type_rows[@]}"; do grep -n "^| ${row}" "${skill}" | cut -d: -f1; done \
  | sort -n | head -n 1)
for row in "${stop_rows[@]}"; do
  line=$(grep "^| ${row}" "${skill}")
  contains "SKILL.md: '${row}' always stops" '| Always stop' "${line}"
  contains "SKILL.md: '${row}' asks" 'ask' "${line##*| Always stop}"
  contains "SKILL.md: '${row}' records the answer" "Record the answer as the user's" "${line}"
  row_at=$(grep -n "^| ${row}" "${skill}" | cut -d: -f1)
  check "SKILL.md: '${row}' comes before the file-type rows" yes \
    "$([[ -n ${row_at} && ${row_at} -lt ${first_type} ]] && echo yes)"
done
# Step 6 stages through the script, whose exits the tests below pin
check 'SKILL.md: no step stages a resolved path directly' '' \
  "$(grep -nE 'git add -- |^! grep' "${skill}")"
check 'SKILL.md: no step moves a file with mv' '' \
  "$(grep -nE '(^|[^a-z-])mv -- ' "${skill}" | grep -v 'git mv -- ')"
check 'SKILL.md: a path given to git rm or checkout is literal' '' \
  "$(grep -nE "git (rm|checkout --ours|checkout --theirs) -- '<" "${skill}" \
    | grep -v 'GIT_LITERAL_PATHSPECS=1 git')"
for needed in "scripts/stage-resolved.sh' -- '<path>'" "scripts/keep-name.sh' '<kept name>'" \
  "scripts/move-file.sh' '<path>' '<new path>'" "git ls-files -- '<rejected directory>/'" \
  "git rev-parse --verify -q ':2:<added_by_us>'" '- Exit 0:' '- Exit 1:' '- Exit 2:' '- Exit 3:' \
  '--side-chosen=base' '--side-chosen=branch' '--hits-read' 'keep both new names' \
  'keep the old name' "and ask which to keep. Take that side with" \
  "'<new path>' \\" "scripts/stage-resolved.sh' -- '<new path>'" \
  "git cat-file -e HEAD:'<added_by_us>' && git show HEAD:'<added_by_us>' >'<kept name>'"; do
  contains "SKILL.md: names ${needed}" "${needed}" "$(cat "${skill}")"
done

echo '== state.sh'
init_origin "${dir}/state.git" "${dir}/state" main
cd "${dir}/state" || exit 2
commit 'sp ace é.txt' one 'Add a spaced file'
git switch --quiet -c side && commit 'sp ace é.txt' side 'Change it on side'
git switch --quiet main
commit 'sp ace é.txt' main 'Change it on main'
run 0 'state: clean' "${scripts}/state.sh"
check 'state: op' none "$(kv op)"
check 'state: branch' main "$(kv branch)"
check 'state: dirty_tracked' 0 "$(kv dirty_tracked)"
touch untracked.txt
run 0 'state: untracked only' "${scripts}/state.sh"
check 'state: untracked files do not count' 0 "$(kv dirty_tracked)"
echo changed >base.txt
run 0 'state: tracked edit' "${scripts}/state.sh"
check 'state: a tracked edit counts' 1 "$(kv dirty_tracked)"
git checkout --quiet -- base.txt && rm untracked.txt
git switch --quiet --detach
run 0 'state: detached' "${scripts}/state.sh"
check 'state: detached HEAD has no branch' '' "$(kv branch)"
git switch --quiet main
git merge --quiet side >/dev/null 2>&1
run 0 'state: merge' "${scripts}/state.sh"
check 'state: merge op' merge "$(kv op)"
check 'state: conflict path unquoted' 'sp ace é.txt' "$(kv conflict)"
git merge --abort
git cherry-pick side >/dev/null 2>&1
run 0 'state: cherry-pick' "${scripts}/state.sh"
check 'state: cherry-pick op' cherry-pick "$(kv op)"
git cherry-pick --abort
git switch --quiet side && git rebase --apply main >/dev/null 2>&1
run 0 'state: apply rebase' "${scripts}/state.sh"
check 'state: rebase-apply op' rebase-apply "$(kv op)"
check 'state: rebase-apply branch' side "$(kv branch)"
git rebase --abort && git switch --quiet main
git format-patch --quiet -1 side -o "${dir}/patches"
git am "${dir}"/patches/*.patch >/dev/null 2>&1
run 0 'state: am' "${scripts}/state.sh"
check 'state: am op' am "$(kv op)"
git am --abort
git bisect start >/dev/null 2>&1
run 0 'state: bisect' "${scripts}/state.sh"
check 'state: bisect op' bisect "$(kv op)"
git bisect reset >/dev/null 2>&1

echo '== modify/delete conflicts'
git switch --quiet main
commit 'yarn lock' lock 'Add a lock file'
git switch --quiet -c base-deletes
git rm --quiet -- 'yarn lock' && git commit --quiet -m 'Drop it'
git switch --quiet -c base-changes main && commit 'yarn lock' base 'Change it on the base'
git switch --quiet -c keeps main && commit 'yarn lock' branch 'Change it on the branch'
git switch --quiet -c drops main && git rm --quiet -- 'yarn lock' && git commit --quiet -m 'Drop it'
git switch --quiet keeps && git rebase base-deletes >/dev/null 2>&1
run 0 'modify/delete: base deleted' "${scripts}/state.sh"
check 'modify/delete: deleted by us' 'yarn lock' "$(kv deleted_by_us)"
check 'modify/delete: not deleted by them' '' "$(kv deleted_by_them)"
check 'modify/delete: still a conflict' 'yarn lock' "$(kv conflict)"
git rebase --abort
git switch --quiet drops && git rebase base-changes >/dev/null 2>&1
run 0 'modify/delete: branch deleted' "${scripts}/state.sh"
check 'modify/delete: deleted by them' 'yarn lock' "$(kv deleted_by_them)"
check 'modify/delete: not deleted by us' '' "$(kv deleted_by_us)"
git rm --quiet -- 'yarn lock' && git rebase --continue >/dev/null 2>&1
check 'modify/delete: git rm finishes the rebase' none "$(kv op "$("${scripts}/state.sh")")"
check 'modify/delete: the file stays deleted' no "$([[ -e 'yarn lock' ]] && echo yes || echo no)"
git switch --quiet keeps && git rebase base-deletes >/dev/null 2>&1
check 'modify/delete: keeping a side stages' 0 \
  "$("${scripts}/stage-resolved.sh" --side-chosen=branch -- 'yarn lock' >/dev/null 2>&1; echo $?)"
git rebase --continue >/dev/null 2>&1
check 'modify/delete: staging finishes the rebase' none "$(kv op "$("${scripts}/state.sh")")"
check "modify/delete: git add keeps the branch's version" branch "$(cat 'yarn lock')"
git switch --quiet -c lock-only main
commit 'yarn lock' branch 'Change only the lock file'
git rebase base-deletes >/dev/null 2>&1
git rm --quiet -- 'yarn lock' && git rebase --continue >/dev/null 2>&1
check 'modify/delete: an emptied commit drops silently' none "$(kv op "$("${scripts}/state.sh")")"
check 'modify/delete: step 7 sees no commits left' 0 "$(git rev-list --count base-deletes..HEAD)"
git switch --quiet main

# run_of <character> <count>: a run built at runtime, so no conflict marker sits in this file
run_of() { printf "%${2}s" '' | tr ' ' "$1"; }
stage() { "${scripts}/stage-resolved.sh" "$@" >/dev/null 2>&1; echo $?; }
# staged <path>: the index holds the path with no conflict left
staged() {
  [[ -n $(git ls-files -- "$1") && -z $(git ls-files -u -- "$1") ]] && echo yes || echo no
}

echo '== stage-resolved.sh'
git init --quiet -b main "${dir}/gate"
cd "${dir}/gate" || exit 2
commit tracked one 'Add a tracked file'
rm tracked
check 'gate: a missing file is refused' 2 "$(stage -- tracked)"
check 'gate: a missing file is not staged as a deletion' ' D tracked' "$(git status --porcelain)"
git checkout --quiet -- tracked
mkdir sub && touch sub/file
check 'gate: a directory is refused' 2 "$(stage -- sub)"
printf 'clean\n' >./-x
check 'gate: an unknown flag is refused' 2 "$(stage -x)"
check 'gate: a name without -- is not staged' '' "$(git ls-files -- -x)"
rm -f -- ./-x
if ((EUID != 0)); then
  printf 'clean\n' >unreadable && chmod 000 unreadable
  check 'gate: an unreadable file is refused' 2 "$(stage -- unreadable)"
  rm -f unreadable
fi
printf 'clean\n' >./-dash
check 'gate: a name like a flag is a name' 0 "$(stage -- -dash)"
printf '%s x\n' "$(run_of '<' 7)" >./-dash
check 'gate: markers in a name like a flag' 1 "$(stage -- -dash)"
git reset --quiet -- -dash && rm -rf -- -dash sub
for spec in '<:7' '<:8' '=:7' '=:8' '>:7' '>:8' '|:7' '|:8'; do
  printf 'text\n%s x\n' "$(run_of "${spec%%:*}" "${spec##*:}")" >probe
  check "gate: sees the marker ${spec}" 1 "$(stage -- probe)"
done
check 'gate: a read hit can be staged' 0 "$(stage --hits-read -- probe)"
git reset --quiet -- probe
printf '\377\n%s x\n' "$(run_of '<' 7)" >probe
check 'gate: sees a marker after invalid UTF-8' 1 "$(stage -- probe)"
printf 'clean\n' >'[id].txt' && printf 'clean\n' >i.txt
check 'gate: a glob name is staged' 0 "$(stage -- '[id].txt')"
check 'gate: a glob name stages nothing else' '' "$(git ls-files -- i.txt)"
git reset --quiet && rm -f -- '[id].txt' i.txt
mkdir -p nested && printf 'clean\n' >nested/file
check 'gate: a subdirectory is refused' 2 "$(cd nested && stage -- file)"
check 'gate: nothing is staged from a subdirectory' '' "$(git ls-files -- nested/file)"
rm -rf nested
printf 'clean\n' >locked && touch "$(git rev-parse --git-path index.lock)"
check 'gate: a failed git add is refused' 2 "$(stage -- locked)"
rm -f "$(git rev-parse --git-path index.lock)" locked
printf 'probe working-tree-encoding=UTF-16\n' >"$(git rev-parse --git-path info/attributes)"
printf '%s x\n' "$(run_of '<' 7)" | iconv -f UTF-8 -t UTF-16 >probe
check 'gate: sees markers through an encoding' 1 "$(stage -- probe)"
check 'gate: markers through an encoding stage nothing' '' "$(git ls-files -- probe)"
: >"$(git rev-parse --git-path info/attributes)"
git reset --quiet -- probe 2>/dev/null
git reset --quiet -- probe
printf '%s\n' "$(run_of '<' 6) x" >probe
check 'gate: a shorter run is not a marker' 0 "$(stage -- probe)"
git reset --quiet -- probe
printf '%sx\n' "$(run_of '<' 8)" >probe
check 'gate: a run with text attached is not a marker' 0 "$(stage -- probe)"
git reset --quiet -- probe
printf '%s\r\n' "$(run_of '=' 7)" >probe
check 'gate: sees a marker ending in a carriage return' 1 "$(stage -- probe)"
printf 'probe conflict-marker-size=4\n' >>"$(git rev-parse --git-path info/attributes)"
printf '%s x\n' "$(run_of '<' 4)" >probe
check 'gate: follows a shorter conflict-marker-size' 1 "$(stage -- probe)"
: >"$(git rev-parse --git-path info/attributes)"
rm -f probe

# conflict <path> <writer>: the path conflicts between a base and a branch, each writing its own
# side through "<writer> <path> <side>", and the rebase has stopped on it
conflict() {
  git switch --quiet main
  "$2" "$1" start && git add -- "$1" && git commit --quiet -m "Add $1"
  git switch --quiet -c "base-$1"
  "$2" "$1" BASE && git add -- "$1" && git commit --quiet -m "Change $1 on the base"
  git switch --quiet -c "branch-$1" main
  "$2" "$1" BRANCH && git add -- "$1" && git commit --quiet -m "Change $1 on the branch"
  git rebase "base-$1" >/dev/null 2>&1
}
write_binary() { { printf 'x\0'; seq 1 500; printf '%s\n' "$2"; } >"$1"; }
write_text() { { seq 1 20; printf '%s\n' "$2"; } >"$1"; }
write_link() { rm -f "$1"; ln -s "$2" "$1"; }

conflict blob write_binary
check 'gate: a binary conflict needs a person' 3 "$(stage -- blob)"
check 'gate: a binary conflict is left unmerged' no "$(staged blob)"
check 'gate: another spelling of the path is refused' 2 "$(stage -- ./blob)"
check 'gate: another spelling leaves it unmerged' no "$(staged blob)"
check 'gate: the flag needs a side' 2 "$(stage --side-chosen -- blob)"
check 'gate: the file must hold the side named' 3 "$(stage --side-chosen=branch -- blob)"
check 'gate: a refused side stays unmerged' no "$(staged blob)"
printf 'neither\n' >blob
check 'gate: a binary answer must be one side' 3 "$(stage --side-chosen=branch -- blob)"
git checkout --quiet --theirs -- blob
check "gate: the user's answer is staged" 0 "$(stage --side-chosen=branch -- blob)"
git rebase --continue >/dev/null 2>&1
check "gate: the branch's side was kept" BRANCH "$(tail -n 1 blob)"
conflict link write_link
check 'gate: a symlink conflict needs a person' 3 "$(stage -- link)"
git checkout --quiet --ours -- link
check "gate: the user's answer on a symlink is staged" 0 "$(stage --side-chosen=base -- link)"
git rebase --continue >/dev/null 2>&1
printf 'attr merge=binary\n' >>"$(git rev-parse --git-path info/attributes)"
conflict attr write_text
check 'gate: a merge=binary conflict needs a person' 3 "$(stage -- attr)"
write_text attr regenerated
check 'gate: a regenerated merge=binary file still needs an answer' 3 "$(stage -- attr)"
check 'gate: a regenerated merge=binary file can be chosen' 0 "$(stage --side-chosen=base -- attr)"
git rebase --abort
printf 'unset -merge\n' >"$(git rev-parse --git-path info/attributes)"
conflict unset write_text
write_text unset regenerated
check 'gate: a -merge conflict needs a person' 3 "$(stage -- unset)"
git rebase --abort
: >"$(git rev-parse --git-path info/attributes)"
# Git settles this for one side with no markers: the base has a NUL neither side keeps
write_nul_base() {
  if [[ $2 == start ]]; then { printf 'x\0\n'; seq 1 20; } >"$1"; else write_text "$1" "$2"; fi
}
conflict nulbase write_nul_base
check 'gate: a NUL only in the merge base needs a person' 3 "$(stage -- nulbase)"
write_text nulbase neither
check 'gate: a NUL in the base still needs an answer' 3 "$(stage -- nulbase)"
git rebase --abort
conflict ones write_text
git checkout --quiet --ours -- ones
check 'gate: a result matching one side needs a person' 3 "$(stage -- ones)"
check 'gate: a matching result stays unmerged' no "$(staged ones)"
check 'gate: a matching result cannot name the other side' 3 "$(stage --side-chosen=branch -- ones)"
check 'gate: a chosen side is staged' 0 "$(stage --side-chosen=base -- ones)"
git rebase --abort
git switch --quiet main
mkdir -p tree && commit tree/a one 'Add files in a directory' && commit tree/b one 'Add another'
git switch --quiet -c base-tree
commit tree/a base 'Change it on the base' && commit tree/b base 'Change it on the base'
git switch --quiet -c branch-tree main
commit tree/a branch 'Change it on the branch'
commit tree/b branch 'Change it on the branch'
git rebase base-tree >/dev/null 2>&1
touch tree/untracked
check 'gate: a directory of conflicts is refused' 2 "$(stage -- tree)"
check 'gate: the answer flag does not stage a directory' 2 "$(stage --side-chosen=base -- tree)"
check 'gate: nothing in the directory was staged' no "$(staged tree/a)"
rm -f tree/untracked
git rebase --abort
git switch --quiet main
conflict plain write_text
check 'gate: an ordinary conflict has markers' 1 "$(stage -- plain)"
write_text plain both
check 'gate: an ordinary resolution is staged' 0 "$(stage -- plain)"
git rebase --continue >/dev/null 2>&1
git switch --quiet main

# renames <repository> <old> <base name> <branch name> <base edit> <branch edit>: both sides rename
# the file and append their edit, and the rebase has stopped on it
renames() {
  git init --quiet -b main "${dir}/$1"
  cd "${dir}/$1" || exit 2
  seq 1 200 >"$2" && git add -- "$2" && git commit --quiet -m 'Add a file both sides rename'
  git switch --quiet -c base
  git mv -- "$2" "$3" && { [[ -z $5 ]] || printf '%s\n' "$5" >>"$3"; }
  git add -- "$3" && git commit --quiet -m 'Rename it on the base'
  git switch --quiet -c branch main
  git mv -- "$2" "$4" && { [[ -z $6 ]] || printf '%s\n' "$6" >>"$4"; }
  git add -- "$4" && git commit --quiet -m 'Rename it on the branch'
  git rebase base >/dev/null 2>&1
}
same_stages() {
  [[ $(git rev-parse ":2:$1") == "$(git rev-parse ":3:$2")" ]] && echo yes || echo no
}

echo '== a rename on both sides'
renames both 'old lock' 'base lock' 'branch lock' BASE BRANCH
run 0 'rename both: state' "${scripts}/state.sh"
check 'rename both: still rebasing' rebase-merge "$(kv op)"
check 'rename both: the old name' 'old lock' "$(kv deleted_by_both)"
check "rename both: the base's name" 'base lock' "$(kv added_by_us)"
check "rename both: the branch's name" 'branch lock' "$(kv added_by_them)"
check 'rename both: every name is a conflict' 3 "$(grep -c '^conflict=' <<<"${out}")"
check 'rename both: conflicting edits merge into both names' yes \
  "$(same_stages 'base lock' 'branch lock')"
contains 'rename both: names pair through the commit' 'old lock => branch lock' \
  "$(git show --summary -M --format= REBASE_HEAD)"
contains 'rename both: names pair through the base' 'old lock => base lock' \
  "$(git diff --summary -M main base)"
run 0 'rename both: keep the branch name' "${scripts}/keep-name.sh" 'branch lock' 'old lock' \
  'base lock'
check 'rename both: the other name is gone' no "$([[ -e 'base lock' ]] && echo yes || echo no)"
check 'rename both: the kept name needs an answer' 3 "$(stage -- 'branch lock')"
check 'rename both: markers stop the kept name' 1 "$(stage --side-chosen=branch -- 'branch lock')"
{ seq 1 200; echo both; } >'branch lock'
check 'rename both: the resolved name is staged' 0 "$(stage --side-chosen=branch -- 'branch lock')"
git rebase --continue >/dev/null 2>&1
check 'rename both: the answer finishes the rebase' none "$(kv op "$("${scripts}/state.sh")")"
check 'rename both: the kept name stays' both "$(tail -n 1 'branch lock')"
check 'rename both: the commit survives' 1 "$(git rev-list --count base..HEAD)"

renames only old base-name only-name BASE ''
run 0 'rename only: keep the base name' "${scripts}/keep-name.sh" base-name old only-name
check 'rename only: the base name is staged' 0 "$(stage --side-chosen=base -- base-name)"
git rebase --continue >/dev/null 2>&1
check 'rename only: the commit drops silently' 0 "$(git rev-list --count base..HEAD)"
check "rename only: the base's edit stays" BASE "$(tail -n 1 base-name)"

echo '== a rename on both sides that git cannot merge'
git init --quiet -b main "${dir}/unmergeable"
cd "${dir}/unmergeable" || exit 2
{ printf 'x\0'; seq 1 2000; } >blob && git add -- blob && git commit --quiet -m 'Add a binary file'
git switch --quiet -c base
git mv -- blob blob-base && printf 'BASE\n' >>blob-base
git add -- blob-base && git commit --quiet -m 'Rename it on the base'
git switch --quiet -c branch main
git mv -- blob blob-branch && printf 'BRANCH\n' >>blob-branch
git add -- blob-branch && git commit --quiet -m 'Rename it on the branch'
git rebase base >/dev/null 2>&1
check 'unmergeable: the two sides differ' no "$(same_stages blob-base blob-branch)"
run 0 'unmergeable: keep the branch name' "${scripts}/keep-name.sh" blob-branch blob blob-base
check 'unmergeable: the kept name is staged' 0 "$(stage --side-chosen=branch -- blob-branch)"
git rebase --continue >/dev/null 2>&1
check "unmergeable: the branch's edit stays" BRANCH "$(tail -n 1 blob-branch)"

echo '== a rename on both sides differing only by case'
renames case-base Foo foo FOO BASE BRANCH
run 0 'case: keep the base name' "${scripts}/keep-name.sh" foo Foo FOO
printf 'edited\n' >foo
run 0 'case: a repeat answer is safe' "${scripts}/keep-name.sh" foo Foo FOO
check 'case: a repeat answer keeps an edit' edited "$(cat foo)"
check 'case: the kept file survives' yes "$([[ -e foo ]] && echo yes)"
check 'case: the spelling on disk is the kept one' foo "$(printf '%s\n' [Ff][Oo][Oo])"
write_text foo both
check 'case: the kept name is staged' 0 "$(stage --side-chosen=base -- foo)"
git rebase --continue >/dev/null 2>&1
check 'case: the rebase finishes' none "$(kv op "$("${scripts}/state.sh")")"
check 'case: the commit keeps the file' foo "$(git ls-files)"
renames case-branch Bar bar BAR BASE BRANCH
run 0 'case: keep the branch name' "${scripts}/keep-name.sh" BAR Bar bar
check 'case: the spelling on disk is the branch one' BAR "$(printf '%s\n' [Bb][Aa][Rr])"
check 'case: keeping it still sees the markers' 1 "$(stage --side-chosen=branch -- BAR)"

if [[ $(git -C "${dir}/case-branch" config core.ignorecase) == true ]]; then
  renames case-spelling Baz BAZ other-name '' ''
  check 'case: staging one spelling of a pair is refused' 2 "$(stage --side-chosen=base -- BAZ)"
fi

echo '== a partial answer, seen as a later session would find it'
renames partial old x y BASE BRANCH
git rm --quiet -- old
run 0 'partial: state' "${scripts}/state.sh"
check 'partial: the old name is gone' '' "$(kv deleted_by_both)"
contains 'partial: the rename is still in the commit' 'old => y' \
  "$(git show --summary -M --format= REBASE_HEAD)"
check 'partial: a new name still needs an answer' 3 "$(stage -- x)"
check 'partial: the markers still stop a new name' 1 "$(stage --side-chosen=base -- x)"
run 0 'partial: keep-name tolerates a removed name' "${scripts}/keep-name.sh" y old x
check 'partial: the markers still stop the kept name' 1 "$(stage --side-chosen=branch -- y)"

echo '== keep-name.sh'
renames answers old new-one new-two '' ''
printf 'notes\n' >untracked.txt
run 3 'keep-name: refuses an untracked file' "${scripts}/keep-name.sh" new-two old new-one \
  untracked.txt
check 'keep-name: the refusal keeps the untracked file' notes "$(cat untracked.txt)"
check 'keep-name: the refusal removes no other name' yes \
  "$([[ -e new-one && -n $(git ls-files -u -- old) ]] && echo yes)"
rm -f untracked.txt
run 2 'keep-name: refuses the old name as the kept name' "${scripts}/keep-name.sh" old new-one
run 2 'keep-name: refuses the kept name among the others' "${scripts}/keep-name.sh" new-two old \
  new-two
mkdir -p subdir
run 3 'keep-name: refuses a directory' "${scripts}/keep-name.sh" new-two old subdir
rmdir subdir
check 'keep-name: a subdirectory is refused' 2 \
  "$(mkdir -p inner && cd inner && "${scripts}/keep-name.sh" new-two old >/dev/null 2>&1; echo $?)"
rmdir inner
rm -f new-two
run 0 'keep-name: restores a missing kept name from its one side' "${scripts}/keep-name.sh" \
  new-two old new-one
check 'keep-name: the restored name has its content' 200 "$(tail -n 1 new-two)"
check 'keep-name: keeps the kept name unmerged' no "$(staged new-two)"
renames both-names old left right '' ''
GIT_LITERAL_PATHSPECS=1 git rm --quiet --cached -- old
check 'keep both: the first name is staged' 0 "$(stage --side-chosen=base -- left)"
check 'keep both: a new name cannot name a side without it' 3 "$(stage --side-chosen=base -- right)"
cp right right.saved && printf 'edited\n' >>right
check 'keep both: an edited name still cannot name a side without it' 3 \
  "$(stage --side-chosen=base -- right)"
mv right.saved right
check 'keep both: the second name is staged' 0 "$(stage --side-chosen=branch -- right)"
git rebase --continue >/dev/null 2>&1
check 'keep both: the rebase finishes' none "$(kv op "$("${scripts}/state.sh")")"
check 'keep both: both names stay' 'left right' "$(git ls-files | paste -sd ' ' -)"
renames old-name start kept-side gone-side '' ''
run 0 'keep old: drop one new name' "${scripts}/keep-name.sh" kept-side gone-side
check 'keep old: the move and staging run as one command' 0 \
  "$("${scripts}/move-file.sh" kept-side start >/dev/null 2>&1 \
    && "${scripts}/stage-resolved.sh" -- start >/dev/null 2>&1; echo $?)"
git rebase --continue >/dev/null 2>&1
check 'keep old: the rebase finishes' none "$(kv op "$("${scripts}/state.sh")")"
check 'keep old: only the old name stays' start "$(git ls-files)"

echo '== a name both sides added'
git init --quiet -b main "${dir}/add"
cd "${dir}/add" || exit 2
seq 1 50 >old && git add -- old && git commit --quiet -m 'Add a file both sides rename'
git switch --quiet -c base
git mv -- old kept && commit other 'other\nfile' 'Rename it and add another on the base'
git switch --quiet -c branch main
git mv -- old other && git commit --quiet -m 'Rename it on the branch'
git rebase base >/dev/null 2>&1
run 0 'add: state' "${scripts}/state.sh"
check 'add: the name both sides added' other "$(kv added_by_both)"
run 3 'add: keep-name refuses to remove it' "${scripts}/keep-name.sh" kept old other
check 'add: the refusal changes nothing' yes \
  "$([[ -e other && -n $(git ls-files -u -- old) ]] && echo yes)"
run 0 'add: keep the other names apart' "${scripts}/keep-name.sh" kept old
git show HEAD:other >other
check 'add: the kept name is staged' 0 "$(stage --side-chosen=base -- kept)"
rm -f other
run 2 'add: a missing name both sides added is not restored' "${scripts}/keep-name.sh" other kept
git show HEAD:other >other
check "add: the base's other file needs an answer" 3 "$(stage -- other)"
check "add: the base's other file is staged" 0 "$(stage --side-chosen=base -- other)"
git rebase --continue >/dev/null 2>&1
check 'add: the rebase finishes' none "$(kv op "$("${scripts}/state.sh")")"
check "add: the base's other file survives" other "$(head -n 1 other)"
run 2 'keep-name: a name outside the conflict' "${scripts}/keep-name.sh" kept other
git switch --quiet main
git mv -- old '[n]ame' && git commit --quiet -m 'Rename to a name holding a glob'
printf 'decoy\n' >name && git add -- name
git commit --quiet -m 'Add what the glob would match'
git switch --quiet -c glob-base
git mv -- '[n]ame' base-glob && git commit --quiet -m 'Rename it on the base'
git switch --quiet -c glob-branch main
git mv -- '[n]ame' branch-glob && git commit --quiet -m 'Rename it on the branch'
git rebase glob-base >/dev/null 2>&1
run 0 'keep-name: removes a glob name literally' "${scripts}/keep-name.sh" branch-glob '[n]ame' \
  base-glob
check 'keep-name: the glob matched nothing else' decoy "$(git show :name)"
git rebase --abort
git switch --quiet main
git rm --quiet -- name && git commit --quiet -m 'Remove the decoy'
git switch --quiet main
commit clean clean 'Add a clean file'
conflict plain write_text
run 2 'keep-name: an ordinary conflict is not a kept name' "${scripts}/keep-name.sh" plain clean
check 'keep-name: the refusal removes no clean file' clean "$(cat clean)"
git rebase --abort
git switch --quiet main
seq 1 50 >renamed-file && git add -- renamed-file
git commit --quiet -m 'Add a file both sides rename'
commit gone-file start 'Add a file one side deletes'
git switch --quiet -c other-base
git mv -- renamed-file base-name && git rm --quiet -- gone-file
git commit --quiet -m 'Rename one and delete the other on the base'
git switch --quiet -c other-branch main
git mv -- renamed-file branch-name && commit gone-file edit 'Rename one and edit the other'
git rebase other-base >/dev/null 2>&1
run 3 "keep-name: refuses another conflict's path" "${scripts}/keep-name.sh" branch-name \
  renamed-file base-name gone-file
check "keep-name: the other conflict's edit stays" edit "$(cat gone-file)"
git rebase --abort

echo '== a directory rename'
git init --quiet -b main "${dir}/moved"
cd "${dir}/moved" || exit 2
mkdir moved && commit moved/kept kept 'Add a directory one side renames'
git switch --quiet -c base
git mv -- moved renamed && git commit --quiet -m 'Rename the directory on the base'
for answer in accept back; do
  git switch --quiet -c "branch-${answer}" main
  commit moved/new new 'Add a file on the branch'
  git rebase base >/dev/null 2>&1
  run 0 "directory ${answer}: state" "${scripts}/state.sh"
  check "directory ${answer}: the location" renamed/new "$(kv added_by_them)"
  check "directory ${answer}: no old name" '' "$(kv deleted_by_both)"
  check "directory ${answer}: the location needs an answer" 3 "$(stage -- renamed/new)"
  if [[ ${answer} == back ]]; then
    mkdir -p moved && printf 'mine\n' >moved/new
    run 3 'directory back: an occupied path is refused' "${scripts}/move-file.sh" renamed/new \
      moved/new
    check 'directory back: the occupied file is unchanged' mine "$(cat moved/new)"
    check 'directory back: the placed file is unchanged' new "$(cat renamed/new)"
    rm -f moved/new
    run 0 'directory back: move it' "${scripts}/move-file.sh" renamed/new moved/new
    check 'directory back: the file is staged' 0 "$(stage -- moved/new)"
  else
    check "directory accept: git's location is staged" 0 \
      "$(stage --side-chosen=branch -- renamed/new)"
  fi
  git rebase --continue >/dev/null 2>&1
  check "directory ${answer}: the rebase finishes" none "$(kv op "$("${scripts}/state.sh")")"
done
check 'directory back: the file is back' new "$(cat moved/new)"

echo '== a file meeting a directory'
git init --quiet -b main "${dir}/parked"
cd "${dir}/parked" || exit 2
commit start start 'Start'
git switch --quiet -c base
mkdir foo && commit foo/bar bar 'Add a directory on the base'
git switch --quiet -c branch main
commit foo file 'Add a file on the branch'
git rebase base >/dev/null 2>&1
run 0 'parked: state' "${scripts}/state.sh"
parked=$(kv added_by_them)
contains 'parked: git parks the file under a ~ name' 'foo~' "${parked}"
commit_free=$(git ls-files -- start)
run 3 'parked: a tracked destination is refused' "${scripts}/move-file.sh" "${parked}" start
check 'parked: the tracked file is unchanged' start "$(cat "${commit_free}")"
run 2 'move-file: refuses a path that is not conflicted' "${scripts}/move-file.sh" start elsewhere
run 2 'move-file: a glob does not match a conflicted path' "${scripts}/move-file.sh" 'foo~*' \
  elsewhere
run 0 'parked: move it to a real name' "${scripts}/move-file.sh" "${parked}" real
check 'parked: the real name is staged' 0 "$(stage -- real)"
git rebase --continue >/dev/null 2>&1
check 'parked: the rebase finishes' none "$(kv op "$("${scripts}/state.sh")")"
check 'parked: the file has the real name' file "$(cat real)"

echo '== a lock file kept through a rename on both sides'
renames lock keep.lock base-name.lock branch-name.lock BASE BRANCH
git checkout --quiet --ours -- base-name.lock
check 'lock kept: --ours cannot give the base version' 1 \
  "$(stage --side-chosen=base -- base-name.lock)"
run 0 'lock kept: keep the branch name' "${scripts}/keep-name.sh" branch-name.lock keep.lock \
  base-name.lock
git cat-file -e HEAD:base-name.lock && git show HEAD:base-name.lock >branch-name.lock
check 'lock kept: the base version is staged' 0 "$(stage --side-chosen=branch -- branch-name.lock)"
git rebase --continue >/dev/null 2>&1
check 'lock kept: the rebase finishes' none "$(kv op "$("${scripts}/state.sh")")"
check "lock kept: the kept name holds the base's version" BASE "$(tail -n 1 branch-name.lock)"
git cat-file -e HEAD:no-such-name 2>/dev/null && git show HEAD:no-such-name >written
check 'lock kept: a missing HEAD path stops before writing' no \
  "$([[ -e written ]] && echo yes || echo no)"
cd "${dir}/state" || exit 2

echo '== a repository whose default branch is master'
init_origin "${dir}/master.git" "${dir}/master" master
cd "${dir}/master" || exit 2
git switch --quiet -c topic && commit topic.txt topic 'Add topic'
fixtures master master
run 0 'master: online' "${scripts}/resolve-base.sh"
check 'master: base from GitHub' master "$(kv base)"
touch "${FAKE_GH}/offline"
run 0 'master: offline' "${scripts}/resolve-base.sh"
check 'master: base from origin/HEAD' master "$(kv base)"
check 'master: offline is unconfirmed' failed "$(kv github)"
run 0 'master: prepare' "${scripts}/prepare.sh" topic master master origin
check 'master: target' origin/master "$(kv target)"
check 'master: local master up to date' up-to-date "$(kv ff_default)"

echo '== main scenario'
init_origin "${dir}/origin.git" "${dir}/me" main
git clone --quiet "${dir}/origin.git" "${dir}/them"
cd "${dir}/me" || exit 2
commit shared.txt 'a\nb\nc' 'Add shared'
git push --quiet origin main
git switch --quiet -c feature
commit shared.txt 'A\nb\nc' 'Change the first line'
git push --quiet origin feature
git branch --quiet other main && git push --quiet origin other
start_main=$(git rev-parse main)
them git pull --quiet
them commit shared.txt 'a\nb\nC' 'Change the last line'
them git push --quiet origin main

echo '== resolve-base.sh'
fixtures resolve
run 0 'resolve: default' "${scripts}/resolve-base.sh"
check 'resolve: branch' feature "$(kv branch)"
check 'resolve: default base' main "$(kv base)"
check 'resolve: default source' default "$(kv source)"
check 'resolve: confirmed by GitHub' ok "$(kv github)"
check 'resolve: no parent' '' "$(kv parent)"
touch "${FAKE_GH}/offline"
run 0 'resolve: offline' "${scripts}/resolve-base.sh"
check 'resolve offline: base from origin/HEAD' main "$(kv base)"
check 'resolve offline: no repo' '' "$(kv repo)"
check 'resolve offline: unconfirmed' failed "$(kv github)"
contains "resolve offline: keeps gh's error" 'error connecting' "${err}"
rm "${FAKE_GH}/offline"
touch "${FAKE_GH}/fail-list-open"
run 0 'resolve: pull request lookup fails' "${scripts}/resolve-base.sh"
check 'resolve lookup failed: base' main "$(kv base)"
check 'resolve lookup failed: source' default "$(kv source)"
check 'resolve lookup failed: unconfirmed' failed "$(kv github)"
contains "resolve lookup failed: keeps gh's error" 'HTTP 401' "${err}"
rm "${FAKE_GH}/fail-list-open"
run 0 'resolve: argument' "${scripts}/resolve-base.sh" other
check 'resolve: argument base' other "$(kv base)"
check 'resolve: argument source' argument "$(kv source)"
run 2 'resolve: a name with shell metacharacters is refused' "${scripts}/resolve-base.sh" 'a;b'
run 1 'resolve: unknown branch' "${scripts}/resolve-base.sh" no-such-branch
contains 'resolve: unknown branch says why' 'is not a branch on origin' "${err}"
cat >"${FAKE_GH}/list-open-head-feature.json" <<'JSON'
[{"number": 9, "baseRefName": "main", "isDraft": false, "author": {"login": "someone"}}]
JSON
run 0 'resolve: only another author has a PR from this name' "${scripts}/resolve-base.sh"
check "resolve: another author's PR is ignored" '' "$(kv pr)"
cat >"${FAKE_GH}/list-open-head-feature.json" <<'JSON'
[{"number": 7, "baseRefName": "other", "isDraft": true, "author": {"login": "me"}}]
JSON
run 0 'resolve: pull request' "${scripts}/resolve-base.sh"
check 'resolve: pull request base' other "$(kv base)"
check 'resolve: pull request source' pull-request "$(kv source)"
check 'resolve: pull request number' 7 "$(kv pr)"
check 'resolve: draft' true "$(kv draft)"

echo '== prepare.sh and overlap.sh'
run 0 'prepare: stale local main' "${scripts}/prepare.sh" feature main main origin
check 'prepare: behind' 1 "$(kv behind)"
check 'prepare: ahead' 1 "$(kv ahead)"
check 'prepare: old_head' "$(git rev-parse feature)" "$(kv old_head)"
check 'prepare: old_base' "${start_main}" "$(kv old_base)"
check 'prepare: push_remote' origin "$(kv push_remote)"
check 'prepare: remote_head' "$(git rev-parse feature)" "$(kv remote_head)"
check 'prepare: integrated' yes "$(kv remote_integrated)"
check 'prepare: fast-forward' yes "$(kv ff_default)"
check 'prepare: main moved' "$(git rev-parse origin/main)" "$(git rev-parse main)"
old_base=$(kv old_base) old_head=$(kv old_head)
git branch --quiet -f main "${start_main}"
git worktree add --quiet "${dir}/wt" main
run 0 'prepare: main in a worktree' "${scripts}/prepare.sh" feature main main origin
check 'prepare: main held by a worktree' skipped:checked-out "$(kv ff_default)"
git worktree remove "${dir}/wt"
git branch --quiet -f main "$(git commit-tree -p "${start_main}" -m local "${start_main}^{tree}")"
run 0 'prepare: diverged main' "${scripts}/prepare.sh" feature main main origin
check 'prepare: diverged main' skipped:diverged "$(kv ff_default)"
git branch --quiet -D main
run 0 'prepare: no local main' "${scripts}/prepare.sh" feature main main origin
check 'prepare: no local main' skipped:no-local-branch "$(kv ff_default)"
git branch --quiet main origin/main
run 0 'prepare: another base' "${scripts}/prepare.sh" feature other main origin
check 'prepare: not the base' not-the-base "$(kv ff_default)"
"${scripts}/prepare.sh" feature no-such-base main origin >/dev/null 2>&1
check 'prepare: a missing base fails' 1 "$(($? != 0))"
run 0 'overlap' "${scripts}/overlap.sh" "${old_base}" "${old_head}" origin/main
check 'overlap: both sides changed' shared.txt "${out}"
"${scripts}/overlap.sh" deadbeef HEAD HEAD >/dev/null 2>&1
check 'overlap: a bad revision fails' 1 "$(($? != 0))"

echo '== push-lease.sh'
git rebase --quiet origin/main
run 0 'prepare: after the rebase' "${scripts}/prepare.sh" feature main main origin
check 'prepare: nothing behind' 0 "$(kv behind)"
check 'prepare: local main up to date' up-to-date "$(kv ff_default)"
run 0 'push: rebased branch' "${scripts}/push-lease.sh" feature
check 'push: confirmed' yes "$(kv confirmed)"
check 'push: remote equals HEAD' "$(git rev-parse HEAD)" \
  "$(git ls-remote origin refs/heads/feature | cut -f1)"
run 0 'push: again' "${scripts}/push-lease.sh" feature
check 'push: repeat is confirmed' yes "$(kv confirmed)"
contains 'push: repeat says so' 'nothing to push' "${err}"
git branch --quiet fresh && run 0 'push: first push' "${scripts}/push-lease.sh" fresh
check 'push: first push confirmed' yes "$(kv confirmed)"

# The colleague pushes to the branch; a clone that fetched but never integrated it may not overwrite
them git fetch --quiet
them git switch --quiet feature
them commit theirs.txt theirs 'Add theirs'
them git push --quiet origin feature
theirs=$(them git rev-parse HEAD)
run 0 'prepare: colleague pushed' "${scripts}/prepare.sh" feature main main origin
check 'prepare: remote not integrated' no "$(kv remote_integrated)"
check 'prepare: remote_head is theirs' "${theirs}" "$(kv remote_head)"
git commit --quiet --amend -m 'Change the first line again'
run 3 'push: fetched but unintegrated' "${scripts}/push-lease.sh" feature
check 'push: remote left alone' "${theirs}" "$(git ls-remote origin refs/heads/feature | cut -f1)"
git reset --quiet --hard origin/feature

# A reflog entry from before the branch was recreated proves nothing about the new branch
git switch --quiet -C feature origin/main
commit unrelated.txt unrelated 'Unrelated work'
run 3 'push: recreated branch' "${scripts}/push-lease.sh" feature
check 'push: recreated branch left the remote alone' "${theirs}" \
  "$(git ls-remote origin refs/heads/feature | cut -f1)"
git reset --quiet --hard "${theirs}"

# Someone pushes between the script's ls-remote and its push: the lease must reject it
mkdir -p "${dir}/shim"
cat >"${dir}/shim/git" <<'SHIM'
#!/usr/bin/env bash
if [[ $1 == push && -e $RACE_MARKER ]]; then
  rm -f "$RACE_MARKER"
  (cd "$RACE_CLONE" && "$REAL_GIT" commit --quiet --allow-empty -m race \
    && "$REAL_GIT" push --quiet origin HEAD:refs/heads/feature)
fi
exec "$REAL_GIT" "$@"
SHIM
chmod +x "${dir}/shim/git"
them git fetch --quiet && them git reset --quiet --hard origin/feature
git commit --quiet --amend -m 'Add theirs, reworded'
touch "${dir}/race"
run 5 'push: lost race' env PATH="${dir}/shim:${PATH}" RACE_MARKER="${dir}/race" \
  RACE_CLONE="${dir}/them" REAL_GIT="${real_git}" "${scripts}/push-lease.sh" feature
check 'push: race winner kept' "$(them git rev-parse HEAD)" \
  "$(git ls-remote origin refs/heads/feature | cut -f1)"
git fetch --quiet origin && git reset --quiet --hard origin/feature

echo '== a conflict, seen as a later session would find it'
them git switch --quiet main
them commit base.txt theirs 'Change base on main'
them git push --quiet origin main
commit base.txt mine 'Change base on the branch'
commit later.txt later 'Add a later commit'
before=$(git rev-parse HEAD)
git fetch --quiet origin
git rebase --quiet origin/main >/dev/null 2>&1
run 0 'conflict: state' "${scripts}/state.sh"
check 'conflict: op' rebase-merge "$(kv op)"
check 'conflict: branch' feature "$(kv branch)"
check 'conflict: path' base.txt "$(kv conflict)"
check 'conflict: orig_head' "${before}" "$(kv orig_head)"
check 'conflict: onto' "$(git rev-parse origin/main)" "$(kv onto)"
contains 'conflict: onto_refs names origin/main' origin/main "$(kv onto_refs)"
total=$(git rev-list --count "origin/main..${before}")
check 'conflict: step on a commit that is not last' "$((total - 1))/${total}" "$(kv step)"
cat >"${FAKE_GH}/list-open-head-feature.json" <<'JSON'
[{"number": 7, "baseRefName": "main", "isDraft": false, "author": {"login": "me"}}]
JSON
run 0 'conflict: resolve-base mid-rebase' "${scripts}/resolve-base.sh"
check 'conflict: branch found while detached' feature "$(kv branch)"
check 'conflict: pull request found while detached' 7 "$(kv pr)"
echo merged >base.txt && git add base.txt && git rebase --continue >/dev/null 2>&1
check 'conflict: resolved' none "$(kv op "$("${scripts}/state.sh")")"
git rebase --quiet -x false --onto "${start_main}" HEAD~1 >/dev/null 2>&1
run 0 'wrong base: state' "${scripts}/state.sh"
check 'wrong base: still rebasing' rebase-merge "$(kv op)"
case $(kv onto_refs) in *origin/main*) rc=1 ;; *) rc=0 ;; esac
check 'wrong base: onto_refs lacks origin/main' 0 "${rc}"
git rebase --abort

echo '== stack.sh'
fixtures stack
git switch --quiet -c child && commit child.txt child 'Add child'
git push --quiet origin child
git switch --quiet -c grandchild && commit grandchild.txt grandchild 'Add grandchild'
git switch --quiet -c sibling feature && commit sibling.txt sibling 'Add sibling'
git switch --quiet -c otherpr feature && commit otherpr.txt otherpr 'Add otherpr'
git switch --quiet -c develop origin/main && commit develop.txt develop 'Add develop'
git merge --quiet --no-edit feature >/dev/null
git branch --quiet notparent origin/main
git branch --quiet backup feature
git switch --quiet feature
git worktree add --quiet "${dir}/sibling-wt" sibling
printf '[{"number": 11, "baseRefName": "feature"}]\n' >"${FAKE_GH}/list-open-head-child.json"
printf '[{"number": 13, "baseRefName": "main"}]\n' >"${FAKE_GH}/list-open-head-otherpr.json"
cat >"${FAKE_GH}/list-open-base-feature.json" <<'JSON'
[{"number": 11, "headRefName": "child"}, {"number": 14, "headRefName": "notparent"},
 {"number": 12, "headRefName": "ghost"}]
JSON
old_feature=$(git rev-parse HEAD)
git commit --quiet --amend -m 'Change base on the branch (rebased)'
run 0 'stack: list' "${scripts}/stack.sh" feature "${old_feature}" main test/repo
rows=${out}
expected='feature child ok|feature develop has-merges|feature otherpr other-base|feature sibling ok'
expected+='|feature notparent not-on-parent|feature ghost not-local|child grandchild ok'
actual=$(awk -F '\t' '{ print $1, $3, $8 }' <<<"${rows}" | paste -sd '|' -)
check 'stack: rows' "${expected}" "${actual}"
touch "${FAKE_GH}/fail-list-open-head"
run 1 'stack: pull request lookup fails' "${scripts}/stack.sh" feature "${old_feature}" main \
  test/repo
contains "stack: keeps gh's error" 'HTTP 401' "${err}"
rm "${FAKE_GH}/fail-list-open-head"
touch "${FAKE_GH}/fail-list-open"
run 1 'stack: pull request list fails with no child' "${scripts}/stack.sh" otherpr \
  "$(git rev-parse otherpr)" main test/repo
contains "stack: keeps the list's error" 'HTTP 401' "${err}"
run 0 'stack: no repo consults no pull request' "${scripts}/stack.sh" feature "${old_feature}" main
rm "${FAKE_GH}/fail-list-open"
check 'stack: pull request' 11 "$(awk -F '\t' '$3 == "child" { print $5 }' <<<"${rows}")"
wt=$(awk -F '\t' '$3 == "sibling" { print $6 }' <<<"${rows}")
check 'stack: worktree' "$(cd "${dir}/sibling-wt" && pwd -P)" "$(cd "${wt}" && pwd -P)"
check 'stack: pushed child' yes "$(awk -F '\t' '$3 == "child" { print $7 }' <<<"${rows}")"
check 'stack: unpushed child' no "$(awk -F '\t' '$3 == "grandchild" { print $7 }' <<<"${rows}")"
check 'stack: empty fields print as -' - \
  "$(awk -F '\t' '$3 == "grandchild" { print $5 }' <<<"${rows}")"
check 'stack: no row for a branch at the old tip' '' "$(awk -F '\t' '$3 == "backup"' <<<"${rows}")"
git worktree remove "${dir}/sibling-wt"
while IFS=$'\t' read -r parent parent_old child _ _ _ _ note; do
  [[ ${note} == ok ]] && git rebase --quiet --onto "${parent}" "${parent_old}" "${child}" </dev/null
done <<<"${rows}"
git merge-base --is-ancestor feature grandchild
check 'stack: grandchild on the new feature' 0 "$?"
check 'stack: grandchild carries two commits' 2 "$(git rev-list --count feature..grandchild)"
check 'stack: develop untouched' 1 "$(git rev-list --merges --count origin/main..develop)"
git switch --quiet feature

echo '== merged parents'
fixtures merged
git switch --quiet -c localparent origin/main && commit lp.txt lp 'Add localparent'
git switch --quiet -c localchild && commit lc.txt lc 'Add localchild'
touch "${FAKE_GH}/offline"
run 1 'merged: unpushed parent, offline' "${scripts}/resolve-base.sh" localparent
contains 'merged: offline says why' 'gh cannot reach' "${err}"
rm "${FAKE_GH}/offline"
run 1 'merged: unpushed parent, no merged PR' "${scripts}/resolve-base.sh" localparent
contains 'merged: online says why' 'no merged pull request' "${err}"
touch "${FAKE_GH}/fail-list-merged"
run 1 'merged: unpushed parent, lookup fails' "${scripts}/resolve-base.sh" localparent
contains 'merged: failed lookup says why' 'gh cannot reach' "${err}"
contains "merged: failed lookup keeps gh's error" 'HTTP 401' "${err}"
rm "${FAKE_GH}/fail-list-merged"
touch "${FAKE_GH}/fail-list-open"
run 1 'merged: only the open lookup fails' "${scripts}/resolve-base.sh" localparent
contains 'merged: the merged lookup answered' 'no merged pull request' "${err}"
rm "${FAKE_GH}/fail-list-open"
printf '[{"number": 5, "headRefOid": "%s", "baseRefName": "main"}]\n' "$(git rev-parse feature)" \
  >"${FAKE_GH}/list-merged-head-localparent.json"
run 1 'merged: an old PR from a reused name' "${scripts}/resolve-base.sh" localparent

# Squash-merged and deleted, with no local trace: only GitHub can name the old tip
git switch --quiet -c parent2 origin/main
commit p2.txt one 'Start parent2' && commit p2.txt two 'Finish parent2'
git switch --quiet -c child2 && commit c2.txt c2 'Add child2'
git push --quiet origin parent2 child2
parent2=$(git rev-parse parent2)
them git fetch --quiet && them git pull --quiet origin main
them git merge --quiet --squash origin/parent2 >/dev/null
them git commit --quiet -m 'Add parent2 (squashed)'
them git push --quiet origin main
them git push --quiet origin --delete parent2
git branch --quiet -D parent2 && git update-ref -d refs/remotes/origin/parent2
printf '[{"number": 21, "baseRefName": "parent2", "isDraft": false, "author": {"login": "me"}}]\n' \
  >"${FAKE_GH}/list-open-head-child2.json"
printf '[{"number": 20, "headRefOid": "%s", "baseRefName": "main"}]\n' "${parent2}" \
  >"${FAKE_GH}/list-merged-head-parent2.json"
run 0 'merged parent' "${scripts}/resolve-base.sh"
check 'merged parent: source' merged-parent "$(kv source)"
check 'merged parent: base' main "$(kv base)"
check 'merged parent: parent_pr' 20 "$(kv parent_pr)"
check 'merged parent: old tip from GitHub' "${parent2}" "$(kv old_parent_tip)"
base=$(kv base) tip=$(kv old_parent_tip)
git fetch --quiet origin
run 0 "merged parent: rebase from the script's output" \
  git rebase --quiet --onto "origin/${base}" "${tip}"
check 'merged parent: only the child commit remains' 1 "$(git rev-list --count origin/main..HEAD)"

# Squash-merged into a non-default base with the branch kept: the child's PR still targets it
git switch --quiet -c parent4 origin/other && commit p4.txt p4 'Add parent4'
git switch --quiet -c child4 && commit c4.txt c4 'Add child4'
git push --quiet origin parent4 child4
parent4=$(git rev-parse parent4)
printf '[{"number": 41, "baseRefName": "parent4", "isDraft": false, "author": {"login": "me"}}]\n' \
  >"${FAKE_GH}/list-open-head-child4.json"
printf '[{"number": 40, "headRefOid": "%s", "baseRefName": "other"}]\n' "${parent4}" \
  >"${FAKE_GH}/list-merged-head-parent4.json"
run 0 'kept parent' "${scripts}/resolve-base.sh"
check 'kept parent: source' merged-parent "$(kv source)"
check 'kept parent: parent' parent4 "$(kv parent)"
check 'kept parent: base from the merged PR' other "$(kv base)"
check 'kept parent: old tip' "${parent4}" "$(kv old_parent_tip)"
touch "${FAKE_GH}/fail-list-merged"
run 0 'kept parent: lookup fails' "${scripts}/resolve-base.sh"
check 'kept parent failed: source' pull-request "$(kv source)"
check 'kept parent failed: unconfirmed' failed "$(kv github)"
contains "kept parent failed: keeps gh's error" 'HTTP 401' "${err}"
rm "${FAKE_GH}/fail-list-merged"

# Squash-merged with the branch deleted, so GitHub retargeted the child to main
git switch --quiet -c parent3 origin/main && commit p3.txt p3 'Add parent3'
git switch --quiet -c child3 && commit c3.txt c3 'Add child3'
parent3=$(git rev-parse parent3)
cat >"${FAKE_GH}/list-merged-base-main.json" <<JSON
[{"number": 32, "headRefName": "child3", "headRefOid": "$(git rev-parse child3)"},
 {"number": 31, "headRefName": "merged-in", "headRefOid": "$(git rev-parse origin/main)"},
 {"number": 30, "headRefName": "parent3", "headRefOid": "${parent3}"}]
JSON
run 0 'retargeted' "${scripts}/resolve-base.sh"
check 'retargeted: source' default "$(kv source)"
check 'retargeted: parent skips own and already-merged heads' parent3 "$(kv parent)"
check 'retargeted: old tip' "${parent3}" "$(kv old_parent_tip)"
touch "${FAKE_GH}/fail-list-merged"
run 0 'retargeted: scan fails' "${scripts}/resolve-base.sh"
check 'retargeted failed: no parent found' '' "$(kv parent)"
check 'retargeted failed: unconfirmed' failed "$(kv github)"
contains "retargeted failed: keeps gh's error" 'HTTP 401' "${err}"
run 0 'retargeted: default named, scan fails' "${scripts}/resolve-base.sh" main
check 'retargeted named: source' argument "$(kv source)"
check 'retargeted named: unconfirmed' failed "$(kv github)"
check 'retargeted named: no parent found' '' "$(kv parent)"
rm "${FAKE_GH}/fail-list-merged"
printf '[{"number": 31, "headRefName": "merged-in", "headRefOid": "%s"}]\n' \
  "$(git rev-parse origin/main)" >"${FAKE_GH}/list-merged-base-main.json"
run 0 'retargeted: only an already-merged head' "${scripts}/resolve-base.sh"
check 'retargeted: no parent from a head already in main' '' "$(kv parent)"
printf '[{"number": 30, "headRefName": "parent3", "headRefOid": "%s"}]\n' "${parent3}" \
  >"${FAKE_GH}/list-merged-base-main.json"
git update-ref -d refs/remotes/origin/main
run 0 'retargeted: no origin/main' "${scripts}/resolve-base.sh"
check 'retargeted: no scan without origin/main' '' "$(kv parent)"
git fetch --quiet origin

echo '== wait-merged.sh'
fixtures wait
printf '{"state": "OPEN", "mergeCommit": null}\n' >"${FAKE_GH}/pr-5.json.1"
cp "${FAKE_GH}/pr-5.json.1" "${FAKE_GH}/pr-5.json.2"
printf '{"state": "MERGED", "mergeCommit": {"oid": "abc123"}}\n' >"${FAKE_GH}/pr-5.json"
run 0 'wait: merged after two polls' "${scripts}/wait-merged.sh" 5 test/repo
check 'wait: state' MERGED "$(kv state)"
check 'wait: merge commit' abc123 "$(kv merge_commit)"
check 'wait: polled three times' 3 "$(cat "${FAKE_GH}/count-5")"
printf '{"state": "CLOSED", "mergeCommit": null}\n' >"${FAKE_GH}/pr-6.json"
run 0 'wait: closed' "${scripts}/wait-merged.sh" 6 test/repo
check 'wait: closed state' CLOSED "$(kv state)"
check 'wait: closed has no merge commit' '' "$(kv merge_commit)"
for n in 1 2 3 4 5 6 7 8 9; do touch "${FAKE_GH}/pr-7.fail.${n}"; done
printf '{"state": "MERGED", "mergeCommit": {"oid": "def456"}}\n' >"${FAKE_GH}/pr-7.json"
run 0 'wait: nine failures, then success' "${scripts}/wait-merged.sh" 7 test/repo
check 'wait: recovered' MERGED "$(kv state)"
touch "${FAKE_GH}/pr-8.failall"
run 1 'wait: gives up' "${scripts}/wait-merged.sh" 8 test/repo
contains "wait: reports gh's last error" 'HTTP 401' "${err}"
check 'wait: gave up after ten polls' 10 "$(cat "${FAKE_GH}/count-8")"

echo '== a fork'
fixtures fork
git init --quiet --bare -b main "${dir}/up/proj.git"
git -C "${dir}/me" push --quiet "${dir}/up/proj.git" origin/main:refs/heads/main
git init --quiet --bare -b main "${dir}/forkowner/fork.git"
git clone --quiet "${dir}/up/proj.git" "${dir}/forkclone" 2>/dev/null
cd "${dir}/forkclone" || exit 2
git remote rename origin upstream
git remote add origin "${dir}/forkowner/fork.git"
git switch --quiet -c fix && commit fix.txt fix 'Add fix'
run 0 'fork: resolve' "${scripts}/resolve-base.sh"
check 'fork: remote' upstream "$(kv remote)"
check 'fork: repo slug' up/proj "$(kv repo)"
contains 'fork: gh asked about the upstream slug' 'repo view up/proj' \
  "$(cat "${FAKE_GH}/calls.log")"

if ((failed)); then exit 1; fi
echo 'All /rebase script tests passed.'
