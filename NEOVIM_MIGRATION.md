# NeoVim Migration Guide

This guide covers migrating from your current Vim configuration to NeoVim with lazy.nvim plugin management.

## Key Differences & NeoVim Advantages

### What NeoVim Provides by Default
- **Lua configuration** - More powerful and faster than Vimscript
- **Built-in LSP client** - No need for Syntastic or separate language server plugins
- **TreeSitter** - Superior syntax highlighting and text objects
- **Async I/O** - Better performance for plugins
- **Better defaults** - Many settings you've configured are already default

### NeoVim Default Settings (Remove from Config)
These settings from your vimrc are already default in NeoVim:
```vim
set nocompatible        " Always true in NeoVim
set autoindent          " Default in NeoVim
set autoread            " Default in NeoVim
set backspace=2         " Default behavior in NeoVim
set hlsearch            " Default in NeoVim
set incsearch           " Default in NeoVim
set laststatus=2        " Default in NeoVim
set ruler               " Default in NeoVim
set showcmd             " Default in NeoVim
set smarttab            " Default in NeoVim
set wildmenu            " Default in NeoVim
filetype plugin indent on  " Default in NeoVim
syntax on               " Default in NeoVim
```

### Settings That Need Adjustment
| Vim Setting | NeoVim Equivalent | Notes |
|-------------|-------------------|-------|
| `set clipboard=unnamed` | `vim.opt.clipboard = "unnamedplus"` | Better cross-platform support |
| `set pastetoggle=<F2>` | Remove entirely | Not needed in NeoVim |
| `set list listchars=tab:»·,trail:·` | `vim.opt.listchars = { tab = "»·", trail = "·" }` | Lua table syntax |

## Configuration Structure

### Recommended Directory Structure
```
~/.config/nvim/
├── init.lua                 # Main config file
├── lua/
│   ├── config/
│   │   ├── options.lua      # Vim options
│   │   ├── keymaps.lua      # Key mappings
│   │   ├── autocmds.lua     # Auto commands
│   │   └── lazy.lua         # Lazy.nvim setup
│   └── plugins/
│       ├── editor.lua       # Editor plugins (nvim-tree, telescope, etc.)
│       ├── lsp.lua          # LSP configuration
│       ├── ui.lua           # UI plugins (statusline, colorscheme)
│       ├── git.lua          # Git plugins
│       └── ruby.lua         # Ruby/Rails specific plugins
```

## Plugin Migration Analysis

### 🗑️ Remove - Obsolete or Built-in to NeoVim

| Current Plugin | Reason to Remove |
|----------------|-----------------|
| `VundleVim/Vundle.vim` | Replace with lazy.nvim |
| `matchit.zip` | Built into NeoVim 0.8+ |
| `bogado/file-line` | Built into NeoVim |
| `jQuery` | Modern JS doesn't need this |
| `vim-coffee-script` | CoffeeScript is largely deprecated |
| `mtscout6/vim-cjsx` | CJSX is rarely used |
| `Rename` | Covered by vim-eunuch's `:Rename` |
| `textobj-user` + `textobj-rubyblock` | Use TreeSitter text objects |
| `ruby-matchit` | Use TreeSitter for Ruby matching |

### 🔄 Replace - Use TreeSitter Instead

| Current Plugin | TreeSitter Parser |
|----------------|-------------------|
| `pangloss/vim-javascript` | `javascript`, `typescript` |
| `jelera/vim-javascript-syntax` | `javascript` |
| `mxw/vim-jsx` | `tsx`, `javascript` |
| `tpope/vim-haml` | `haml`, `scss`, `sass` |
| `hashivim/vim-terraform` | `hcl`, `terraform` |
| `Markdown` | `markdown`, `markdown_inline` |

### 🔄 Replace - Better Lua Alternatives

