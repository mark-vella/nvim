return {
        "sindrets/diffview.nvim",
        version = "*",
        lazy = true,
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
                "nvim-lua/plenary.nvim",
        },
        opts = {
                diff_binaries = false,
                enhanced_diff_hl = false,
                git_cmd = { "git" },
                hg_cmd = { "hg" },
                use_icons = true,
                show_help_hints = true,
                watch_index = true,
                icons = {
                        folder_closed = "",
                        folder_open = "",
                },
                signs = {
                        fold_closed = "",
                        fold_open = "",
                        done = "✓",
                },
                view = {
                        -- Available layouts:
                        --    |'diff1_plain'
                        --    |'diff2_horizontal'
                        --    |'diff2_vertical'
                        --    |'diff3_horizontal'
                        --    |'diff3_vertical'
                        --    |'diff3_mixed'
                        --    |'diff4_mixed'
                        --
                        default = {
                                -- Config for changed files, and staged files in diff views.
                                layout = "diff2_horizontal",
                                disable_diagnostics = false,
                                winbar_info = false,
                        },
                        merge_tool = {
                                -- Config for conflicted files in diff views during a merge or rebase.
                                layout = "diff3_horizontal",
                                disable_diagnostics = true,
                                winbar_info = true,
                        },
                        file_history = {
                                -- Config for changed files in file history views.
                                layout = "diff2_horizontal",
                                disable_diagnostics = false,
                                winbar_info = false,
                        },
                },
                file_panel = {
                        -- One of 'list' or 'tree' (default: "tree")
                        listing_style = "tree",
                        -- Only applies when listing_style is 'tree' (default values)
                        tree_options = {
                                flatten_dirs = true,
                                folder_statuses = "only_folded",
                        },
                        win_config = {
                                position = "left",
                                width = 33,
                                win_opts = {},
                        },
                },
                file_history_panel = {
                        log_options = {
                                git = {
                                        single_file = {
                                                diff_merges = "combined",
                                        },
                                        multi_file = {
                                                diff_merges = "first-parent",
                                        },
                                },
                                hg = {
                                        single_file = {},
                                        multi_file = {},
                                },
                        },
                        win_config = {
                                position = "bottom",
                                height = 16,
                                win_opts = {},
                        },
                },
                commit_log_panel = {
                        win_config = {},
                },
                default_args = {
                        DiffviewOpen = {},
                        DiffviewFileHistory = {},
                },
                hooks = {},
                keymaps = {
                        -- Keymaps are not defined with actions here to avoid errors.
                        -- Custom keymaps can be added after setup if needed.
                        disable_defaults = false,
                },
        },
        config = function(_, opts)
                require("diffview").setup(opts)
        end,
}
