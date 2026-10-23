require('conform').setup({
  formatters_by_ft = {
    c = { 'clang_format' },
    cpp = { 'clang_format' },
    objc = { 'clang_format' },
    objcpp = { 'clang_format' },
    cuda = { 'clang_format' },
    lua = { 'stylua' },
  },
  format_on_save = function(buf)
    if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
      return
    end
    return { timeout_ms = 1500, lsp_format = 'fallback' }
  end,
})

vim.api.nvim_create_user_command('FormatToggle', function(opts)
  if opts.bang then
    vim.b.disable_autoformat = not vim.b.disable_autoformat
    vim.notify('Buffer autoformat: ' .. (vim.b.disable_autoformat and 'off' or 'on'))
  else
    vim.g.disable_autoformat = not vim.g.disable_autoformat
    vim.notify('Global autoformat: ' .. (vim.g.disable_autoformat and 'off' or 'on'))
  end
end, { bang = true })

local styles = { 'LLVM', 'Google', 'Chromium', 'Mozilla', 'WebKit', 'Microsoft', 'GNU' }

vim.api.nvim_create_user_command('ClangFormatInit', function(opts)
  local style = opts.args ~= '' and opts.args or 'LLVM'
  local root = vim.fs.root(0, { '.git', 'CMakeLists.txt', 'compile_commands.json' }) or vim.fn.getcwd()
  local out = vim.system({ 'clang-format', '-style=' .. style, '-dump-config' }, { text = true }):wait()
  if out.code ~= 0 then
    return vim.notify(out.stderr ~= '' and out.stderr or 'clang-format failed', vim.log.levels.ERROR)
  end
  local path = root .. '/.clang-format'
  vim.fn.writefile(vim.split(out.stdout, '\n'), path)
  vim.cmd.edit(path)
end, {
  nargs = '?',
  complete = function() return styles end,
})
