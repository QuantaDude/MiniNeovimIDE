vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.ide_start = vim.uv.hrtime() -- startup timer shown on the dashboard

vim.loader.enable()

require('ide.options')
require('ide.pack')
require('ide.pack_extra') -- NvChad base46/ui/volt/minty, which-key, nvim-cmp, LuaSnip
require('ide.theme').load()
require('ide.syntax')
require('ide.regions').setup()
require('ide.completion').setup() -- before lsp: adds completion capabilities
require('ide.lsp').setup()
require('ide.format')
require('ide.explorer').setup()
require('ide.debug')
require('ide.build')
require('ide.cmake')
require('ide.perf')
require('ide.git')
require('ide.keymaps')

-- IDE layer
require('ide.lspx').setup()
require('ide.ui').setup()
require('ide.editing').setup()
require('ide.terminal').setup()
require('ide.whichkey').setup()
require('ide.cheatsheet').setup()
require('ide.dashboard').setup()