| Current Plugin | NeoVim Alternative | Stars | Why Better |
|----------------|-------------------|-------|------------|
| `scrooloose/syntastic` | Built-in LSP + `nvim-lint` | N/A | Native, faster, more accurate |
| `scrooloose/nerdtree` | `nvim-tree/nvim-tree.lua` | 7.5k+ | Lua, faster, better integration |
| `rking/ag.vim` + `gabesoft/vim-ags` | `nvim-telescope/telescope.nvim` | 18.5k+ | Far more powerful fuzzy finder |
| `ervandew/supertab` | `hrsh7th/nvim-cmp` | 9.2k+ | LSP-aware, more extensible |
| `scrooloose/nerdcommenter` | `numToStr/Comment.nvim` | 4k+ | Simpler, TreeSitter-aware |
| `surround.vim` | `kylechui/nvim-surround` | 3.5k+ | TreeSitter support, more features |
| `Align` + `Tabular` | `echasnovski/mini.align` | Part of mini.nvim | Modern, well-maintained |
| `Raimondi/delimitMate` | `windwp/nvim-autopairs` | 3.2k+ | TreeSitter-aware |
| `nathanaelkane/vim-indent-guides` | `lukas-reineke/indent-blankline.nvim` | 4.3k+ | Scope highlighting |
| `airblade/vim-gitgutter` | `lewis6991/gitsigns.nvim` | 6.4k+ | Faster, more features |
| `flazz/vim-colorschemes` | Modern themes (see below) | N/A | Better maintained |
| `ap/vim-css-color` | `NvChad/nvim-colorizer.lua` | 600+ | Faster, virtual text |
| `DirDiff.vim` | `sindrets/diffview.nvim` | 4k+ | Much more powerful |

### ✅ Keep - Still Excellent

| Plugin | Notes |
|--------|-------|
| `tpope/vim-fugitive` | Still the best Git wrapper |
| `tpope/vim-rails` | Essential for Rails development |
| `tpope/vim-endwise` | Auto-adds `end` in Ruby |
| `tpope/vim-repeat` | Enhances `.` command for plugins |
| `tpope/vim-abolish` | Unique case-aware substitution |
| `tpope/vim-eunuch` | Useful Unix commands |
| `tpope/vim-dispatch` | Async execution for RSpec |
| `thoughtbot/vim-rspec` | RSpec runner integration |
| `DrawIt` | ASCII diagrams (niche but unique) |

### 🆕 Recommended Modern Additions

| Plugin | Purpose | Stars |
|--------|---------|-------|
| `nvim-treesitter/nvim-treesitter` | Syntax highlighting, text objects | 13k+ |
| `neovim/nvim-lspconfig` | LSP configuration | 11k+ |
| `williamboman/mason.nvim` | LSP/linter/formatter installer | 8.5k+ |
| `hrsh7th/nvim-cmp` | Completion engine | 9.2k+ |
| `nvim-telescope/telescope.nvim` | Fuzzy finder | 18.5k+ |
| `folke/which-key.nvim` | Keybinding popup help | 5.8k+ |
| `nvim-lualine/lualine.nvim` | Fast statusline | 6.5k+ |
| `folke/trouble.nvim` | Diagnostics list | 5.8k+ |
| `catppuccin/nvim` or `folke/tokyonight.nvim` | Modern colorschemes | 5k+ each |

## Migration Steps

### 1. Install NeoVim
```bash
brew install neovim
nvim --version  # Should be 0.10+
```

### 2. Create NeoVim Config Structure
```bash
mkdir -p ~/.config/nvim/lua/{config,plugins}
```

### 3. Create Configuration Files
The configuration files are created by this migration process in:
- `home/.config/nvim/init.lua`
- `home/.config/nvim/lua/config/options.lua`
- `home/.config/nvim/lua/config/keymaps.lua`
- `home/.config/nvim/lua/config/autocmds.lua`
- `home/.config/nvim/lua/config/lazy.lua`
- `home/.config/nvim/lua/plugins/*.lua`

### 4. Install Plugins
On first launch, lazy.nvim will automatically install all plugins:
```bash
nvim
```

### 5. Install Language Servers
Inside NeoVim, run:
```vim
:Mason
```
Then install the servers you need (ruby_lsp, ts_ls, eslint, terraformls, etc.)

## Language Server Setup (Replaces Syntastic)

