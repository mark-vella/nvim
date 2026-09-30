-- Colorscheme selection. The saved choice is either a colorscheme name or "omarchy", the
-- catch-all that follows the current Omarchy theme and switches along with it. Colorscheme
-- plugins stay lazy; lazy.nvim loads them on :colorscheme.

local M = {}

-- Global so colors/omarchy.lua and keymaps can reach it
_G.MrkTheme = M

M.OMARCHY = "omarchy"

local choice_file = vim.fn.stdpath("data") .. "/last_theme.txt"
local omarchy_dir = vim.fn.expand("~/.local/state/omarchy/current")
local omarchy_theme_file = omarchy_dir .. "/theme/neovim.lua"

local choice
local applying = false
local picking = false
-- Source of the last applied Omarchy theme, used to skip no-op reloads
local omarchy_applied
-- Names the applied Omarchy theme answers to, so reloads of it don't pin a theme
local omarchy_names = {}
-- Plugins set up with Omarchy opts, which need resetting when a theme has none
local configured = {}

local function read(path)
        local f = io.open(path, "r")

        if not f then
                return nil
        end

        local content = f:read("*all")
        f:close()

        return content
end

local function notify(msg, level)
        vim.notify(msg, level or vim.log.levels.WARN, { title = "Theme" })
end

local function persist(name)
        if name == choice then
                return
        end

        choice = name

        local f = io.open(choice_file, "w")

        if f then
                f:write(name)
                f:close()
        end
end

local function plugin_name(spec)
        return spec.name or (spec[1] or spec.url or spec.dir or ""):match("[^/]+$")
end

function M.omarchy_available()
        return vim.fn.filereadable(omarchy_theme_file) == 1
end

-- Reads Omarchy's LazyVim-style spec: theme plugin specs plus a LazyVim entry naming the
-- colorscheme.
function M.omarchy_theme()
        local source = read(omarchy_theme_file)

        if not source then
                return nil
        end

        local chunk = load(source, "@" .. omarchy_theme_file)

        if not chunk then
                return nil
        end

        local ok, specs = pcall(chunk)

        if not ok or type(specs) ~= "table" then
                return nil
        end

        local theme = { source = source, plugins = {} }

        for _, spec in ipairs(specs) do
                if type(spec) == "table" and spec[1] == "LazyVim/LazyVim" then
                        theme.colorscheme = spec.opts and spec.opts.colorscheme
                elseif type(spec) == "table" then
                        table.insert(theme.plugins, spec)
                end
        end

        return theme.colorscheme and theme or nil
end

-- Lazy specs for the current Omarchy theme's plugins, so a theme outside the preinstalled
-- set still gets installed. Opts are applied at switch time, not by lazy.
function M.omarchy_plugin_specs()
        local theme = M.omarchy_available() and M.omarchy_theme()
        local specs = {}

        for _, spec in ipairs(theme and theme.plugins or {}) do
                spec = vim.deepcopy(spec)
                spec.opts, spec.config, spec.priority = nil, nil, nil
                table.insert(specs, spec)
        end

        return specs
end

local function configure(spec)
        local name = plugin_name(spec)
        local plugin = require("lazy.core.config").plugins[name]

        if not plugin then
                notify(("Theme plugin %s is not installed, restart Neovim to install it"):format(name))
                return
        end

        if spec.opts == nil and spec.config == nil and not configured[name] then
                return
        end

        require("lazy").load({ plugins = { name } })

        local opts = spec.opts or {}

        if type(opts) == "function" then
                opts = opts(plugin, {}) or {}
        end

        if type(spec.config) == "function" then
                spec.config(plugin, opts)
        else
                local main = require("lazy.core.loader").get_main(plugin)

                if main then
                        require(main).setup(opts)
                end
        end

        configured[name] = spec.opts ~= nil or spec.config ~= nil
end

local function colorscheme(name)
        applying = true
        local ok, err = pcall(vim.cmd.colorscheme, name)
        applying = false

        if not ok then
                notify(("Failed to load colorscheme %s: %s"):format(name, err), vim.log.levels.ERROR)
        end

        return ok
end

function M.apply_omarchy()
        local theme = M.omarchy_theme()

        if not theme then
                notify("No Omarchy Neovim theme found")
                return false
        end

        for _, spec in ipairs(theme.plugins) do
                configure(spec)
        end

        -- Light themes flip this themselves, and themes like gruvbox read it to pick a variant
        vim.g.colors_name = nil
        vim.o.background = "dark"

        local ok = colorscheme(theme.colorscheme)

        omarchy_applied = theme.source
        omarchy_names = { [theme.colorscheme] = true, [vim.g.colors_name or ""] = true }

        return ok
