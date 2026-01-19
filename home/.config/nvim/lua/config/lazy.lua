-- Lazy.nvim plugin manager configuration

require("lazy").setup({
  spec = {
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false, -- Always use latest git commit
  },
  install = {
    colorscheme = { "catppuccin", "habamax" },
  },
  checker = {
    enabled = true, -- Check for plugin updates
    notify = false, -- Don't spam notifications
  },
  change_detection = {
    notify = false, -- Don't notify on config changes
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

