return {
  'sindrets/diffview.nvim',
  version = '*', -- Use the latest release instead of the latest commit
  lazy = true, -- Load lazily to improve startup time
  event = { 'BufReadPost', 'BufNewFile' }, -- Load on buffer read or new file to catch git-related actions
  dependencies = {
    'nvim-lua/plenary.nvim', -- Required dependency for diffview.nvim
  },
  opts = {
    diff_binaries = false, -- Show diffs for binaries (default: false)
    enhanced_diff_hl = false, -- See |diffview-config-enhanced_diff_hl| (default: false)
    git_cmd = { 'git' }, -- The git executable followed by default args (default: { "git" })
    hg_cmd = { 'hg' }, -- The hg executable followed by default args (default: { "hg" })
    use_icons = true, -- Requires nvim-web-devicons (default: true)
    show_help_hints = true, -- Show hints for how to open the help panel (default: true)
    watch_index = true, -- Update views and index buffers when the git index changes (default: true)
    icons = { -- Only applies when use_icons is true (default values)
      folder_closed = '',
      folder_open = '',
    },
    signs = { -- Default symbols for UI elements
      fold_closed = '',
      fold_open = '',
      done = '✓',
    },
    view = {
      -- Configure the layout and behavior of different types of views.
      -- Available layouts:
      --  'diff1_plain'
      --    |'diff2_horizontal'
      --    |'diff2_vertical'
      --    |'diff3_horizontal'
      --    |'diff3_vertical'
      --    |'diff3_mixed'
      --    |'diff4_mixed'
      -- For more info, see |diffview-config-view.x.layout|.
      default = {
        -- Config for changed files, and staged files in diff views.
        layout = 'diff2_horizontal', -- Default layout for standard diff views (default: "diff2_horizontal")
        disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view (default: false)
        winbar_info = false, -- See |diffview-config-view.x.winbar_info| (default: false)
      },
      merge_tool = {
        -- Config for conflicted files in diff views during a merge or rebase.
        layout = 'diff3_horizontal', -- Set to diff3_horizontal as requested (default in docs: "diff3_horizontal")
        disable_diagnostics = true, -- Temporarily disable diagnostics for diff buffers while in the view (default: true)
        winbar_info = true, -- See |diffview-config-view.x.winbar_info| (default: true)
      },
      file_history = {
        -- Config for changed files in file history views.
        layout = 'diff2_horizontal', -- Default layout for file history views (default: "diff2_horizontal")
        disable_diagnostics = false, -- Temporarily disable diagnostics for diff buffers while in the view (default: false)
        winbar_info = false, -- See |diffview-config-view.x.winbar_info| (default: false)
      },
    },
    file_panel = {
      listing_style = 'tree', -- One of 'list' or 'tree' (default: "tree")
      tree_options = { -- Only applies when listing_style is 'tree' (default values)
        flatten_dirs = true, -- Flatten dirs that only contain one single dir (default: true)
        folder_statuses = 'only_folded', -- One of 'never', 'only_folded' or 'always' (default: "only_folded")
      },
      win_config = { -- See |diffview-config-win_config| (default values)
        position = 'left',
        width = 35,
        win_opts = {},
      },
    },
    file_history_panel = {
      log_options = { -- See |diffview-config-log_options| (default values)
        git = {
          single_file = {
            diff_merges = 'combined', -- Default merge diff handling for single file (default: "combined")
          },
          multi_file = {
            diff_merges = 'first-parent', -- Default merge diff handling for multiple files (default: "first-parent")
          },
        },
        hg = {
          single_file = {},
          multi_file = {},
        },
      },
      win_config = { -- See |diffview-config-win_config| (default values)
        position = 'bottom',
        height = 16,
        win_opts = {},
      },
    },
    commit_log_panel = {
      win_config = {}, -- See |diffview-config-win_config| (default: {})
    },
    default_args = { -- Default args prepended to the arg-list for the listed commands (default: {})
      DiffviewOpen = {},
      DiffviewFileHistory = {},
    },
    hooks = {}, -- See |diffview-config-hooks| (default: {})
    keymaps = {
      disable_defaults = false, -- Disable the default keymaps (default: false)
      -- Keymaps are not defined with actions here to avoid errors.
      -- Custom keymaps can be added after setup if needed.
    },
  },
  config = function(_, opts)
    -- Setup diffview with the provided options
    require('diffview').setup(opts)
    -- If custom keymaps are needed, they can be defined here after requiring actions
    -- local actions = require('diffview.actions')
    -- Example: vim.keymap.set('n', '<leader>co', actions.conflict_choose('ours'), { desc = 'Choose OURS' })
  end,
}
