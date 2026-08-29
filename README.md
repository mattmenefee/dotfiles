# dotfiles

Personal macOS development environment managed with [Homesick][homesick_link]. Configures Zsh (with
[Oh My Zsh][oh_my_zsh_link]), Vim via [Vundle][vundle_link], [tmux][tmux_link], Ruby development
tools via [rbenv][rbenv_link], and a curated set of [Homebrew][homebrew_link] packages for web
development. Uses [mise][mise_link] for managing non-Ruby tool versions.

tmux key bindings and options are documented inline in `home/.tmux.conf`.

## Getting Started

1. Install [Homebrew][homebrew_link]

1. Install [rbenv][rbenv_link] and the [rbenv-default-gems][rbenv_default_gems_link] plugin

    Homesick is a Ruby gem and recent versions of macOS no longer ship a system Ruby, so rbenv
    comes first. The Brewfile installs it too, but `brew bundle` cannot run before this repository
    is on disk.

    The plugin installs a fixed list of gems into every Ruby that rbenv builds. Homesick is on that
    list, so setting the plugin up now is what lets the Ruby in step 4 arrive with Homesick already
    installed. Cloning it needs no Ruby of its own:

    ```shell
    brew install rbenv ruby-build

    # `.zshrc` in this repository already runs `rbenv init`. Rather than let rbenv write to the
    # `.zshrc` that Homesick is about to replace, just load rbenv into the current shell:
    eval "$(rbenv init - zsh)"

    git clone https://github.com/rbenv/rbenv-default-gems.git "$(rbenv root)/plugins/rbenv-default-gems"
    ```

1. Clone this repository and point the plugin at its gem list

    `homesick clone` would normally do the first line, but Homesick is exactly the gem that does
    not exist yet. Plain `git` is the way out of that loop, and cloning into `~/.homesick/repos` is
    all `homesick clone` does anyway — step 5 picks the castle up from there.

    ```shell
    git clone https://github.com/mattmenefee/dotfiles.git ~/.homesick/repos/dotfiles

    mkdir -p "$(rbenv root)"
    ln -s ~/.homesick/repos/dotfiles/home/.rbenv/default-gems "$(rbenv root)/default-gems"
    ```

    The symlink has to exist before the next step. `home/.rbenv/default-gems` is the list the
    plugin reads, and the plugin skips silently when that file is missing — a Ruby installed
    without it looks like a normal success and simply has none of the gems.

1. Install Ruby

    ```shell
    rbenv install -l # list all available versions
    rbenv install [version]
    rbenv global [version] # set global Ruby version
    ```

    Everything in `home/.rbenv/default-gems` lands in the new Ruby as part of that install —
    Homesick, gem_updater, mailcatcher, awesome_print and ruby-lsp — so none of them needs
    installing by hand, and every Ruby installed later gets the same set.

1. Symlink the dotfiles

    ```shell
    homesick link dotfiles
    ```

    Homesick does not recognize a symlink that already points where it belongs, so it reports
    `conflict ~/.rbenv/default-gems exists` and prompts to overwrite. Answer `n`: that is the link
    from step 3, and it is already correct.

1. Install tools managed by Homebrew

    The Brewfile installs the CircleCI CLI from a third-party tap, which Homebrew's cask-trust gate
    blocks until it is explicitly trusted. Run the one-time `brew trust` first, then
    [`brew bundle`][brew_bundle_link]:

    ```shell
    cd ~/.homesick/repos/dotfiles/
    brew trust --cask circleci-public/circleci/circleci@next
    brew bundle
    ```

    Ruby versions are managed with rbenv. Other tool versions (e.g., Ansible, Terraform) are managed
    with [mise][mise_link], which is installed via Homebrew and activated through the Oh My Zsh
    `mise` plugin.

1. Start the database services

    ```shell
    brew services start postgresql@18
    brew services start redis
    ```

    `postgresql@18` is a versioned formula, so Homebrew keeps it keg-only and does not symlink its
    binaries into the prefix. That is why `.zshrc` puts `/opt/homebrew/opt/postgresql@18/bin` on
    `PATH` explicitly, and why `psql` only resolves once the dotfiles are linked.

1. Update RubyGems

    ```shell
    gem update --system
    ```

