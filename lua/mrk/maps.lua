vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Exit to netrw in current buffer's dir
vim.keymap.set("n", "-", "<cmd>Ex<CR>")

-- Clear any highlights on search
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Open diagnostic quickfix list
vim.keymap.set(
        "n",
        "<leader>q",
        vim.diagnostic.setloclist,
        { desc = "open diagnostic [q]uickfix list" }
)

-- Exit terminal mode in built-in terminal
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "exit terminal mode" })

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", "<cmd>echo 'use h to move'<CR>")
vim.keymap.set("n", "<down>", "<cmd>echo 'use j to move'<CR>")
vim.keymap.set("n", "<up>", "<cmd>echo 'use k to move'<CR>")
vim.keymap.set("n", "<right>", "<cmd>echo 'use l to move'<CR>")

-- Shift focus between windows
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "move focus to the left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "move focus to the upper window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "move focus to the right window" })
