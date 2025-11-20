require("mrk.opts")
require("mrk.maps")
require("mrk.autos")

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
        },
})

-- Load persisted theme
local theme_file = vim.fn.stdpath("data") .. "/last_theme.txt"
local f = io.open(theme_file, "r")

if f then
        local theme = f:read("*all")

        f:close()

        if theme and theme ~= "" then
                pcall(vim.cmd.colorscheme, theme)
        end
end
