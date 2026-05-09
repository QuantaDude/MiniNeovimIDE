require("gruvbox").setup()
vim.cmd.colorscheme("gruvbox")
-- vim.cmd("colorscheme gruvbox")

-- vim.cmd.packadd("vim-dadbod")
-- vim.cmd.packadd("vim-dadbod-ui")

require("mini.icons").setup()
require("mini.comment").setup()
require("mini.files").setup()
require('mini.statusline').setup()
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

local wk = require("which-key")

wk.setup({
  preset = "modern",
  delay = 300,

  win = {
    border = "rounded",
  },
})

wk.add({
  { "<leader>f", group = "file" },
  { "<leader>g", group = "git" },
  { "<leader>b", group = "buffer" },
})
vim.keymap.set("n", "<leader>gd", function()
  require("mini.diff").toggle()
end, { desc = "Toggle git diff" })



vim.o.showtabline = 2
vim.o.tabline = "%!v:lua.MyTabLine()"

function MyTabLine()
  local s = ""

  local current = vim.api.nvim_get_current_buf()

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buflisted then
      local name = vim.fn.fnamemodify(
        vim.api.nvim_buf_get_name(buf),
        ":t"
      )

      if name == "" then
        name = "[No Name]"
      end

      -- Highlight current buffer
      if buf == current then
        s = s .. "%#TabLineSel#"
      else
        s = s .. "%#TabLine#"
      end

      -- Click target
      s = s .. "%" .. buf .. "T"

      s = s .. " " .. name .. " "
    end
  end

  s = s .. "%#TabLineFill#"

  return s
end

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
