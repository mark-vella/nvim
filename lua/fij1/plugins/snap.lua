return {
  {
    'mistricky/codesnap.nvim',
    build = 'make',
    config = function()
      require('codesnap').setup {
        bg_color = '#ffffff',
      }
    end,
  },
}
