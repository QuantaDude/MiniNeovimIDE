local map = vim.keymap.set

local function dap(fn, ...)
  local args = { ... }
  return function()
    require('dap')[fn](unpack(args))
  end
end

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('t', '<Esc><Esc>', [[<C-\><C-n>]])
map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

map('n', '<leader>e', function() require('ide.explorer').toggle() end, { desc = 'File explorer' })
map('n', '<leader>ff', function() MiniPick.builtin.files() end, { desc = 'Find files' })
map('n', '<leader>fg', function() MiniPick.builtin.grep_live() end, { desc = 'Live grep' })
map('n', '<leader>fb', function() MiniPick.builtin.buffers() end, { desc = 'Buffers' })
map('n', '<leader>fh', function() MiniPick.builtin.help() end, { desc = 'Help' })
map('n', '<leader>fr', function() MiniPick.builtin.resume() end, { desc = 'Resume picker' })
map('n', '<leader>fs', function() MiniExtra.pickers.lsp({ scope = 'document_symbol' }) end, { desc = 'Document symbols' })
map('n', '<leader>fS', function() MiniExtra.pickers.lsp({ scope = 'workspace_symbol' }) end, { desc = 'Workspace symbols' })
map('n', '<leader>fd', function() MiniExtra.pickers.diagnostic() end, { desc = 'Diagnostics' })
map('n', '<leader>ut', function() require('ide.theme').pick() end, { desc = 'Theme picker' })

map({ 'n', 'x' }, '<leader>cf', function()
  require('conform').format({ async = true, lsp_format = 'fallback' })
end, { desc = 'Format' })
map('n', '<leader>ch', function() require('ide.lsp').switch_source_header() end, { desc = 'Switch source/header' })
map('n', '<leader>cb', function() require('ide.build').build() end, { desc = 'Build' })

local function cmd(name)
  return function()
    local ok, err = pcall(vim.cmd, name)
    if not ok then
      vim.notify(('%s failed: %s'):format(name, err), vim.log.levels.WARN)
    end
  end
end

map('n', '<leader>mg', cmd('CMakeGenerate'), { desc = 'CMake generate' })
map('n', '<leader>mb', cmd('CMakeBuild'), { desc = 'CMake build' })
map('n', '<leader>mr', cmd('CMakeRun'), { desc = 'CMake run' })
map('n', '<leader>md', cmd('CMakeDebug'), { desc = 'CMake debug' })
map('n', '<leader>mc', cmd('CMakeClean'), { desc = 'CMake clean' })
map('n', '<leader>mx', cmd('CMakeStopExecutor'), { desc = 'CMake stop build' })
map('n', '<leader>mt', cmd('CMakeSelectLaunchTarget'), { desc = 'CMake launch target' })
map('n', '<leader>mT', cmd('CMakeSelectBuildTarget'), { desc = 'CMake build target' })
map('n', '<leader>mv', cmd('CMakeSelectBuildType'), { desc = 'CMake build type' })
map('n', '<leader>ma', cmd('CMakeLaunchArgs'), { desc = 'CMake launch args' })
map('n', '<leader>ms', cmd('CMakeSettings'), { desc = 'CMake settings' })

map('n', '<leader>pr', cmd('PerfRecord'), { desc = 'Perf record and load' })
map('n', '<leader>pl', cmd('PerfLoadCallGraph'), { desc = 'Perf load call graph' })
map('n', '<leader>pa', cmd('PerfToggleAnnotations'), { desc = 'Perf toggle annotations' })
map('n', '<leader>ph', cmd('PerfHottestLines'), { desc = 'Perf hottest lines' })
map('n', '<leader>ps', cmd('PerfHottestSymbols'), { desc = 'Perf hottest symbols' })
map('n', '<leader>pc', cmd('PerfHottestCallersFunction'), { desc = 'Perf callers of function' })
map('n', '<leader>pf', cmd('PerfAnnotateFunction'), { desc = 'Perf annotate function' })
map('n', '<leader>pe', cmd('PerfPickEvent'), { desc = 'Perf pick event' })
map('n', '<leader>pF', cmd('PerfCycleFormat'), { desc = 'Perf cycle format' })
map('x', '<leader>pc', ':PerfHottestCallersSelection<CR>', { desc = 'Perf callers of selection' })
map('x', '<leader>pf', ':PerfAnnotateSelection<CR>', { desc = 'Perf annotate selection' })

map('x', '<leader>cr', function() require('ide.regions').wrap() end, { desc = 'Wrap in #pragma region' })
map('n', '<leader>cR', function() require('ide.regions').list() end, { desc = 'List regions' })
map('n', ']r', function() require('ide.regions').jump(false) end, { desc = 'Next region' })
map('n', '[r', function() require('ide.regions').jump(true) end, { desc = 'Previous region' })

map('n', '<F5>', dap('continue'), { desc = 'Debug: start/continue' })
map('n', '<F9>', dap('toggle_breakpoint'), { desc = 'Debug: breakpoint' })
map('n', '<F10>', dap('step_over'), { desc = 'Debug: step over' })
map('n', '<F11>', dap('step_into'), { desc = 'Debug: step into' })
map('n', '<S-F11>', dap('step_out'), { desc = 'Debug: step out' })
map('n', '<leader>db', dap('toggle_breakpoint'), { desc = 'Toggle breakpoint' })
map('n', '<leader>dB', function()
  require('dap').set_breakpoint(vim.fn.input('Condition: '))
end, { desc = 'Conditional breakpoint' })
map('n', '<leader>dc', dap('continue'), { desc = 'Continue' })
map('n', '<leader>dC', dap('run_to_cursor'), { desc = 'Run to cursor' })
map('n', '<leader>do', dap('step_over'), { desc = 'Step over' })
map('n', '<leader>di', dap('step_into'), { desc = 'Step into' })
map('n', '<leader>dO', dap('step_out'), { desc = 'Step out' })
map('n', '<leader>dl', dap('run_last'), { desc = 'Run last' })
map('n', '<leader>dr', dap('restart'), { desc = 'Restart' })
map('n', '<leader>dt', dap('terminate'), { desc = 'Terminate' })
map('n', '<leader>dR', dap('repl.toggle'), { desc = 'REPL' })
map('n', '<leader>du', function() require('dapui').toggle() end, { desc = 'Debug UI' })
map({ 'n', 'x' }, '<leader>de', function() require('dapui').eval() end, { desc = 'Evaluate' })
map('n', '<leader>dm', function() require('ide.memview').open() end, { desc = 'Memory view' })
map('x', '<leader>dm', function() require('ide.memview').open_visual() end, { desc = 'Memory view of selection' })

map({ 'i', 's' }, '<Tab>', function()
  if vim.snippet.active({ direction = 1 }) then
    return '<Cmd>lua vim.snippet.jump(1)<CR>'
  end
  return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>'
end, { expr = true })

map({ 'i', 's' }, '<S-Tab>', function()
  if vim.snippet.active({ direction = -1 }) then
    return '<Cmd>lua vim.snippet.jump(-1)<CR>'
  end
  return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>'
end, { expr = true })

map('i', '<CR>', function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ 'selected' }).selected ~= -1 then
    return '<C-y>'
  end
  return '<CR>'
end, { expr = true })
