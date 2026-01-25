-- ~/.config/nvim-minimal/init.lua
require("config.options")
require("config.plugins")
require("config.treesitter")
require("config.lsp")
require("config.completion")
require("config.format")
require("config.ui")
require("config.pickers")
require("config.autocmds")

require("config.keymaps")

print("nvim-minimal loaded")


vim.lsp.handlers["textDocument/hover"] =
    vim.lsp.with(vim.lsp.handlers.hover, {
      border = "rounded",
      max_width = 80,
    })
