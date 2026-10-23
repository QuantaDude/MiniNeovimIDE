local dap = require('dap')
local dapui = require('dapui')

dapui.setup()
require('nvim-dap-virtual-text').setup({})
require('ide.memview').setup()

local function lldb_cmd()
  for _, exe in ipairs({ 'lldb-dap', 'lldb-vscode' }) do
    if vim.fn.executable(exe) == 1 then
      -- Absolute path on purpose: with `console = integratedTerminal` lldb-dap
      -- asks nvim-dap to re-launch *itself* in a terminal, and when it was
      -- started by bare name it resolves argv[0] against the cwd
      -- ("<project>/lldb-dap is not executable").
      local abs = vim.fn.exepath(exe)
      return abs ~= '' and abs or exe
    end
  end
  return 'lldb-dap'
end

-- initialize_timeout_sec only controls when the "Debug adapter didn't respond"
-- warning appears (default 4 s); lldb-dap can take longer on a cold start.
dap.adapters.lldb = {
  type = 'executable', command = lldb_cmd(), name = 'lldb',
  options = { initialize_timeout_sec = 20 },
}
dap.adapters.gdb = {
  type = 'executable', command = 'gdb', args = { '--interpreter=dap' },
  options = { initialize_timeout_sec = 20 },
}

--- :IdeDapCheck [lldb|gdb] -- start the adapter by hand, send it a DAP
--- `initialize` request and report what came back (or stderr when nothing did).
vim.api.nvim_create_user_command('IdeDapCheck', function(o)
  local name = o.args ~= '' and o.args or 'lldb'
  local a = dap.adapters[name]
  if type(a) ~= 'table' or a.type ~= 'executable' then
    return vim.notify(('IdeDapCheck: no executable adapter "%s"'):format(name), vim.log.levels.ERROR)
  end
  if vim.fn.executable(a.command) ~= 1 then
    return vim.notify(('IdeDapCheck: "%s" is not executable / not on PATH'):format(a.command), vim.log.levels.ERROR)
  end
  local body = vim.json.encode({
    seq = 1, type = 'request', command = 'initialize',
    arguments = { adapterID = 'check', linesStartAt1 = true, columnsStartAt1 = true, pathFormat = 'path' },
  })
  local msg = ('Content-Length: %d\r\n\r\n%s'):format(#body, body)
  local cmd = vim.list_extend({ a.command }, a.args or {})
  local t0, out, reported = vim.uv.hrtime(), '', false
  local proc
  local function elapsed()
    return math.floor((vim.uv.hrtime() - t0) / 1e6)
  end
  local function report(answered, res)
    if reported then
      return
    end
    reported = true
    vim.schedule(function()
      if proc then
        pcall(proc.kill, proc, 9)
      end
      if answered then
        vim.notify(('%s answered initialize in %d ms (success=%s)'):format(
          table.concat(cmd, ' '), elapsed(), tostring(out:find('"success"%s*:%s*true') ~= nil)))
      else
        local e = vim.trim((res and res.stderr) or '')
        vim.notify(('%s did NOT answer initialize (exit %s after %d ms)\nstderr: %s'):format(
          table.concat(cmd, ' '), tostring(res and res.code), elapsed(), e ~= '' and e:sub(1, 600) or '(empty)'),
          vim.log.levels.ERROR)
      end
    end)
  end
  local ok, err = pcall(function()
    proc = vim.system(cmd, {
      stdin = true, text = true, timeout = 20000,
      stdout = function(_, data)
        if data then
          out = out .. data
          if out:find('"command"%s*:%s*"initialize"') then
            report(true)
          end
        end
      end,
    }, function(res)
      report(false, res)
    end)
    proc:write(msg)
  end)
  if not ok then
    vim.notify('IdeDapCheck: failed to start adapter: ' .. tostring(err), vim.log.levels.ERROR)
  end
end, { nargs = '?', complete = function() return { 'lldb', 'gdb' } end, desc = 'Probe a debug adapter' })

local last_program, last_args = nil, ''

local function program()
  last_program = vim.fn.input('Executable: ', last_program or (vim.fn.getcwd() .. '/build/'), 'file')
  return last_program
end

local function args()
  last_args = vim.fn.input('Args: ', last_args)
  return vim.split(last_args, ' ', { trimempty = true })
end

local function launch(adapter, with_args)
  return {
    name = ('Launch (%s)%s'):format(adapter, with_args and ' with args' or ''),
    type = adapter,
    request = 'launch',
    program = program,
    args = with_args and args or {},
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  }
end

dap.configurations.cpp = {
  launch('lldb'),
  launch('lldb', true),
  launch('gdb'),
  {
    name = 'Attach (lldb)',
    type = 'lldb',
    request = 'attach',
    pid = require('dap.utils').pick_process,
    cwd = '${workspaceFolder}',
  },
}
dap.configurations.c = dap.configurations.cpp

dap.listeners.before.attach['ide.ui'] = dapui.open
dap.listeners.before.launch['ide.ui'] = dapui.open
dap.listeners.before.event_terminated['ide.ui'] = dapui.close
dap.listeners.before.event_exited['ide.ui'] = dapui.close

vim.fn.sign_define('DapBreakpoint', { text = '●', texthl = 'DiagnosticError' })
vim.fn.sign_define('DapBreakpointCondition', { text = '◆', texthl = 'DiagnosticWarn' })
vim.fn.sign_define('DapLogPoint', { text = '◉', texthl = 'DiagnosticInfo' })
vim.fn.sign_define('DapStopped', { text = '▶', texthl = 'DiagnosticOk', linehl = 'CursorLine' })
vim.fn.sign_define('DapBreakpointRejected', { text = '○', texthl = 'DiagnosticHint' })
