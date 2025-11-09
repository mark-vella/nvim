-- ThePrimeagen setup
vim.g.mapleader = ' '
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

vim.keymap.set('n', 'J', 'mzJ`z')
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '<leader>zig', '<cmd>LspRestart<cr>')

-- greatest remap ever
vim.keymap.set('x', '<leader>p', [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set('n', '<leader>Y', [["+Y]])

vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])

-- This is going to get me cancelled
vim.keymap.set('i', '<C-c>', '<Esc>')

vim.keymap.set('n', 'Q', '<nop>')
vim.keymap.set('n', '<leader>f', vim.lsp.buf.format)

vim.keymap.set('n', '<C-k>', '<cmd>cnext<CR>zz')
vim.keymap.set('n', '<C-j>', '<cmd>cprev<CR>zz')
vim.keymap.set('n', '<leader>k', '<cmd>lnext<CR>zz')
vim.keymap.set('n', '<leader>j', '<cmd>lprev<CR>zz')

vim.keymap.set('n', '<leader>s', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })

-- This is a great mapping, investigate how to make it work for me with TypeScript.
vim.keymap.set('n', '<leader>ee', 'oif err != nil {<CR>}<Esc>Oreturn err<Esc>')

-- Visit init.lua file in /custom
vim.keymap.set('n', '<leader>vpp', '<cmd>e ~/.config/nvim/lua/custom/plugins/init.lua<CR>')

vim.keymap.set('n', '<leader><leader>', function()
  vim.cmd 'so'
end)

-- Eslint setup
vim.api.nvim_set_keymap('n', '<leader>ll', ':Eslint<CR>:w<CR>', { noremap = true, silent = true })

-- Oil setup
vim.api.nvim_set_keymap('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent directory', noremap = true, silent = true })

-- Themery setup
vim.api.nvim_set_keymap('n', '<leader>tt', '<CMD>Themery<CR>', { desc = 'Open Themery in Telescope', noremap = true, silent = true })

-- Transparency setup
vim.api.nvim_set_keymap('n', '<leader>tp', '<CMD>TransparentToggle<CR>', { desc = 'Toggle transparency', noremap = true, silent = true })

-- Copilot setup
vim.api.nvim_set_keymap('i', '<C-j>', 'copilot#Next()', { desc = 'Navigate to next Copilot suggestion', expr = true, silent = true, noremap = true })
vim.api.nvim_set_keymap('i', '<C-k>', 'copilot#Previous()', { desc = 'Navigate to previous Copilot suggestion', expr = true, silent = true, noremap = true })
vim.api.nvim_set_keymap('i', '<C-\\>', 'copilot#Dismiss()', { desc = 'Dismiss the Copilot suggestion', expr = true, silent = true, noremap = true })

-- LSP setup
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostics for current line' })

return {}