Your Syntastic configuration:
```vim
let g:syntastic_scss_checkers = ['scss_lint']
let g:syntastic_haml_checkers = ['haml_lint']
let g:syntastic_javascript_checkers = ['eslint']
let g:syntastic_python_checkers = ['python']
let g:syntastic_yaml_checkers = ['pyyaml']
```

Becomes LSP configuration with Mason:

| Syntastic Checker | LSP/Linter |
|-------------------|------------|
| `scss_lint` | `stylelint-lsp` |
| `haml_lint` | `haml-lint` via nvim-lint |
| `eslint` | `eslint-lsp` |
| `python` | `pyright` or `pylsp` |
| `pyyaml` | `yamlls` |

## Colorscheme Migration

Your current `colorscheme railscasts` can be replaced with:
- **catppuccin** - Modern, many flavors (mocha, latte, frappe, macchiato)
- **tokyonight** - Popular dark theme with storm/night/day variants
- **rose-pine** - Soft, pastel colors
- **gruvbox.nvim** - Classic warm theme, Lua rewrite
- **kanagawa** - Japanese-inspired palette

Or keep railscasts by using a Lua port if available.

## Key Mapping Migration Reference

Your vimrc mappings translated to Lua:

```lua
-- In lua/config/keymaps.lua
local map = vim.keymap.set

-- Your existing mappings
map("n", "QQ", "<cmd>q<CR>", { desc = "Quit" })
map("n", "WW", "<cmd>wall<CR>", { desc = "Write all" })
map("n", "NN", "<cmd>next<CR>", { desc = "Next file" })
map("n", "PP", "<cmd>previous<CR>", { desc = "Previous file" })
map("n", "+", "<C-A>", { desc = "Increment" })
map("n", "-", "<C-X>", { desc = "Decrement" })

-- Insert mode escape
map("i", "jj", "<Esc>")
map("i", "jk", "<Esc>")

-- Split navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to below split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to above split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Disable arrow keys (your "Get off my lawn" mappings)
map("n", "<Left>", "<cmd>echo 'Use h'<CR>")
map("n", "<Right>", "<cmd>echo 'Use l'<CR>")
map("n", "<Up>", "<cmd>echo 'Use k'<CR>")
map("n", "<Down>", "<cmd>echo 'Use j'<CR>")

-- Leader mappings
map("n", "<leader><space>", "<cmd>nohlsearch<CR>", { desc = "Clear search" })
map("n", "<leader>,", "<cmd>%s/\\s\\+$//<CR>", { desc = "Remove trailing whitespace" })

-- RSpec mappings (with vim-rspec)
map("n", "<leader>t", ":call RunCurrentSpecFile()<CR>", { desc = "Run spec file" })
map("n", "<leader>s", ":call RunNearestSpec()<CR>", { desc = "Run nearest spec" })
map("n", "<leader>l", ":call RunLastSpec()<CR>", { desc = "Run last spec" })
map("n", "<leader>a", ":call RunAllSpecs()<CR>", { desc = "Run all specs" })
```

## Timeline & Approach

### Phase 1: Foundation
- [ ] Create directory structure
- [ ] Set up lazy.nvim
- [ ] Migrate core options and keymaps
- [ ] Add essential plugins (nvim-tree, telescope, colorscheme)

### Phase 2: Language Support
- [ ] Set up TreeSitter with parsers
- [ ] Configure LSP for Ruby, JavaScript, YAML, Terraform
- [ ] Set up completion (nvim-cmp)
- [ ] Migrate Ruby/Rails plugins

### Phase 3: Polish
- [ ] Add gitsigns.nvim (replaces gitgutter)
- [ ] Configure which-key for discoverability
- [ ] Add trouble.nvim for diagnostics
- [ ] Fine-tune based on workflow

## Resources

- [lazy.nvim Documentation](https://lazy.folke.io/)
- [nvim-lspconfig Server Configurations](https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md)
- [Awesome Neovim](https://github.com/rockerBOO/awesome-neovim)
- [Neovimcraft Plugin Search](https://neovimcraft.com/)
- [Dotfyle Trending Plugins](https://dotfyle.com/neovim/plugins/trending)

