local M = {}

local cache = {}
local fts = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' }
local start_pat = '^%s*#%s*pragma%s+region'
local end_pat = '^%s*#%s*pragma%s+endregion'

local function scan(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local c = cache[buf]
  if c and c.tick == tick then
    return c
  end
  local depth, kind, level = 0, {}, {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match(start_pat) then
      depth = depth + 1
      kind[i], level[i] = 's', depth
    elseif depth > 0 and line:match(end_pat) then
      kind[i], level[i] = 'e', depth
      depth = depth - 1
    else
      level[i] = depth
    end
  end
  c = { tick = tick, kind = kind, level = level }
  cache[buf] = c
  return c
end

function M.foldexpr()
  local lnum = vim.v.lnum
  local c = scan(vim.api.nvim_get_current_buf())
  local k = c.kind[lnum]
  if k == 's' then
    return '>' .. c.level[lnum]
  elseif k == 'e' then
    return '<' .. c.level[lnum]
  end
  local base = c.level[lnum] or 0
  local r = tostring(vim.treesitter.foldexpr(lnum))
  if r == '=' then
    return '='
  end
  local pre, n = r:match('^([<>]?)(%d+)$')
  if not n then
    return base
  end
  return pre .. (tonumber(n) + base)
end

function M.foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local name = line:match(start_pat .. '%s*(.-)%s*$')
  if name then
    local count = vim.v.foldend - vim.v.foldstart + 1
    return ('▸ %s  (%d lines)'):format(name ~= '' and name or 'region', count)
  end
  return vim.fn.foldtext()
end

function M.list()
  local items = {}
  for i, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local name = line:match(start_pat .. '%s*(.-)%s*$')
    if name then
      items[#items + 1] = { lnum = i, label = ('%4d  %s'):format(i, name ~= '' and name or '(unnamed)') }
    end
  end
  if #items == 0 then
    return vim.notify('No #pragma region in this buffer', vim.log.levels.INFO)
  end
  vim.ui.select(items, {
    prompt = 'Regions',
    format_item = function(it) return it.label end,
  }, function(choice)
    if choice then
      vim.api.nvim_win_set_cursor(0, { choice.lnum, 0 })
      vim.cmd('normal! zv')
    end
  end)
end

function M.jump(backwards)
  vim.fn.search([[^\s*#\s*pragma\s\+region]], backwards and 'bW' or 'W')
end

function M.wrap()
  local a, b = vim.fn.line('v'), vim.fn.line('.')
  local first, last = math.min(a, b), math.max(a, b)
  vim.cmd('normal! \27')
  vim.ui.input({ prompt = 'Region name: ' }, function(name)
    if name == nil then
      return
    end
    local indent = vim.fn.getline(first):match('^%s*')
    local header = indent .. '#pragma region' .. (name ~= '' and (' ' .. name) or '')
    vim.api.nvim_buf_set_lines(0, last, last, false, { indent .. '#pragma endregion' })
    vim.api.nvim_buf_set_lines(0, first - 1, first - 1, false, { header })
  end)
end

function M.setup()
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ide.regions', { clear = true }),
    pattern = fts,
    callback = function()
      vim.opt_local.foldmethod = 'expr'
      vim.opt_local.foldexpr = "v:lua.require'ide.regions'.foldexpr()"
      vim.opt_local.foldtext = "v:lua.require'ide.regions'.foldtext()"
    end,
  })
  vim.api.nvim_create_autocmd('BufWipeout', {
    callback = function(ev) cache[ev.buf] = nil end,
  })
  vim.api.nvim_create_user_command('Regions', M.list, {})
end

return M
