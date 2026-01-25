vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if not client then return end

    -- disable formatting for servers we don't want
    if client.name == "tsserver" then
      client.server_capabilities.documentFormattingProvider = false
    end
  end,
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

