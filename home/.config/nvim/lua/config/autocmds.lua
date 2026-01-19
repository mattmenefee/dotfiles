-- Autocommands
-- Migrated from vimrc

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- General autocommands group
local general = augroup("General", { clear = true })

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
  group = general,
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
  desc = "Remove trailing whitespace",
})

-- Filetype detection
local filetypes = augroup("Filetypes", { clear = true })

-- Axlsx files are Ruby
autocmd({ "BufRead", "BufNewFile" }, {
  group = filetypes,
  pattern = "*.axlsx",
  callback = function()
    vim.bo.filetype = "ruby"
  end,
})

-- Encrypted Rails credentials
autocmd({ "BufRead", "BufNewFile" }, {
  group = filetypes,
  pattern = "*.yml.enc*",
  callback = function()
    vim.bo.filetype = "yaml"
  end,
})

-- Dockerfile variants
autocmd({ "BufRead", "BufNewFile" }, {
  group = filetypes,
  pattern = "Dockerfile*",
  callback = function()
    vim.bo.filetype = "dockerfile"
  end,
})

-- Capistrano service templates
autocmd({ "BufRead", "BufNewFile" }, {
  group = filetypes,
  pattern = "*.service.erb",
  callback = function()
    vim.bo.filetype = "ruby.ini"
  end,
})

-- Markdown settings
local markdown = augroup("Markdown", { clear = true })

autocmd({ "BufRead", "BufNewFile" }, {
  group = markdown,
  pattern = "*.md",
  callback = function()
    vim.bo.filetype = "markdown"
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 80
  end,
})

-- Open Markdown in browser
autocmd("BufEnter", {
  group = markdown,
  pattern = "*.md",
  callback = function()
    vim.keymap.set("n", "<F5>", function()
      vim.fn.system({ "open", "-a", "Google Chrome.app", vim.fn.expand("%:p") })
    end, { buffer = true, desc = "Open in Chrome" })
  end,
})

-- Git commit settings
local git = augroup("Git", { clear = true })

autocmd("FileType", {
  group = git,
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 72
  end,
})

