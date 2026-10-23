local M = {}

function M.switch_source_header()
  local buf = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = buf, name = 'clangd' })[1]
  if not client then
    return vim.notify('clangd is not attached', vim.log.levels.WARN)
  end
  client:request('textDocument/switchSourceHeader', { uri = vim.uri_from_bufnr(buf) }, function(err, result)
    if err or not result or result == '' then
      return vim.notify('No matching source/header', vim.log.levels.INFO)
    end
    vim.cmd.edit(vim.uri_to_fname(result))
  end, buf)
end

function M.setup()
  vim.lsp.config('clangd', {
    cmd = {
      'clangd',
      '--background-index',
      '--clang-tidy',
      '--header-insertion=iwyu',
      '--completion-style=detailed',
      '--function-arg-placeholders=true',
      '--enable-config',
    },
    filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
    root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', 'CMakeLists.txt', 'meson.build', '.git' },
    init_options = { usePlaceholders = true, completeUnimported = true, clangdFileStatus = true },
  })
  vim.lsp.enable('clangd')

  vim.diagnostic.config({
    virtual_text = { spacing = 2, source = 'if_many' },
    severity_sort = true,
    float = { source = true },
  })

  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('ide.lsp', { clear = true }),
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if not client then
        return
      end
      -- native completion is the fallback; nvim-cmp (ide.completion) sets vim.g.ide_cmp
      if not vim.g.ide_cmp and client:supports_method('textDocument/completion') then
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
      end
      if client:supports_method('textDocument/inlayHint') then
        vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
      end
      local function map(lhs, rhs, desc)
        vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
      end
      map('gd', vim.lsp.buf.definition, 'Go to definition')
      map('gD', vim.lsp.buf.declaration, 'Go to declaration')
    end,
  })
end

return M
