-- lua/config/pickers.lua
vim.cmd.packadd("plenary.nvim")
vim.cmd.packadd("telescope.nvim")

local telescope = require("telescope")

telescope.setup({
  defaults = {
    prompt_prefix = "❯ ",
    selection_caret = "➤ ",
    sorting_strategy = "ascending",
    layout_config = {
      prompt_position = "top",
    },
  },
})
