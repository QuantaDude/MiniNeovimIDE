local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

-- auto open/close UI
dap.listeners.after.event_initialized["dapui"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui"] = function()
  dapui.close()
end

dap.adapters.lldb = {
  type = "executable",
  command = "lldb-dap",
  name = "lldb",
}
dap.configurations.cpp = {
  {
    name = "Launch C++",
    type = "lldb",
    request = "launch",
    program = function()
      return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
    args = {},
    runInTerminal = false,
  },
}

-- reuse for C
dap.configurations.c = dap.configurations.cpp

require("dapui").setup({
  layouts = {
    {
      elements = {
        "scopes",
        "breakpoints",
        "stacks",
        "memory",
      },
      size = 40,
      position = "left",
    },
    {
      elements = { "repl", "console" },
      size = 10,
      position = "bottom",
    },
  },
})
