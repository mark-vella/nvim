return {
        {
                "mark-vella/oc.nvim",
                lazy = false,
                priority = 1000,
                config = function()
                        require("oc").setup({})
                        vim.cmd.colorscheme("oc")
                end,
        },
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
}
