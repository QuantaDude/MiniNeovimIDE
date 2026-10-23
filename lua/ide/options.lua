local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = 'yes'
o.cursorline = true
o.scrolloff = 8
o.wrap = false
o.termguicolors = true
o.winborder = 'rounded'

o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.inccommand = 'split'

o.splitright = true
o.splitbelow = true
o.updatetime = 250
o.timeoutlen = 400
o.undofile = true
o.swapfile = false
o.mouse = 'a'
o.clipboard = 'unnamedplus'

o.completeopt = { 'menu', 'menuone', 'noinsert', 'popup', 'fuzzy' }
o.pumheight = 12

o.foldmethod = 'expr'
o.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
o.foldlevel = 99
o.foldlevelstart = 99
o.foldcolumn = '1'
o.fillchars = { fold = ' ', foldopen = '▾', foldclose = '▸', foldsep = ' ' }
