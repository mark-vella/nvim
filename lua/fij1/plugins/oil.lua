return {
  {
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup {
        columns = {
          'icon',
        },
        view_options = {
          show_hidden = true,
        },
        win_options = {
          signcolumn = 'yes:2',
        },
      }
    end,
    dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  },
  {
    'refractalize/oil-git-status.nvim',

    dependencies = {
      'stevearc/oil.nvim',
    },

    config = function()
      require('oil-git-status').setup {
        show_ignored = true,
      }
    end,
  },
}
