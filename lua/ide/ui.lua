-- IDE chrome: notifications, buffer tabline, statusline, colorify, extra
-- pickers and the <leader>u toggles.
local M = {}

local map = vim.keymap.set

---------------------------------------------------------------- statusline
local function lsp_names()
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        names[#names + 1] = c.name
    end
    return #names > 0 and ('󰒋 ' .. table.concat(names, ',')) or ''
end

local function build_section()
    local ft = vim.bo.filetype
    if ft ~= 'c' and ft ~= 'cpp' and ft ~= 'cmake' and ft ~= 'cuda' then
        return ''
    end
    local info = require('ide.project').cmake()
    if not info or not info.build_type then
        return ''
    end
    return ('󰔷 %s%s'):format(info.build_type, info.target and (' · ' .. info.target) or '')
end

local function recording()
    local reg = vim.fn.reg_recording()
    return reg ~= '' and ('󰑊 @' .. reg) or ''
end

local function statusline()
    local sl = require('mini.statusline')
    sl.setup({
        use_icons = true,
        content = {
            active = function()
                local mode, mode_hl = sl.section_mode({ trunc_width = 120 })
                local git = sl.section_git({ trunc_width = 40 })
                local diff = sl.section_diff({ trunc_width = 75 })
                local diagnostics = sl.section_diagnostics({ trunc_width = 75 })
                local filename = sl.section_filename({ trunc_width = 140 })
                local fileinfo = sl.section_fileinfo({ trunc_width = 120 })
                local search = sl.section_searchcount({ trunc_width = 75 })
                local location = sl.section_location({ trunc_width = 75 })

                return sl.combine_groups({
                    { hl = mode_hl,                 strings = { mode } },
                    { hl = 'MiniStatuslineDevinfo', strings = { git, diff } },
                    '%<',
                    { hl = 'MiniStatuslineFilename', strings = { filename } },
                    '%=',
                    { hl = 'MiniStatuslineFilename', strings = { recording(), diagnostics } },
                    { hl = 'MiniStatuslineDevinfo',  strings = { lsp_names(), build_section() } },
                    { hl = 'MiniStatuslineFileinfo', strings = { fileinfo } },
                    { hl = mode_hl,                  strings = { search, location } },
                })
            end,
        },
    })
end

---------------------------------------------------------------- highlights
local function apply_highlights()
    -- mini.* groups follow the base46 palette when base46 is what's applied;
    -- with a plain :colorscheme mini's own defaults are left alone
    if vim.g.colors_name ~= 'base46' then
        return
    end
    local c = require('ide.base46').palette()
    local function hl(name, spec)
        vim.api.nvim_set_hl(0, name, spec)
    end
    hl('MiniStatuslineModeNormal', { fg = c.black, bg = c.blue, bold = true })
    hl('MiniStatuslineModeInsert', { fg = c.black, bg = c.green, bold = true })
    hl('MiniStatuslineModeVisual', { fg = c.black, bg = c.purple, bold = true })
    hl('MiniStatuslineModeReplace', { fg = c.black, bg = c.red, bold = true })
    hl('MiniStatuslineModeCommand', { fg = c.black, bg = c.yellow, bold = true })
    hl('MiniStatuslineModeOther', { fg = c.black, bg = c.teal, bold = true })
    hl('MiniStatuslineDevinfo', { fg = c.white, bg = c.one_bg2 })
    hl('MiniStatuslineFilename', { fg = c.light_grey, bg = c.statusline_bg })
    hl('MiniStatuslineFileinfo', { fg = c.white, bg = c.one_bg2 })
    hl('MiniStatuslineInactive', { fg = c.grey_fg, bg = c.statusline_bg })
end

---------------------------------------------------------------- setup
function M.setup()
    -- notifications (also shows clangd indexing progress)
    local ok_notify, notify = pcall(require, 'mini.notify')
    if ok_notify then
        notify.setup({ window = { config = { border = 'rounded' }, winblend = 0 } })
        vim.notify = notify.make_notify()
        map('n', '<leader>un', function() notify.clear() end, { desc = 'Dismiss notifications' })
        map('n', '<leader>uN', function() notify.show_history() end, { desc = 'Notification history' })
    end

    -- buffer tabs, window-local `:bdelete` that keeps the layout, git helpers
    require('mini.tabline').setup({ show_icons = true, tabpage_section = 'right' })
    require('mini.bufremove').setup()
    require('mini.git').setup()

    statusline()

    -- code actions / "select" prompts through mini.pick
    if _G.MiniPick and MiniPick.ui_select then
        vim.ui.select = MiniPick.ui_select
    end

    -- NvChad's colorify: swatches next to #rrggbb (and LSP document colors)
    local ok_nv, nvconfig = pcall(require, 'nvconfig')
    if ok_nv and nvconfig.colorify.enabled then
        local ok, colorify = pcall(require, 'nvchad.colorify')
        if ok then
            colorify.run()
        end
    end

    apply_highlights()
    vim.api.nvim_create_autocmd({ 'ColorScheme', 'User' }, {
        group = vim.api.nvim_create_augroup('ide.ui_hl', { clear = true }),
        callback = function(ev)
            if ev.event == 'ColorScheme' or ev.match == 'NvThemeReload' then
                apply_highlights()
            end
        end,
    })

    -- ---------------------------------------------------------- keymaps
    map('n', '<leader>uC', function() require('ide.theme').pick_colorscheme() end,
        { desc = 'Colorscheme picker (plain)' })
    map('n', '<leader>uc', function() require('minty.huefy').open() end, { desc = 'Color picker (minty)' })
    map('n', '<leader>us', function() require('minty.shades').open() end, { desc = 'Color shades (minty)' })
    map('n', '<leader>ud', function() require('ide.dashboard').open() end, { desc = 'Dashboard' })
    map('n', '<leader>uD', '<cmd>IdeDoctor<cr>', { desc = 'Toolchain doctor' })
    map('n', '<leader>uf', '<cmd>FormatToggle<cr>', { desc = 'Toggle format on save' })
    map('n', '<leader>uU', function() vim.pack.update() end, { desc = 'Update plugins' })
    map('n', '<leader>ul', function() vim.wo.number = not vim.wo.number end, { desc = 'Toggle line numbers' })
    map('n', '<leader>uL', function() vim.wo.relativenumber = not vim.wo.relativenumber end,
        { desc = 'Toggle relative numbers' })
    -- extra pickers
    map('n', '<leader>fo', function() MiniExtra.pickers.oldfiles() end, { desc = 'Recent files' })
    map('n', '<leader>fw', function()
        MiniPick.builtin.grep({ pattern = vim.fn.expand('<cword>') })
    end, { desc = 'Grep word under cursor' })
    map('n', '<leader>fk', function() MiniExtra.pickers.keymaps() end, { desc = 'Keymaps' })
    map('n', '<leader>fc', function() MiniExtra.pickers.commands() end, { desc = 'Commands' })
    map('n', '<leader>fl', function() MiniExtra.pickers.buf_lines({ scope = 'current' }) end,
        { desc = 'Lines in buffer' })
    map('n', '<leader>fm', function() MiniExtra.pickers.marks() end, { desc = 'Marks' })

    -- git (mini.git): log, history of the line/selection, commit
    map('n', '<leader>gl', '<cmd>Git log --oneline --graph --decorate -n 40<cr>', { desc = 'Git log' })
    map('n', '<leader>gc', '<cmd>Git commit<cr>', { desc = 'Git commit' })
    map('n', '<leader>gh', function() MiniGit.show_at_cursor() end, { desc = 'Git: show commit at cursor' })
    map('x', '<leader>gh', function() MiniGit.show_range_history() end, { desc = 'Git: history of selection' })
end

return M
