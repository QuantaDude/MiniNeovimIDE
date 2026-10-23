-- LSP extras on top of ide.lsp (which only sets up clangd): code-action /
-- rename / call-hierarchy maps, signature help while typing, inlay-hint
-- toggle, optional hover-on-idle, diagnostic icons and lua_ls for editing
-- this very config.
local M = {}

local augroup = vim.api.nvim_create_augroup('ide.lspx', { clear = true })

local function lua_ls()
  if vim.fn.executable('lua-language-server') ~= 1 then
    return
  end
  vim.lsp.config('lua_ls', {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_markers = { '.luarc.json', '.luarc.jsonc', '.stylua.toml', 'stylua.toml', '.git', 'init.lua' },
    settings = {
      Lua = {
        runtime = { version = 'LuaJIT' },
        diagnostics = { globals = { 'vim' } },
        workspace = {
          checkThirdParty = false,
          library = { vim.env.VIMRUNTIME },
        },
        telemetry = { enable = false },
      },
    },
  })
  vim.lsp.enable('lua_ls')
end

local function diagnostic_icons()
  local s = vim.diagnostic.severity
  vim.diagnostic.config({
    signs = {
      text = {
        [s.ERROR] = '\u{F015A}',
        [s.WARN] = '\u{F0026}',
        [s.INFO] = '\u{F02FC}',
        [s.HINT] = '󰌵',
      },
    },
  })
end

local function on_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if not client then
    return
  end

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
  end

  map({ 'n', 'x' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')
  map('n', '<leader>cA', function()
    vim.lsp.buf.code_action({ context = { only = { 'source' }, diagnostics = {} } })
  end, 'Source action (whole file)')
  map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')

  if client:supports_method('callHierarchy/incomingCalls') then
    map('n', '<leader>ci', vim.lsp.buf.incoming_calls, 'Incoming calls')
    map('n', '<leader>co', vim.lsp.buf.outgoing_calls, 'Outgoing calls')
  end

  -- parameter hints while typing "(" or ","  (NvChad's signature helper)
  local sig = client.server_capabilities.signatureHelpProvider
  if sig and sig.triggerCharacters then
    vim.schedule(function()
      local ok, signature = pcall(require, 'nvchad.lsp.signature')
      if ok and vim.api.nvim_buf_is_valid(ev.buf) then
        signature.setup(client, ev.buf)
      end
    end)
  end
end

local function floats_blocking()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg.relative ~= '' and cfg.focusable ~= false then
      return true
    end
  end
  return false
end

--- Diagnostic (or hover docs) popup when the cursor rests on a symbol.
--- Toggle with <leader>uH or `let g:ide_autohover = v:false`.
local function autohover()
  vim.g.ide_autohover = vim.g.ide_autohover ~= false

  vim.api.nvim_create_autocmd('CursorHold', {
    group = augroup,
    callback = function()
      if not vim.g.ide_autohover or vim.fn.mode() ~= 'n' or vim.bo.buftype ~= '' then
        return
      end
      if floats_blocking() then
        return
      end
      if #vim.diagnostic.get(0, { lnum = vim.fn.line('.') - 1 }) > 0 then
        vim.diagnostic.open_float(nil, { focus = false, scope = 'line' })
      elseif #vim.lsp.get_clients({ bufnr = 0, method = 'textDocument/hover' }) > 0 then
        vim.lsp.buf.hover({ silent = true })
      end
    end,
  })

  vim.keymap.set('n', '<leader>uH', function()
    vim.g.ide_autohover = not vim.g.ide_autohover
    vim.notify('Hover on idle: ' .. (vim.g.ide_autohover and 'on' or 'off'))
  end, { desc = 'Toggle hover on idle' })
end

function M.setup()
  lua_ls()
  diagnostic_icons()
  autohover()

  vim.api.nvim_create_autocmd('LspAttach', { group = augroup, callback = on_attach })

  vim.keymap.set('n', '<leader>uh', function()
    local on = not vim.lsp.inlay_hint.is_enabled()
    vim.lsp.inlay_hint.enable(on)
    vim.notify('Inlay hints: ' .. (on and 'on' or 'off'))
  end, { desc = 'Toggle inlay hints' })
end

return M
