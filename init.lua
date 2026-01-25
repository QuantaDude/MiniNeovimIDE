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

print("nvim-minimal loaded")

-- install mini.nvim (contains mini.files)
vim.pack.add({
  "https://github.com/echasnovski/mini.files",
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
      cmd = { "lua-language-server" },
      root_dir = root,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim" },
          },
          workspace = {
            checkThirdParty = false,
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
