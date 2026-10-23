-- Start screen: project + toolchain panels, actions, recent files / projects.
--
--   * shown when nvim starts without arguments (and via :Dashboard / <leader>ud)
--   * hotkeys (f g r n ...), j/k move inside a panel, h/l jump between panels,
--     <CR> or double-click activates, digits open recent files, A-C projects
--   * colors come from the active base46 theme and follow theme changes
local M = {}

local api = vim.api
local dw = vim.fn.strdisplaywidth
local ns = api.nvim_create_namespace('ide.dashboard')
local ns_sel = api.nvim_create_namespace('ide.dashboard.sel')

local st = {
  buf = nil,
  win = nil,
  items = {},
  sel_key = 'f',
  saved = {},
  info = { git = nil, tools = nil },
  plugins = nil,
}

local MAX_RECENT = 6
local MAX_PROJECTS = 3

---------------------------------------------------------------- highlights
local function apply_highlights()
  local c = require('ide.base46').palette()
  local function hl(name, spec)
    api.nvim_set_hl(0, name, spec)
  end
  local grad = { c.purple, c.blue, c.blue, c.cyan, c.teal, c.green }
  for n = 1, 6 do
    hl('IdeDashH' .. n, { fg = grad[n] or c.blue, bold = true })
  end
  hl('IdeDashTitle', { fg = c.blue, bold = true })
  hl('IdeDashSub', { fg = c.light_grey })
  hl('IdeDashBorder', { fg = c.grey_fg or c.light_grey })
  hl('IdeDashKey', { fg = c.yellow, bold = true })
  hl('IdeDashLabel', { fg = c.white })
  hl('IdeDashName', { fg = c.white, bold = true })
  hl('IdeDashIcon', { fg = c.blue })
  hl('IdeDashDim', { fg = c.light_grey })
  hl('IdeDashOk', { fg = c.green })
  hl('IdeDashBad', { fg = c.red })
  hl('IdeDashWarn', { fg = c.yellow })
  hl('IdeDashAccent', { fg = c.purple })
  hl('IdeDashSel', { bg = c.one_bg2 or c.lightbg })
  hl('IdeDashFooter', { fg = c.light_grey, italic = true })
end

---------------------------------------------------------------- helpers
local function S(text, hl)
  return { text, hl }
end

local function row_width(segs)
  local w = 0
  for _, sg in ipairs(segs) do
    w = w + dw(sg[1])
  end
  return w
end

local function spaces(n)
  return string.rep(' ', math.max(n, 0))
end

