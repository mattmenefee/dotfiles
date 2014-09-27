dotfiles
========

dotfiles managed using [homesick](https://github.com/technicalpickles/homesick).

### Installation

1. Setup homebrew
```bash
  $ ruby -e "$(curl -fsSkL raw.github.com/mxcl/homebrew/go)"
```

1. Install command-line tools using Homebrew and Brew-Cask
```bash
  $ brew bundle ~/Brewfile
  $ brew bundle ~/Caskfile
```

1. Setup homesick and symlick dotfiles:
```bash
  $ gem install homesick
  $ homesick clone mattmenefee/dotfiles
  $ homesick symlink dotfiles
```

1. Install Vundle
```bash
  $ cd ~/.dotfiles
  $ zsh init.zsh
```

1. Install default gems
```bash
  $ gem install bundler
  $ gem install awesome_print
  $ gem install proxylocal
```

1. Setup Git config
```bash
  # Insert appropriate values
  $ git config --global user.name "$GIT_AUTHOR_NAME"
  $ git config --global user.email "$GIT_AUTHOR_EMAIL"
```

### Updating

```bash
  # Homebrew
  $ brew update && brew upgrade brew-cask && brew cleanup && brew cask cleanup
  $ brew doctor && brew cask doctor

  # RubyGems
  $ gem update --system

  # Bundler
  $ gem update bundler
```
