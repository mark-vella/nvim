-- Highlight selection when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "Highlight selection when yanking text",
        group = vim.api.nvim_create_augroup("mrk-highlight-yank", { clear = true }),
        callback = function()
                vim.hl.on_yank()
        end,
})
