vim.cmd.packadd("everforest")
vim.cmd.colorscheme("everforest")
vim.cmd.packadd("vim-dadbod")
vim.cmd.packadd("vim-dadbod-ui")

require("mini.icons").setup()
require("mini.comment").setup()
require("mini.files").setup()
require("mini.diff").setup({
  view = {
    style = "sign", -- line-based highlights
  },
  signs = {
    add    = { text = "" },
    change = { text = "" },
    delete = { text = "" },
  },
})
vim.keymap.set("n", "<leader>gd", function()
  require("mini.diff").toggle()
end, { desc = "Toggle git diff" })
