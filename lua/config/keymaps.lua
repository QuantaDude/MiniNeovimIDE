-- setup mini.files
vim.keymap.set("n", "<leader>e", function()
  local mf = require("mini.files")

  if mf.get_explorer_state() ~= nil then
    mf.close()
  else
    mf.open()
  end
end, { desc = "Toggle file explorer (mini.files)" })



vim.keymap.set("n", "<leader>f", function()
  require("config.format").format_buffer()
end, { desc = "Format buffer" })


vim.keymap.set("i", "<C-Space>", "<C-x><C-o>", { desc = "LSP completion" })

vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "References" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Implementation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<cr>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<cmd>split<cr>", { desc = "Horizontal split" })
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")
vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save buffer" })

vim.keymap.set("n", "<leader>/", function()
  local line = vim.fn.line(".")
  require("mini.comment").toggle_lines(line, line)
end, { desc = "Toggle comment (line)" })

vim.keymap.set("v", "<leader>/", function()
  vim.cmd("normal! <Esc>")

  local start_line = vim.fn.getpos("'<")[2]
  local end_line   = vim.fn.getpos("'>")[2]

  local s          = math.min(start_line, end_line)
  local e          = math.max(start_line, end_line)

  local last       = vim.api.nvim_buf_line_count(0)
  s                = math.max(1, math.min(s, last))
  e                = math.max(1, math.min(e, last))

  require("mini.comment").toggle_lines(s, e)
end, { desc = "Toggle comment (selection)" })

vim.keymap.set("n", "<leader>ca", function()
  vim.lsp.buf.code_action({
    context = { only = { "quickfix", "refactor", "source" } },
    range = {
      ["start"] = { vim.fn.line(".") - 1, 0 },
      ["end"]   = { vim.fn.line(".") - 1, vim.fn.col("$") },
    },
  })
end, { desc = "Code actions (current line)" })

vim.keymap.set("n", "<leader>cA", function()
  vim.lsp.buf.code_action({
    context = { only = { "quickfix", "refactor", "source" } },
  })
end, { desc = "Code actions (whole file)" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
vim.keymap.set("n", "]e", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })

vim.keymap.set("n", "[e", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "Prev error" })
vim.keymap.set("n", "]w", function()
  vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Next warning" })

vim.keymap.set("n", "[w", function()
  vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.WARN })
end, { desc = "Prev warning" })

vim.keymap.set("n", "<leader>ba", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf)
        and vim.api.nvim_buf_get_option(buf, "modified") then
      vim.notify("Unsaved buffers exist", vim.log.levels.WARN)
      return
    end
  end

  vim.cmd("%bd")
end, { desc = "Close all buffers (safe)" })

vim.keymap.set("n", "<leader>t", function()
  vim.cmd("botright split | resize 15 | terminal")
end, { desc = "Terminal (bottom)" })

-- open DB UI
vim.keymap.set("n", "<leader>db", "<cmd>DBUI<cr>", { desc = "Dadbod UI" })

-- run query under cursor / selection
vim.keymap.set("n", "<leader>dq", "<cmd>DB<cr>", { desc = "Run query" })
vim.keymap.set("v", "<leader>dq", "<cmd>DB<cr>", { desc = "Run selected query" })
