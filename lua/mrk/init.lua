require("mrk.opts")
require("mrk.maps")
require("mrk.autos")

local theme_file = vim.fn.stdpath("data") .. "/last_theme.txt"
local active_theme
local f = io.open(theme_file, "r")

if f then
        active_theme = vim.trim(f:read("*all") or "")
        f:close()

        if active_theme == "" then
                active_theme = nil
        end
end

vim.g.mrk_active_theme = active_theme

-- Install `lazy.nvim` package manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
        local lazyrepo = "https://github.com/folke/lazy.nvim.git"
        local out = vim.fn.system({
                "git",
                "clone",
                "--filter=blob:none",
                "--branch=stable",
                lazyrepo,
                lazypath,
        })

        if vim.v.shell_error ~= 0 then
                vim.api.nvim_echo({
                        { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
                        { out, "WarningMsg" },
                        { "\nPress any key to exit..." },
                }, true, {})
                vim.fn.getchar()
                os.exit(1)
        end
end
vim.opt.rtp:prepend(lazypath)
--

require("lazy").setup({
        spec = {
                { import = "mrk.plugins" },
        },
        checker = {
                enabled = true,
                notify = false,
        },
})

if active_theme and vim.g.colors_name ~= active_theme then
        pcall(vim.cmd.colorscheme, active_theme)
end
