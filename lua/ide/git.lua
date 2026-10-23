require('gitsigns').setup({
  on_attach = function(buf)
    local gs = require('gitsigns')

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
    end

    local function range()
      local a, b = vim.fn.line('.'), vim.fn.line('v')
      return { math.min(a, b), math.max(a, b) }
    end

    local function nav(dir, fallback)
      return function()
        if vim.wo.diff then
          vim.cmd.normal({ fallback, bang = true })
        else
          gs.nav_hunk(dir)
        end
      end
    end

    map('n', ']h', nav('next', ']c'), 'Next hunk')
    map('n', '[h', nav('prev', '[c'), 'Previous hunk')
    map('n', '<leader>gs', gs.stage_hunk, 'Stage/unstage hunk')
    map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
    map('x', '<leader>gs', function() gs.stage_hunk(range()) end, 'Stage/unstage selection')
    map('x', '<leader>gr', function() gs.reset_hunk(range()) end, 'Reset selection')
    map('n', '<leader>gS', gs.stage_buffer, 'Stage buffer')
    map('n', '<leader>gR', gs.reset_buffer, 'Reset buffer')
    map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
    map('n', '<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame line')
    map('n', '<leader>gB', gs.toggle_current_line_blame, 'Toggle inline blame')
    map('n', '<leader>gd', gs.diffthis, 'Diff against index')
    map('n', '<leader>gq', gs.setqflist, 'Hunks to quickfix')
    map({ 'o', 'x' }, 'ih', gs.select_hunk, 'Select hunk')
  end,
})
