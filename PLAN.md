# NeoVim Migration Plan

Migration from MacVim + Vundle + Vimscript to Neovim with its native
conventions and ecosystem. Phased to allow stopping at any phase boundary and
still having a working editor.

Scope: `home/.vimrc`, `home/.config/nvim/`, `Brewfile`, `init.zsh`, `.zshrc`
alias, and `README.md`.

---

## Phase 1 — Minimum cutover (this PR)

**Goal:** Stop launching MacVim. Start launching Neovim. Keep every plugin,
keybinding, and behavior identical. No Lua, no plugin manager changes, no
linter changes.

**Also addresses:** [#64][issue-64] (undodir workaround cleanup) by dropping
the explicit `undodir`/`mkdir` block — Neovim defaults to
`~/.local/state/nvim/undo//`, which is outside the homesick castle and
auto-created.

### Changes

1. Create `home/.config/nvim/init.vim` containing the full former `.vimrc`
   contents, **minus** the `undodir` block.
   - First line: `set runtimepath^=~/.vim runtimepath+=~/.vim/after` so Vundle
     continues finding `~/.vim/bundle/`.
   - Second line: `let &packpath = &runtimepath`.
2. Delete `home/.vimrc` entirely (no MacVim fallback to maintain).
3. Update `home/.zshrc` alias: `alias vim='nvim'` (was `alias vim='mvim -v'`).
4. Update `init.zsh` bootstrap: `nvim +PluginInstall +qall` (was
   `vim +BundleInstall +qall`).
5. Remove `brew 'macvim'` from `Brewfile`.
6. Update `README.md`:
   - Replace "Vim via Vundle" framing with "Neovim via Vundle (transitional)".
   - Update the bootstrap step that says "installs Vundle plugins for MacVim".

### Manual cleanup (per-machine, not in repo)

- [ ] `rm -rf ~/.vim/undo` (the workaround directory from #63 is no longer
      written to)
- [ ] `brew uninstall macvim` after confirming the alias swap works
- [ ] Verify `homesick link dotfiles` produces no `.un~` symlinks on a fresh
      run (closes #64)

### Acceptance

- `nvim` opens with all 30+ plugins loaded from `~/.vim/bundle/`
- `vim` alias resolves to `nvim`
- No `.un~` files appear next to source files in the castle
- README accurately describes the current state

---

## Phase 2 — Neovim-compat hygiene (small, opportunistic)

**Goal:** Remove Vim-only quirks that are no-ops or warnings under Neovim.
Tiny PR, mechanical changes.

### Changes

- Remove `set pastetoggle=<F2>` — Neovim handles paste automatically via
  bracketed-paste and the option is deprecated.
- Remove the explicit `set nocompatible` (Neovim is always non-compatible).
- Audit `set rtp+=~/.vim/bundle/Vundle.vim` and the `vundle#begin()` call —
  these still work but flag for Phase 3.
- Remove `Plugin 'matchit.zip'` — Neovim ships matchit and loads it
  automatically.

### Acceptance

- `nvim --headless +qall` produces no deprecation warnings related to our
  config

---

## Phase 3 — Plugin manager: Vundle → lazy.nvim

**Goal:** Replace Vundle. This is the **foundational phase** for everything
that comes after, because most modern Neovim plugins assume a Lua-capable
manager (lazy.nvim, packer.nvim, etc.).

### Why lazy.nvim

- De-facto standard in 2025; actively maintained
- Lazy-loads by default → faster startup
- Lockfile (`lazy-lock.json`) → reproducible installs
- UI for plugin management (`:Lazy`)

### Changes

- Bootstrap `lazy.nvim` into `~/.local/share/nvim/lazy/lazy.nvim` from
  `init.vim` (the bootstrap snippet from lazy.nvim docs).
- Convert every `Plugin '...'` line to a `lazy.nvim` spec in a new
  `home/.config/nvim/lua/plugins.lua` (still keep `init.vim` as entry point —
  Lua conversion comes in Phase 7).
- Drop `Plugin 'VundleVim/Vundle.vim'` and the `call vundle#begin()` /
  `call vundle#end()` block.
- Remove the `~/.vim/bundle/` directory and the `set rtp+=~/.vim/...` line.
- Commit `lazy-lock.json` so machines stay in sync.
- Update `init.zsh`: `nvim --headless "+Lazy! sync" +qa`.
- Update `README.md` to describe lazy.nvim instead of Vundle.

### Plugins to drop during conversion

- `jQuery` — obsolete
- `Markdown` (vim-scripts version) — replace with `preservim/vim-markdown` or
  defer to treesitter in Phase 6
- `Rename` — vim-eunuch already provides `:Rename`
- `vim-coffee-script` — assess actual usage; likely dead

### Acceptance

- `~/.vim/bundle/` is gone
- `:Lazy` opens the management UI
- `lazy-lock.json` is committed
- Startup time measurable improvement (`nvim --startuptime /tmp/start.log`)

---

## Phase 4 — Diagnostics: syntastic → built-in LSP + nvim-lint

**Goal:** Replace synchronous, slow `syntastic` with Neovim's async-native
diagnostics stack.

### Why

- `syntastic` blocks the UI on save (it shells out and waits)
- Neovim has `vim.diagnostic` and `vim.lsp` built in since 0.5
- LSP gives go-to-definition, hover docs, rename, etc. — free upside

### Changes

- Add `neovim/nvim-lspconfig` and `williamboman/mason.nvim` for managing LSP
  servers
- Add `mfussenegger/nvim-lint` for the non-LSP linters you currently use via
  syntastic:
  - `eslint` (JS) → mostly replaced by `eslint-lsp` now
  - `scss_lint`, `haml_lint`, `pyyaml`, `language_check` → keep via nvim-lint
- Add `lewis6991/gitsigns.nvim` to replace `airblade/vim-gitgutter` (also
  async, with `vim.diagnostic`-style sign column)
- Remove `Plugin 'scrooloose/syntastic'` and `Plugin 'myint/syntastic-extras'`
- Remove all the `let g:syntastic_*` config blocks
- Configure LSP servers for the languages in your stack:
  - Ruby: `ruby_lsp` or `solargraph`
  - JS/TS: `ts_ls`
  - Terraform: `terraformls`
  - YAML: `yamlls`
  - Bash: `bashls`

### Acceptance

- Save no longer pauses
- `<leader>` diagnostic keymaps (jump to next error, hover, etc.) work
- `:LspInfo` shows attached servers for each language

---

## Phase 5 — File navigation and search

**Goal:** Replace tree/search plugins with their modern Neovim equivalents.

### Changes

- Replace `scrooloose/nerdtree` with `nvim-tree/nvim-tree.lua` OR
  `stevearc/oil.nvim` (oil.nvim is the modern choice — edits the filesystem
  as a buffer)
- Replace `rking/ag.vim` and `gabesoft/vim-ags` with
  `nvim-telescope/telescope.nvim` (live grep, file find, buffer list, LSP
  pickers)
- Switch `the_silver_searcher` (ag) → `ripgrep` (rg) in `Brewfile` —
  telescope and most modern tooling expect rg
- Update all `<Leader>s`, `<Leader>a`, `<Leader><Leader>a` mappings to call
  telescope pickers
- Update `let g:NERDTreeHijackNetrw=1`, `let NERDTreeShowHidden=1`, and the
  startup-NERDTree autocmd → equivalent nvim-tree/oil setup

### Acceptance

- `<Leader>s` on a word opens telescope grep results
- `<C-p>` or equivalent opens a fuzzy file picker
- Tree explorer of choice opens on startup

---

## Phase 6 — Treesitter + completion

**Goal:** Modern syntax highlighting and structural editing, plus real
completion.

### Changes

- Add `nvim-treesitter/nvim-treesitter` with parsers for: ruby, javascript,
  typescript, tsx, html, scss, yaml, markdown, lua, vim, vimdoc, bash,
  dockerfile, terraform, python
- Drop these syntax/ftplugin plugins (treesitter handles them):
  - `pangloss/vim-javascript`
  - `jelera/vim-javascript-syntax`
  - `mtscout6/vim-cjsx`
  - `mxw/vim-jsx` (and the `let g:jsx_ext_required = 0` line)
  - `vim-coffee-script` (if not already dropped)
- Add `hrsh7th/nvim-cmp` + sources (`cmp-nvim-lsp`, `cmp-buffer`, `cmp-path`)
  → replaces `ervandew/supertab`
- Add `nvim-treesitter/nvim-treesitter-textobjects` → richer text objects,
  may eventually replace `textobj-rubyblock`/`textobj-user`
- Optional: `windwp/nvim-autopairs` replacing `Raimondi/delimitMate`

### Acceptance

- Ruby/JS/etc. syntax highlighting visibly richer
- Tab triggers a completion menu sourced from LSP
- `:TSUpdate` keeps parsers fresh

---

## Phase 7 — Convert `init.vim` to `init.lua`

**Goal:** Pure Lua config. This is mostly mechanical translation, done last
so the previous phases stabilize first.

### Changes

- Create `home/.config/nvim/init.lua` and a `lua/` directory structure:
  ```
  home/.config/nvim/
    init.lua
    lua/
      options.lua      -- everything that was set xxx
      keymaps.lua      -- everything that was map/nnoremap/etc.
      autocmds.lua     -- everything that was autocmd
      plugins.lua      -- lazy.nvim spec (moved from Phase 3)
      lsp.lua          -- LSP config (moved from Phase 4)
    after/
      ftplugin/
        markdown.lua   -- replaces the inline au BufRead *.md blocks
        gitcommit.lua  -- replaces the inline gitcommit autocmd
  ```
- Delete `home/.config/nvim/init.vim`
- Use `vim.opt`, `vim.keymap.set`, `vim.api.nvim_create_autocmd` instead of
  their Vimscript equivalents
- Move filetype-specific behavior out of giant `au BufRead` blocks into
  `after/ftplugin/<lang>.lua` files (Neovim convention)

### Acceptance

- `home/.config/nvim/init.vim` no longer exists
- `:checkhealth` reports green across the board
- All keybindings still work

---

## Out of scope (intentionally)

- Replacing `tpope/vim-fugitive` (still the best git plugin; no compelling
  successor)
- Replacing `vim-rails`, `vim-eunuch`, `vim-abolish`, `vim-repeat`,
  `vim-endwise`, `vim-surround` (all still maintained by tpope and work
  natively in nvim)
- Replacing `thoughtbot/vim-rspec` — could move to `vim-test` or
  `nvim-neotest/neotest` in a future phase but not necessary

---

## Issue tracking

| Phase | Issue |
|-------|-------|
| 1 | [#67][issue-67] (also closes [#64][issue-64]) |
| 2 | [#68][issue-68] |
| 3 | [#69][issue-69] |
| 4 | [#70][issue-70] |
| 5 | [#71][issue-71] |
| 6 | [#72][issue-72] |
| 7 | [#73][issue-73] |

[issue-64]: https://github.com/mattmenefee/dotfiles/issues/64
[issue-67]: https://github.com/mattmenefee/dotfiles/issues/67
[issue-68]: https://github.com/mattmenefee/dotfiles/issues/68
[issue-69]: https://github.com/mattmenefee/dotfiles/issues/69
[issue-70]: https://github.com/mattmenefee/dotfiles/issues/70
[issue-71]: https://github.com/mattmenefee/dotfiles/issues/71
[issue-72]: https://github.com/mattmenefee/dotfiles/issues/72
[issue-73]: https://github.com/mattmenefee/dotfiles/issues/73
