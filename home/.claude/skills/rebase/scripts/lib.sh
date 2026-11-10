# shellcheck shell=bash
#
# Shared by the /rebase scripts, which source it rather than run it.

# Exits 2 unless every argument is a branch name made only of letters, digits, dots, underscores,
# slashes and dashes. Git accepts shell metacharacters in branch names, and the skill substitutes
# these names into commands, so anything else is refused rather than quoted.
require_plain_names() {
  local name
  for name in "$@"; do
    [[ $name =~ ^[A-Za-z0-9._/-]+$ ]] || {
      echo "Refusing branch name '$name': only letters, digits and . _ / - are allowed." >&2
      exit 2
    }
  done
}

# Prints the remote <branch> pushes to, in git's own order of precedence
push_remote_of() {
  git config "branch.$1.pushRemote" \
    || git config remote.pushDefault \
    || git config "branch.$1.remote" \
    || echo origin
}

# Prints the SHA <remote> holds for branch <name>, or nothing when the branch does not exist there.
# ls-remote matches patterns by suffix, so the awk keeps only the exact ref.
remote_sha() {
  git ls-remote "$1" "refs/heads/$2" | awk -v ref="refs/heads/$2" '$2 == ref { print $1 }'
}

# Succeeds when <sha> is reachable from <ref> or from a reflog entry since the branch was last
# created or reset: that is, when this clone had that commit on this incarnation of the branch, so
# overwriting it on the remote loses nothing this clone never saw. Entries from before a reset
# belong to an earlier branch of the same name and prove nothing. This is a stricter form of the
# check --force-if-includes makes, which git skips when the lease names an explicit SHA.
reachable_from_reflog() {
  local ref=$1 sha=$2 entry
  git cat-file -e "$sha^{commit}" 2>/dev/null || return 1
  while IFS= read -r entry; do
    git merge-base --is-ancestor "$sha" "$entry" && return 0
  done < <({
    git rev-parse "$ref"
    reflog_tips "$ref"
  } | awk '!seen[$0]++')
  return 1
}

# Prints every tip <ref> has had since it was last created or reset, newest first. An entry's old
# value counts as well as its new one: once gc has expired the older entries, the tip before a
# rebase survives only as the old value of the rebase's own entry. git log -g cannot print old
# values, so the reflog file is read; under the reftable backend there is no file, and only the new
# values are available.
reflog_tips() {
  local log
  log=$(git rev-parse --git-path "logs/$1")
  if [[ ! -f $log ]]; then
    git log -g --format='%H %gs' "$1" 2>/dev/null \
      | awk '{ print $1 } /^[0-9a-f]+ branch: (Created from|Reset to) / { exit }'
    return
  fi
  # Each line is "<old> <new> <name> <<email>> <time> <zone>\t<message>", oldest first. The message
  # is found after the zone, not at the first tab, because git keeps a tab inside a name. A boundary
  # entry drops what came before it, its own old value included.
  awk '{ split($0, sha, " "); msg = "" }
    match($0, /> [0-9]+ [-+][0-9]+\t/) { msg = substr($0, RSTART + RLENGTH) }
    msg ~ /^branch: (Created from|Reset to) / { n = 0; tip[++n] = sha[2]; next }
    { tip[++n] = sha[1]; tip[++n] = sha[2] }
    END { for (i = n; i > 0; i--) if (tip[i] !~ /^0+$/) print tip[i] }' "$log"
}
