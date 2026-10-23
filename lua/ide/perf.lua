local util = require('perfanno.util')

require('perfanno').setup({
  line_highlights = util.make_bg_highlights(nil, '#FF0000', 10),
  vt_highlight = util.make_fg_highlight('#FF0000'),
  ts_function_patterns = {
    default = { 'function', 'method' },
    c = { 'function_definition' },
    cpp = { 'function_definition', 'lambda_expression' },
  },
})

vim.api.nvim_create_user_command('PerfRecord', function(opts)
  local target = opts.args
  if target == '' then
    target = vim.fn.input('Run under perf: ', vim.fn.getcwd() .. '/build/', 'file')
  end
  if target == '' then
    return
  end
  vim.cmd('botright 12new')
  vim.fn.jobstart('perf record --call-graph dwarf -o perf.data ' .. target, {
    term = true,
    cwd = vim.fn.getcwd(),
    on_exit = function(_, code)
      if code == 0 then
        vim.schedule(function() vim.cmd('PerfLoadCallGraph') end)
      end
    end,
  })
end, { nargs = '*', complete = 'file' })
