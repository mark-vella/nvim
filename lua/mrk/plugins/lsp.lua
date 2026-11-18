return {
        {
                "NMAC427/guess-indent.nvim",
                event = "BufReadPost",
        },

        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        {
                "folke/lazydev.nvim",
                ft = "lua",
                opts = {
                        library = {
                                -- Load luvit types when the `vim.uv` word is found
                                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                        },
                },
        },

        -- Useful status updates for LSP.
        {
                "j-hui/fidget.nvim",
                event = "LspAttach",
                cmd = "Fidget",
                opts = {},
        },

        -- Main LSP Configuration
        {
                "neovim/nvim-lspconfig",
                event = { "BufReadPre", "BufNewFile" },
                dependencies = {
                        -- Automatically install LSPs and related tools to stdpath for Neovim
                        -- Mason must be loaded before its dependents so we need to set it up here.
                        { "mason-org/mason.nvim", opts = {} },
                        "mason-org/mason-lspconfig.nvim",
                        "WhoIsSethDaniel/mason-tool-installer.nvim",

                        -- Loaded here rather than on its own `ft`, which would re-run FileType for the
                        -- first Lua buffer
                        "folke/lazydev.nvim",
                },
                config = function()
                        --  This function gets run when an LSP attaches to a particular buffer.
                        --    That is to say, every time a new file is opened that is associated with
                        --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
                        --    function will be executed to configure the current buffer
                        vim.api.nvim_create_autocmd("LspAttach", {
                                group = vim.api.nvim_create_augroup(
                                        "mrk-lsp-attach",
                                        { clear = true }
                                ),
                                callback = function(event)
                                        -- Function that lets us more easily define mappings specific
                                        -- for LSP related items. It sets the mode, buffer and description for us each time.
                                        local map = function(keys, func, desc, mode)
                                                mode = mode or "n"
                                                vim.keymap.set(mode, keys, func, {
                                                        buffer = event.buf,
                                                        desc = "LSP: " .. desc,
                                                })
                                        end

                                        -- The following two autocommands are used to highlight references of the
                                        -- word under your cursor when your cursor rests there for a little while.
                                        --    See `:help CursorHold` for information about when this is executed
                                        --
                                        -- When you move your cursor, the highlights will be cleared (the second autocommand).
                                        local client =
                                                vim.lsp.get_client_by_id(event.data.client_id)

                                        if
                                                client
                                                and client:supports_method(
                                                        vim.lsp.protocol.Methods.textDocument_documentHighlight,
                                                        event.buf
                                                )
                                        then
                                                local highlight_augroup =
                                                        vim.api.nvim_create_augroup(
                                                                "mrk-lsp-highlight",
                                                                { clear = false }
                                                        )
                                                vim.api.nvim_create_autocmd(
                                                        { "CursorHold", "CursorHoldI" },
                                                        {
                                                                buffer = event.buf,
                                                                group = highlight_augroup,
                                                                callback = vim.lsp.buf.document_highlight,
                                                        }
                                                )

                                                vim.api.nvim_create_autocmd(
                                                        { "CursorMoved", "CursorMovedI" },
                                                        {
                                                                buffer = event.buf,
                                                                group = highlight_augroup,
                                                                callback = vim.lsp.buf.clear_references,
                                                        }
                                                )

                                                vim.api.nvim_create_autocmd("LspDetach", {
                                                        group = vim.api.nvim_create_augroup(
                                                                "mrk-lsp-detach",
                                                                { clear = true }
                                                        ),
                                                        callback = function(event2)
                                                                vim.lsp.buf.clear_references()
                                                                vim.api.nvim_clear_autocmds({
                                                                        group = "mrk-lsp-highlight",
                                                                        buffer = event2.buf,
                                                                })
                                                        end,
                                                })
                                        end

                                        -- The following code creates a keymap to toggle inlay hints in your
                                        -- code, if the language server you are using supports them
                                        --
                                        -- Inlay hints are disabled by default
                                        if
                                                client
                                                and client:supports_method(
                                                        vim.lsp.protocol.Methods.textDocument_inlayHint,
                                                        event.buf
                                                )
                                        then
                                                map("<leader>th", function()
                                                        vim.lsp.inlay_hint.enable(
                                                                not vim.lsp.inlay_hint.is_enabled({
                                                                        bufnr = event.buf,
                                                                })
                                                        )
                                                end, "[T]oggle Inlay [H]ints")
                                        end
                                end,
                        })

                        -- Diagnostic Config
                        vim.diagnostic.config({
                                severity_sort = true,
                                float = { border = "rounded", source = "if_many" },
                                underline = { severity = vim.diagnostic.severity.ERROR },
                                signs = vim.g.have_nerd_font
                                                and {
                                                        text = {
                                                                [vim.diagnostic.severity.ERROR] = "󰅚 ",
                                                                [vim.diagnostic.severity.WARN] = "󰀪 ",
                                                                [vim.diagnostic.severity.INFO] = "󰋽 ",
                                                                [vim.diagnostic.severity.HINT] = "󰌶 ",
                                                        },
                                                }
                                        or {},
                                virtual_text = {
                                        source = "if_many",
                                        spacing = 2,
                                },
                        })

                        local function nearest_bin(root_dir, path)
                                local found = root_dir
                                        and vim.fs.find(path, { path = root_dir, upward = true })[1]
                                return found and vim.fn.executable(found) == 1 and found or nil
                        end

                        local ts_inlay_hints = {
                                parameterNames = {
                                        enabled = "all",
                                        suppressWhenArgumentMatchesName = true,
                                },
                                parameterTypes = { enabled = true },
                                variableTypes = {
                                        enabled = true,
                                        suppressWhenTypeMatchesName = true,
                                },
                                propertyDeclarationTypes = { enabled = true },
                                functionLikeReturnTypes = { enabled = true },
                                enumMemberValues = { enabled = true },
                        }

                        -- The tsrs tsdk carries the effect-tsgo patch; the plain TypeScript binary reports no Effect diagnostics.
                        vim.lsp.config("tsc", {
                                cmd = function(dispatchers, config)
                                        local bin = nearest_bin(
                                                config.root_dir,
                                                "node_modules/tsrs/tsdk/tsgo"
                                        ) or nearest_bin(
                                                config.root_dir,
                                                "node_modules/.bin/tsc"
                                        ) or nearest_bin(
                                                config.root_dir,
                                                "node_modules/.bin/tsgo"
                                        ) or "tsc"
                                        return vim.lsp.rpc.start(
                                                { bin, "--lsp", "--stdio" },
                                                dispatchers
                                        )
                                end,
                                settings = {
                                        typescript = {
                                                inlayHints = ts_inlay_hints,
                                        },
                                        javascript = {
                                                inlayHints = ts_inlay_hints,
                                        },
                                },
                        })

                        -- lspconfig only looks in the package root's node_modules, which a pnpm workspace package lacks.
                        vim.lsp.config("oxlint", {
                                cmd = function(dispatchers, config)
                                        local bin = nearest_bin(
                                                config.root_dir,
                                                "node_modules/.bin/oxlint"
                                        ) or "oxlint"
                                        return vim.lsp.rpc.start({ bin, "--lsp" }, dispatchers)
                                end,
                        })

                        vim.lsp.config("tailwindcss", {
                                workspace_required = true,
                                root_dir = function(bufnr, on_dir)
                                        local fname = vim.api.nvim_buf_get_name(bufnr)
                                        local markers =
                                                require("lspconfig.util").insert_package_json(
                                                        {},
                                                        "tailwindcss",
                                                        fname
                                                )
                                        local found = vim.fs.find(
                                                markers,
                                                { path = fname, upward = true }
                                        )[1]
                                        if found then
                                                on_dir(vim.fs.dirname(found))
                                        end
                                end,
                        })

                        vim.lsp.config("lua_ls", {
                                settings = {
                                        Lua = {
                                                completion = { callSnippet = "Replace" },
                                                diagnostics = { disable = { "missing-fields" } },
                                        },
                                },
                        })

                        local has_go = vim.fn.executable("go") == 1

                        local ensure_installed = {
                                "lua-language-server",
                                "tsc",
                                "astro-language-server",
                                "oxlint",
                                "oxfmt",
                                "tailwindcss-language-server",
                                "stylua",
                                "prettier",
                                "docker-compose-language-service",
                                "docker-language-server",
                                "dockerfile-language-server",
                                "gh-actions-language-server",
                                "circleci-yaml-language-server",
                                "yaml-language-server",
                        }

                        if has_go then
                                vim.list_extend(ensure_installed, {
                                        "gopls",
                                        "goimports",
                                        "gofumpt",
                                        "golines",
                                        "gomodifytags",
                                })
                        end

                        require("mason-tool-installer").setup({
                                ensure_installed = ensure_installed,
                        })

                        -- Enabling the servers reads the whole mason registry, so it waits for the first
                        -- screen. Servers enabled before VimEnter would skip buffers that already have a filetype.
                        local function setup_servers()
                                vim.lsp.config("*", {
                                        capabilities = require("blink.cmp").get_lsp_capabilities(),
                                })

                                require("mason-lspconfig").setup({
                                        automatic_enable = { exclude = { "eslint", "stylua" } },
                                })
                        end

                        if vim.v.vim_did_enter == 1 then
                                vim.schedule(setup_servers)
                        else
                                vim.api.nvim_create_autocmd("VimEnter", {
                                        once = true,
                                        callback = function()
                                                vim.schedule(setup_servers)
                                        end,
                                })
                        end
                end,
        },

        -- Autoformat
        {
                "stevearc/conform.nvim",
                event = { "BufWritePre" },
                cmd = { "ConformInfo" },
                keys = {
                        {
                                "<leader>f",
                                function()
                                        require("conform").format({
                                                async = true,
                                                lsp_format = "fallback",
                                        })
                                end,
                                mode = "",
                                desc = "[f]ormat buffer",
                        },
                },
                opts = function()
                        local has_go = vim.fn.executable("go") == 1

                        local formatters_by_ft = {
                                lua = { "stylua" },
                                typescript = { "oxfmt" },
                                typescriptreact = { "oxfmt" },
                                tsx = { "oxfmt" },
                                javascript = { "oxfmt" },
                                javascriptreact = { "oxfmt" },
                                jsx = { "oxfmt" },
                                json = { "oxfmt" },
                                jsonc = { "oxfmt" },
                                json5 = { "oxfmt" },
                                yaml = { "oxfmt" },
                                html = { "oxfmt" },
                                vue = { "oxfmt" },
                                css = { "oxfmt" },
                                scss = { "oxfmt" },
                                less = { "oxfmt" },
                                graphql = { "oxfmt" },
                                markdown = { "oxfmt" },
                                mdx = { "oxfmt" },
                                astro = { "prettier" },
                        }

                        if has_go then
                                formatters_by_ft.go = { "goimports", "gofumpt" }
                        end

                        return {
                                notify_on_error = true,
                                format_on_save = function(bufnr)
                                        -- Disable "format_on_save lsp_fallback" for languages that don't
                                        -- have a well standardized coding style. You can add additional
                                        -- languages here or re-enable it for the disabled ones.
                                        local disable_filetypes = { c = true, cpp = true }
                                        if disable_filetypes[vim.bo[bufnr].filetype] then
                                                return nil
                                        else
                                                return {
                                                        timeout_ms = 500,
                                                        lsp_format = "fallback",
                                                }
                                        end
                                end,
                                formatters_by_ft = formatters_by_ft,
                        }
                end,
        },

        -- Autocompletion
        {
                "saghen/blink.cmp",
                event = "InsertEnter",
                version = "1.*",
                dependencies = {
                        -- Snippet Engine
                        {
                                "L3MON4D3/LuaSnip",
                                version = "2.*",
                                build = (function()
                                        -- Build Step is needed for regex support in snippets.
                                        -- This step is not supported in many windows environments.
                                        -- Remove the below condition to re-enable on windows.
                                        if
                                                vim.fn.has("win32") == 1
                                                or vim.fn.executable("make") == 0
                                        then
                                                return
                                        end
                                        return "make install_jsregexp"
                                end)(),
                                dependencies = {
                                        -- `friendly-snippets` contains a variety of premade snippets.
                                        --    See the README about individual language/framework/plugin snippets:
                                        --    https://github.com/rafamadriz/friendly-snippets
                                        -- {
                                        --   'rafamadriz/friendly-snippets',
                                        --   config = function()
                                        --     require('luasnip.loaders.from_vscode').lazy_load()
                                        --   end,
                                        -- },
                                },
                                opts = {},
                        },
                        "folke/lazydev.nvim",
                },
                --- @module 'blink.cmp'
                --- @type blink.cmp.Config
                opts = {
                        keymap = {
                                -- 'default' (recommended) for mappings similar to built-in completions
                                --   <c-y> to accept ([y]es) the completion.
                                --    This will auto-import if your LSP supports it.
                                --    This will expand snippets if the LSP sent a snippet.
                                -- 'super-tab' for tab to accept
                                -- 'enter' for enter to accept
                                -- 'none' for no mappings
                                --
                                -- For an understanding of why the 'default' preset is recommended,
                                -- you will need to read `:help ins-completion`
                                --
                                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                                --
                                -- All presets have the following mappings:
                                -- <tab>/<s-tab>: move to right/left of your snippet expansion
                                -- <c-space>: Open menu or open docs if already open
                                -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
                                -- <c-e>: Hide menu
                                -- <c-k>: Toggle signature help
                                --
                                -- See :h blink-cmp-config-keymap for defining your own keymap
                                preset = "default",

                                -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
                                --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
                        },

                        appearance = {
                                -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                                -- Adjusts spacing to ensure icons are aligned
                                nerd_font_variant = "mono",
                        },

                        completion = {
                                -- By default, you may press `<c-space>` to show the documentation.
                                -- Optionally, set `auto_show = true` to show the documentation after a delay.
                                documentation = { auto_show = false, auto_show_delay_ms = 500 },
                        },

                        sources = {
                                default = { "lsp", "path", "snippets", "lazydev" },
                                providers = {
                                        lazydev = {
                                                module = "lazydev.integrations.blink",
                                                score_offset = 100,
                                        },
                                },
                        },

                        snippets = { preset = "luasnip" },

                        fuzzy = { implementation = "prefer_rust_with_warning" },

                        -- Shows a signature help window while you type arguments for a function
                        signature = { enabled = true },
                },
        },
}
