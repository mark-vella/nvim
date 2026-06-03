local active_theme = vim.g.mrk_active_theme

local function omarchy_theme_specs()
        if not vim.g.mrk_using_omarchy_theme then
                return nil
        end

        local ok, specs = pcall(dofile, vim.g.mrk_omarchy_theme_file)

        if not ok or type(specs) ~= "table" then
                return nil
        end

        local colorscheme
        local result = {}

        for _, spec in ipairs(specs) do
                if type(spec) == "table" and spec[1] == "LazyVim/LazyVim" then
                        colorscheme = spec.opts and spec.opts.colorscheme or colorscheme
                elseif type(spec) == "table" then
                        spec.lazy = false
                        spec.priority = spec.priority or 1000
                        table.insert(result, spec)
                end
        end

        if colorscheme and result[1] then
                local existing_config = result[1].config

                result[1].config = function(...)
                        if type(existing_config) == "function" then
                                existing_config(...)
                        end

                        pcall(vim.cmd.colorscheme, colorscheme)
                end
        end

        return result
end

local omarchy_specs = omarchy_theme_specs()

if omarchy_specs then
        return omarchy_specs
end

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
