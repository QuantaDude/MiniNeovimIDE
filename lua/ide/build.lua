local function root()
  return vim.fs.root(0, { 'CMakeLists.txt', 'Makefile', 'meson.build', '.git' }) or vim.fn.getcwd()
end

local function build()
  local dir = root()
  if vim.uv.fs_stat(dir .. '/CMakeLists.txt') then
    vim.cmd('CMakeBuild')
  elseif vim.uv.fs_stat(dir .. '/Makefile') then
    vim.cmd('botright 12new')
    vim.fn.jobstart({ 'make', '-j' }, { term = true, cwd = dir })
  else
    vim.notify('No CMakeLists.txt or Makefile found', vim.log.levels.WARN)
  end
end

local tools = {
  'clangd', 'clang-format', 'lldb-dap', 'lldb-vscode', 'gdb',
  'cmake', 'perf', 'rg', 'tree-sitter', 'git', 'cc',
}

local function doctor()
  local lines = {}
  for _, exe in ipairs(tools) do
    lines[#lines + 1] = ('%s %s'):format(vim.fn.executable(exe) == 1 and 'ok     ' or 'missing', exe)
  end
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO, { title = 'IdeDoctor' })
end

vim.api.nvim_create_user_command('Build', build, {})
vim.api.nvim_create_user_command('IdeDoctor', doctor, {})

return { build = build }
