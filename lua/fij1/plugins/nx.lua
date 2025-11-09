return {
  'henrique-smr/nx.nvim',
  dependencies = {
    'ibhagwan/fzf-lua',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('nx').setup()
  end,
}
