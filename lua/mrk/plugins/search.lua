return {
        {
                "MagicDuck/grug-far.nvim",
                opts = {},
                keys = {
                        {
                                "<leader>S",
                                function()
                                        require("grug-far").open({ transient = true })
                                end,
                                desc = "[S]earch project",
                        },
                },
        },
}
