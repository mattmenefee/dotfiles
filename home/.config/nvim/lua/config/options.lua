-- Options configuration
-- Migrated from vimrc, excluding NeoVim defaults

local opt = vim.opt

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true

-- History
opt.history = 2000

-- Display
opt.number = true
opt.signcolumn = "yes"
opt.scrolloff = 7
opt.sidescroll = 8
opt.showmatch = true
opt.list = true
opt.listchars = { tab = "»·", trail = "·" }
opt.visualbell = true

-- Tabs and indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.shiftround = true

-- Text width
opt.textwidth = 100
opt.wrapmargin = 2

-- Search (ignorecase and smartcase are not defaults)
opt.ignorecase = true
opt.smartcase = true

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Buffer switching
opt.switchbuf = "useopen"

-- Virtual edit in block mode
opt.virtualedit = "block"

-- Clipboard (use unnamedplus for NeoVim)
opt.clipboard = "unnamedplus"

-- Auto-write before commands
opt.autowrite = true
opt.confirm = true

-- Shorter messages
opt.shortmess:append("atI")

-- Shorter updatetime for better UX
opt.updatetime = 250
opt.timeoutlen = 300

-- HTML indent tags
vim.g.html_indent_tags = "li\\|p"

