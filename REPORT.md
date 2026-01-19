# NeoVim Migration Report

**Date:** January 18, 2026
**Branch:** `neovim`

## Summary

Migrated from Vim with Vundle to NeoVim with lazy.nvim, embracing Lua configuration and modern plugin alternatives.

## What Was Accomplished

### 1. Configuration Analysis

Reviewed the existing Vim setup:
- **43 Vundle plugins** in `home/.vimrc`
- **276 lines** of Vimscript configuration
- Heavy Ruby/Rails focus with RSpec integration
- Syntastic-based linting for multiple languages

### 2. Documentation Updates

Updated `NEOVIM_MIGRATION.md` with:
- Accurate plugin migration tables based on actual vimrc content
- NeoVim default settings that can be removed
- Settings requiring adjustment for NeoVim
- Syntastic-to-LSP migration mapping
- Complete keymapping translation reference
- Phase-based migration checklist

### 3. NeoVim Configuration Created

Created a complete lazy.nvim-based configuration:

```
home/.config/nvim/
├── init.lua                 # Entry point, lazy.nvim bootstrap
├── lua/
│   ├── config/
│   │   ├── options.lua      # Vim options (42 lines)
│   │   ├── keymaps.lua      # Key mappings (52 lines)
│   │   ├── autocmds.lua     # Autocommands (89 lines)
│   │   └── lazy.lua         # Plugin manager setup (28 lines)
│   └── plugins/
│       ├── editor.lua       # Core editing (135 lines)
│       ├── lsp.lua          # LSP & completion (185 lines)
│       ├── ui.lua           # Theme & statusline (132 lines)
│       ├── git.lua          # Git integration (95 lines)
│       └── ruby.lua         # Ruby/Rails tools (95 lines)
```

**Total:** 10 Lua files, ~850 lines of configuration

## Plugin Migration Summary

### Removed (9 plugins)
Obsolete or built into NeoVim:

| Plugin | Reason |
|--------|--------|
| `VundleVim/Vundle.vim` | Replaced by lazy.nvim |
| `matchit.zip` | Built into NeoVim 0.8+ |
| `bogado/file-line` | Built into NeoVim |
| `jQuery` | Outdated, modern JS doesn't need it |
| `vim-coffee-script` | CoffeeScript deprecated |
| `mtscout6/vim-cjsx` | CJSX rarely used |
| `Rename` | Covered by vim-eunuch |
| `textobj-user` | Replaced by TreeSitter |
| `ruby-matchit` | Replaced by TreeSitter |

### Replaced with TreeSitter (6 plugins)
Syntax highlighting now handled by nvim-treesitter:

| Plugin | TreeSitter Parser |
|--------|-------------------|
| `pangloss/vim-javascript` | javascript, typescript |
| `jelera/vim-javascript-syntax` | javascript |
| `mxw/vim-jsx` | tsx, javascript |
| `tpope/vim-haml` | haml, scss, sass |
| `hashivim/vim-terraform` | hcl, terraform |
| `Markdown` | markdown, markdown_inline |

### Replaced with Lua Alternatives (12 plugins)

| Old Plugin | New Plugin | Stars |
|------------|------------|-------|
| `scrooloose/syntastic` | Built-in LSP + Mason | N/A |
| `myint/syntastic-extras` | nvim-lint (if needed) | N/A |
| `scrooloose/nerdtree` | nvim-tree/nvim-tree.lua | 7.5k+ |
| `rking/ag.vim` | nvim-telescope/telescope.nvim | 18.5k+ |
| `gabesoft/vim-ags` | nvim-telescope/telescope.nvim | 18.5k+ |
| `ervandew/supertab` | hrsh7th/nvim-cmp | 9.2k+ |
| `scrooloose/nerdcommenter` | numToStr/Comment.nvim | 4k+ |
| `surround.vim` | kylechui/nvim-surround | 3.5k+ |
| `Align` + `Tabular` | echasnovski/mini.align | Part of mini.nvim |
| `Raimondi/delimitMate` | windwp/nvim-autopairs | 3.2k+ |
| `nathanaelkane/vim-indent-guides` | lukas-reineke/indent-blankline.nvim | 4.3k+ |
| `airblade/vim-gitgutter` | lewis6991/gitsigns.nvim | 6.4k+ |
| `flazz/vim-colorschemes` | catppuccin/nvim | 5k+ |
| `ap/vim-css-color` | NvChad/nvim-colorizer.lua | 600+ |
| `DirDiff.vim` | sindrets/diffview.nvim | 4k+ |
| `textobj-rubyblock` | nvim-treesitter-textobjects | 2.3k+ |