1. Install [Oh My Zsh][oh_my_zsh_link]

    ```shell
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ```

    The following Oh My Zsh plugins are enabled in `.zshrc`:

    | Plugin | Source | Description |
    | ------ | ------ | ----------- |
    | [git][omz_git] | built-in | Git aliases and helper functions |
    | [rails][omz_rails] | built-in | Rails command aliases |
    | [docker][omz_docker] | built-in | Docker completions |
    | [vi-mode][omz_vimode] | built-in | Vim keybindings in the shell |
    | [mise][omz_mise] | built-in | Activates [mise][mise_link] for version management |
    | [z][omz_z] | built-in | Jump to frequently used directories (e.g., `z dotfiles`) |
    | [gh][omz_gh] | built-in | GitHub CLI completions |
    | [bundler][omz_bundler] | built-in | Runs bundled commands via `bundle exec`; adds `be`, `bi`, `bl`, `bp`, `bu` |

    Two additional Zsh plugins are installed via Homebrew (included in the Brewfile) and sourced at
    the bottom of `.zshrc`:

    - **[zsh-syntax-highlighting][zsh_sh_link]** — highlights commands as you type
    - **[zsh-autosuggestions][zsh_as_link]** — suggests commands from history as you type

1. Select the iTerm2 profile

    `homesick link` puts a dynamic profile at
    `~/Library/Application Support/iTerm2/DynamicProfiles/main.json`. iTerm2 reads that directory
    at launch and again whenever a file in it changes, so the profile shows up with no import
    step — but it does not become the default on its own.

    **Settings → Profiles**, select **Matt (dotfiles)**, then **Other Actions… → Set as Default**.

    Dynamic profiles are read-only in iTerm2's UI. Changing one means editing `main.json` in this
    repository, which is the point of keeping it here rather than in iTerm2's own preferences.

1. Install [Vundle][vundle_link] and run the Vim plugin installer

    Vundle is not itself installed by Vundle: `.vimrc` adds `~/.vim/bundle/Vundle.vim` to the
    runtime path and calls into it, so that clone has to exist before Vim can install anything.

    ```shell
    git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

    cd ~/.homesick/repos/dotfiles
    zsh init.zsh
    ```

    This installs Vundle plugins for MacVim. Neovim is in the Brewfile but is not configured here.

1. Set up Git config

    `home/.gitconfig` carries no `[user]` section on purpose — it ends with an include instead:

    ```gitconfig
    [include]
      path = ~/.gitconfig.local
    ```

    The identity belongs in that file, which this repository does not track. `git config --global`
    would put it in `~/.gitconfig`, and Homesick has symlinked that to the tracked copy: Git
    resolves the symlink and writes the name and email into this public repository. Name the
    include file explicitly instead:

    ```shell
    # Insert appropriate values
    git config --file ~/.gitconfig.local user.name "$GIT_AUTHOR_NAME"
    git config --file ~/.gitconfig.local user.email "$GIT_AUTHOR_EMAIL"
    ```

    GitHub Desktop writes the same two settings the same wrong way from its first-run **Configure
    Git** screen, prefilled from the signed-in account and without asking. Skip that screen, or undo
    it afterwards — a `[user]` section appended to `home/.gitconfig` is what it leaves behind, and a
    `git diff` in the castle is where it surfaces:

    ```shell
    cd ~/.homesick/repos/dotfiles/
    git diff home/.gitconfig    # a [user] section here is the identity that should have gone local
    git restore home/.gitconfig # discard it; re-run the `--file` commands above
    ```

