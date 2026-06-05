-- Web development defaults for React, TypeScript, CSS, REST files, and NestJS.

local M = {}

local function map(mode, lhs, rhs, desc, extra)
  vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", {
    noremap = true,
    silent = true,
    desc = desc,
  }, extra or {}))
end

local function setup_color_tools()
  require("colorizer").setup({
    "css",
    "scss",
    "sass",
    "less",
    "html",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
  }, {
    RGB = true,
    RRGGBB = true,
    names = true,
    RRGGBBAA = true,
    rgb_fn = true,
    hsl_fn = true,
    css = true,
    css_fn = true,
    tailwind = true,
    mode = "background",
  })

  require("ccc").setup({
    highlighter = {
      auto_enable = true,
      lsp = true,
    },
  })

  map("n", "<leader>cp", "<cmd>CccPick<cr>", "Color picker")
  map("n", "<leader>cc", "<cmd>CccConvert<cr>", "Convert color under cursor")
  map("n", "<leader>ct", "<cmd>ColorizerToggle<cr>", "Toggle color previews")
end



local function setup_emmet()
  vim.g.user_emmet_install_global = 0
  vim.g.user_emmet_leader_key = "<C-y>"

  vim.api.nvim_create_autocmd("FileType", {
    pattern = {
      "html",
      "css",
      "scss",
      "sass",
      "less",
      "javascriptreact",
      "typescriptreact",
      "vue",
      "svelte",
    },
    callback = function()
      vim.cmd.EmmetInstall()
    end,
  })
end

local function setup_autotag()
  require("nvim-ts-autotag").setup({
    opts = {
      enable_close = true,
      enable_rename = true,
      enable_close_on_slash = false,
    },
  })
end

function M.setup()
  setup_color_tools()
  setup_emmet()
  setup_autotag()
end

return M
