vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)

    if not client then return end

    -- disable formatting for servers we don't want
    if client.name == "tsserver" or client.name == "ts_ls" then
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
      }) or vim.fn.getcwd(),
    })
  end,
})

local function start_web_language_server(name, cmd, root_markers, settings)
  if vim.fn.executable(cmd[1]) ~= 1 then
    return
  end

  local root = vim.fs.root(0, root_markers) or vim.fn.getcwd()

  vim.lsp.start({
    name = name,
    cmd = cmd,
    root_dir = root,
    settings = settings,
  })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "css",
    "scss",
    "sass",
    "less",
  },
  callback = function()
    start_web_language_server("cssls", { "vscode-css-language-server", "--stdio" }, {
      "package.json",
      ".git",
    }, {
      css = { validate = true },
      scss = { validate = true },
      less = { validate = true },
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "html",
    "javascriptreact",
    "typescriptreact",
  },
  callback = function()
    start_web_language_server("html", { "vscode-html-language-server", "--stdio" }, {
      "package.json",
      ".git",
    }, {
      html = {
        format = { enable = false },
        hover = { documentation = true, references = true },
      },
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "json",
  callback = function()
    start_web_language_server("jsonls", { "vscode-json-language-server", "--stdio" }, {
      "package.json",
      ".git",
    }, {
      json = {
        validate = { enable = true },
      },
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
    if vim.fs.root(0, { ".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", "eslint.config.js" }) then
      start_web_language_server("eslint", { "vscode-eslint-language-server", "--stdio" }, {
        ".eslintrc",
        ".eslintrc.js",
        ".eslintrc.cjs",
        ".eslintrc.json",
        "eslint.config.js",
        "package.json",
        ".git",
      })
    end

    if vim.fs.root(0, { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.ts", "postcss.config.js" }) then
      start_web_language_server("tailwindcss", { "tailwindcss-language-server", "--stdio" }, {
        "tailwind.config.js",
        "tailwind.config.cjs",
        "tailwind.config.ts",
        "postcss.config.js",
        "package.json",
        ".git",
      })
    end
  end,
})
