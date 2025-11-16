return {
        {
                "folke/sidekick.nvim",
                opts = {
                        cli = {
                                mux = {
                                        backend = "tmux",
                                        create = "terminal",
                                        enabled = true,
                                        split = {
                                                vertical = true,
                                                size = 0.75,
                                        },
                                },
                        },
                },
                keys = {
                        {
                                "<tab>",
                                function()
                                        if not require("sidekick").nes_jump_or_apply() then
                                                return "<Tab>"
                                        end
                                end,
                                expr = true,
                                desc = "Goto/Apply Next Edit Suggestion",
                        },
                        {
                                "<leader>ac",
                                function()
                                        require("sidekick.cli").toggle({
                                                name = "opencode",
                                                focus = true,
                                        })
                                end,
                                desc = "Sidekick Toggle CLI",
                        },
                        {
                                "<leader>af",
                                function()
                                        require("sidekick.cli").send({ msg = "{file}" })
                                end,
                                desc = "Send File",
                        },
                        {
                                "<leader>av",
                                function()
                                        require("sidekick.cli").send({ msg = "{selection}" })
                                end,
                                mode = { "x" },
                                desc = "Send Visual Selection",
                        },
                },
        },
}
