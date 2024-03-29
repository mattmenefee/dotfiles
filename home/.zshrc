#!/bin/bash
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
alias dc='docker-compose'
alias dcb='docker-compose build'
alias dcsp='docker-compose run --service-ports --rm web'
alias dcspr='docker-compose run --service-ports --rm web bin/rspec'
alias dockercleancontainers="docker ps -aq | xargs docker rm"
alias dockercleanimages="docker images -aq -f dangling=true | xargs docker rmi"
alias dockerclean="dockercleancontainers && dockercleanimages"
alias docker-killall="docker ps -q | xargs docker kill"
alias rrr="bin/rspec"
alias rrrore="bin/rspec spec --tag @open_source_risk --format documentation --format RSpec::Instafail"
alias rrroresys="bin/rspec spec/system --tag @open_source_risk --format documentation --format RSpec::Instafail"
alias puma="bin/puma -C config/puma.rb"
alias resetdb='bin/rails db:drop db:create db:migrate db:test:prepare'
alias rbc="bin/rubocop"
alias rbca="bin/rubocop -A"
alias rbctodo="bin/rubocop --regenerate-todo"
alias dbm="bin/rails db:migrate"
alias ci="bin/rake ci"
alias tp="bin/rails db:test:prepare"
alias bdi="brew deps --tree --installed"
alias bubo="brew update && brew outdated"
alias bubcbd="brew upgrade && brew cleanup && brew doctor"
alias r="bin/rails"
alias vallog="tail -f log/valuations.log"
alias yo="yarn outdated"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how many often would you like to wait before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git rails docker vi-mode asdf)

source $ZSH/oh-my-zsh.sh

### Added by the Heroku Toolbelt
export PATH="/opt/homebrew/heroku/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$PATH:/opt/homebrew/sbin"
eval "$(rbenv init -)"

# Set editor to Vim
export EDITOR="mvim -v"

# Temporarily prevent Ruby deprecation warnings from showing while we adjust to Ruby 2.7
export RUBYOPT="-W:no-deprecated"

# ruby-build installs a non-Homebrew OpenSSL for each Ruby version installed and these are never upgraded.
# To link Rubies to Homebrew's OpenSSL 1.1 (which is upgraded) add the following
# to your ~/.zshrc:
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"

# Use overcommit for all repositories created/cloned going forward
GIT_TEMPLATE_DIR=$(overcommit --template-dir)
export GIT_TEMPLATE_DIR

# Make postgresql@16 available in the PATH
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

# Note: this must be placed at the bottom of .zshrc
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
