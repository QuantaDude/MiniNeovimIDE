local langs = {
  'c', 'cpp', 'cmake', 'make', 'lua', 'vim', 'vimdoc', 'query',
  'markdown', 'markdown_inline', 'json', 'yaml', 'toml', 'bash', 'diff', 'gitcommit',
}

local ok, ts = pcall(require, 'nvim-treesitter')
if ok then
  ts.install(langs)
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('ide.syntax', { clear = true }),
  callback = function(ev)
    if not pcall(vim.treesitter.start, ev.buf) then
      return
    end
    vim.wo.foldmethod = 'expr'
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
    if ev.match ~= 'c' and ev.match ~= 'cpp' then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
