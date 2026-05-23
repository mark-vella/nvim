return {
        {
                "dmtrKovalenko/fff.nvim",
                build = function()
                        require("fff.download").download_or_build_binary()
                end,
                lazy = false,
                opts = {
                        lazy_sync = true,
                        debug = {
                                enabled = false,
                                show_scores = false,
                        },
                },
                keys = {
                        {
                                "<leader>sf",
                                function()
                                        require("fff").find_files()
                                end,
                                desc = "[s]earch [f]iles",
                        },
                        {
                                "<leader>sg",
                                function()
                                        require("fff").live_grep()
                                end,
                                desc = "[s]earch via [g]rep",
                        },
                        {
                                "<leader>fz",
                                function()
                                        require("fff").live_grep({
                                                grep = {
                                                        modes = { "fuzzy", "plain" },
                                                },
                                        })
                                end,
                                desc = "[f]uzzy grep",
                        },
                        {
                                "<leader>sw",
                                function()
                                        require("fff").live_grep({
                                                query = vim.fn.expand("<cword>"),
                                        })
                                end,
                                desc = "[s]earch [w]ord",
                                mode = { "n", "x" },
                        },
                },
        },
}