local function pad_to(segs, w)
  local cur = row_width(segs)
  if cur < w then
    segs[#segs + 1] = S(spaces(w - cur))
  end
  return segs
end

local function trunc(s, max, from_left)
  if dw(s) <= max then
    return s
  end
  local chars = vim.fn.split(s, '\\zs')
  if from_left then
    while #chars > 0 and dw('…' .. table.concat(chars)) > max do
      table.remove(chars, 1)
    end
    return '…' .. table.concat(chars)
  end
  while #chars > 0 and dw(table.concat(chars) .. '…') > max do
    table.remove(chars)
  end
  return table.concat(chars) .. '…'
end

local function file_icon(path)
  if _G.MiniIcons then
    local ok, icon, hl = pcall(MiniIcons.get, 'file', path)
    if ok and icon then
      return icon, hl
    end
  end
  return '', 'IdeDashIcon'
end

---------------------------------------------------------------- data
local function recent_files()
  local cwd = vim.fn.getcwd()
  local scoped, other, seen = {}, {}, {}
  for _, f in ipairs(vim.v.oldfiles or {}) do
    if #scoped >= MAX_RECENT then
      break
    end
    if not seen[f] and not f:find('/%.git/') and not f:find('^/tmp/') and vim.uv.fs_stat(f) then
      seen[f] = true
      if vim.startswith(f, cwd .. '/') then
        scoped[#scoped + 1] = f
      else
        other[#other + 1] = f
      end
    end
  end
  local out = vim.list_slice(scoped, 1, MAX_RECENT)
  for _, f in ipairs(other) do
    if #out >= MAX_RECENT then
      break
    end
    out[#out + 1] = f
  end
  return out
end

local function recent_projects(limit)
  local current = require('ide.project').root()
  local home = vim.uv.os_homedir()
  local out, seen = {}, { [current] = true }
  if home then
    seen[home] = true
  end
  for idx, f in ipairs(vim.v.oldfiles or {}) do
    if #out >= limit or idx > 120 then
      break
    end
    local root = vim.fs.root(f, { '.git', 'CMakeLists.txt', 'meson.build', 'compile_commands.json' })
    if root and not seen[root] and vim.uv.fs_stat(root) then
      seen[root] = true
      out[#out + 1] = root
    end
  end
  return out
end

local function tips()
  return {
    'Press <Space> and wait: which-key lists every leader mapping',
    '<Space>?  opens the keymap cheatsheet',
    '<Space>ut  previews base46 themes live and saves your pick',
    'F5 debug · F9 breakpoint · F10/F11 step over/into',
    '<Space>mg configure · <Space>mb build · <Space>mr run (CMake)',
    '<Space>pr records a perf profile and annotates your source',
    'Select code, then <Space>cr wraps it in a foldable #pragma region',
    '<Space>dm shows a hex view of process memory while debugging',
    '<Space>cf formats with clang-format · <Space>ch swaps header/source',
    '<Space>uh toggles inlay hints · <Space>uH hover-on-idle',
    '<Space>tt toggles a bottom terminal (<A-t> also works inside it)',
    '<Space>fk searches every keymap · <Space>fc every command',
  }
end

---------------------------------------------------------------- actions
local function try_cmd(name)
  return function()
    local ok, err = pcall(vim.cmd, name)
    if not ok then
      vim.notify(('%s failed: %s'):format(name, err), vim.log.levels.WARN)
    end
  end
end

local function switch_project(root)
  vim.cmd.cd(vim.fn.fnameescape(root))
  vim.notify('Project: ' .. root)
  st.info.git = nil
  M.refresh()
end

local function project_picker()
  local roots = recent_projects(30)
  if #roots == 0 then
    return vim.notify('No recent projects yet', vim.log.levels.INFO)
  end
  local items = {}
  for _, r in ipairs(roots) do
    items[#items + 1] = { text = vim.fn.fnamemodify(r, ':~'), root = r }
  end
  MiniPick.start({
    source = {
      name = 'Projects',
      items = items,
      choose = function(item)
        if item then
          vim.schedule(function()
            switch_project(item.root)
          end)
        end
      end,
    },
  })
end

local actions = {
  { key = 'f', icon = '\u{F0C7C}', label = 'Find file', hint = 'SPC ff', run = function() MiniPick.builtin.files() end },
  { key = 'g', icon = '󰈭', label = 'Live grep', hint = 'SPC fg', run = function() MiniPick.builtin.grep_live() end },
  { key = 'r', icon = '\u{F02DA}', label = 'Recent files', hint = 'SPC fo', run = function() MiniExtra.pickers.oldfiles() end },
  { key = 'n', icon = '\u{F0752}', label = 'New file', hint = ':enew', run = function() vim.cmd('enew') end },
  { key = 'e', icon = '\u{F024B}', label = 'File explorer', hint = 'SPC e', run = function() require('ide.explorer').toggle() end },
  { key = 'p', icon = '\u{F0253}', label = 'Switch project', hint = '', run = project_picker },
  { key = 'b', icon = '\u{F08EA}', label = 'Build', hint = 'SPC cb', run = try_cmd('Build') },
  { key = 'x', icon = '\u{F040A}', label = 'Run', hint = 'SPC mr', run = try_cmd('CMakeRun') },
  { key = 'd', icon = '\u{F00E4}', label = 'Debug', hint = 'SPC md', run = try_cmd('CMakeDebug') },
  { key = 't', icon = '󰉼', label = 'Themes', hint = 'SPC ut', run = function() require('ide.theme').pick() end },
  { key = 'c', icon = '\u{F030C}', label = 'Cheatsheet', hint = 'SPC ?', run = function() require('ide.cheatsheet').open() end },
  { key = 'i', icon = '󰓙', label = 'Toolchain doctor', hint = 'SPC uD', run = try_cmd('IdeDoctor') },
  { key = 'u', icon = '󰚰', label = 'Update plugins', hint = 'SPC uU', run = function() vim.pack.update() end },
  { key = 'q', icon = '󰗼', label = 'Quit', hint = ':qa', run = function() vim.cmd('qa') end },
}

---------------------------------------------------------------- panels
local function marker(kind, item)
  return { '', nil, mark = kind, item = item }
end

--- Wrap content rows in a rounded frame of outer width `w`.
---@param rows table[] each: segs[] or { segs = segs[], item = item }
local function panel(title, rows, w, min_rows)
  local inner = w - 4
  local out = {}
  local tl = ' ' .. title .. ' '
  out[1] = {
    S('╭─', 'IdeDashBorder'),
    S(tl, 'IdeDashTitle'),
    S(string.rep('─', math.max(w - 3 - dw(tl), 0)) .. '╮', 'IdeDashBorder'),
  }
  local n = math.max(#rows, min_rows or 0)
  for idx = 1, n do
    local r = rows[idx] or {}
    local segs = r.segs or r
    local item = r.item
    local line = { S('│ ', 'IdeDashBorder') }
    if item then
      line[#line + 1] = marker('s', item)
    end
    local body = pad_to(vim.deepcopy(segs), inner)
    vim.list_extend(line, body)
    if item then
      line[#line + 1] = marker('e', item)
    end
    line[#line + 1] = S(' │', 'IdeDashBorder')
    out[#out + 1] = line
  end
  out[#out + 1] = { S('╰' .. string.rep('─', w - 2) .. '╯', 'IdeDashBorder') }
  return out
end

local function hcat(a, wa, b, wb, gap)
  local out = {}
  for r = 1, math.max(#a, #b) do
    local line = {}
    vim.list_extend(line, a[r] or { S(spaces(wa)) })
    line[#line + 1] = S(spaces(gap))
    vim.list_extend(line, b[r] or { S(spaces(wb)) })
    out[#out + 1] = line
  end
  return out
end

local function project_rows(inner, project)
  local rows = {}
  rows[#rows + 1] = { S(' '), S('\u{F03D6} ', 'IdeDashAccent'), S(trunc(project.name, inner - 4), 'IdeDashName') }

  local kind
  if project.kind then
    kind = '󰒓 ' .. project.kind .. (project.std and (' · ' .. project.std) or '')
    rows[#rows + 1] = { S(' ' .. kind, 'IdeDashLabel') }
  else
    rows[#rows + 1] = { S(' 󰒓 no build system found', 'IdeDashDim') }
  end

  local g = st.info.git
  if g == nil then
    rows[#rows + 1] = { S(' \u{F062C} …', 'IdeDashDim') }
  elseif g == false then
    rows[#rows + 1] = { S(' \u{F062C} not a git repository', 'IdeDashDim') }
  else
    local line = { S(' \u{F062C} ', 'IdeDashAccent'), S(trunc(g.branch, inner - 16), 'IdeDashLabel') }
    if g.dirty > 0 then
      line[#line + 1] = S('  ●' .. g.dirty, 'IdeDashWarn')
    else
      line[#line + 1] = S('  ✓', 'IdeDashOk')
    end
    if g.ahead > 0 then
      line[#line + 1] = S(' ↑' .. g.ahead, 'IdeDashDim')
    end
    if g.behind > 0 then
      line[#line + 1] = S(' ↓' .. g.behind, 'IdeDashDim')
    end
    rows[#rows + 1] = line
  end

  local cm = project.kind == 'CMake' and require('ide.project').cmake() or nil
  if project.kind == 'CMake' then
    if cm and cm.build_type then
      rows[#rows + 1] = {
        S(' 󰔷 ', 'IdeDashIcon'),
        S(cm.build_type, 'IdeDashLabel'),
        S(cm.target and (' → ' .. trunc(cm.target, inner - 14)) or '', 'IdeDashDim'),
      }
    else
      rows[#rows + 1] = { S(' 󰔷 not configured (SPC mg)', 'IdeDashDim') }
    end
  end

  if project.compile_db then
    rows[#rows + 1] = { S(' ✓ ', 'IdeDashOk'), S('compile_commands.json', 'IdeDashDim') }
  else
    rows[#rows + 1] = { S(' ✗ ', 'IdeDashWarn'), S('no compile_commands.json', 'IdeDashDim') }
  end

  rows[#rows + 1] = { S(' ' .. trunc(vim.fn.fnamemodify(project.root, ':~'), inner - 2, true), 'IdeDashDim') }
  return rows
end

local function tool_rows(inner)
  local list = st.info.tools
  if not list then
    return { { S(' probing toolchain…', 'IdeDashDim') } }
  end
  local half = math.ceil(#list / 2)
  local colw = math.floor(inner / 2)
  local rows = {}
  for r = 1, half do
    local line = {}
    for col = 0, 1 do
      local t = list[r + col * half]
      local cell = {}
      if t then
        if t.exe then
          cell[#cell + 1] = S(' ✓ ', 'IdeDashOk')
          cell[#cell + 1] = S(t.name, 'IdeDashLabel')
          if t.version then
            cell[#cell + 1] = S(' ' .. t.version, 'IdeDashDim')
          end
        else
          cell[#cell + 1] = S(' ✗ ', 'IdeDashBad')
          cell[#cell + 1] = S(t.name, 'IdeDashDim')
        end
      end
      pad_to(cell, colw)
      vim.list_extend(line, cell)
    end
    rows[#rows + 1] = line
  end
  return rows
end

local function action_rows(inner, items)
  local rows = {}
  for _, a in ipairs(actions) do
    local item = { key = a.key, run = a.run, panel = 'L' }
    items[#items + 1] = item
    local line = {
      S(' '),
      S(a.key, 'IdeDashKey'),
      S('  '),
      S(a.icon, 'IdeDashIcon'),
      S(' '),
      S(a.label, 'IdeDashLabel'),
    }
    local gap = inner - row_width(line) - dw(a.hint) - 1
    line[#line + 1] = S(spaces(gap))
    line[#line + 1] = S(a.hint, 'IdeDashDim')
    rows[#rows + 1] = { segs = line, item = item }
  end
  return rows
end

local function recent_rows(inner, items)
  local rows = {}
  local files = recent_files()
  rows[#rows + 1] = { S(' Files', 'IdeDashDim') }
  if #files == 0 then
    rows[#rows + 1] = { S('  nothing opened yet', 'IdeDashDim') }
  end
  for n, f in ipairs(files) do
    local item = {
      key = tostring(n),
      panel = 'R',
      run = function()
        vim.cmd.edit(vim.fn.fnameescape(f))
      end,
    }
    items[#items + 1] = item
    local icon, icon_hl = file_icon(f)
    local name = vim.fs.basename(f)
    local dirname = vim.fs.dirname(f)
    local dir = dirname == vim.fn.getcwd() and '' or vim.fn.fnamemodify(dirname, ':~:.')
    local avail = inner - 8 - dw(name)
    local line = {
      S(' '),
      S(tostring(n), 'IdeDashKey'),
      S('  '),
      S(icon, icon_hl),
      S(' '),
      S(trunc(name, inner - 8), 'IdeDashLabel'),
    }
    if avail > 6 and dir ~= '' then
      line[#line + 1] = S('  ' .. trunc(dir, avail - 2, true), 'IdeDashDim')
    end
    rows[#rows + 1] = { segs = line, item = item }
  end

  local roots = recent_projects(MAX_PROJECTS)
  rows[#rows + 1] = { S('') }
  rows[#rows + 1] = { S(' Projects', 'IdeDashDim') }
  if #roots == 0 then
    rows[#rows + 1] = { S('  none yet', 'IdeDashDim') }
  end
  for n, root in ipairs(roots) do
    local key = string.char(64 + n)
    local item = {
      key = key,
      panel = 'R',
      run = function()
        switch_project(root)
      end,
    }
    items[#items + 1] = item
    local name = vim.fs.basename(root)
    local avail = inner - 8 - dw(name)
    local line = {
      S(' '),
      S(key, 'IdeDashKey'),
      S('  '),
      S('\u{F024B}', 'IdeDashAccent'),
      S(' '),
      S(trunc(name, inner - 8), 'IdeDashName'),
    }
    if avail > 6 then
      line[#line + 1] = S('  ' .. trunc(vim.fn.fnamemodify(root, ':~'), avail - 2, true), 'IdeDashDim')
    end
    rows[#rows + 1] = { segs = line, item = item }
  end
  return rows
end

---------------------------------------------------------------- layout
local logo = {
  { ' ██████╗ ', '██╔════╝ ', '██║      ', '██║      ', '╚██████╗ ', ' ╚═════╝ ' },
  { '         ', '   ██╗   ', ' ██████╗ ', ' ╚═██╔═╝ ', '   ╚═╝   ', '         ' },
}

local function logo_lines()
  local out = {}
  for r = 1, 6 do
    out[r] = logo[1][r] .. logo[2][r] .. logo[2][r]
  end
  return out
end

--- Build the whole screen as lines of segments and the item list.
local function build(width, height)
  local lines = {}
  local items = {}
  local project = require('ide.project').detect()

  local function center(segs)
    local w = row_width(segs)
    local pad = math.max(math.floor((width - w) / 2), 0)
    table.insert(segs, 1, S(spaces(pad)))
    return segs
  end
  local function push(segs)
    lines[#lines + 1] = segs
  end
  local function blank()
    push({ S('') })
  end

  -- header
  local v = vim.version()
  local version = ('Neovim %d.%d.%d'):format(v.major, v.minor, v.patch)
  if height >= 40 then
    for r, text in ipairs(logo_lines()) do
      push(center({ S(text, 'IdeDashH' .. r) }))
    end
    blank()
    push(center({ S('N E O V I M   ·   C + +   I D E', 'IdeDashTitle') }))
    push(center({ S(version .. '  ·  clangd  ·  CMake  ·  LLDB / GDB  ·  perf', 'IdeDashSub') }))
  else
    push(center({ S('  C++ IDE', 'IdeDashTitle'), S('   ' .. version, 'IdeDashSub') }))
  end
  blank()

  local two_col = width >= 104
  local lw, rw, gap
  if two_col then
    lw, rw, gap = 48, 54, 2
  else
    lw = math.min(width - 4, 60)
    rw = lw
    gap = 0
  end

  -- info row
  local prow = project_rows(lw - 4, project)
  local trow = tool_rows(rw - 4)
  local min_rows = math.max(#prow, #trow)
  local pblock = panel('Project', prow, lw, min_rows)
  local tblock = panel('Toolchain', trow, rw, min_rows)

  -- actions / recent
  local arow = action_rows(lw - 4, items)
  local rrow = recent_rows(rw - 4, items)
  local min2 = math.max(#arow, #rrow)
  local ablock = panel('Actions', arow, lw, min2)
  local rblock = panel('Recent', rrow, rw, min2)

  local function emit(block)
    for _, line in ipairs(block) do
      push(center(line))
    end
  end

  if two_col then
    emit(hcat(pblock, lw, tblock, rw, gap))
    blank()
    emit(hcat(ablock, lw, rblock, rw, gap))
  else
    emit(pblock)
    emit(tblock)
    emit(ablock)
    emit(rblock)
  end
  blank()

  -- footer
  local ms = vim.g.ide_start and math.floor((vim.uv.hrtime() - vim.g.ide_start) / 1e6) or nil
  local foot = {}
  if st.plugins then
    foot[#foot + 1] = S(('  %d plugins'):format(st.plugins), 'IdeDashFooter')
  end
  if ms then
    foot[#foot + 1] = S(('   󰅐 %d ms'):format(ms), 'IdeDashFooter')
  end
  foot[#foot + 1] = S('   ' .. os.date('%a %d %b'), 'IdeDashFooter')
  push(center(foot))
  local tip_list = tips()
  push(center({ S('󰛨 ' .. tip_list[(tonumber(os.date('%j')) % #tip_list) + 1], 'IdeDashFooter') }))

  -- vertical centering (slightly above middle)
  local top = math.max(math.floor((height - #lines) / 2) - 1, 0)
  for _ = 1, top do
    table.insert(lines, 1, { S('') })
  end
  return lines, items
end

---------------------------------------------------------------- render
local function by_key(key)
  for _, it in ipairs(st.items) do
    if it.key == key then
      return it
    end
  end
end

local function select(item, move)
  if not item then
    return
  end
  st.sel_key = item.key
  if st.buf and api.nvim_buf_is_valid(st.buf) then
    api.nvim_buf_clear_namespace(st.buf, ns_sel, 0, -1)
    pcall(api.nvim_buf_set_extmark, st.buf, ns_sel, item.row, item.cs, {
      end_col = item.ce,
      hl_group = 'IdeDashSel',
      priority = 50,
    })
  end
  if move and st.win and api.nvim_win_is_valid(st.win) then
    pcall(api.nvim_win_set_cursor, st.win, { item.row + 1, item.cs })
  end
end

local function valid()
  return st.buf and api.nvim_buf_is_valid(st.buf) and st.win and api.nvim_win_is_valid(st.win)
    and api.nvim_win_get_buf(st.win) == st.buf
end

function M.render()
  if not valid() then
    return
  end
  local width = api.nvim_win_get_width(st.win)
  local height = api.nvim_win_get_height(st.win)
  local lines, items = build(width, height)

  local text = {}
  local marks = {}
  for r, segs in ipairs(lines) do
    local line = ''
    for _, sg in ipairs(segs) do
      if sg.mark == 's' then
        sg.item.row = r - 1
        sg.item.cs = #line
      elseif sg.mark == 'e' then
        sg.item.ce = #line
      elseif sg[1] ~= '' then
        if sg[2] then
          marks[#marks + 1] = { r - 1, #line, #line + #sg[1], sg[2] }
        end
        line = line .. sg[1]
      end
    end
    text[r] = line
  end

  vim.bo[st.buf].modifiable = true
  api.nvim_buf_set_lines(st.buf, 0, -1, false, text)
  vim.bo[st.buf].modifiable = false
  api.nvim_buf_clear_namespace(st.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(st.buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end

  st.items = items
  select(by_key(st.sel_key) or items[1], true)
end

--- Re-run the async probes and redraw.
function M.refresh()
  local project = require('ide.project')
  project.git(function(g)
    st.info.git = g or false
    M.render()
  end)
  if not st.info.tools then
    project.tools(function(list)
      st.info.tools = list
      M.render()
    end)
  end
  M.render()
end

---------------------------------------------------------------- navigation
local function move_vertical(dir)
  local cur = by_key(st.sel_key)
  if not cur then
    return
  end
  local same = vim.tbl_filter(function(it)
    return it.panel == cur.panel
  end, st.items)
  for idx, it in ipairs(same) do
    if it == cur then
      select(same[((idx - 1 + dir) % #same) + 1], true)
      return
    end
  end
end

local function move_horizontal()
  local cur = by_key(st.sel_key)
  if not cur then
    return
  end
  local best, dist
  for _, it in ipairs(st.items) do
    if it.panel ~= cur.panel then
      local d = math.abs(it.row - cur.row)
      if not dist or d < dist then
        best, dist = it, d
      end
    end
  end
  select(best, true)
end

local function cycle(dir)
  for idx, it in ipairs(st.items) do
    if it.key == st.sel_key then
      select(st.items[((idx - 1 + dir) % #st.items) + 1], true)
      return
    end
  end
end

local function activate(key)
  local it = by_key(key or st.sel_key)
  if it then
    it.run()
  end
end

local function sync_from_cursor()
  if not valid() then
    return
  end
  local pos = api.nvim_win_get_cursor(st.win)
  local row, col = pos[1] - 1, pos[2]
  local best, dist
  for _, it in ipairs(st.items) do
    local d = math.abs(it.row - row) * 1000
    if it.row == row then
      d = (col >= it.cs and col <= it.ce) and 0 or math.min(math.abs(col - it.cs), math.abs(col - it.ce))
    end
    if not dist or d < dist then
      best, dist = it, d
    end
  end
  if best and best.key ~= st.sel_key then
    select(best, false)
  end
end

local function set_keymaps(buf)
  local function map(lhs, fn)
    vim.keymap.set('n', lhs, fn, { buffer = buf, nowait = true, silent = true })
  end
  for _, a in ipairs(actions) do
    map(a.key, function() activate(a.key) end)
  end
  for n = 1, MAX_RECENT do
    map(tostring(n), function() activate(tostring(n)) end)
  end
  for n = 1, MAX_PROJECTS do
    local key = string.char(64 + n)
    map(key, function() activate(key) end)
  end
  map('j', function() move_vertical(1) end)
  map('k', function() move_vertical(-1) end)
  map('<Down>', function() move_vertical(1) end)
  map('<Up>', function() move_vertical(-1) end)
  map('h', move_horizontal)
  map('l', move_horizontal)
  map('<Left>', move_horizontal)
  map('<Right>', move_horizontal)
  map('<Tab>', function() cycle(1) end)
  map('<S-Tab>', function() cycle(-1) end)
  map('<CR>', function() activate() end)
  map('<2-LeftMouse>', function()
    sync_from_cursor()
    activate()
  end)
  map('<LeftMouse>', function()
    local m = vim.fn.getmousepos()
    if m.winid == st.win then
      pcall(api.nvim_win_set_cursor, st.win, { m.line, math.max(m.column - 1, 0) })
      sync_from_cursor()
    end
  end)
end

---------------------------------------------------------------- open / setup
local function restore_chrome()
  if st.saved.showtabline ~= nil then
    vim.o.showtabline = st.saved.showtabline
    st.saved.showtabline = nil
  end
end

function M.open()
  if valid() then
    api.nvim_set_current_win(st.win)
    return M.refresh()
  end

  local old = api.nvim_get_current_buf()
  local buf = api.nvim_create_buf(false, true)
  api.nvim_win_set_buf(0, buf)
  st.buf, st.win = buf, api.nvim_get_current_win()

  -- the empty buffer we replaced would otherwise linger in the tabline
  if api.nvim_buf_is_valid(old) and api.nvim_buf_get_name(old) == '' and not vim.bo[old].modified
    and vim.bo[old].buftype == '' then
    pcall(api.nvim_buf_delete, old, {})
  end

  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].swapfile = false
  vim.bo[buf].buflisted = false
  vim.bo[buf].filetype = 'ide_dashboard'
  vim.b[buf].ministatusline_disable = true
  vim.b[buf].minitrailspace_disable = true

  for opt, val in pairs({
    number = false, relativenumber = false, signcolumn = 'no', foldcolumn = '0',
    cursorline = false, list = false, wrap = false, colorcolumn = '', spell = false,
  }) do
    api.nvim_set_option_value(opt, val, { win = st.win })
  end

  if st.saved.showtabline == nil then
    st.saved.showtabline = vim.o.showtabline
  end
  vim.o.showtabline = 0

  set_keymaps(buf)

  local group = api.nvim_create_augroup('ide.dashboard.buf', { clear = true })
  api.nvim_create_autocmd('CursorMoved', { group = group, buffer = buf, callback = sync_from_cursor })
  api.nvim_create_autocmd({ 'BufWinLeave', 'BufWipeout' }, { group = group, buffer = buf, callback = restore_chrome })
  api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    callback = function()
      vim.schedule(M.render)
    end,
  })
  api.nvim_create_autocmd('DirChanged', {
    group = group,
    callback = function()
      st.info.git = nil
      vim.schedule(M.refresh)
    end,
  })

  M.refresh()
end

local function should_open_on_start()
  if vim.g.ide_no_dashboard or vim.fn.argc() ~= 0 then
    return false
  end
  if api.nvim_buf_get_name(0) ~= '' or vim.bo.modified or vim.bo.buftype ~= '' then
    return false
  end
  -- piped stdin / `-c "edit ..."` style invocations leave content or a name
  if api.nvim_buf_line_count(0) > 1 or #(api.nvim_buf_get_lines(0, 0, 1, false)[1] or '') > 0 then
    return false
  end
  return true
end

function M.setup()
  apply_highlights()
  api.nvim_create_autocmd({ 'ColorScheme', 'User' }, {
    group = api.nvim_create_augroup('ide.dashboard.hl', { clear = true }),
    callback = function(ev)
      if ev.event == 'ColorScheme' or ev.match == 'NvThemeReload' then
        apply_highlights()
        vim.schedule(M.render)
      end
    end,
  })

  api.nvim_create_user_command('Dashboard', M.open, { desc = 'Open the start screen' })

  api.nvim_create_autocmd('VimEnter', {
    group = api.nvim_create_augroup('ide.dashboard.start', { clear = true }),
    nested = true,
    callback = function()
      vim.schedule(function()
        local ok, plugins = pcall(vim.pack.get, nil, { info = false })
        if ok then
          st.plugins = #plugins
        end
        if should_open_on_start() then
          M.open()
        end
      end)
    end,
  })
end

return M
