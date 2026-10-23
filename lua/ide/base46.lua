-- Bridge between this config and NvChad's base46 (theme engine) + nvchad-ui.
--
-- Only the pieces we want are used: highlight compilation, the theme picker,
-- the cheatsheet, colorify, the cmp format and LSP signature helper. The rest
-- of the NvChad framework (statusline, tabufline, nvdash, ...) is not loaded.
local M = {}

-- same order base46 itself uses (see base46/init.lua)
local INTEGRATIONS = {
  'blankline', 'blink', 'cmp', 'defaults', 'devicons', 'git', 'lsp', 'mason',
  'nvcheatsheet', 'nvimtree', 'statusline', 'syntax', 'treesitter', 'tbline',
  'telescope', 'whichkey',
}

local state_dir = vim.fn.stdpath('state')
local mode_file = vim.fs.joinpath(state_dir, 'theme_mode')

local function cache()
  return vim.g.base46_cache
end

local function chadrc_path()
  return vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'chadrc.lua')
end

---@return boolean
function M.available()
  if M._available == nil then
    M._available = (pcall(require, 'nvconfig') and pcall(require, 'base46')) and true or false
  end
  return M._available
end

--- 'base46' (default) or 'colorscheme' (a plain :colorscheme was chosen with <leader>uC)
function M.mode()
  local ok, lines = pcall(vim.fn.readfile, mode_file)
  return (ok and lines[1] == 'colorscheme') and 'colorscheme' or 'base46'
end

function M.set_mode(mode)
  pcall(vim.fn.mkdir, state_dir, 'p')
  pcall(vim.fn.writefile, { mode }, mode_file)
end

local function stamp_file()
  return cache() .. '.stamp'
end

local function current_stamp()
  local ok, lines = pcall(vim.fn.readfile, chadrc_path())
  return vim.fn.sha256(ok and table.concat(lines, '\n') or '')
end

--- Compile the highlight cache if it is missing or chadrc.lua / plugins changed.
function M.ensure_cache()
  if not M.available() then
    return false
  end
  local stamp = current_stamp()
  local ok, old = pcall(vim.fn.readfile, stamp_file())
  local fresh = ok and old[1] == stamp and not vim.g.ide_base46_stale
  if fresh and vim.uv.fs_stat(cache() .. 'defaults') then
    return true
  end
  local done, err = pcall(function()
    require('base46').compile()
    vim.fn.writefile({ stamp }, stamp_file())
  end)
  vim.g.ide_base46_stale = nil
  if not done then
    vim.notify('base46: compile failed: ' .. tostring(err), vim.log.levels.ERROR)
  end
  return done
end

--- Apply the base46 theme from the compiled cache (what `:colorscheme base46` does).
---@return boolean
function M.load()
  if not (M.available() and M.ensure_cache()) then
    return false
  end

  vim.cmd('hi clear')
  if vim.fn.exists('syntax_on') == 1 then
    vim.cmd('syntax reset')
  end

  local opts = require('nvconfig').base46
  local excluded = {}
  for _, name in ipairs(opts.excluded or {}) do
    excluded[name] = true
  end

  local seen = {}
  local names = vim.list_extend(vim.deepcopy(INTEGRATIONS), opts.integrations or {})
  for _, name in ipairs(names) do
    if not seen[name] and not excluded[name] then
      seen[name] = true
      local file = cache() .. name
      if vim.uv.fs_stat(file) then
        local ok, err = pcall(dofile, file)
        if not ok then
          vim.notify(('base46: %s: %s'):format(name, err), vim.log.levels.WARN)
        end
      end
    end
  end

  vim.g.colors_name = 'base46'
  vim.api.nvim_exec_autocmds('User', { pattern = 'NvThemeReload', modeline = false })
  return true
end

--- Recompile + reload from the current in-memory nvconfig (used after edits).
function M.reload()
  if M.available() then
    require('base46').load_all_highlights()
  end
end

-- The NvChad picker persists the choice by calling utils.replace_word() on
-- confirm only. Hook that so confirming also flips us back to base46 mode.
local function hook_persist()
  local utils = require('nvchad.utils')
  if utils._ide_hooked then
    return
  end
  utils._ide_hooked = true
  local replace_word = utils.replace_word
  utils.replace_word = function(...)
    replace_word(...)
    M.set_mode('base46')
  end
end

--- NvChad's base46 theme picker (live preview, fuzzy filter, persists to chadrc.lua)
function M.pick()
  if not M.available() then
    return vim.notify('base46 / nvchad-ui are not installed yet (restart nvim)', vim.log.levels.WARN)
  end
  if not M.ensure_cache() then
    return
  end

  local was_plain = M.mode() == 'colorscheme'
  local previous = vim.g.colors_name
  if was_plain then
    M.load() -- browse on a clean base46 canvas
  end

  hook_persist()
  local ok, err = pcall(function()
    require('nvchad.themes').open()
  end)
  if not ok then
    vim.notify('theme picker failed: ' .. tostring(err), vim.log.levels.ERROR)
    if was_plain and previous and previous ~= 'base46' then
      pcall(vim.cmd.colorscheme, previous)
    end
    return
  end

  -- cancelled while a plain colorscheme was active -> put it back
  if was_plain and previous and previous ~= 'base46' then
    local win = require('nvchad.themes.state').input_win
    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(win),
      once = true,
      callback = function()
        vim.schedule(function()
          if M.mode() == 'colorscheme' then
            pcall(vim.cmd.colorscheme, previous)
          end
        end)
      end,
    })
  end
end

--- Palette (base_30 names) for our own highlight groups. Falls back to the
--- active colorscheme's groups when base46 is not what is currently applied.
---@return table<string,string>
function M.palette()
  if vim.g.colors_name == 'base46' and cache() and vim.uv.fs_stat(cache() .. 'colors') then
    local ok, colors = pcall(dofile, cache() .. 'colors')
    if ok and type(colors) == 'table' then
      return colors
    end
  end

  local function fg(group, fallback)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    return hl.fg and ('#%06x'):format(hl.fg) or fallback
  end
  local function bg(group, fallback)
    local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
    return hl.bg and ('#%06x'):format(hl.bg) or fallback
  end

  local base = bg('Normal', '#1e222a')
  return {
    black = base,
    darker_black = bg('NormalFloat', base),
    black2 = bg('Pmenu', base),
    one_bg = bg('CursorLine', base),
    one_bg2 = bg('Visual', base),
    statusline_bg = bg('StatusLine', base),
    white = fg('Normal', '#d0d0d0'),
    light_grey = fg('Comment', '#808080'),
    grey_fg = fg('LineNr', '#606060'),
    blue = fg('Function', '#61afef'),
    cyan = fg('Special', '#56b6c2'),
    teal = fg('Type', '#4ec9b0'),
    green = fg('String', '#98c379'),
    yellow = fg('WarningMsg', '#e5c07b'),
    orange = fg('Constant', '#d19a66'),
    red = fg('ErrorMsg', '#e06c75'),
    purple = fg('Keyword', '#c678dd'),
    pink = fg('Statement', '#e06c75'),
    baby_pink = fg('Identifier', '#e06c75'),
    vibrant_green = fg('DiffAdd', '#98c379'),
    lightbg = bg('Visual', base),
  }
end

return M
