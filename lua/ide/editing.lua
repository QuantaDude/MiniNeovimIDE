-- General editing, buffer, window and diagnostics helpers.
-- Ported (and tidied) from the old MiniNeovimIDE config, minus anything
-- web-specific and minus its hand-rolled bracket pairing (mini.pairs from
-- ide.explorer already handles that).
local M = {}

local map = vim.keymap.set

local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', false)
end

local function esc_repl(s)
  return vim.fn.escape(s, '/\\&~')
end

---------------------------------------------------------------- commands
local function commands()
  local cmd = vim.api.nvim_create_user_command

  cmd('PrependLines', function(o)
    vim.cmd(('%d,%dnormal! I%s'):format(o.line1, o.line2, o.args))
  end, { range = true, nargs = 1, desc = 'Insert text at the start of each line' })

  cmd('AppendLines', function(o)
    vim.cmd(('%d,%dnormal! A%s'):format(o.line1, o.line2, o.args))
  end, { range = true, nargs = 1, desc = 'Append text to the end of each line' })

  cmd('PrefixWord', function(o)
    local word = vim.fn.expand('<cword>')
    vim.cmd(('%%s/\\<%s\\>/%s&/g'):format(word, esc_repl(o.args)))
  end, { nargs = 1, desc = 'Prefix every occurrence of the word under the cursor' })

  cmd('SuffixWord', function(o)
    local word = vim.fn.expand('<cword>')
    vim.cmd(('%%s/\\<%s\\>/&%s/g'):format(word, esc_repl(o.args)))
  end, { nargs = 1, desc = 'Suffix every occurrence of the word under the cursor' })
end

---------------------------------------------------------------- buffers
local function has_listed_file_buffer()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.api.nvim_buf_get_name(b) ~= '' then
      return true
    end
  end
  return false
end

local function maybe_dashboard()
  vim.schedule(function()
    if not has_listed_file_buffer() then
      local ok, dash = pcall(require, 'ide.dashboard')
      if ok then
        dash.open()
      end
    end
  end)
end

local function close_buffer(force)
  local ok, bufremove = pcall(require, 'mini.bufremove')
  if ok then
    bufremove.delete(0, force)
  else
    vim.cmd(force and 'bdelete!' or 'bdelete')
  end
  maybe_dashboard()
end

local function any_modified()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].modified then
      return true
    end
  end
  return false
end

local function buffers()
  map('n', '<leader>bw', '<cmd>write<cr>', { desc = 'Save buffer' })
  map('n', '<leader>bW', '<cmd>wall<cr>', { desc = 'Save all buffers' })
  map('n', '<leader>bc', function() close_buffer(false) end, { desc = 'Close buffer' })
  map('n', '<leader>bC', function() close_buffer(true) end, { desc = 'Close buffer (discard changes)' })
  map('n', '<leader>bb', '<cmd>buffer #<cr>', { desc = 'Alternate buffer' })
  map('n', '<leader>bo', function()
    local cur = vim.api.nvim_get_current_buf()
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if b ~= cur and vim.bo[b].buflisted and not vim.bo[b].modified then
        pcall(vim.api.nvim_buf_delete, b, {})
      end
    end
  end, { desc = 'Close other buffers' })
  map('n', '<leader>ba', function()
    if any_modified() then
      return vim.notify('Unsaved buffers exist', vim.log.levels.WARN)
    end
    vim.cmd('%bdelete')
    maybe_dashboard()
  end, { desc = 'Close all buffers (safe)' })
end

---------------------------------------------------------------- windows
local function windows()
  map('n', '<leader>v', '<cmd>vsplit<cr>', { desc = 'Vertical split' })
  map('n', '<leader>h', '<cmd>split<cr>', { desc = 'Horizontal split' })
  map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit window' })
  map('n', '<leader>Q', '<cmd>quitall<cr>', { desc = 'Quit Neovim' })

  map('n', '<C-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
  map('n', '<C-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
  map('n', '<C-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
  map('n', '<C-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })
end

---------------------------------------------------------------- text
local function text()
  -- native gc / gcc do the work; these are the old <leader>/ muscle-memory maps
  map('n', '<leader>/', 'gcc', { remap = true, desc = 'Toggle comment (line)' })
  map('x', '<leader>/', 'gc', { remap = true, desc = 'Toggle comment (selection)' })

  -- block insert / append over N lines (count): <leader>3I, <leader>5A, ...
  map('n', '<leader>i', function()
    local n = vim.v.count1
    feed('<C-v>' .. (n > 1 and (n - 1) .. 'j' or '') .. 'I')
  end, { desc = 'Insert at cursor column on N lines' })
  map('n', '<leader>I', function()
    local n = vim.v.count1
    feed('0<C-v>' .. (n > 1 and (n - 1) .. 'j' or '') .. 'I')
  end, { desc = 'Insert at start of N lines' })
  local function append_eol()
    local n = vim.v.count1
    feed('<C-v>' .. (n > 1 and (n - 1) .. 'j' or '') .. '$A')
  end
  map('n', '<leader>a', append_eol, { desc = 'Append at end of N lines' })
  map('n', '<leader>A', append_eol, { desc = 'Append at end of N lines (alias)' })

  -- rename / replace
  map('n', '<leader>rr', [[:%s/\<<C-r><C-w>\>//g<Left><Left>]], { desc = 'Replace word in buffer' })
  map('x', '<leader>r', [[:s/\<<C-r><C-w>\>//gc<Left><Left><Left>]], { desc = 'Replace word in selection' })

  -- prefix / suffix the word under the cursor inside the enclosing { ... }
  local function in_braces(kind)
    return function()
      local word = vim.fn.expand('<cword>')
      local text_in = vim.fn.input(kind == 'p' and 'Prefix: ' or 'Suffix: ')
      if text_in == '' then
        return
      end
      local sub = kind == 'p' and (esc_repl(text_in) .. '&') or ('&' .. esc_repl(text_in))
      local ok, err = pcall(vim.cmd, ([[?{?+1,/}/-1s/\<%s\>/%s/g]]):format(word, sub))
      if not ok then
        vim.notify('No enclosing { } block: ' .. tostring(err), vim.log.levels.WARN)
      end
    end
  end
  map('n', '<leader>{p', in_braces('p'), { desc = 'Prefix word inside { }' })
  map('n', '<leader>{s', in_braces('s'), { desc = 'Suffix word inside { }' })

  -- C uses /* */ by default; line comments are what C/C++ code bases want
  vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('ide.editing', { clear = true }),
    pattern = { 'c', 'cuda' },
    callback = function(ev)
      vim.bo[ev.buf].commentstring = '// %s'
    end,
  })
end

---------------------------------------------------------------- diagnostics
local function diagnostics()
  local sev = vim.diagnostic.severity
  local function jump(count, severity)
    return function()
      vim.diagnostic.jump({ count = count, severity = severity })
    end
  end
  map('n', ']e', jump(1, sev.ERROR), { desc = 'Next error' })
  map('n', '[e', jump(-1, sev.ERROR), { desc = 'Previous error' })
  map('n', ']w', jump(1, sev.WARN), { desc = 'Next warning' })
  map('n', '[w', jump(-1, sev.WARN), { desc = 'Previous warning' })
  map('n', '<leader>cd', function() vim.diagnostic.open_float() end, { desc = 'Line diagnostics' })
  map('n', '<leader>cq', function() vim.diagnostic.setqflist() end, { desc = 'Diagnostics to quickfix' })
end

function M.setup()
  commands()
  buffers()
  windows()
  text()
  diagnostics()
end

return M
