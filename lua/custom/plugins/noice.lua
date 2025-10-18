vim.keymap.set('n', '<leader>nl', function()
  require('noice').cmd 'last'
end)

vim.keymap.set('n', '<leader>nd', function()
  require('noice').cmd 'dismiss'
end)

return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  opts = {},
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
}
