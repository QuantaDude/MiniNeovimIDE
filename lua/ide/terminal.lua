-- Integrated terminals: a persistent bottom panel, a floating terminal, and
-- the quick "new terminal" maps from the old config.
local M = {}

local panels = { bottom = nil, float = nil } -- { buf = n, win = n|nil }

local function buf_ok(b)
  return b ~= nil and vim.api.nvim_buf_is_valid(b)
end

local function win_ok(w)
  return w ~= nil and vim.api.nvim_win_is_valid(w)
end

--- Start the user's shell in the current window's buffer.
---@param on_exit? fun()
local function start_shell(on_exit)
  vim.fn.jobstart(vim.o.shell, {
    term = true,
    cwd = vim.fn.getcwd(),
    on_exit = on_exit and vim.schedule_wrap(on_exit) or nil,
  })
end

local function forget(kind)
  local p = panels[kind]
  if not p then
    return
  end
  if win_ok(p.win) then
    pcall(vim.api.nvim_win_close, p.win, true)
  end
  if buf_ok(p.buf) then
    pcall(vim.api.nvim_buf_delete, p.buf, { force = true })
  end
  panels[kind] = nil
end

function M.toggle_bottom()
  local p = panels.bottom
  if p and win_ok(p.win) then
    vim.api.nvim_win_hide(p.win)
    p.win = nil
    return
  end

  vim.cmd('botright 15split')
  local win = vim.api.nvim_get_current_win()
  if p and buf_ok(p.buf) then
    vim.api.nvim_win_set_buf(win, p.buf)
  else
    vim.cmd('enew')
    local buf = vim.api.nvim_get_current_buf()
    vim.bo[buf].buflisted = false
    start_shell(function()
      forget('bottom')
    end)
    p = { buf = buf }
    panels.bottom = p
  end
  p.win = win
  vim.cmd('startinsert')
end

function M.toggle_float()
  local p = panels.float
  if p and win_ok(p.win) then
    vim.api.nvim_win_hide(p.win)
    p.win = nil
    return
  end

  local buf = (p and buf_ok(p.buf)) and p.buf or vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = ' Terminal ',
    title_pos = 'center',
  })
  if not (p and buf_ok(p.buf)) then
    vim.bo[buf].buflisted = false
    start_shell(function()
      forget('float')
    end)
    p = { buf = buf }
    panels.float = p
  end
  p.win = win
  vim.cmd('startinsert')
end

function M.setup()
  local group = vim.api.nvim_create_augroup('ide.terminal', { clear = true })

  vim.api.nvim_create_autocmd('TermOpen', {
    group = group,
    callback = function(ev)
      local win = vim.fn.bufwinid(ev.buf)
      if win > 0 then
        for opt, val in pairs({ number = false, relativenumber = false, signcolumn = 'no', foldcolumn = '0', cursorline = false }) do
          vim.api.nvim_set_option_value(opt, val, { win = win })
        end
      end
      -- move between windows without leaving terminal mode first
      for _, key in ipairs({ 'h', 'j', 'k', 'l' }) do
        vim.keymap.set('t', '<C-' .. key .. '>', '<C-\\><C-n><C-w>' .. key, {
          buffer = ev.buf,
          desc = 'Terminal: go to window ' .. key,
        })
      end
    end,
  })

  -- always land in terminal mode when focusing a terminal
  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].buftype == 'terminal' then
        vim.cmd('startinsert')
      end
    end,
  })

  local map = vim.keymap.set
  map({ 'n', 't' }, '<A-t>', M.toggle_bottom, { desc = 'Terminal: toggle bottom panel' })
  map('n', '<leader>tt', M.toggle_bottom, { desc = 'Toggle bottom terminal' })
  map('n', '<leader>tf', M.toggle_float, { desc = 'Toggle floating terminal' })
  map('n', '<leader>tn', function()
    vim.cmd('enew | terminal')
  end, { desc = 'New terminal (current window)' })
  map('n', '<leader>th', function()
    vim.cmd('botright split | resize 15 | terminal')
  end, { desc = 'New terminal (bottom split)' })
  map('n', '<leader>tv', function()
    vim.cmd('botright vsplit | vertical resize 80 | terminal')
  end, { desc = 'New terminal (vertical split)' })
  map('n', '<leader>tc', function()
    if vim.bo.buftype == 'terminal' then
      vim.cmd('bd!')
    end
  end, { desc = 'Close terminal buffer' })
end

return M
