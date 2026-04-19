return {
        -- Collection of various small independent plugins/modules
        {
                "echasnovski/mini.nvim",
                config = function()
                        -- Simple and easy statusline.
                        -- set use_icons to true if you have a Nerd Font
                        local statusline = require("mini.statusline")
                        statusline.setup({ use_icons = vim.g.have_nerd_font })

                        -- You can configure sections in the statusline by overriding their
                        -- default behavior
                        ---@diagnostic disable-next-line: duplicate-set-field
                        statusline.section_location = function()
                                return "%2l:%-2v"
                        end

                        vim.api.nvim_create_autocmd("BufReadPost", {
                                group = vim.api.nvim_create_augroup("mrk-mini-textobjects", {
                                        clear = true,
                                }),
                                once = true,
                                callback = function()
                                        -- Better Around/Inside textobjects
                                        --
                                        -- Examples:
                                        --  - va)  - [V]isually select [A]round [)]paren
                                        --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
                                        --  - ci'  - [C]hange [I]nside [']quote
                                        require("mini.ai").setup({ n_lines = 500 })

                                        -- Add/delete/replace surroundings (brackets, quotes, etc.)
                                        --
                                        -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
                                        -- - sd'   - [S]urround [D]elete [']quotes
                                        -- - sr)'  - [S]urround [R]eplace [)] [']
                                        require("mini.surround").setup()
                                end,
                        })
                end,
        },
}
