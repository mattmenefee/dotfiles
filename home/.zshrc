#!/bin/zsh

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

# Autoload functions from ~/.zsh/functions, ahead of the compinit that oh-my-zsh runs. Each is
# named rather than globbed out of the directory: autoload takes the name from an absolute path's
# basename, and zsh resolves functions before external commands, so a glob would make any file
# landing in there a live command — one named `git` would shadow the real binary.
typeset -U fpath
fpath=(~/.zsh/functions $fpath)
# Note the braces: zsh leaves a single-element `{sysdoc}` literal and the autoload silently fails,
# so if this list ever shrinks back to one name the braces have to come off
autoload -Uz ~/.zsh/functions/{pr-conflicts,sysdoc}

# Sourced, not autoloaded: these four functions share a private helper, and anything in fpath
# becomes a live command name
source ~/.zsh/worktree.zsh

source ~/.zsh/aliases.zsh

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git rails docker vi-mode mise z gh bundler)

source $ZSH/oh-my-zsh.sh

# Mole shell completion. Must follow oh-my-zsh.sh, which runs compinit.
if output="$(mole completion zsh 2>/dev/null)"; then eval "$output"; fi

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

# Rollbar MCP server, read from the Keychain so the token stays out of this repo
export ROLLBAR_ACCESS_TOKEN="$(security find-generic-password -s rollbar-mcp -w 2>/dev/null)"

source ~/.zsh/iterm2-tab-title.zsh

# Note: these must be placed at the bottom of .zshrc
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
