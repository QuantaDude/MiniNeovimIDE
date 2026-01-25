local ts = require("nvim-treesitter")
local augroup = vim.api.nvim_create_augroup("myconfig.treesitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "*" },
  callback = function(event)
    local filetype = event.match
    local lang = vim.treesitter.language.get_lang(filetype)
    local is_installed, error = vim.treesitter.language.add(lang)

    if not is_installed then
      local available_langs = ts.get_available()
      local is_available = vim.tbl_contains(available_langs, lang)

      if is_available then
        vim.notify("Installing treesitter parser for " .. lang, vim.log.levels.INFO)
        ts.install({ lang }):wait(30 * 1000)
      end
    end

    local ok, _ = pcall(vim.treesitter.start, event.buf, lang)
    if not ok then return end

    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
  end
})

vim.api.nvim_create_autocmd("PackChanged", {
  group = augroup,
  pattern = { "nvim-treesitter" },
  callback = function(event)
    vim.notify("Updating treesitter parsers", vim.log.levels.INFO)
    ts.update(nil, { summary = true }):wait(30 * 1000)
  end
})

