-- vim.cmd.packadd("gruvbox")
vim.o.background = "dark"
require("gruvbox").setup()
vim.cmd.colorscheme("gruvbox")
vim.cmd("colorscheme gruvbox")

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


require("mini.starter").setup({
  header = table.concat({
    "░░░ micro nvim IDE ░░░"
  }, "\n"),

  items = {
    { name = "New file",      action = "enew",                 section = "Actions" },
    { name = "Find file",     action = "Telescope find_files", section = "Actions" },
    { name = "Find word",     action = "Telescope live_grep",  section = "Actions" },
    { name = "Recent files",  action = "Telescope oldfiles",   section = "Actions" },
    { name = "Open explorer", action = "lua MiniFiles.open()", section = "Actions" },
    { name = "Quit",          action = "qa",                   section = "Actions" },
  },
  content_hooks = {
    require("mini.starter").gen_hook.adding_bullet("▸ "),
    require("mini.starter").gen_hook.aligning("center", "center"),
  },
  footer = function()
    return "Neovim " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch
  end,
})
