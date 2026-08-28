# Stops oh-my-zsh's own auto-title from fighting the hooks below. oh-my-zsh reads this inside
# omz_termsupport_precmd and omz_termsupport_preexec rather than at load time, so it does not have
# to precede `source $ZSH/oh-my-zsh.sh` — it only has to be set before the first prompt. That is
# what lets it sit with the hooks it exists to serve, and what makes the two removable together.
DISABLE_AUTO_TITLE="true"

# iTerm2 tab title: publish shell state (dir) as an iTerm2 user variable and seed session.autoName
# with the current git branch so idle tabs show the branch; child processes (Claude Code, vim, ssh)
# overwrite autoName with their own titles while running. Configure iTerm2 profile Title → Custom:
#   \(session.autoName) · \(user.dir)
# Ordering matters because iTerm2 truncates from the right — the leftmost token carries the most
# distinguishing info when many tabs are open.
_set_iterm2_user_var() {
  local b64
  b64=$(printf '%s' "$2" | base64 | tr -d '\n')
  printf '\e]1337;SetUserVar=%s=%s\a' "$1" "$b64"
}

_tab_title_idle() {
  local branch dir
  branch=$(git branch --show-current 2>/dev/null)
  [[ -z $branch ]] && branch=$(git rev-parse --short HEAD 2>/dev/null)
  [[ -z $branch ]] && branch="no-git"
  dir=${${PWD/#$HOME/~}:t}
  _set_iterm2_user_var dir "$dir"
  printf '\e]1;%s\a' "$branch"
}

# Fallback title for processes that don't emit their own OSC title. Claude Code, vim with
# titlestring, ssh, tmux, etc. will overwrite this almost immediately, which is what we want.
_tab_title_running() { printf '\e]1;▶ %s\a' "$1" }

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tab_title_idle
add-zsh-hook preexec _tab_title_running