### Kept (9 plugins)
Still the best options available:

| Plugin | Reason |
|--------|--------|
| `tpope/vim-fugitive` | Best Git wrapper for (Neo)Vim |
| `tpope/vim-rails` | Essential Rails integration |
| `tpope/vim-endwise` | Auto-adds `end` in Ruby |
| `tpope/vim-repeat` | Enhances `.` command |
| `tpope/vim-abolish` | Unique case-aware substitution |
| `tpope/vim-eunuch` | Unix command helpers |
| `tpope/vim-dispatch` | Async command execution |
| `thoughtbot/vim-rspec` | RSpec runner integration |
| `DrawIt` | ASCII diagrams (niche but unique) |

### New Additions (8 plugins)
Modern NeoVim essentials:

| Plugin | Purpose |
|--------|---------|
| `folke/lazy.nvim` | Plugin manager |
| `nvim-treesitter/nvim-treesitter` | Syntax highlighting & text objects |
| `neovim/nvim-lspconfig` | LSP configuration |
| `williamboman/mason.nvim` | LSP/linter installer |
| `folke/which-key.nvim` | Keybinding popup help |
| `nvim-lualine/lualine.nvim` | Statusline |
| `akinsho/bufferline.nvim` | Buffer tabs |
| `folke/trouble.nvim` | Diagnostics list |

## Settings Changes

### Removed (NeoVim Defaults)
These 13 settings are now default in NeoVim:
- `nocompatible`, `autoindent`, `autoread`, `backspace=2`
- `hlsearch`, `incsearch`, `laststatus=2`, `ruler`
- `showcmd`, `smarttab`, `wildmenu`
- `filetype plugin indent on`, `syntax on`

### Adjusted
| Vim | NeoVim | Reason |
|-----|--------|--------|
| `clipboard=unnamed` | `clipboard=unnamedplus` | Better cross-platform support |
| `pastetoggle=<F2>` | Removed | NeoVim handles paste automatically |
| `listchars=tab:»·,trail:·` | `listchars = { tab = "»·", trail = "·" }` | Lua table syntax |

## Key Mapping Preservation

All custom mappings from vimrc have been preserved in `lua/config/keymaps.lua`:

- `QQ`, `WW`, `NN`, `PP` - Quick commands
- `jj`, `jk` - Escape insert mode
- `<C-h/j/k/l>` - Split navigation
- Arrow key warnings ("Get off my lawn")
- `<leader><space>` - Clear search highlight
- `<leader>t/s/l/a` - RSpec runners
- `gl` (visual) - Git blame selection

## LSP Configuration

Syntastic checkers migrated to LSP:

| Syntastic | LSP Server |
|-----------|------------|
| `scss_lint` | stylelint-lsp |
| `haml_lint` | haml-lint via nvim-lint |
| `eslint` | eslint-lsp |
| `python` | pyright or pylsp |
| `pyyaml` | yamlls |

Mason auto-installs: `ruby_lsp`, `ts_ls`, `eslint`, `terraformls`, `yamlls`, `lua_ls`

## Next Steps

1. **Deploy**: Run `homesick link dotfiles` to symlink the config
2. **First Launch**: Run `nvim` - lazy.nvim will install plugins automatically
3. **Install LSPs**: Run `:Mason` and install language servers
4. **Test Workflow**: Verify RSpec integration, Git operations, and search work as expected
5. **Customize**: Adjust colorscheme, keybindings, or plugins as needed

## Files Modified/Created

| File | Action |
|------|--------|
| `NEOVIM_MIGRATION.md` | Updated with accurate migration info |
| `home/.config/nvim/init.lua` | Created |
| `home/.config/nvim/lua/config/options.lua` | Created |
| `home/.config/nvim/lua/config/keymaps.lua` | Created |
| `home/.config/nvim/lua/config/autocmds.lua` | Created |
| `home/.config/nvim/lua/config/lazy.lua` | Created |
| `home/.config/nvim/lua/plugins/editor.lua` | Created |
| `home/.config/nvim/lua/plugins/lsp.lua` | Created |
| `home/.config/nvim/lua/plugins/ui.lua` | Created |
| `home/.config/nvim/lua/plugins/git.lua` | Created |
| `home/.config/nvim/lua/plugins/ruby.lua` | Created |

