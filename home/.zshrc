#!/bin/bash
# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"

# Example aliases
alias e='exec'
alias ta='tmux -2 attach || tn'
alias be="bundle exec"
alias bi="bundle install -j 8"
alias bo="bundle outdated"
alias bu="bundle update"
alias gg='git goggles'
alias vim='mvim -v'
alias dc='docker-compose'
alias dcsp='docker-compose run --service-ports --rm web'
alias dcspr='docker-compose run --service-ports --rm web bundle exec rspec'
alias dockercleancontainers="docker ps -aq | xargs docker rm"
alias dockercleanimages="docker images -aq -f dangling=true | xargs docker rmi"
alias dockerclean="dockercleancontainers && dockercleanimages"
alias docker-killall="docker ps -q | xargs docker kill"
alias rrr="bin/rspec"
alias puma="bin/puma -C config/puma.rb"
alias cuc="bin/cucumber"
alias subl="/Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl"
alias reset_dev_db='bin/rails db:drop db:create db:migrate db:test:prepare'
alias rbc="bin/rubocop"
alias dbm="bin/rails db:migrate"
alias ci="bin/rake ci"
alias tp="bin/rails db:test:prepare"

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
plugins=(git zsh-syntax-highlighting rails docker vi-mode)

source $ZSH/oh-my-zsh.sh

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$PATH:/usr/local/sbin"
eval "$(rbenv init -)"

### Set up Go
export GOPATH="$HOME/code/gopath"

# Set editor to Vim
export EDITOR="mvim -v"

# Export the Docker environment variables to the shell
# eval "$(docker-machine env default)"

# Use overcommit for all repositories created/cloned going forward
GIT_TEMPLATE_DIR=$(overcommit --template-dir)
export GIT_TEMPLATE_DIR
