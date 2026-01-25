local M = require("config.format")
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = M.format_buffer,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesAction",
  callback = function(event)
    if event.data.action == "open" then
      require("mini.files").close()
    end
  end,
})

vim.api.nvim_create_autocmd("CursorHold", {
  callback = function()
    if vim.fn.mode() ~= "n" then
      return
    end
    -- don't show hover if a floating window is already open
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end
    end

    local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })

    if #diagnostics > 0 then
      vim.diagnostic.open_float(nil, {
        focus = false,
        scope = "line",
        border = "rounded",
      })
    else
      vim.lsp.buf.hover()
    end
  end,
})
vim.api.nvim_create_autocmd("CursorHoldI", {
  callback = function()
    -- only show if an LSP is attached
    if not vim.lsp.get_clients({ bufnr = 0 })[1] then
      return
    end

    -- don't open if a floating window already exists
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        return
      end
    end

    vim.lsp.buf.signature_help()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "sql", "mysql", "plsql" },
  callback = function()
    vim.bo.omnifunc = "vim_dadbod_completion#omni"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "http",
  callback = function()
    -- load plugin only now
    vim.cmd.packadd("nvim-httpyac")

    -- setup (safe to call multiple times)
    require("nvim-httpyac").setup({})

    -- buffer-local keymaps
    local opts = { buffer = true, desc = "HTTP request (httpyac)" }

    vim.keymap.set("n", "<leader>rr", function()
      require("nvim-httpyac").run()
    end, opts)

    vim.keymap.set("v", "<leader>rr", function()
      require("nvim-httpyac").run()
    end, opts)
  end,
})