1. Set up an SSH key and `~/.ssh/config`

    Neither the key nor `~/.ssh/config` is tracked here. A private key never belongs in a
    repository, and the config names one machine's key paths, so both stay local.

    ```shell
    # Insert appropriate value
    ssh-keygen -t ed25519 -C "$GIT_AUTHOR_EMAIL"
    ```

    `~/.ssh/config` is what keeps the passphrase from coming back after every reboot. `UseKeychain`
    reads it from the macOS Keychain instead of prompting, and `AddKeysToAgent` loads the key into
    the agent the first time something needs it:

    ```ssh-config
    Host github.com
      AddKeysToAgent yes
      UseKeychain yes
      IdentityFile ~/.ssh/id_ed25519
    ```

    ```shell
    # Store the passphrase in the Keychain, which is what UseKeychain then reads
    ssh-add --apple-use-keychain ~/.ssh/id_ed25519

    # Upload the public key to GitHub and confirm it authenticates
    gh ssh-key add ~/.ssh/id_ed25519.pub --title "$(scutil --get ComputerName)"
    ssh -T git@github.com
    ```

    `gh ssh-key add` needs the `admin:public_key` scope, which `gh auth login` does not request by
    default — `gh auth refresh -h github.com -s admin:public_key` adds it to an existing login.

    A successful `ssh -T` greets you by name and **exits 1**, because GitHub never gives the
    connection a shell. That is the expected result, not a failure.

    Git operations stay on HTTPS: `.config/gh/config.yml` sets `git_protocol: https`, `.gitconfig`
    sets `credential.helper = osxkeychain` to go with it, and Homesick clones over HTTPS too. The
    key is for the things that want SSH regardless — other hosts, deploy access, signing.

1. Store secrets in the macOS Keychain

    `.zshrc` is committed to this public repository, so secrets are never exported inline. Each one
    is stored in the Keychain and read back at shell startup, which keeps the lookup safe to publish
    while the value stays on the machine.

    ```shell
    # Insert appropriate values
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$USER" -w "$SECRET"
    ```

    The matching export in `.zshrc` names the service literally, and redirects stderr so that a
    machine which has not stored the secret yet still opens shells without an error:

    ```shell
    export ROLLBAR_ACCESS_TOKEN="$(security find-generic-password -s rollbar-mcp -w 2>/dev/null)"
    ```

    | Variable | Keychain service | Used by |
    | -------- | ---------------- | ------- |
    | `ROLLBAR_ACCESS_TOKEN` | `rollbar-mcp` | Rollbar MCP server in Claude Code |

    These lookups run only for interactive shells, because `.zshrc` is where they live. An
    application launched from the Dock rather than a terminal does not inherit them.

## Updating

```shell
# Homebrew
brewup

# RubyGems
gem update --system

# Bundler
gem update bundler

# mise (non-Ruby tool versions)
mise self-update
mise upgrade

# Dotfiles via Homesick
homesick pull --all
homesick link --force dotfiles
```

`homesick pull` only fetches; it does not relink. A file added inside a directory that is already
symlinked, such as `home/.zsh`, appears with no further action — but a new top-level file does not,
and until the `link` run it is simply absent, with nothing to say why. `--force` is what makes the
run unattended: without it homesick prompts for every path that already exists. Those paths are
normally correct symlinks that it removes and recreates, but a real file left at a managed path
would be overwritten the same way.

Oh My Zsh is configured to auto-update daily via `zstyle` settings in `.zshrc`.

### Docker Desktop's `PATH` block

A Docker Desktop update may append this to `.zprofile`, `.bash_profile`, and `.profile` — all three
of which are tracked here:

```shell
# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/matt/.docker/bin"
# End of Docker Desktop section.
```

Delete it whenever it shows up in a diff. The block is inert, and it is wrong in this repository:

- The CLI tools are installed in **System** mode (see [Settings → Advanced][docker_settings_link]),
  which symlinks them into `/usr/local/bin`. Everything in `$HOME/.docker/bin` duplicates those
  symlinks.
- `/usr/local/bin` is the first entry in `/etc/paths`, and the block *appends* to `PATH`, so it
  could never win a lookup anyway — `command -v docker` resolves to `/usr/local/bin/docker`.
- The path is hardcoded to one absolute home directory, so it is wrong on any other machine these
  dotfiles are linked into.

Selecting **System** does not reliably prevent this: version 4.90.0 wrote the block during a
self-update with System already selected.

[homesick_link]: https://github.com/technicalpickles/homesick
[homebrew_link]: https://brew.sh/
[brew_bundle_link]: https://docs.brew.sh/Brew-Bundle-and-Brewfile
[rbenv_link]: https://github.com/rbenv/rbenv
[rbenv_default_gems_link]: https://github.com/rbenv/rbenv-default-gems
[vundle_link]: https://github.com/VundleVim/Vundle.vim
[tmux_link]: https://github.com/tmux/tmux
[mise_link]: https://mise.jdx.dev/
[docker_settings_link]: https://docs.docker.com/desktop/settings-and-maintenance/settings/
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
