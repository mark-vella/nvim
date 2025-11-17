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

-- Move lines up/down in visual mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "drag current line down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "drag current line up" })

-- Joins the line below while preserving cursor position
vim.keymap.set("n", "J", "mzJ`z", { desc = "[J]oin the line below preserving cursor pos" })

-- Scroll half-page up/down while keeping cursor centered
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "scroll down half-page centrally" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "scroll up half-page centrally" })

-- Scroll through prev/next terms centrally
vim.keymap.set("n", "N", "Nzzzv", { desc = "go to prev search term" })
vim.keymap.set("n", "n", "nzzzv", { desc = "go to [n]ext search term" })

-- Restart LSP server, for when it gets stuck
vim.keymap.set("n", "<leader>zig", "<cmd>LspRestart<cr>", { desc = "restart lsp server" })

-- Black-hole delete (not overwriting the paste buffer)
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d', { desc = "black-hole [d]elete" })

-- Black-hole paste (not overwriting the past buffer)
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "black-hole [p]aste" })

-- Disable Ex mode
vim.keymap.set("n", "Q", "<nop>")

-- Alternative escape insert mode
vim.keymap.set("i", "<C-c>", "<Esc>", { desc = "[c]ancel insert mode" })

-- System clipboard yanking
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "[Y]ank entire line to system clipboard" })
vim.keymap.set(
        { "n", "v" },
        "<leader>y",
        [["+y]],
        { desc = "[y]ank selection to system clipboard" }
)
