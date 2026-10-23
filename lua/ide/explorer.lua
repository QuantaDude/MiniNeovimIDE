local M = {}

function M.toggle()
  if MiniFiles.close() then
    return
  end
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' or not vim.uv.fs_stat(path) then
    path = nil
  end
  MiniFiles.open(path)
end

function M.setup()
  require('mini.icons').setup()
  require('mini.files').setup({
    windows = { preview = true, width_focus = 32, width_nofocus = 16, width_preview = 56 },
    options = { use_as_default_explorer = true },
  })
  require('mini.pick').setup()
  require('mini.extra').setup()
  require('mini.statusline').setup()
  require('mini.pairs').setup()

  vim.api.nvim_create_autocmd('User', {
    pattern = 'MiniFilesBufferCreate',
    callback = function(ev)
      local function open_in(cmd)
        return function()
          local entry = MiniFiles.get_fs_entry()
          if not entry or entry.fs_type ~= 'file' then
            return
          end
          local target = MiniFiles.get_explorer_state().target_window
          MiniFiles.close()
          vim.api.nvim_set_current_win(target)
          vim.cmd(cmd .. ' ' .. vim.fn.fnameescape(entry.path))
        end
      end
      vim.keymap.set('n', '<C-s>', open_in('split'), { buffer = ev.data.buf_id })
      vim.keymap.set('n', '<C-v>', open_in('vsplit'), { buffer = ev.data.buf_id })
    end,
  })
end

return M
