return {
        {
                "nvim-treesitter/nvim-treesitter",
                lazy = false,
                branch = "main",
                build = ":TSUpdate",
                main = "nvim-treesitter.configs",
                config = function()
                        require("nvim-treesitter").setup({
                                -- Directory to install parsers and queries to
                                install_dir = vim.fn.stdpath("data") .. "/site",
                        })

                        require("nvim-treesitter").install({
                                "bash",
                                "cmake",
                                "csv",
                                "curl",
                                "diff",
                                "editorconfig",
                                "git_rebase",
                                "gitattributes",
                                "gitcommit",
                                "gitignore",
                                "html",
                                "hurl",
                                "javascript",
                                "jsonc",
                                "jsx",
                                "kotlin",
                                "lua",
                                "luadoc",
                                "markdown",
                                "markdown_inline",
                                "objc",
                                "query",
                                "solidity",
                                "sql",
                                "swift",
                                "tmux",
                                "todotxt",
                                "toml",
                                "tsx",
                                "typescript",
                                "vim",
                                "vimdoc",
                                "zsh",
                        })
                end,
        },
        {
                "nvim-treesitter/nvim-treesitter-context",
                dependencies = { "nvim-treesitter/nvim-treesitter" },
                config = function()
                        require("treesitter-context").setup({
                                -- Enable this plugin (Can be enabled/disabled later via commands)
                                enable = true,

                                -- Enable multiwindow support.
                                multiwindow = false,

                                -- How many lines the window should span. Values <= 0 mean no limit.
                                max_lines = 0,

                                -- Minimum editor window height to enable context. Values <= 0 mean no limit.
                                min_window_height = 0,

                                -- Show line numbers in context
                                line_numbers = true,

                                -- Maximum number of lines to show for a single context
                                multiline_threshold = 5,

                                -- Which context lines to discard if `max_lines` is exceeded. Choices: "inner", "outer"
                                trim_scope = "outer",

                                -- Line used to calculate context. Choices: "cursor", "topline"
                                -- Separator between context and content. Should be a single character string, like "-".
                                mode = "cursor",

                                -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
                                separator = nil,

                                -- The Z-index of the context window
                                zindex = 20,

                                -- (fun(buf: integer): boolean) return false to disable attaching
                                on_attach = nil,
                        })
                end,
        },
}
