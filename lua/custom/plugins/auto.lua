vim.api.nvim_create_autocmd('FileType', {
  pattern = 'markdown',
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true -- wrap at word boundaries
    vim.opt_local.breakindent = true -- maintain indent on wrapped lines
  end,
})

return {}
