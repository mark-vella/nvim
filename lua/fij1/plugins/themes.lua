return {
  { 'Mofiqul/vscode.nvim' },

  { 'rebelot/kanagawa.nvim' },

  { 'catppuccin/nvim', name = 'catppuccin' },

  { 'rose-pine/neovim', name = 'rose-pine' },

  { 'sainnhe/gruvbox-material' },

  { 'projekt0n/github-nvim-theme' },

  { 'jthvai/lavender.nvim' },

  { 'savq/melange-nvim' },

  {
    'briones-gabriel/darcula-solid.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
  },

  { 'ellisonleao/gruvbox.nvim' },

  { 'Mofiqul/adwaita.nvim' },

  { 'xero/miasma.nvim' },

  { 'miikanissi/modus-themes.nvim' },

  { 'arzg/vim-colors-xcode' },

  {
    'folke/tokyonight.nvim',
    config = function()
      require 'tokyonight'

      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },
}
