# Instructions: run using "brew bundle"

# Terminal tools
cask 'iterm2'
brew 'bash'
brew 'macvim'
brew 'neovim'
brew 'the_silver_searcher'
brew 'tmux'
brew 'zsh'
brew 'zsh-autosuggestions'
brew 'zsh-syntax-highlighting'

# Web Development tools
cask 'firefox'
cask 'tableplus'
cask 'miro'
cask 'zeplin'
cask 'zed'

# MacOS interface management tools
cask 'raycast'
cask 'rectangle'
cask 'caffeine'
brew 'mole' # for deep cleaning and optimizing your Mac

# Programming languages and related tools
brew 'rust' # for running Ruby with the YJIT compiler
brew 'rbenv'
brew 'ruby-build'
brew 'node'
brew 'uv' # Python package installer, runner, and virtualenv manager

# Version Control tools
brew 'git'
brew 'gh' # for the GitHub CLI
brew 'git-lfs' # .gitconfig sets `required = true`, so LFS repos fail to check out without it
cask 'github'

# Continuous Integration tools
# Requires a one-time `brew trust --cask circleci-public/circleci/circleci@next`
# before `brew bundle`
tap 'circleci-public/circleci'
cask 'circleci-public/circleci/circleci@next' # CircleCI CLI (preview build)

# Databases
brew 'sqlite'
brew 'redis'
brew 'postgresql@18'
brew 'pgcli'

# Container tools
# If /Applications/Docker.app already exists outside Homebrew's Caskroom, `brew bundle` adopts it:
# it backs the bundle up, removes the original, then writes a Spotlight attribute onto the bundled
# `kubectl`. That write needs App Management, which a terminal lacks by default (`sudo` does not
# help — macOS checks the responsible application, not the uid), and the failure cleanup purges the
# backup too. Recover with `brew install --cask docker-desktop`; images and volumes are untouched.
cask 'docker-desktop'

# Image processing tools
brew 'vips' # the Rails v7 default for image processing
brew 'poppler' # for creating PDF previews

# Hosting tools
brew 'heroku'

# Infrastructure management tools
brew 'ansible'
brew 'mise'
brew 'yq' # YAML processor (like jq for YAML)
brew 'awscli' # for S3-compatible object storage, e.g. DigitalOcean Spaces
cask 'tailscale-app' # Mesh VPN; the `tailscale` formula is the headless daemon, not the macOS app

# For the Open Source Risk Engine (ORE)
brew 'cmake'
brew 'ninja' # Use Ninja for cmake
brew 'boost'
brew 'swig'
brew 'eigen'

# For linting
brew 'hadolint' # Dockerfile linter
brew 'yamllint'
brew 'ansible-lint'
brew 'shellcheck'
brew 'shfmt' # Autoformat shell script source code

# Other programs
cask 'basictex'
cask 'calibre'
cask 'typora'
cask 'zoom'
cask 'cleanmymac'

# For Claude Code
brew 'gum' # Interactive terminal UI for multi-select menus in Claude Code commands

