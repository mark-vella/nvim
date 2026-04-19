local active_theme = vim.g.mrk_active_theme

local function is_active_theme(matcher)
        if not active_theme then
                return false
        end

        if type(matcher) == "function" then
                return matcher(active_theme)
        end

        return vim.tbl_contains(matcher, active_theme)
end

local function colorscheme(repo, matcher, extra)
        local spec = extra or {}
        local active = is_active_theme(matcher)

        spec[1] = repo
        spec.lazy = not active

        if active then
                spec.priority = 1000
        end

        return spec
end

return {
        colorscheme("mark-vella/oc.nvim", { "oc" }),
        colorscheme("miikanissi/modus-themes.nvim", function(theme)
                return theme == "modus" or vim.startswith(theme, "modus_")
        end),
        colorscheme("nyoom-engineering/oxocarbon.nvim", { "oxocarbon" }),
        colorscheme("zootedb0t/citruszest.nvim", { "citruszest" }),
        colorscheme("rose-pine/neovim", function(theme)
                return theme == "rose-pine" or vim.startswith(theme, "rose-pine-")
        end, {
                name = "rose-pine",
        }),
        colorscheme("catppuccin/nvim", function(theme)
                return theme == "catppuccin" or vim.startswith(theme, "catppuccin-")
        end),
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
