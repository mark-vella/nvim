--- Hurl.nvim Lazy.nvim plugin specification with inline documentation.
---
--- @module HurlPluginSpec
--- @brief Plugin spec for jellydn/hurl.nvim
--- @field dependencies string[] List of plugin dependencies
--- @field ft string Filetype to trigger loading of this plugin
--- @field opts HurlSetupOpts Options passed to require('hurl').setup()
--- @field keys table[] Key mappings for Hurl commands
return {
  'jellydn/hurl.nvim',
  dependencies = {
    -- UI components for popup
    'MunifTanjim/nui.nvim',
    -- Async helper library
    'nvim-lua/plenary.nvim',
    -- Tree-sitter for .hurl syntax
    'nvim-treesitter/nvim-treesitter',
    -- Optional: markdown renderer
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = { file_types = { 'markdown' } },
      ft = { 'markdown' },
    },
  },
  -- Load when editing .hurl files
  ft = 'hurl',
  --------------------------------------------------------------------------
  --- Setup options for hurl.nvim
  ---
  --- @class HurlSetupOpts
  --- @field debug boolean            Show debugging info (default: false)
  --- @field show_notification boolean Show a notification on run (default: false)
  --- @field mode "split" | "popup"    Display mode for responses (default: "split")
  --- @field formatters table<string,string[]>
  ---                                Formatter commands per filetype
  --- @field mappings table<string,string>
  ---                                Key mappings within response view
  --- @field env_file string[]         Names of env files to search
  --- @field fixture_vars table[]      Custom dynamic variables
  --- @field fixture_vars[].name string
  ---                                Variable name
  --- @field fixture_vars[].callback fun():string
  ---                                Returns the variable value
  opts = {
    -- Show debugging info
    debug = false,
    -- Show notification on each request
    show_notification = true,
    -- "split" or "popup"
    mode = 'popup',
    -- External formatters by extension
    formatters = {
      -- JSON via jq (brew install jq)
      json = { 'jq' },
      -- HTML via prettier (npm install -g prettier)
      html = { 'prettier', '--parser', 'html' },
      -- XML via tidy-html5 (brew install tidy-html5)
      xml = { 'tidy', '-xml', '-i', '-q' },
    },
    -- Mappings in the response buffer
    mappings = {
      close = 'q', -- Close popup/split
      next_panel = '<C-n>', -- Next response panel
      prev_panel = '<C-p>', -- Previous response panel
    },
    -- Environment file names to look for
    env_file = { 'vars.env' },
    -- Custom fixture variables
    fixture_vars = {
      {
        name = 'random_int_number',
        callback = function()
          return tostring(math.random(1, 1000))
        end,
      },
      {
        name = 'random_float_number',
        callback = function()
          return string.format('%.2f', math.random() * 10)
        end,
      },
    },
  },
  --------------------------------------------------------------------------
  --- Key mappings for invoking Hurl commands
  ---
  --- Each entry: { lhs, rhs, mode?, desc }
  keys = {
    { '<leader>ha', '<cmd>HurlRunner<CR>', desc = 'Run all requests' },
    { '<leader>hh', '<cmd>HurlRunnerAt<CR>', desc = 'Run request under cursor' },
    { '<leader>hb', '<cmd>HurlRunnerToEntry<CR>', desc = 'Run up to entry' },
    { '<leader>hf', '<cmd>HurlRunnerToEnd<CR>', desc = 'Run from entry to end' },
    { '<leader>ht', '<cmd>HurlToggleMode<CR>', desc = 'Toggle split/popup mode' },
    { '<leader>hv', '<cmd>HurlVerbose<CR>', desc = 'Run in verbose mode' },
    { '<leader>hV', '<cmd>HurlVeryVerbose<CR>', desc = 'Run in very verbose mode' },
    { '<leader>hs', '<cmd>HurlRunner<CR>', mode = 'v', desc = 'Run selection' },
  },
}
