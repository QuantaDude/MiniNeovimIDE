-- NvChad's cheatsheet (grid layout), fed with this config's own keymaps.
--
-- NvChad groups mappings by the first word of their `desc`, which does not
-- suit descriptions like "Find files" or "CMake build". Here the sections are
-- the which-key groups (<leader>f -> "Find", <leader>m -> "CMake", ...), and
-- keys that carry no `desc` (completion, window motions) are listed by hand.
local M = {}

local MODES = { 'n', 'x', 'i', 't' }

-- descriptions of built-in mappings (Neovim 0.11+) that are not worth listing
local builtin_desc = {
  '^:', '^vim%.', '^Jump', '^Select', '^Add empty', '^Toggle comment', '^Comment textobject',
  '^Opens ', '^Show diagnostics',
  'action for', -- mini.pairs internals
  '^Which%-key', -- which-key trigger maps
}

local function is_builtin(desc)
  for _, pat in ipairs(builtin_desc) do
    if desc:find(pat) then
      return true
    end
  end
  return false
end

-- keys that have no `desc` (or are built in) but belong on the sheet
local extras = {
  { 'Completion', 'Next / previous item', '<Tab> / <S-Tab>' },
  { 'Completion', 'Open completion menu', '<C-Space>' },
  { 'Completion', 'Confirm selected item', '<CR>' },
  { 'Completion', 'Close menu', '<C-e>' },
  { 'Completion', 'Scroll documentation', '<C-d> / <C-f>' },
  { 'Snippets', 'Jump to next / previous placeholder', '<Tab> / <S-Tab>' },
  { 'Goto / LSP', 'Hover documentation', 'K' },
  { 'Goto / LSP', 'References', 'grr' },
  { 'Goto / LSP', 'Implementation', 'gri' },
  { 'Goto / LSP', 'Type definition', 'grt' },
  { 'Goto / LSP', 'Rename symbol', 'grn' },
  { 'Goto / LSP', 'Code action', 'gra' },
  { 'Goto / LSP', 'Document symbols (outline)', 'gO' },
  { 'Goto / LSP', 'Signature help (insert)', '<C-s>' },
  { 'Navigation', 'Next / previous diagnostic', ']d / [d' },
  { 'Navigation', 'Next / previous buffer', ']b / [b' },
  { 'Navigation', 'Next / previous quickfix', ']q / [q' },
  { 'Navigation', 'Next / previous tree-sitter node (visual)', ']n / [n' },
  { 'Editing', 'Toggle comment (operator / line)', 'gc / gcc' },
  { 'Editing', 'Expand / shrink selection by node', 'an / in' },
  { 'Windows', 'Move between windows', '<C-h/j/k/l>' },
  { 'Windows', 'Show diagnostics under cursor', '<C-w>d' },
  { 'General', 'Clear search highlight', '<Esc>' },
  { 'Terminal', 'Leave terminal mode', '<Esc><Esc>' },
}

local function section_for(lhs)
  local l = lhs:lower()
  if lhs:sub(1, 1) == ' ' then
    return require('ide.whichkey').name_for('<leader>' .. lhs:sub(2, 2)) or 'General'
  end
  if l:match('^<f%d+>') or l:match('^<s%-f%d+>') then
    return 'Debug keys'
  end
  if l:match('^[%[%]]') then
    return 'Navigation'
  end
  if l:match('^g') then
    return 'Goto / LSP'
  end
  if l:match('^<c%-[hjkl]>') or l:match('^<c%-up>') or l:match('^<c%-down>')
    or l:match('^<c%-left>') or l:match('^<c%-right>') then
    return 'Windows'
  end
  return 'General'
end

local function pretty_lhs(lhs)
  if lhs:sub(1, 1) == ' ' then
    return '<leader> +' .. lhs -- "<leader> + ff", same as NvChad
  end
  return lhs
end

local function capitalize(s)
  return (s:gsub('^%l', string.upper))
end

--- Replacement for nvchad.cheatsheet.organize_mappings()
---@return table<string, string[][]>
function M.organize()
  local out, seen = {}, {}

  local function add(heading, desc, key)
    local id = heading .. '\0' .. desc .. '\0' .. key
    if seen[id] then
      return
    end
    seen[id] = true
    out[heading] = out[heading] or {}
    table.insert(out[heading], { capitalize(desc), key })
  end

  local function collect(maps)
    for _, m in ipairs(maps) do
      local desc = m.desc
      if desc and not desc:find('\n') and not is_builtin(desc)
        and not m.lhs:find('<Plug>') and not m.lhs:find('<SNR>') then
        if m.mode ~= 'n' and m.mode ~= 'x' and m.mode ~= 'v' then
          desc = desc .. ' (' .. m.mode .. ')'
        end
        add(section_for(m.lhs), desc, pretty_lhs(m.lhs))
      end
    end
  end

  for _, mode in ipairs(MODES) do
    collect(vim.api.nvim_get_keymap(mode))
    collect(vim.api.nvim_buf_get_keymap(0, mode))
  end

  for _, e in ipairs(extras) do
    add(e[1], e[2], e[3])
  end

  for _, list in pairs(out) do
    table.sort(list, function(a, b)
      return a[2] < b[2]
    end)
  end
  return out
end

function M.open()
  local ok, ch = pcall(require, 'nvchad.cheatsheet')
  if not ok then
    return vim.notify('nvchad-ui is not installed yet (restart nvim)', vim.log.levels.WARN)
  end
  if vim.g.nvcheatsheet_displayed then
    return vim.cmd('bw')
  end
  require('ide.base46').ensure_cache()
  ch.organize_mappings = M.organize
  local theme = require('nvconfig').cheatsheet.theme
  require('nvchad.cheatsheet.' .. theme)()
end

function M.setup()
  vim.api.nvim_create_user_command('NvCheatsheet', M.open, { desc = 'Open the keymap cheatsheet' })
  vim.api.nvim_create_user_command('Cheatsheet', M.open, { desc = 'Open the keymap cheatsheet' })
  vim.keymap.set('n', '<leader>?', M.open, { desc = 'Cheatsheet' })
end

return M
