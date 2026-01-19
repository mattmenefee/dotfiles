-- Editor plugins
-- Core editing functionality

return {
  -- File explorer (replaces NERDTree)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        filters = { dotfiles = false },
        view = { width = 35 },
        renderer = {
          group_empty = true,
        },
        -- Auto-open like your NERDTree autocmd
        -- Handled in autocmds if desired
      })
    end,
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
      { "<leader>E", "<cmd>NvimTreeFindFile<CR>", desc = "Find file in explorer" },
    },
  },

  -- Fuzzy finder (replaces ag.vim and vim-ags)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
      })
      pcall(telescope.load_extension, "fzf")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fw", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      -- Your Ags-style mappings
      { "<leader>a", "<cmd>Telescope live_grep<CR>", desc = "Search (grep)" },
    },
  },

  -- Commenting (replaces NERDCommenter)
  {
    "numToStr/Comment.nvim",
    opts = {},
  },

  -- Surround (replaces surround.vim with Lua version)
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- Auto pairs (replaces delimitMate)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },

  -- Which-key for keybinding help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      plugins = { spelling = true },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Buffer local keymaps",
      },
    },
  },

  -- Text alignment (replaces Align and Tabular)
  {
    "echasnovski/mini.align",
    version = "*",
    opts = {},
  },

  -- Indent guides (replaces vim-indent-guides)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true },
    },
  },

  -- Repeat plugin commands with .
  { "tpope/vim-repeat" },

  -- Case-aware substitution
  { "tpope/vim-abolish" },

  -- Unix commands
  { "tpope/vim-eunuch" },

  -- Auto-add 'end' in Ruby, etc.
  { "tpope/vim-endwise" },

  -- Async dispatch for running commands
  { "tpope/vim-dispatch" },

  -- Highlight colors in CSS (replaces vim-css-color)
  {
    "NvChad/nvim-colorizer.lua",
    opts = {
      user_default_options = {
        css = true,
        css_fn = true,
      },
    },
  },

  -- Diff view (replaces DirDiff)
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diff view" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "File history" },
    },
  },
}

