return {
  's1n7ax/nvim-terminal',
  config = function()
    vim.o.hidden = true
    require('nvim-terminal').setup {
      toggle_keymap = '<leader>;',
    }
  end,
}
