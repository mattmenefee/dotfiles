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
check 'resolve: no parent' '' "$(kv parent)"
touch "${FAKE_GH}/offline"
run 0 'resolve: offline' "${scripts}/resolve-base.sh"
check 'resolve offline: base from origin/HEAD' main "$(kv base)"
check 'resolve offline: no repo' '' "$(kv repo)"
rm "${FAKE_GH}/offline"
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
