return {
        "jellydn/hurl.nvim",
        dependencies = {
                "MunifTanjim/nui.nvim",
                "nvim-lua/plenary.nvim",
                "nvim-treesitter/nvim-treesitter",
                {
                        "MeanderingProgrammer/render-markdown.nvim",
                        opts = { file_types = { "markdown" } },
                        ft = { "markdown" },
                },
        },
        ft = "hurl",
        opts = {
                debug = true,
                show_notification = true,
                mode = "popup",
                formatters = {
                        json = { "jq" },
                        html = { "prettier", "--parser", "html" },
                },
                mappings = {
                        close = "q", -- Close popup/split
                        next_panel = "<C-n>", -- Next response panel
                        prev_panel = "<C-p>", -- Previous response panel
                },
                env_file = { "vars.env" },
                fixture_vars = {
                        {
                                name = "random_int_number",
                                callback = function()
                                        return tostring(math.random(1, 1000))
                                end,
                        },
                        {
                                name = "random_float_number",
                                callback = function()
                                        return string.format("%.2f", math.random() * 10)
                                end,
                        },
                },
        },
        keys = {
                {
                        "<leader>ha",
                        "<cmd>HurlRunner<CR>",
                        desc = "[h]url run [a]ll",
                },
                {
                        "<leader>hh",
                        "<cmd>HurlRunnerAt<CR>",
                        desc = "[h]url run [h]ere",
                },
                {
                        "<leader>hb",
                        "<cmd>HurlRunnerToEntry<CR>",
                        desc = "[h]url to entry",
                },
                {
                        "<leader>hf",
                        "<cmd>HurlRunnerToEnd<CR>",
                        desc = "[h]url to end",
                },
                {
                        "<leader>ht",
                        "<cmd>HurlToggleMode<CR>",
                        desc = "[h]url toggle",
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
                        desc = "[h]url selection",
                },
        },
}
