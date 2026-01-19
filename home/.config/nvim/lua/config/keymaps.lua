-- Key mappings
-- Migrated from vimrc

local map = vim.keymap.set

-- Quick commands
map("n", "QQ", "<cmd>q<CR>", { desc = "Quit" })
map("n", "WW", "<cmd>wall<CR>", { desc = "Write all" })
map("n", "NN", "<cmd>next<CR>", { desc = "Next file" })
map("n", "PP", "<cmd>previous<CR>", { desc = "Previous file" })

-- Increment/decrement
map("n", "+", "<C-A>", { desc = "Increment number" })
map("n", "-", "<C-X>", { desc = "Decrement number" })

-- Insert mode completion shortcuts
map("i", "<C-F>", "<C-X><C-F>", { desc = "File completion" })
map("i", "<C-L>", "<C-X><C-L>", { desc = "Line completion" })

-- Escape insert mode
map("i", "jj", "<Esc>", { desc = "Escape insert mode" })
map("i", "jk", "<Esc>", { desc = "Escape insert mode" })

-- Split navigation
map("n", "<C-J>", "<C-W><C-J>", { desc = "Move to split below" })
map("n", "<C-K>", "<C-W><C-K>", { desc = "Move to split above" })
map("n", "<C-L>", "<C-W><C-L>", { desc = "Move to split right" })
map("n", "<C-H>", "<C-W><C-H>", { desc = "Move to split left" })

-- "Get off my lawn" - disable arrow keys
map("n", "<Left>", "<cmd>echo 'Use h'<CR>", { desc = "Use h instead" })
map("n", "<Right>", "<cmd>echo 'Use l'<CR>", { desc = "Use l instead" })
map("n", "<Up>", "<cmd>echo 'Use k'<CR>", { desc = "Use k instead" })
map("n", "<Down>", "<cmd>echo 'Use j'<CR>", { desc = "Use j instead" })

-- Leader mappings
map("n", "<leader><space>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>,", "<cmd>%s/\\s\\+$//<CR>", { desc = "Remove trailing whitespace" })

-- Git blame for visual selection
map("v", "gl", function()
  local file = vim.fn.expand("%:p")
  local line_start = vim.fn.line("'<")
  local line_end = vim.fn.line("'>")
  vim.cmd(string.format("!git blame %s | sed -n %d,%dp", file, line_start, line_end))
end, { desc = "Git blame selection" })

-- Open help in vertical split
vim.cmd([[cabbrev h vertical help]])

-- Write with sudo (alternative for NeoVim)
map("c", "w!!", "w !sudo tee % > /dev/null", { desc = "Write with sudo" })

