-- Extra plugins layered on top of ide.pack (which is left untouched).
local function gh(repo)
  return 'https://github.com/' .. repo
end

-- base46 compiles highlight caches here; must be set before base46 is required
vim.g.base46_cache = vim.fn.stdpath('data') .. '/base46/'

local rebuild = { base46 = true, ['nvchad-ui'] = true, volt = true }

vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('ide.pack_extra', { clear = true }),
  callback = function(ev)
    local d = ev.data
    if rebuild[d.spec.name] and (d.kind == 'install' or d.kind == 'update') then
      -- force the next startup to recompile the highlight cache
      pcall(vim.fn.delete, vim.g.base46_cache .. '.stamp')
      vim.g.ide_base46_stale = true
    end
  end,
})

vim.pack.add({
  -- NvChad pieces: theme engine, UI modules (theme picker, cheatsheet, colorify)
  -- and the widget library they draw with. The NvChad *framework* is not used.
  gh('NvChad/base46'),
  { src = gh('NvChad/ui'), name = 'nvchad-ui' },
  gh('nvzone/volt'),
  gh('nvzone/minty'),

  -- discoverability
  { src = gh('folke/which-key.nvim'), version = vim.version.range('3.*') },

  -- completion (styled by nvchad-ui) + snippets
  gh('hrsh7th/nvim-cmp'),
  gh('hrsh7th/cmp-nvim-lsp'),
  gh('hrsh7th/cmp-buffer'),
  gh('hrsh7th/cmp-path'),
  gh('saadparwaiz1/cmp_luasnip'),
  { src = gh('L3MON4D3/LuaSnip'), version = vim.version.range('2.*') },
  gh('rafamadriz/friendly-snippets'),
}, { confirm = false })
