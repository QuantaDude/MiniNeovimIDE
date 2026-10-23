-- Project / toolchain facts shown on the dashboard and in the statusline.
-- Everything that shells out is asynchronous; everything sync is a cheap stat.
local M = {}

local root_markers = { 'CMakeLists.txt', 'meson.build', 'compile_commands.json', 'Makefile', '.git' }

---@return string
function M.root(from)
  return vim.fs.root(from or vim.fn.getcwd(), root_markers) or vim.fn.getcwd()
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_head(path, max)
  local ok, lines = pcall(vim.fn.readfile, path, '', max or 400)
  return ok and lines or {}
end

local function detect_std(root, kind)
  if kind == 'CMake' then
    for _, line in ipairs(read_head(root .. '/CMakeLists.txt')) do
      local n = line:match('CMAKE_CXX_STANDARD%s+(%d+)') or line:match('cxx_std_(%d+)')
      if n then
        return 'C++' .. n
      end
    end
  elseif kind == 'Meson' then
    for _, line in ipairs(read_head(root .. '/meson.build')) do
      local n = line:match('cpp_std%s*=%s*[\'"]c%+%+(%w+)') or line:match('cpp_std=c%+%+(%w+)')
      if n then
        return 'C++' .. n
      end
    end
  end
  for _, file in ipairs({ root .. '/.clangd', root .. '/.clang-format' }) do
    for _, line in ipairs(read_head(file, 60)) do
      local n = line:match('%-std=c%+%+(%w+)') or line:match('Standard:%s*c%+%+(%w+)') or line:match('Standard:%s*Cpp(%d+)')
      if n then
        return 'C++' .. n
      end
    end
  end
end

--- Cheap, synchronous facts about the project in the current directory.
function M.detect()
  local root = M.root()
  local kind
  if exists(root .. '/CMakeLists.txt') then
    kind = 'CMake'
  elseif exists(root .. '/meson.build') then
    kind = 'Meson'
  elseif exists(root .. '/Makefile') then
    kind = 'Make'
  end
  return {
    root = root,
    name = vim.fs.basename(root),
    kind = kind,
    std = detect_std(root, kind),
    compile_db = exists(root .. '/compile_commands.json') or exists(root .. '/build/compile_commands.json'),
    is_git = exists(root .. '/.git'),
  }
end

local cmake_cache = { at = 0, value = nil }

--- Build type / target from cmake-tools (nil outside CMake projects). Cached ~1s.
function M.cmake()
  local now = vim.uv.hrtime()
  if now - cmake_cache.at < 1e9 then
    return cmake_cache.value
  end
  cmake_cache.at = now
  cmake_cache.value = nil

  if not exists(M.root() .. '/CMakeLists.txt') then
    return nil
  end
  local ok, cmake = pcall(require, 'cmake-tools')
  if not ok then
    return nil
  end
  local function str(v)
    if type(v) == 'table' then
      return table.concat(v, ',')
    end
    return v ~= '' and v or nil
  end
  local _, build_type = pcall(cmake.get_build_type)
  local _, launch = pcall(cmake.get_launch_target)
  local _, build = pcall(cmake.get_build_target)
  cmake_cache.value = {
    build_type = str(build_type),
    target = str(launch) or str(build),
  }
  return cmake_cache.value
end

--- Branch + changed-file count, asynchronously.
---@param cb fun(info: { branch: string, dirty: integer, ahead: integer, behind: integer }|nil)
function M.git(cb)
  local root = M.root()
  if not exists(root .. '/.git') then
    return cb(nil)
  end
  if vim.fn.executable('git') ~= 1 then
    return cb(nil)
  end
  vim.system({ 'git', '-C', root, 'status', '--porcelain=v1', '-b' }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 or not res.stdout then
        return cb(nil)
      end
      local lines = vim.split(res.stdout, '\n', { trimempty = true })
      local head = (lines[1] or ''):gsub('^## ', '')
      local branch = head:match('^([^%.%s]+)') or head
      if head:match('^No commits yet on (%S+)') then
        branch = head:match('^No commits yet on (%S+)')
      end
      cb({
        branch = branch,
        dirty = math.max(#lines - 1, 0),
        ahead = tonumber(head:match('ahead (%d+)')) or 0,
        behind = tonumber(head:match('behind (%d+)')) or 0,
      })
    end)
  end)
end

-- name, executables to try, label shown
local tools = {
  { 'clangd', { 'clangd' } },
  { 'clang-format', { 'clang-format' } },
  { 'cmake', { 'cmake' } },
  { 'ninja', { 'ninja' } },
  { 'gdb', { 'gdb' } },
  { 'lldb-dap', { 'lldb-dap', 'lldb-vscode' } },
  { 'perf', { 'perf' } },
  { 'ripgrep', { 'rg' } },
  { 'tree-sitter', { 'tree-sitter' } },
  { 'compiler', { 'c++', 'g++', 'clang++' } },
}

local no_version_flag = { ['lldb-dap'] = true }

--- Which tools exist (and their versions), asynchronously. `cb` runs once,
--- after every probe finished.
---@param cb fun(list: { name: string, exe: string|nil, version: string|nil }[])
function M.tools(cb)
  local out, pending = {}, #tools
  local function done()
    pending = pending - 1
    if pending == 0 then
      cb(out)
    end
  end
  for i, t in ipairs(tools) do
    local name, candidates = t[1], t[2]
    local exe
    for _, c in ipairs(candidates) do
      if vim.fn.executable(c) == 1 then
        exe = c
        break
      end
    end
    out[i] = { name = name, exe = exe }
    if exe and not no_version_flag[name] then
      local ok = pcall(vim.system, { exe, '--version' }, { text = true, timeout = 2000 }, function(res)
        local text = (res.stdout or '') .. (res.stderr or '')
        out[i].version = text:match('(%d+%.%d+[%.%d]*)')
        vim.schedule(done)
      end)
      if not ok then
        done()
      end
    else
      done()
    end
  end
end

return M
