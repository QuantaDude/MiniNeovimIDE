local M = {}

local state_file = vim.fs.joinpath(vim.fn.stdpath('state'), 'colorscheme')

local function apply(name)
  return pcall(vim.cmd.colorscheme, name)
end

local function saved()
  local ok, lines = pcall(vim.fn.readfile, state_file)
  return ok and lines[1] or nil
end

-- Original loader: plain :colorscheme from the plugins in ide.pack
function M.load_colorscheme()
  local name = saved() or 'catppuccin-mocha'
  if not apply(name) then
    apply('habamax')
  end
end

-- Default: base46 theme from lua/chadrc.lua (NvChad's theme engine).
-- Falls back to the plain colorscheme path when base46 is unavailable or when
-- a plain colorscheme was chosen via <leader>uC.
function M.load()
  local b46 = require('ide.base46')
  if b46.mode() == 'base46' and b46.available() and b46.load() then
    return
  end
  M.load_colorscheme()
end

-- Original MiniPick colorscheme picker (installed :colorscheme plugins), <leader>uC
function M.pick_colorscheme()
  local original = vim.g.colors_name
  local picked = MiniPick.start({
    source = {
      name = 'Themes (<Tab> previews)',
      items = vim.fn.getcompletion('', 'color'),
      preview = function(buf, item)
        apply(item)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { item })
      end,
      choose = function() end,
    },
  })
  if picked then
    apply(picked)
    vim.fn.writefile({ picked }, state_file)
    if picked ~= 'base46' then
      require('ide.base46').set_mode('colorscheme')
    else
      require('ide.base46').set_mode('base46')
    end
  elseif original then
    apply(original)
  end
end

-- <leader>ut: NvChad's base46 theme picker (live preview, saved to chadrc.lua)
function M.pick()
  require('ide.base46').pick()
end

return M
