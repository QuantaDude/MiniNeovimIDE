-- which-key: shows what is available after <leader>, g, z, [, ], <C-w>, ...
-- `M.groups` is also what the cheatsheet uses to name its sections.
local M = {}

---@type { [1]: string, [2]: string, icon: string, color: string }[]
M.groups = {
  { '<leader>b', 'Buffers', icon = '󰓩', color = 'azure' },
  { '<leader>c', 'Code', icon = '\u{F0169}', color = 'green' },
  { '<leader>d', 'Debug', icon = '\u{F00E4}', color = 'red' },
  { '<leader>f', 'Find', icon = '\u{F0349}', color = 'cyan' },
  { '<leader>g', 'Git', icon = '\u{F02A2}', color = 'orange' },
  { '<leader>m', 'CMake', icon = '\u{F0493}', color = 'blue' },
  { '<leader>p', 'Perf', icon = '󰓅', color = 'yellow' },
  { '<leader>r', 'Rename / Replace', icon = '󰑕', color = 'purple' },
  { '<leader>s', 'Snippets', icon = '\u{F0174}', color = 'green' },
  { '<leader>t', 'Terminal', icon = '\u{F018D}', color = 'grey' },
  { '<leader>u', 'UI / Toggles', icon = '󰔡', color = 'azure' },
}

-- prefixes that are not under <leader>
M.motions = {
  { '[', 'Previous' },
  { ']', 'Next' },
  { 'g', 'Goto / LSP' },
  { 'z', 'Folds / Spelling' },
}

function M.name_for(prefix)
  for _, g in ipairs(M.groups) do
    if g[1] == prefix then
      return g[2]
    end
  end
end

function M.setup()
  local ok, wk = pcall(require, 'which-key')
  if not ok then
    return
  end

  wk.setup({
    preset = 'modern',
    delay = 300,
    win = { border = 'rounded', padding = { 1, 2 } },
    icons = { mappings = true },
    sort = { 'local', 'order', 'group', 'alphanum', 'mod' },
  })

  local spec = {}
  for _, g in ipairs(M.groups) do
    spec[#spec + 1] = {
      g[1],
      group = g[2],
      mode = { 'n', 'x' },
      icon = { icon = g.icon, color = g.color },
    }
  end
  for _, m in ipairs(M.motions) do
    spec[#spec + 1] = { m[1], group = m[2], mode = { 'n', 'x' } }
  end
  wk.add(spec)

  vim.keymap.set('n', '<leader>uw', function()
    wk.show({ global = false })
  end, { desc = 'Buffer-local keymaps (which-key)' })
end

return M
