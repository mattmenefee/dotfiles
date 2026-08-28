# Git worktrees - navigate by number (e.g., wt 1, wt 2)
# Run from any worktree to switch between them
#
# `git worktree list` sorts linked worktrees by full path, and the throwaway worktrees Claude Code
# creates for its subagents live inside the main worktree (`.claude/worktrees/agent-<id>`). They
# therefore sort ahead of every permanent worktree and renumber all of them mid-session. Listing
# the temporary ones last keeps `wt 2` pointing at the same checkout whether or not agents are
# running.
#
# `wtl` reorders git's own listing so it keeps the commit and branch columns, while `wt` reads
# `--porcelain -z`. Plain `--porcelain` already returns a path containing spaces intact; `-z` is
# what also survives a path containing a literal newline, which would otherwise split a single
# worktree across two records.
#
# The two only stay in step because of three things git guarantees and this code does not: refnames
# cannot contain a component beginning with a dot, so the branch column can never carry the marker;
# plain `git worktree list` omits lock and prune reasons, which are free text, so adding `-v` here
# would leak them into the match; and git C-quotes control characters, so one worktree is always
# one line for `nl` to number.
#
# The `.claude/worktrees/` layout belongs to Claude Code, and any worktree under such a path is
# held back, not only the throwaway ones. If the layout ever changes, the marker has to move in
# `wtlist`, in `_wt_paths`, and in `home/.gitignore_global` together.

# git worktree list, with Claude Code's temporary agent worktrees moved to the end
wtlist() {
  git worktree list | awk '
    index($0, "/.claude/worktrees/") { temporary[++count] = $0; next }
    { print }
    END { for (i = 1; i <= count; i++) print temporary[i] }
  '
}

# Worktree paths in the same order `wtl` prints them, returned in $reply so that no delimiter has
# to survive the trip back. Callers must declare `local -a reply` first.
_wt_paths() {
  emulate -L zsh
  local -a temporary
  # `dir`, never `path`: zsh ties `path` to `PATH`, so a local of that name empties it and `git`
  # stops resolving for the rest of the function
  local record dir
  reply=()
  for record in ${(0)"$(git worktree list --porcelain -z)"}; do
    [[ $record == 'worktree '* ]] || continue
    dir=${record#worktree }
    if [[ $dir == */.claude/worktrees/* ]]; then
      temporary+=("$dir")
    else
      reply+=("$dir")
    fi
  done
  reply+=("${temporary[@]}")
}

wt() {
  # Name the options rather than reaching for `emulate -L zsh`, which would also switch off
  # AUTO_PUSHD for the `cd` below
  setopt local_options no_ksh_arrays no_octal_zeroes
  # The upper bound is what keeps a very long number away from the subscript, where zsh would
  # complain about truncating it before reporting anything useful
  if [[ $# -ne 1 || ${1-} != <1-999999> ]]; then
    echo "Usage: wt <number>" >&2
    return 1
  fi
  local -a reply
  local worktree_path
  _wt_paths
  if (( $#reply == 0 )); then
    echo "wt: no worktrees found (are you in a git repo?)" >&2
    return 1
  fi
  worktree_path=${reply[$1]}
  if [[ -z "$worktree_path" ]]; then
    echo "Worktree $1 not found (wtl lists 1-$#reply)" >&2
    return 1
  fi
  if [[ ! -d "$worktree_path" ]]; then
    echo "Worktree $1 is listed but its directory is gone: $worktree_path" >&2
    return 1
  fi
  cd -- "$worktree_path" || return
}

# List all worktrees with numbers
wtl() {
  setopt local_options pipefail
  wtlist | nl
}
