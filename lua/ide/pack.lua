local function gh(repo)
  return 'https://github.com/' .. repo
end

vim.api.nvim_create_autocmd('PackChanged', {
  callback = function(ev)
    local d = ev.data
    if d.spec.name == 'nvim-treesitter' and (d.kind == 'install' or d.kind == 'update') then
      if not d.active then
        vim.cmd.packadd('nvim-treesitter')
      end
      vim.cmd('TSUpdate')
    end
  end,
})

vim.pack.add({
  { src = gh('nvim-treesitter/nvim-treesitter'), version = 'main' },
  gh('stevearc/conform.nvim'),
  gh('nvim-mini/mini.nvim'),
  gh('mfussenegger/nvim-dap'),
  gh('rcarriga/nvim-dap-ui'),
  gh('nvim-neotest/nvim-nio'),
  gh('theHamsta/nvim-dap-virtual-text'),
  gh('nvim-lua/plenary.nvim'),
  gh('Civitasv/cmake-tools.nvim'),
  gh('t-troebst/perfanno.nvim'),
  gh('lewis6991/gitsigns.nvim'),
  { src = gh('catppuccin/nvim'), name = 'catppuccin' },
  { src = gh('rose-pine/neovim'), name = 'rose-pine' },
  gh('folke/tokyonight.nvim'),
  gh('ellisonleao/gruvbox.nvim'),
  gh('rebelot/kanagawa.nvim'),
}, { confirm = false })
