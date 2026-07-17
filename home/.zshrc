#!/bin/bash

# Configure oh-my-zsh updates (once per day)
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 1
zstyle ':omz:update' verbosity default

# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

alias e='exec'
alias ta='tmux -2 attach || tn'
alias be="bundle exec"
alias bi="bundle install -j 8"
alias bo="bundle outdated"
alias bu="bundle update"
alias vim='mvim -v'
alias rrr="bin/rspec"
alias rrrore="bin/rspec spec --tag @open_source_risk --tag @flaky --format documentation --format RSpec::Instafail"
alias rrroresys="bin/rspec spec/system --tag @open_source_risk --tag @flaky --format documentation --format RSpec::Instafail"
alias puma="bin/puma -C config/puma.rb"
alias resetdb='bin/rails db:drop db:create db:migrate db:test:prepare'
alias rbc="bin/rubocop"
alias rbca="bin/rubocop -A"
alias rbctodo="bundle exec rubocop --regenerate-todo"
alias hltodo="haml-lint --auto-gen-config --auto-gen-exclude-limit 1000"
alias dbm="bin/rails db:migrate"
alias dbms="bin/rails db:migrate:status"
alias ci="bin/rake ci"
alias tp="bin/rails db:test:prepare"
alias tcac="bin/rails tmp:clear assets:clobber"
alias r="bin/rails"
alias bd="bin/dev"
alias vallog="tail -f log/valuations.log"
alias yo="yarn upgrade-interactive"

# Git worktrees - navigate by number (e.g., wt 1, wt 2)
# Run from any worktree to switch between them
wt() {
  local worktree_path
  worktree_path=$(git worktree list 2>/dev/null | sed -n "${1}p" | awk '{print $1}')
  if [[ -n "$worktree_path" ]]; then
    cd "$worktree_path" || return
  else
    echo "Worktree $1 not found (are you in a git repo with worktrees?)"
  fi
}

# List all worktrees with numbers
alias wtl='git worktree list | nl'

# Docker
alias dc='docker compose'
alias dcb='docker compose build'
# docker compose build --progress=plain --no-cache # to view output of RUN commands
alias dcsp='docker compose run --service-ports --rm web'
alias dcspr='docker compose run --service-ports --rm web bin/rspec'
alias dockercleancontainers="docker ps -aq | xargs docker rm"
alias dockercleanimages="docker images -aq -f dangling=true | xargs docker rmi"
# docker system prune --all
# docker volumes ls
alias dockerclean="dockercleancontainers && dockercleanimages"
alias docker-killall="docker ps -q | xargs docker kill"
alias dc-es="docker compose up -d docker_elasticsearch"

# GitHub
# List open PRs with merge conflicts. PR numbers are OSC 8 hyperlinks
# (clickable in modern terminals). Optional first arg overrides the default
# fetch limit of 500.
pr-conflicts() {
  local limit=${1:-500}
  local esc=$'\033'
  gh pr list --limit "$limit" \
      --json number,title,headRefName,mergeStateStatus,url \
    | jq -r --arg esc "$esc" '
        .[]
        | select(.mergeStateStatus == "DIRTY")
        | "\($esc)]8;;\(.url)\($esc)\\#\(.number)\($esc)]8;;\($esc)\\\t\(.headRefName)\t\(.title)"
      '
}

# Homebrew
alias bdi="brew deps --tree --installed"
alias bubo="brew update && brew outdated"
alias brewup="HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade && brew cleanup && brew autoremove && brew doctor"
# Consider using `brew cleanup --prune=all --dry-run`
# See https://mac.install.guide/homebrew/8


# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Disable oh-my-zsh's default auto-title so our precmd/preexec hooks own it
DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git rails docker vi-mode mise z gh bundler)

source $ZSH/oh-my-zsh.sh

### Added by the Heroku Toolbelt
export PATH="/opt/homebrew/heroku/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$PATH:/opt/homebrew/sbin"
eval "$(rbenv init -)"

# Set editor to Vim
export EDITOR="mvim -v"

# Instruct ruby-build to enable the YJIT compiler
export RUBY_CONFIGURE_OPTS="--enable-yjit"
# Enable YJIT
export RUBY_YJIT_ENABLE=1

# Make postgresql@18 available in the PATH
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# Added by Claude Code
export PATH="$HOME/.local/bin:$PATH"

# Fix Ruby Debug from hanging when using save_and_open_screenshot
export RUBY_DEBUG_FORK_MODE="parent"

# iTerm2 tab title: publish shell state (dir) as an iTerm2 user variable and
# seed session.autoName with the current git branch so idle tabs show the
# branch; child processes (Claude Code, vim, ssh) overwrite autoName with
# their own titles while running. Configure iTerm2 profile Title → Custom:
#   \(session.autoName) · \(user.dir)
# Ordering matters because iTerm2 truncates from the right — the leftmost
# token carries the most distinguishing info when many tabs are open.
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

# Fallback title for processes that don't emit their own OSC title.
# Claude Code, vim with titlestring, ssh, tmux, etc. will overwrite this
# almost immediately, which is what we want.
_tab_title_running() { printf '\e]1;▶ %s\a' "$1" }

autoload -Uz add-zsh-hook
add-zsh-hook precmd _tab_title_idle
add-zsh-hook preexec _tab_title_running

# Note: these must be placed at the bottom of .zshrc
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
