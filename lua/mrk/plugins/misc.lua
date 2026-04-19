return {
        {
                "mluders/comfy-line-numbers.nvim",
                event = "BufReadPost",
                config = function()
                        require("comfy-line-numbers").setup({})
                end,
        },
        {
                "danilamihailov/beacon.nvim",
                event = "BufReadPost",
        },
}
