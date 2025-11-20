-- Highlight selection when yanking text
vim.api.nvim_create_autocmd("TextYankPost", {
        desc = "Highlight selection when yanking text",
        group = vim.api.nvim_create_augroup("mrk-highlight-yank", { clear = true }),
        callback = function()
                vim.hl.on_yank()
        end,
})

-- Persist theme on change
vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("mrk-theme-persist", { clear = true }),
        callback = function()
                local theme = vim.g.colors_name

                if theme then
                        local file = io.open(vim.fn.stdpath("data") .. "/last_theme.txt", "w")

                        if file then
                                file:write(theme)
                                file:close()
                        end
                end
        end,
})
