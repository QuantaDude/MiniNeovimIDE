local M = {}

function M.run_clang_format()
  local buf = vim.api.nvim_get_current_buf()

  local input = table.concat(
    vim.api.nvim_buf_get_lines(buf, 0, -1, false),
    "\n"
  )

  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart(
    { "clang-format" },
    {
      stdin = "pipe",
      stdout_buffered = true,
      stderr_buffered = true,

      on_stdout = function(_, data)
        if data then
          vim.list_extend(stdout, data)
        end
      end,

      on_stderr = function(_, data)
        if data then
          vim.list_extend(stderr, data)
        end
      end,

      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            vim.notify(
              table.concat(stderr, "\n"),
              vim.log.levels.ERROR
            )
          end)
          return
        end

        vim.schedule(function()
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, stdout)
        end)
      end,
    }
  )

  if job_id <= 0 then
    vim.notify("Failed to start clang-format", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job_id, input)
  vim.fn.chanclose(job_id, "stdin")
end

function M.run_prettier()
  local buf = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(buf)

  local input = table.concat(
    vim.api.nvim_buf_get_lines(buf, 0, -1, false),
    "\n"
  )

  local stdout = {}
  local stderr = {}

  local job_id = vim.fn.jobstart(
    { "prettier", "--stdin-filepath", fname },
    {
      stdin = "pipe",
      stdout_buffered = true,
      stderr_buffered = true,

      on_stdout = function(_, data)
        if data then
          vim.list_extend(stdout, data)
        end
      end,

      on_stderr = function(_, data)
        if data then
          vim.list_extend(stderr, data)
        end
      end,

      on_exit = function(_, code)
        if code ~= 0 then
          vim.schedule(function()
            vim.notify(
              table.concat(stderr, "\n"),
              vim.log.levels.ERROR
            )
          end)
          return
        end

        vim.schedule(function()
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, stdout)
        end)
      end,
    }
  )

  if job_id <= 0 then
    vim.notify("Failed to start Prettier", vim.log.levels.ERROR)
    return
  end

  vim.fn.chansend(job_id, input)
  vim.fn.chanclose(job_id, "stdin")
end

function M.format_buffer()
  local ft = vim.bo.filetype


  -- =========================
  -- C / C++ → clang-format
  -- =========================
  if (ft == "c" or ft == "cpp")
      and vim.fn.executable("clang-format") == 1 then
    M.run_clang_format()
    return
  end
  -- =========================
  -- JS / TS / Web → Prettier
  -- =========================
  if vim.tbl_contains({
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "css",
        "scss",
        "html",
        "markdown",
      }, ft) and vim.fn.executable("prettier") == 1 then
    M.run_prettier()
    return
  end


  -- =========================
  -- Fallback → LSP
  -- =========================
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client.server_capabilities.documentFormattingProvider then
      vim.lsp.buf.format({ async = false })
      return
    end
  end
end

return M
