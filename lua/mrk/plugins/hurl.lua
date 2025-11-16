return {
        {
                "jellydn/hurl.nvim",
                dependencies = {
                        "MunifTanjim/nui.nvim",
                        "nvim-lua/plenary.nvim",
                        "nvim-treesitter/nvim-treesitter",
                },
                ft = "hurl",
                opts = {
                        debug = false,
                        show_notification = true,
                        -- "split" or "popup"
                        mode = "popup",
                        formatters = {
                                json = { "jq" },
                        },
                        mappings = {
                                close = "q", -- Close popup/split
                                next_panel = "<C-n>", -- Next response panel
                                prev_panel = "<C-p>", -- Previous response panel
                        },
                        env_file = { "vars.env" },
                },
                keys = {
                        {
                                "<leader>ha",
                                "<cmd>HurlRunner<CR>",
                                desc = "[h]url [a]ll in file",
                        },
                        {
                                "<leader>hh",
                                "<cmd>HurlRunnerAt<CR>",
                                desc = "[h]url [h]ere",
                        },
                        {
                                "<leader>he",
                                "<cmd>HurlRunnerToEntry<CR>",
                                desc = "[h]url run to [e]ntry",
                        },
                        {
                                "<leader>hf",
                                "<cmd>HurlRunnerToEnd<CR>",
                                desc = "[h]url [f]ull",
                        },
                        {
                                "<leader>ht",
                                "<cmd>HurlToggleMode<CR>",
                                desc = "[h]url [t]oggle",
                        },
                        {
                                "<leader>hv",
                                "<cmd>HurlVerbose<CR>",
                                desc = "[h]url [v]erbose",
                        },
                        {
                                "<leader>hV",
                                "<cmd>HurlVeryVerbose<CR>",
                                desc = "[h]url [V]ery verbose",
                        },
                        {
                                "<leader>hs",
                                "<cmd>HurlRunner<CR>",
                                mode = "v",
                                desc = "[h]url [s]election",
                        },
                },
        },
}
