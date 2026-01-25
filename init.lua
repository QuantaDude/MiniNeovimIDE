-- ~/.config/nvim-minimal/init.lua
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.updatetime = 500

print("nvim-minimal loaded")

-- install mini.nvim (contains mini.files)
vim.pack.add({
  "https://github.com/echasnovski/mini.files",
  "https://github.com/echasnovski/mini.comment",
})

-- setup mini.files
vim.keymap.set("n", "<leader>e", function()
  local mf = require("mini.files")

  if mf.get_explorer_state() ~= nil then
    mf.close()
  else
    mf.open()
  end
end,{ desc = "Toggle file explorer (mini.files)" })

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesAction",
  callback = function(event)
    if event.data.action == "open" then
      require("mini.files").close()
    end
  end,
})

-- Theme
vim.pack.add({ "https://github.com/sainnhe/everforest"})
vim.cmd.packadd("everforest")

-- MUST be set before colorscheme
vim.g.everforest_background = "soft"
vim.g.everforest_enable_italic = 1        -- optional
vim.g.everforest_disable_italic_comment = 0
vim.g.everforest_better_performance = 1

vim.cmd.colorscheme("everforest")

-- Tree-sitter
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
}, { confirm = false })

local ts = require("nvim-treesitter")
local augroup = vim.api.nvim_create_augroup("myconfig.treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "*" },
  callback = function(event)
    local filetype = event.match
    local lang = vim.treesitter.language.get_lang(filetype)
    local is_installed, error = vim.treesitter.language.add(lang)

    if not is_installed then
      local available_langs = ts.get_available()
      local is_available = vim.tbl_contains(available_langs, lang)

      if is_available then
        vim.notify("Installing treesitter parser for " .. lang, vim.log.levels.INFO)
        ts.install({ lang }):wait(30 * 1000)
      end
    end

    local ok, _ = pcall(vim.treesitter.start, event.buf, lang)
    if not ok then return end

    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end
})

vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup,
  pattern = { "nvim-treesitter" },
  callback = function(event)
    vim.notify("Updating treesitter parsers", vim.log.levels.INFO)
    ts.update(nil, { summary = true }):wait(30 * 1000)
  end
})


vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function()
    local root = vim.fs.root(0, {
      ".luarc.json",
      ".luarc.jsonc",
      ".git",
    })

    if not root then
      return
    end

    vim.lsp.start({
      name = "lua_ls",
      cmd = { "lua-language-server", '--logpath=~/.local/state/luals' },
      root_dir = root,
      settings = {
        Lua = {
          runtime = {
            version = "LuaJIT",
          },
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            checkThirdParty = false,
            library = {
              vim.env.VIMRUNTIME,
            },
            userThirdParty = {
              vim.fn.stdpath("cache") .. "/lua_ls",
            },
          },
        },
      },
    })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.lsp.start({
      name = "clangd",
      cmd = { "clangd" },
      root_dir = vim.fn.getcwd(),
    })
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.lsp.start({
      name = "pyright",
      cmd = { "pyright-langserver", "--stdio" },
      root_dir = vim.fn.getcwd(),
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  callback = function()
    vim.lsp.start({
      name = "tsserver",
      cmd = { "typescript-language-server", "--stdio" },
      root_dir = vim.fs.root(0, {
        "package.json",
        "tsconfig.json",
        "jsconfig.json",
        ".git",
      }),
    })
  end,
})
vim.lsp.handlers["textDocument/hover"] =
  vim.lsp.with(vim.lsp.handlers.hover, {
    border = "rounded",
    max_width = 80,
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

vim.pack.add({
  "https://github.com/tpope/vim-dadbod",
  "https://github.com/kristijanhusak/vim-dadbod-ui",
  "https://github.com/kristijanhusak/vim-dadbod-completion",
  "https://github.com/abidibo/nvim-httpyac",
})

vim.cmd.packadd("vim-dadbod")
vim.cmd.packadd("vim-dadbod-ui")
vim.cmd.packadd("vim-dadbod-completion")
vim.cmd.packadd("nvim-httpyac")

vim.g.db_ui_save_location = vim.fn.stdpath("config") .. "/db_ui"
vim.g.db_ui_use_nerd_fonts = 1
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_execute_on_save = 0
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


vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "References" })
vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { desc = "Implementation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>v", "<cmd>vsplit<cr>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>h", "<cmd>split<cr>",  { desc = "Horizontal split" })
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

  local s = math.min(start_line, end_line)
  local e = math.max(start_line, end_line)

  local last = vim.api.nvim_buf_line_count(0)
  s = math.max(1, math.min(s, last))
  e = math.max(1, math.min(e, last))

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
