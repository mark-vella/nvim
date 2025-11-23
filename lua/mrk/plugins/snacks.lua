return {
        {
                "folke/snacks.nvim",
                opts = {
                        picker = {},
                        lazygit = {},
                        terminal = {},
                },
                keys = {
                        -- LSP: Rename the variable under your cursor.
                        -- Most Language Servers support renaming across files, etc.
                        {
                                "grn",
                                vim.lsp.buf.rename,
                                desc = "[R]e[n]ame",
                        },

                        -- LSP: Execute a code action, usually your cursor needs to be on top of an error
                        -- or a suggestion from your LSP for this to activate.
                        {
                                "gra",
                                vim.lsp.buf.code_action,
                                desc = "[G]oto Code [A]ction",
                                mode = { "n", "x" },
                        },

                        -- LSP: Find references for the word under your cursor.
                        {
                                "grr",
                                function()
                                        Snacks.picker.lsp_references()
                                end,
                                desc = "[G]oto [R]eferences",
                        },

                        -- LSP: Jump to the implementation of the word under your cursor.
                        -- Useful when your language has ways of declaring types without an actual implementation.
                        {
                                "gri",
                                function()
                                        Snacks.picker.lsp_implementations()
                                end,
                                desc = "[G]oto [I]mplementation",
                        },

                        -- LSP: Jump to the definition of the word under your cursor.
                        -- This is where a variable was first declared, or where a function is defined, etc.
                        -- To jump back, press <C-t>.
                        {
                                "grd",
                                function()
                                        Snacks.picker.lsp_definitions()
                                end,
                                desc = "[G]oto [D]efinition",
                        },

                        -- LSP: WARN: This is not Goto Definition, this is Goto Declaration.
                        -- For example, in C this would take you to the header.
                        {
                                "grD",
                                vim.lsp.buf.declaration,
                                desc = "[G]oto [D]eclaration",
                        },

                        -- LSP: Fuzzy find all the symbols in your current document.
                        -- Symbols are things like variables, functions, types, etc.
                        {
                                "gO",
                                function()
                                        Snacks.picker.lsp_symbols()
                                end,
                                desc = "Open Document Symbols",
                        },

                        -- LSP: Fuzzy find all the symbols in your current workspace.
                        -- Similar to document symbols, except searches over your entire project.
                        {
                                "gW",
                                function()
                                        Snacks.picker.lsp_workspace_symbols()
                                end,
                                desc = "Open Workspace Symbols",
                        },

                        -- LSP: Jump to the type of the word under your cursor.
                        -- Useful when you're not sure what type a variable is and you want to see
                        -- the definition of its *type*, not where it was *defined*.
                        {
                                "grt",
                                function()
                                        Snacks.picker.lsp_type_definitions()
                                end,
                                desc = "[G]oto [T]ype Definition",
                        },

                        --terminal
                        {
                                "<leader>;",
                                function()
                                        Snacks.terminal.open()
                                end,
                                desc = "open terminal",
                        },
                        -- lazygit
                        {
                                "<leader>lg",
                                function()
                                        Snacks.lazygit.open()
                                end,
                                desc = "open [l]azy[g]it",
                        },
                        -- picker
                        {
                                "<leader>:",
                                function()
                                        Snacks.picker.command_history()
                                end,
                                desc = "command history",
                        },
                        {
                                "<leader>n",
                                function()
                                        Snacks.picker.notifications()
                                end,
                                desc = "[n]otification history",
                        },
                        -- find
                        {
                                "<leader>fc",
                                function()
                                        Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
                                end,
                                desc = "[f]ind [c]onfig File",
                        },
                        {
                                "<leader>sf",
                                function()
                                        Snacks.picker.git_files()
                                end,
                                desc = "[s]earch [f]iles",
                        },
                        -- {
                        --         "<leader>fg",
                        --         function()
                        --                 Snacks.picker.git_files()
                        --         end,
                        --         desc = "[f]ind [g]it Files",
                        -- },
                        -- gh
                        {
                                "<leader>gp",
                                function()
                                        Snacks.picker.gh_pr({ state = "open" })
                                end,
                                desc = "[g]ithub [p]ull requests",
                        },
                        -- Grep
                        {
                                "<leader>/",
                                function()
                                        Snacks.picker.lines()
                                end,
                                desc = "buffer lines",
                        },
                        {
                                "<leader>sg",
                                function()
                                        Snacks.picker.grep()
                                end,
                                desc = "[s]earch via [g]rep",
                        },
                        {
                                "<leader>sw",
                                function()
                                        Snacks.picker.grep_word()
                                end,
                                desc = "[s]earch for [w]ord",
                                mode = { "n", "x" },
                        },
                        -- search
                        {
                                "<leader>sC",
                                function()
                                        Snacks.picker.commands()
                                end,
                                desc = "[s]earch [C]ommands",
                        },
                        {
                                "<leader>sd",
                                function()
                                        Snacks.picker.diagnostics()
                                end,
                                desc = "[s]earch [d]iagnostics",
                        },
                        {
                                "<leader>sD",
                                function()
                                        Snacks.picker.diagnostics_buffer()
                                end,
                                desc = "[s]earch [D]iagnostics in buffer",
                        },
                        {
                                "<leader>sh",
                                function()
                                        Snacks.picker.help()
                                end,
                                desc = "[s]earch [h]elp",
                        },
                        {
                                "<leader>sK",
                                function()
                                        Snacks.picker.keymaps()
                                end,
                                desc = "[s]earch [K]eymaps",
                        },
                        {
                                "<leader>sM",
                                function()
                                        Snacks.picker.man()
                                end,
                                desc = "[s]earch [M]anuals",
                        },
                        {
                                "<leader>sq",
                                function()
                                        Snacks.picker.qflist()
                                end,
                                desc = "[s]earch [q]uickfix list",
                        },
                        {
                                "<leader>su",
                                function()
                                        Snacks.picker.undo()
                                end,
                                desc = "[s]earch [u]ndo",
                        },
                        {
                                "<leader>tt",
                                function()
                                        Snacks.picker.colorschemes()
                                end,
                                desc = "search [t]hemes",
                        },
                        -- LSP
                        {
                                "gd",
                                function()
                                        Snacks.picker.lsp_definitions()
                                end,
                                desc = "[g]o to [d]efinition",
                        },
                        {
                                "gD",
                                function()
                                        Snacks.picker.lsp_declarations()
                                end,
                                desc = "[g]o to [D]eclaration",
                        },
                        {
                                "gr",
                                function()
                                        Snacks.picker.lsp_references()
                                end,
                                nowait = true,
                                desc = "[g]o to references",
                        },
                        {
                                "gI",
                                function()
                                        Snacks.picker.lsp_implementations()
                                end,
                                desc = "[g]o to [I]mplementations",
                        },
                        {
                                "gy",
                                function()
                                        Snacks.picker.lsp_type_definitions()
                                end,
                                desc = "[g]o to t[y]pe definitions",
                        },
                        {
                                "gai",
                                function()
                                        Snacks.picker.lsp_incoming_calls()
                                end,
                                desc = "[g]o to c[a]lls [i]ncoming",
                        },
                        {
                                "gao",
                                function()
                                        Snacks.picker.lsp_outgoing_calls()
                                end,
                                desc = "[g]o to c[a]lls [o]utgoing",
                        },
                        {
                                "<leader>ss",
                                function()
                                        Snacks.picker.lsp_symbols()
                                end,
                                desc = "l[s]p [s]ymbols",
                        },
                        {
                                "<leader>sS",
                                function()
                                        Snacks.picker.lsp_workspace_symbols()
                                end,
                                desc = "l[s]p [S]ymbols (workspace)",
                        },
                },
        },
}
