-- NvChad-style user config. Read by `nvconfig` (NvChad/ui) and base46.
--
-- The theme picker (<leader>ut) rewrites the `theme = "..."` line below when
-- you confirm a theme, exactly like it does in NvChad. Keep that name quoted
-- exactly once in this file.

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "doomchad",
  transparency = false,

  -- extra highlight integrations compiled on top of base46's defaults
  integrations = { "dap", "gitsigns", "mini-tabline", "notify" },
}

M.ui = {
  -- "atom" is the style from the screenshot: lighter icon cells on the left,
  -- grey kind column on the right, borderless darker docs pane.
  -- Others: default / flat_light / flat_dark / atom_colored
  cmp = {
    style = "atom",
    icons_left = false,
    abbr_maxwidth = 60,
    format_colors = { lsp = true, icon = "󱓻" },
  },

  -- this config keeps mini.statusline / mini.tabline
  statusline = { enabled = false },
  tabufline = { enabled = false },
}

M.nvdash = { load_on_startup = false }

M.colorify = {
  enabled = true,
  mode = "virtual", -- fg | bg | virtual
  virt_text = "󱓻 ",
  highlight = { hex = true, lspvars = true },
}

M.cheatsheet = {
  theme = "grid", -- grid | simple
}

M.themepicker = {
  style = "bordered", -- bordered | flat | compact
}

return M
