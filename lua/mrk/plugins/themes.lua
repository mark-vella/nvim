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
}