end

-- Reapplies the saved choice
function M.apply()
        if choice == M.OMARCHY then
                return M.omarchy_available() and M.apply_omarchy()
        end

        return colorscheme(choice)
end

function M.set(name)
        persist(name)
        M.apply()
end

-- Follows an Omarchy theme change when on the catch-all
function M.sync()
        if choice ~= M.OMARCHY or not M.omarchy_available() then
                return
        end

        if read(omarchy_theme_file) ~= omarchy_applied then
                M.apply_omarchy()
        end
end

-- Colorscheme picker that previews without saving, and restores the saved choice on cancel
function M.pick()
        local background = vim.o.background
        local selected

        picking = true

        Snacks.picker.colorschemes({
                confirm = function(picker, item)
                        selected = item and item.text
                        picker:close()
                end,
                on_close = function(picker)
                        -- Skip snacks' own restore, which would reload the previewed name
                        picker.preview.state.colorscheme = nil

                        vim.schedule(function()
                                picking = false

                                if selected then
                                        M.set(selected)
                                else
                                        vim.o.background = background
                                        M.apply()
                                end
                        end)
                end,
        })
end

local function watch()
        local handle = vim.uv.new_fs_event()
        local timer = vim.uv.new_timer()

        if not handle or not timer then
                return
        end

        -- omarchy theme set swaps the whole theme directory, so watch its parent and let the
        -- burst of events settle
        handle:start(omarchy_dir, {}, function()
                timer:start(200, 0, vim.schedule_wrap(M.sync))
        end)
end

function M.setup()
        choice = vim.trim(read(choice_file) or "")

        if choice == "" then
                choice = M.OMARCHY
        end

        local group = vim.api.nvim_create_augroup("mrk-theme", { clear = true })

        -- Persist a colorscheme chosen with :colorscheme
        vim.api.nvim_create_autocmd("ColorScheme", {
                group = group,
                callback = function(args)
                        if applying or picking then
                                return
                        end

                        if args.match == M.OMARCHY then
                                if M.omarchy_available() then
                                        persist(M.OMARCHY)
                                end
                        elseif not (choice == M.OMARCHY and omarchy_names[args.match]) then
                                persist(args.match)
                        end
                end,
        })

        if vim.fn.isdirectory(omarchy_dir) == 1 then
                watch()

                vim.api.nvim_create_autocmd("FocusGained", {
                        group = group,
                        callback = M.sync,
                })
        end

        M.apply()
end

local themes = {
        { "mark-vella/oc.nvim" },
        { "miikanissi/modus-themes.nvim" },
        { "nyoom-engineering/oxocarbon.nvim" },
        { "zootedb0t/citruszest.nvim" },

        -- Every theme Omarchy ships a Neovim spec for, matching its LazyVim config
        {
                "bjarneo/aether.nvim",
                branch = "v3",
                name = "aether",
                init = function()
                        -- Aether watches Omarchy's theme file and switches colorschemes itself, even
                        -- when another theme is pinned. watch() above handles that, so mark its hot
                        -- reload as already set up.
                        _G.__aether_hotreload_state = {
                                did_setup = true,
                                fs_event_handles = {},
                                pending_reload_timers = {},
                        }
                end,
        },
        { "bjarneo/ethereal.nvim" },
        { "bjarneo/hackerman.nvim", dependencies = { "bjarneo/aether.nvim" } },
        { "bjarneo/vantablack.nvim" },
        { "bjarneo/white.nvim" },
        { "catppuccin/nvim", name = "catppuccin" },
        { "EdenEast/nightfox.nvim" },
        { "ellisonleao/gruvbox.nvim" },
        { "ficcdaf/ashen.nvim" },
        { "folke/tokyonight.nvim" },
        { "kepano/flexoki-neovim" },
        { "loctvl842/monokai-pro.nvim" },
        { "neanias/everforest-nvim" },
        { "OldJobobo/miasma.nvim" },
        { "OldJobobo/retro-82.nvim" },
        { "omacom-io/lumon.nvim" },
        { "rebelot/kanagawa.nvim" },
        { "ribru17/bamboo.nvim" },
        { "rose-pine/neovim", name = "rose-pine" },
        { "tahayvr/matteblack.nvim" },
}

-- The current Omarchy theme's plugins, in case it uses one not listed above
vim.list_extend(themes, M.omarchy_plugin_specs())

for _, spec in ipairs(themes) do
        spec.lazy = true
end

return vim.list_extend(themes, {
        {
                -- Applies the saved choice before other plugins load
                name = "mrk-theme",
                dir = vim.fn.stdpath("config"),
                lazy = false,
                priority = 1000,
                config = M.setup,
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
})
