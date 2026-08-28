# Shell
alias e='exec'
alias ta='tmux -2 attach || tn'
alias vim='mvim -v'

# Ruby
alias be="bundle exec"
alias bi="bundle install -j 8"
alias bo="bundle outdated"
alias bu="bundle update"

# Rails
alias r="bin/rails"
alias bd="bin/dev"
alias puma="bin/puma -C config/puma.rb"
alias resetdb='bin/rails db:drop db:create db:migrate db:test:prepare'
alias dbm="bin/rails db:migrate"
alias dbms="bin/rails db:migrate:status"
alias tp="bin/rails db:test:prepare"
alias tcac="bin/rails tmp:clear assets:clobber"
alias vallog="tail -f log/valuations.log"

# Testing
alias rrr="bin/rspec"
alias rrrore="bin/rspec spec --tag @open_source_risk --tag @flaky --format documentation --format RSpec::Instafail"
alias rrroresys="bin/rspec spec/system --tag @open_source_risk --tag @flaky --format documentation --format RSpec::Instafail"
alias ci="bin/rake ci"

# Linting
alias rbc="bin/rubocop"
alias rbca="bin/rubocop -A"
alias rbctodo="bundle exec rubocop --regenerate-todo"
alias hltodo="haml-lint --auto-gen-config --auto-gen-exclude-limit 1000"

# JavaScript
alias yo="yarn upgrade-interactive"

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

# Homebrew
alias bdi="brew deps --tree --installed"
alias bubo="brew update && HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew outdated"
alias brewup="brew update && HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade && brew cleanup && brew autoremove && brew doctor"

# Run occasionally: --greedy compares the Caskroom version stamp rather than the installed app
# bundle, so most of what it lists is stamp drift on apps that are already current. Read it and
# upgrade individually; it is not a work queue.
alias bubog="brew update && brew outdated --greedy"

# Consider using `brew cleanup --prune=all --dry-run`
# See https://mac.install.guide/homebrew/8
