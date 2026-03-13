# dotfiles

dotfiles managed using [homesick][homesick_link].

## Getting Started

1. Install [Homebrew][homebrew_link] and
  [homebrew-bundle][brew_bundle_link]

1. Install homesick and symlink dotfiles:

    ```shell
    $ homesick clone mattmenefee/dotfiles
    $ homesick link dotfiles
    ```

1. Install tools managed by Homebrew

    ```shell
    $ cd ~/.homesick/repos/dotfiles/
    $ brew bundle
    ```

1. Set up [rbenv][rbenv_link] and
  [rbenv-default-gems][rbenv_default_gems_link] plugin

    ```shell
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

1. Install [oh-my-zsh][oh_my_zsh_link]

    ```shell
    $ sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

    The following oh-my-zsh plugins are enabled in `.zshrc`:

    | Plugin | Source | Description |
    |--------|--------|-------------|
    | [git][omz_git] | built-in | Git aliases and completions |
    | [rails][omz_rails] | built-in | Rails command aliases |
    | [docker][omz_docker] | built-in | Docker completions |
    | [vi-mode][omz_vimode] | built-in | Vim keybindings in the shell |
    | [mise][omz_mise] | built-in | Activates [mise][mise_link] for version management |
    | [z][omz_z] | built-in | Jump to frequently used directories (e.g., `z dotfiles`) |
    | [gh][omz_gh] | built-in | GitHub CLI completions |
    | [bundler][omz_bundler] | built-in | Auto-prefixes gem commands with `bundle exec` |

    Two additional zsh plugins are installed via Homebrew (included in the
    Brewfile) and sourced at the bottom of `.zshrc`:

    - **[zsh-syntax-highlighting][zsh_sh_link]** — highlights commands as you type
    - **[zsh-autosuggestions][zsh_as_link]** — suggests commands from history as you type

1. Install [Vundle][vundle_link] and run the plugin installer

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
# Homebrew (or use the `brewup` alias defined in .zshrc)
$ brew upgrade && brew cleanup && brew autoremove && brew doctor

# RubyGems
$ gem update --system

# Bundler
$ gem update bundler

# Dotfiles via Homesick
$ homesick pull --all
```

oh-my-zsh is configured to auto-update daily via `zstyle` settings in `.zshrc`.

[homesick_link]: https://github.com/technicalpickles/homesick
[homebrew_link]: https://brew.sh/
[brew_bundle_link]: https://docs.brew.sh/Brew-Bundle-and-Brewfile
[rbenv_link]: https://github.com/rbenv/rbenv
[rbenv_default_gems_link]: https://github.com/rbenv/rbenv-default-gems
[vundle_link]: https://github.com/VundleVim/Vundle.vim
[mise_link]: https://mise.jdx.dev/
[omz_bundler]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/bundler
[omz_docker]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker
[omz_gh]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/gh
[omz_git]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git
[omz_mise]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/mise
[omz_rails]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/rails
[omz_vimode]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/vi-mode
[omz_z]: https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/z
[oh_my_zsh_link]: https://ohmyz.sh/#install
[zsh_as_link]: https://github.com/zsh-users/zsh-autosuggestions
[zsh_sh_link]: https://github.com/zsh-users/zsh-syntax-highlighting
