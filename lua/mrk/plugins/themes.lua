return {
        {
                "xiyaowong/transparent.nvim",
                keys = {
                        {
                                "<leader>tp",
                                "<cmd>TransparentToggle<CR>",
                                desc = "[t]oggle trans[p]arency",
                        },
                },
                opts = {},
        },

        {
                "briones-gabriel/darcula-solid.nvim",
                dependencies = { "rktjmp/lush.nvim" },
        },

        {
                "uhs-robert/oasis.nvim",
                lazy = false,
                priority = 1000,
                config = function()
                        require("oasis").setup()
                end,
        },
}
