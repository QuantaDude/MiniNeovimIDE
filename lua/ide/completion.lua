-- nvim-cmp + LuaSnip, styled with NvChad's "atom" format (see lua/chadrc.lua).
--
-- If nvim-cmp cannot be loaded, vim.g.ide_cmp stays unset and the original
-- native completion (vim.lsp.completion + the Tab/CR maps in ide.keymaps)
-- keeps working exactly as before.
local M = {}

-- buffers where completion popups would only get in the way
local disabled_ft = {
  minipick = true,
  minifiles = true,
  ministarter = true,
  ide_dashboard = true,
  nvcheatsheet = true,
}

-- Kind highlight fallbacks for when a plain :colorscheme is active (base46's
-- own `cmp` integration defines the real ones). All `default = true`.
local function fallback_highlights()
  if vim.g.colors_name == 'base46' then
    return
  end
  local links = {
    CmpPmenu = 'Pmenu',
    CmpSel = 'PmenuSel',
    CmpBorder = 'FloatBorder',
    CmpDoc = 'NormalFloat',
    CmpDocBorder = 'NormalFloat',
    CmpItemAbbr = 'Pmenu',
    CmpItemAbbrMatch = 'Special',
    CmpItemMenu = 'Comment',
    CmpItemKindFunction = 'Function',
    CmpItemKindMethod = 'Function',
    CmpItemKindConstructor = 'Function',
    CmpItemKindVariable = 'Identifier',
    CmpItemKindField = 'Identifier',
    CmpItemKindProperty = 'Identifier',
    CmpItemKindClass = 'Type',
    CmpItemKindStruct = 'Structure',
    CmpItemKindInterface = 'Type',
    CmpItemKindEnum = 'Type',
    CmpItemKindEnumMember = 'Constant',
    CmpItemKindConstant = 'Constant',
    CmpItemKindKeyword = 'Keyword',
    CmpItemKindSnippet = 'Special',
    CmpItemKindText = 'String',
    CmpItemKindModule = 'Include',
    CmpItemKindTypeParameter = 'Type',
  }
  for name, target in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = target, default = true })
  end
end

local function setup_snippets(luasnip)
  luasnip.config.set_config({
    history = true,
    updateevents = 'TextChanged,TextChangedI',
    enable_autosnippets = false,
  })

  -- friendly-snippets for everything except C/C++/CMake, which have curated
  -- sets in lua/snippets/
  require('luasnip.loaders.from_vscode').lazy_load({ exclude = { 'c', 'cpp', 'cmake' } })
  require('luasnip.loaders.from_lua').lazy_load({
    paths = { vim.fs.joinpath(vim.fn.stdpath('config'), 'lua', 'snippets') },
  })

  luasnip.filetype_extend('cuda', { 'cpp' })
  luasnip.filetype_extend('objcpp', { 'cpp' })

  -- leaving insert mode ends the snippet session (no stray jumps later)
  vim.api.nvim_create_autocmd('InsertLeave', {
    group = vim.api.nvim_create_augroup('ide.luasnip', { clear = true }),
    callback = function(ev)
      local session = luasnip.session
      if session.current_nodes[ev.buf] and not session.jump_active then
        luasnip.unlink_current()
      end
    end,
  })
end

---@return boolean ok  true when nvim-cmp is driving completion
function M.setup()
  local ok_cmp, cmp = pcall(require, 'cmp')
  local ok_snip, luasnip = pcall(require, 'luasnip')
  local ok_lsp, cmp_lsp = pcall(require, 'cmp_nvim_lsp')
  if not (ok_cmp and ok_snip and ok_lsp) then
    vim.notify('nvim-cmp / LuaSnip not available: using native completion', vim.log.levels.WARN)
    return false
  end

  setup_snippets(luasnip)

  -- base46's cmp highlights (CmpPmenu, CmpDoc, CmpItemKind*, ...) are loaded
  -- with the theme; these are only for plain :colorscheme mode
  fallback_highlights()
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('ide.cmp_hl', { clear = true }),
    callback = fallback_highlights,
  })

  -- NvChad's format + window tables (style comes from chadrc.ui.cmp.style)
  local styled = {}
  local ok_style, nv = pcall(require, 'nvchad.cmp')
  if ok_style then
    styled = nv
  end

  local function jumpable(dir)
    return luasnip.jumpable(dir)
  end

  local mapping = {
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = false }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback() -- the original <Tab> map from ide.keymaps
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }

  local options = {
    completion = { completeopt = 'menu,menuone' },
    enabled = function()
      if disabled_ft[vim.bo.filetype] or vim.bo.buftype == 'prompt' then
        return false
      end
      if vim.fn.reg_recording() ~= '' or vim.fn.reg_executing() ~= '' then
        return false
      end
      return true
    end,
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = mapping,
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    }, {
      { name = 'buffer', keyword_length = 3 },
      { name = 'path' },
    }),
  }

  cmp.setup(vim.tbl_deep_extend('force', options, styled))

  -- completion capabilities for every LSP server (clangd, lua_ls, ...)
  vim.lsp.config('*', { capabilities = cmp_lsp.default_capabilities() })

  vim.g.ide_cmp = true
  return true
end

return M
