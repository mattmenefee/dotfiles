# dotfiles

dotfiles managed using [homesick][homesick_link].

## Getting Started

1. Install [Homebrew][homebrew_link] and
  [homebrew-bundle][brew_bundle_link] ([tips][brewfile_tips_link])

1. Install [rbenv][rbenv_link] and
  [rbenv-default-gems][rbenv_default_gems_link] plugin

    ```shell
    $ brew install rbenv ruby-build
    $ rbenv init # See rbenv Readme for why this is necessary

    # Set up the rbenv-default-gems plugin
    $ git clone https://github.com/rbenv/rbenv-default-gems.git $(rbenv root)/plugins/rbenv-default-gems

    $ rbenv install -l # list all available versions
    $ rbenv install [version]
    # Restart shell for changes with $PATH to take effect
    $ rbenv global [version] # set global Ruby version
    ```

1. Update Rubygems

    ```shell
    $ gem update --system
    ```

1. Install homesick and symlick dotfiles:

    ```shell
    $ homesick clone mattmenefee/dotfiles
    $ homesick link dotfiles
    ```

1. Install tools managed by Homebrew

    ```shell
    $ cd ~/.homesick/repos/dotfiles/
    $ brew bundle
    ```

1. Install [Vundle][vundle_link]

1. Install [oh-my-zsh][oh_my_zsh_link]

    ```shell
    $ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

1. Set up zsh

    ```shell
    $ cd ~/.homesick/repos/dotfiles
    $ zsh init.zsh
    ```

1. Set up Git config

    ```shell
    # Insert appropriate values
    $ git config --global user.name "$GIT_AUTHOR_NAME"
    $ git config --global user.email "$GIT_AUTHOR_EMAIL"
    ```

## Updating

```shell
# Homebrew
$ brew update && brew outdated
$ brew upgrade && brew cleanup && brew doctor

# RubyGems
$ gem update --system

# Bundler
$ gem update bundler

# Dotfiles via Homesick
$ homesick pull --all
```

[homesick_link]: https://github.com/technicalpickles/homesick
[homebrew_link]: http://brew.sh/
[brew_bundle_link]: https://docs.brew.sh/Brew-Bundle-and-Brewfile
[brewfile_tips_link]: https://robots.thoughtbot.com/brewfile-a-gemfile-but-for-homebrew
[rbenv_link]: https://github.com/sstephenson/rbenv
[rbenv_default_gems_link]: https://github.com/rbenv/rbenv-default-gems
[vundle_link]: https://github.com/VundleVim/Vundle.vim
[oh_my_zsh_link]: https://ohmyz.sh/#install
