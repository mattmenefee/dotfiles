-- Ruby and Rails plugins
-- Ruby/Rails specific development tools

return {
  -- Rails support (keeping - still essential)
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby", "haml", "slim" },
  },

  -- RSpec runner (keeping - essential for Rails testing)
  {
    "thoughtbot/vim-rspec",
    ft = { "ruby" },
    config = function()
      -- Use vim-dispatch for async execution
      vim.g.rspec_runner = "os_x_iterm"
      vim.g.rspec_command = "Dispatch bin/rspec {spec}"
    end,
    keys = {
      { "<leader>t", ":call RunCurrentSpecFile()<CR>", desc = "Run current spec file", ft = "ruby" },
      { "<leader>s", ":call RunNearestSpec()<CR>", desc = "Run nearest spec", ft = "ruby" },
      { "<leader>l", ":call RunLastSpec()<CR>", desc = "Run last spec", ft = "ruby" },
      { "<leader>a", ":call RunAllSpecs()<CR>", desc = "Run all specs", ft = "ruby" },
    },
  },

  -- Alternative/Modern RSpec runner (optional)
  -- Uncomment if you want to try a more modern alternative
  -- {
  --   "nvim-neotest/neotest",
  --   dependencies = {
  --     "nvim-neotest/nvim-nio",
  --     "nvim-lua/plenary.nvim",
  --     "nvim-treesitter/nvim-treesitter",
  --     "olimorris/neotest-rspec",
  --   },
  --   config = function()
  --     require("neotest").setup({
  --       adapters = {
  --         require("neotest-rspec"),
  --       },
  --     })
  --   end,
  --   keys = {
  --     { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
  --     { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file" },
  --     { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
  --     { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
  --   },
  -- },

  -- Ruby text objects via TreeSitter
  -- (textobj-rubyblock is replaced by nvim-treesitter-textobjects)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              -- Ruby blocks: `vam` to select a method, `vim` for inner method
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["ab"] = "@block.outer",
              ["ib"] = "@block.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
}

