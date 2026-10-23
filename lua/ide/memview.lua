local M = {}

local ns = vim.api.nvim_create_namespace('ide.memview')
local COLS = 16
local state = { buf = nil, win = nil, expr = nil, offset = 0, count = 256, prev = nil }

local function warn(msg)
  vim.notify('memview: ' .. msg, vim.log.levels.WARN)
end

local function session()
  local s = require('dap').session()
  if not s then
    warn('no active debug session')
  end
  return s
end

local function resolve(s, expr, cb)
  if expr:match('^0x%x+$') or expr:match('^%d+$') then
    return cb(expr)
  end
  local candidates = { expr, '&' .. expr }
  local function try(i)
    if not candidates[i] then
      return warn('cannot resolve "' .. expr .. '" to an address')
    end
    local args = { expression = candidates[i], context = 'watch' }
    if s.current_frame then
      args.frameId = s.current_frame.id
    end
    s:request('evaluate', args, function(err, resp)
      local ref = not err and resp and (resp.memoryReference or (i > 1 and (resp.result or ''):match('0x%x+')))
      if ref then
        cb(ref)
      else
        try(i + 1)
      end
    end)
  end
  try(1)
end

local function draw(addr, bytes, unreadable)
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end
  local lines = {}
  for r = 0, math.ceil(#bytes / COLS) - 1 do
    local hex, asc = {}, {}
    for j = 0, COLS - 1 do
      local b = bytes:byte(r * COLS + j + 1)
      hex[#hex + 1] = (b and ('%02x '):format(b) or '   ') .. (j == 7 and ' ' or '')
      asc[#asc + 1] = b and ((b >= 32 and b < 127) and string.char(b) or '.') or ' '
    end
    lines[#lines + 1] = ('0x%012x  %s |%s|'):format(addr + r * COLS, table.concat(hex), table.concat(asc))
  end
  if #bytes == 0 then
    lines = { '<unreadable memory>' }
  elseif unreadable and unreadable > 0 then
    lines[#lines + 1] = ('<%d unreadable bytes follow>'):format(unreadable)
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(state.buf, ns, 0, -1)
  local prev = state.prev
  if prev and prev.addr == addr and #prev.bytes == #bytes then
    for i = 1, #bytes do
      if bytes:byte(i) ~= prev.bytes:byte(i) then
        local row, j = math.floor((i - 1) / COLS), (i - 1) % COLS
        local col = 16 + j * 3 + (j >= 8 and 1 or 0)
        vim.api.nvim_buf_set_extmark(state.buf, ns, row, col, { end_col = col + 2, hl_group = 'DiffText' })
      end
    end
  end
  state.prev = { addr = addr, bytes = bytes }

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local title = (' memory  %s  @ 0x%x  %d bytes  [r refresh  n/p page  g goto  +/- size  q close] '):format(state.expr, addr, state.count)
    vim.wo[state.win].winbar = title:gsub('%%', '%%%%')
  end
end

function M.refresh()
  local s = session()
  if not s or not state.expr then
    return
  end
  resolve(s, state.expr, function(ref)
    s:request('readMemory', { memoryReference = ref, offset = state.offset, count = state.count }, function(err, resp)
      if err or not resp then
        return warn((err and err.message) or 'readMemory failed')
      end
      local bytes = resp.data and vim.base64.decode(resp.data) or ''
      local addr = tonumber(resp.address)
      if not addr then
        return warn('adapter returned no address')
      end
      vim.schedule(function()
        draw(addr, bytes, resp.unreadableBytes)
      end)
    end)
  end)
end

local function set_target(expr)
  if not expr or expr == '' then
    return
  end
  state.expr, state.offset, state.prev = expr, 0, nil
  M.refresh()
end

local function ensure_window()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    local b = vim.api.nvim_create_buf(false, true)
    state.buf = b
    vim.bo[b].bufhidden = 'hide'
    vim.bo[b].filetype = 'dapmemory'
    vim.bo[b].modifiable = false
    pcall(vim.api.nvim_buf_set_name, b, 'dap-memory')
    local function map(lhs, fn)
      vim.keymap.set('n', lhs, fn, { buffer = b, nowait = true })
    end
    map('q', function() M.close() end)
    map('r', M.refresh)
    map('n', function() state.offset = state.offset + state.count; M.refresh() end)
    map('p', function() state.offset = state.offset - state.count; M.refresh() end)
    map('+', function() state.count = math.min(state.count * 2, 65536); M.refresh() end)
    map('-', function() state.count = math.max(math.floor(state.count / 2), COLS); M.refresh() end)
    map('g', function()
      vim.ui.input({ prompt = 'Expression or 0xaddress: ', default = state.expr }, set_target)
    end)
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    return
  end
  local origin = vim.api.nvim_get_current_win()
  vim.cmd('botright 14split')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)
  local wo = vim.wo[state.win]
  wo.number, wo.relativenumber, wo.wrap, wo.signcolumn = false, false, false, 'no'
  wo.foldcolumn, wo.cursorline, wo.winfixheight = '0', true, true
  vim.api.nvim_set_current_win(origin)
end

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  state.win = nil
end

function M.open(expr)
  if not session() then
    return
  end
  local function go(e)
    if e and e ~= '' then
      ensure_window()
      set_target(e)
    end
  end
  if expr and expr ~= '' then
    return go(expr)
  end
  vim.ui.input({
    prompt = 'Memory of (expression or 0xaddress): ',
    default = vim.fn.expand('<cexpr>') ~= '' and vim.fn.expand('<cexpr>') or state.expr,
  }, go)
end

function M.open_visual()
  local text = table.concat(vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), { type = vim.fn.mode() }), ' ')
  vim.cmd('normal! \27')
  M.open(vim.trim(text))
end

function M.setup()
  require('dap').listeners.after.event_stopped['ide.memview'] = function()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
      M.refresh()
    end
  end
end

return M
