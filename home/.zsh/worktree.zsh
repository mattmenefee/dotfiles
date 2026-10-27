# Git worktrees - navigate by number (e.g. wt 1, wt 2)
# Run from any worktree to switch between them
#
# A worktree's number is the one its folder ends in, so `wt 10` is `repo10` wherever git happens to
# list it (git sorts linked worktrees by full path, which puts `repo10` before `repo2`). The main
# worktree is always 1. A folder named only digits (`42`) takes that number. A worktree whose folder
# has no usable number (none, a leading zero or more than five digits), or one already taken, gets
# the next number after the highest, in git's order.
#
# The throwaway worktrees Claude Code creates for its subagents live inside the main worktree
# (`.claude/worktrees/agent-<id>`). They are numbered last, so they never take a number from a
# permanent worktree, even when their names end in digits.
#
# `wtl` prints git's own listing so it keeps the commit and branch columns, while `_wt_numbered`
# reads `--porcelain -z`. Plain `--porcelain` already returns a path containing spaces intact; `-z`
# is what also survives a path containing a literal newline, which would otherwise split a single
# worktree across two records.
#
# `wtl` pairs the two listings line for line, which holds only because git lists worktrees in the
# same order in both and C-quotes control characters in the plain one, so one worktree is always one
# line. Plain `git worktree list` also omits lock and prune reasons, which are free text and could
# otherwise span lines, so adding `-v` there would break the pairing.
#
# The `.claude/worktrees/` layout belongs to Claude Code, and any worktree under such a path is held
# back, not only the throwaway ones. If the layout ever changes, the marker has to move in
# `_wt_numbered` and in `home/.gitignore_global` together.

# Worktrees in git's order, returned in $reply as alternating number and path so that no delimiter
# has to survive the trip back. Callers must declare `local -a reply` first.
_wt_numbered() {
  emulate -L zsh
  setopt extended_glob
  # `dirs`, never `path`: zsh ties `path` to `PATH`, so a local of that name empties it and `git`
  # stops resolving for the rest of the function. `(#b)` sets the match arrays, so they are local
  # too, to leave the caller's alone.
  local -a dirs numbers match mbegin mend
  local -A taken
  local record stem agent='*/.claude/worktrees/*'
  local -i i pass highest=1
  for record in ${(0)"$(git worktree list --porcelain -z)"}; do
    [[ $record == 'worktree '* ]] && dirs+=("${record#worktree }")
  done
  reply=()
  (( $#dirs )) || return 0
  numbers=(1)
  taken[1]=1
  stem=${dirs[1]:t}
  [[ $stem == (#b)(*[^0-9]|)[0-9]## ]] && stem=$match[1]
  # Folders named after the main worktree (`repo10` beside `repo`) claim their numbers first, so an
  # unrelated `thing3` elsewhere cannot take 3 from `repo3`. The five-digit cap keeps every number,
  # those handed out after the highest included, within what `wt` accepts.
  for pass in 1 2; do
    for (( i = 2; i <= $#dirs; i++ )); do
      (( numbers[i] == 0 )) || continue
      [[ ${dirs[i]} != $~agent ]] || continue
      [[ ${dirs[i]:t} == (#b)(*[^0-9]|)([1-9][0-9](#c0,4)) ]] || continue
      (( pass == 2 )) || [[ $match[1] == "$stem" ]] || continue
      (( ! ${+taken[$match[2]]} )) || continue
      numbers[i]=$match[2]
      taken[$match[2]]=1
      (( highest = numbers[i] > highest ? numbers[i] : highest ))
    done
  done
  for (( i = 2; i <= $#dirs; i++ )); do
    if (( numbers[i] == 0 )) && [[ ${dirs[i]} != $~agent ]]; then
      numbers[i]=$(( ++highest ))
    fi
  done
  for (( i = 2; i <= $#dirs; i++ )); do
    (( numbers[i] == 0 )) && numbers[i]=$(( ++highest ))
  done
  for (( i = 1; i <= $#dirs; i++ )); do
    reply+=("${numbers[i]}" "${dirs[i]}")
  done
}

wt() {
  # Name the options rather than reaching for `emulate -L zsh`, which would also switch off
  # AUTO_PUSHD for the `cd` below
  setopt local_options no_ksh_arrays no_octal_zeroes
  # The upper bound is what keeps a very long number away from the arithmetic, where zsh would
  # complain about truncating it before reporting anything useful
  if [[ $# -ne 1 || ${1-} != <1-999999> ]]; then
    echo "Usage: wt <number>" >&2
    return 1
  fi
  local -a reply
  local -A worktrees
  # Arithmetic drops leading zeros, so `wt 02` finds the key `2`
  local -i number=$1
  local worktree_path
  _wt_numbered
  if (( $#reply == 0 )); then
    echo "wt: no worktrees found (are you in a git repo?)" >&2
    return 1
  fi
  worktrees=("${reply[@]}")
  worktree_path=${worktrees[$number]-}
  if [[ -z "$worktree_path" ]]; then
    echo "Worktree $1 not found (run wtl to list them)" >&2
    return 1
  fi
  if [[ ! -d "$worktree_path" ]]; then
    echo "Worktree $1 is listed but its directory is gone: $worktree_path" >&2
    return 1
  fi
  cd -- "$worktree_path" || return
}

# List all worktrees with the numbers `wt` takes, in number order
wtl() {
  emulate -L zsh
  local -a reply lines
  local -A by_number
  local -i i
  local number
  _wt_numbered
  (( $#reply )) || return 1
  lines=("${(@f)$(git worktree list)}")
  if (( $#lines * 2 != $#reply )); then
    echo "wtl: the worktrees changed while listing them; run it again" >&2
    return 1
  fi
  for (( i = 1; i <= $#lines; i++ )); do
    by_number[${reply[2 * i - 1]}]=${lines[i]}
  done
  # The same layout as `nl`
  for number in ${(on)${(k)by_number}}; do
    printf '%6d\t%s\n' "$number" "${by_number[$number]}"
  done
}
