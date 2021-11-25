dotfiles
========

dotfiles managed using [homesick](https://github.com/technicalpickles/homesick).

### Getting Started

1. Install [Homebrew](http://brew.sh/) and [homebrew-bundle](https://github.com/Homebrew/homebrew-bundle) ([tips](https://robots.thoughtbot.com/brewfile-a-gemfile-but-for-homebrew))

1. Install [rbenv](https://github.com/sstephenson/rbenv)

    ```bash
    $ brew install rbenv ruby-build
    $ rbenv init # See rbenv Readme for why this is necessary

    $ rbenv install -l # list all available versions
    $ rbenv install [version]
    # Restart shell for changes with PATH to take effect
    $ rbenv global [version] # set global Ruby version
    ```

1. Update Rubygems

    ```bash
    $ gem update --system
    ```

1. Install homesick and symlick dotfiles:

    ```bash
    $ gem install homesick
    $ homesick clone mattmenefee/dotfiles
    $ homesick symlink dotfiles
    ```

1. Install tools managed by Homebrew

    ```bash
    $ cd ~/.homesick/repos/dotfiles/
    $ brew bundle
    ```

1. Install Vundle

    ```bash
    $ cd ~/.homesick/repos/dotfiles
    $ zsh init.zsh
    ```

1. Install default gems

    ```bash
    $ gem install gem_updater
    $ gem install mailcatcher
    $ gem install awesome_print
    $ gem install proxylocal
    ```

1. Set up Git config

    ```bash
    # Insert appropriate values
    $ git config --global user.name "$GIT_AUTHOR_NAME"
    $ git config --global user.email "$GIT_AUTHOR_EMAIL"
    ```

### Updating

```bash
# Homebrew
$ brew update && brew outdated
$ brew upgrade && brew cleanup
$ brew doctor

# RubyGems
$ gem update --system

# Bundler
$ gem update bundler

# Dotfiles via Homesick
$ homesick pull --all
```
