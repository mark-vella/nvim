--[[
rest.nvim Configuration & Reference
===================================

A fast, powerful and extensible HTTP client for Neovim, written in pure Lua.
• Async HTTP via a pure-Lua curl wrapper (or HTTPie, see below)
• Tree-sitter parsing & syntax highlighting for .http files
• Named requests, environment/dynamic variables, Lua/JS scripting
• Automatic cookie handling & persistent storage
• Pre/post request hooks, SSL skip, header management
• Winbar & lualine integration, Telescope extension
• Response formatting via gq, logs & statistics in result pane

Requirements
------------
• Neovim ≥ 0.10.1
• curl or HTTPie
• nvim-treesitter + tree-sitter-http

Installation (lazy.nvim)
------------------------
{
  "rest-nvim/rest.nvim",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "http")
    end,
  },
  config = function()
    -- see config below
  end,
}

HTTPie Integration
------------------
To use HTTPie instead of curl, we declare an `httpie` client here.
Then in your .http files add `# @client=httpie` at the top of a request block.

Example:
  # @client=httpie
  POST http://localhost:8080/api/mcs/create
  Authorization: Bearer {{token}}
  Content-Type: application/json

  { "foo": "bar" }

]]

return {
  'rest-nvim/rest.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, 'http')
    end,
  },
  config = function()
    vim.g.rest_nvim = {
      custom_dynamic_variables = {},
      request = {
        skip_ssl_verification = false,
        hooks = {
          encode_url = true,
          user_agent = 'rest.nvim v' .. require('rest-nvim.api').VERSION,
          set_content_type = true,
        },
      },
      response = {
        hooks = {
          decode_url = true,
          format = true,
        },
      },
      clients = {
        curl = {
          statistics = {
            { id = 'time_total', winbar = 'take', title = 'Time taken' },
            { id = 'size_download', winbar = 'size', title = 'Download size' },
          },
          opts = {
            set_compressed = false,
            certificates = {},
          },
        },
        httpie = {
          cmd = { 'http' },
          args = {
            '--pretty=all',
            '--print=HhBb', -- headers and body for both request and response
            '--follow',
            '--timeout=30',
          },
          statistics = {},
          opts = {},
        },
      },
      cookies = {
        enable = true,
        path = vim.fs.joinpath(vim.fn.stdpath 'data', 'rest-nvim.cookies'),
      },
      env = {
        enable = true,
        pattern = '.*%.env.*',
        find = function()
          local cfg = require 'rest-nvim.config'
          return vim.fs.find(function(name)
            return name:match(cfg.env.pattern)
          end, {
            path = vim.fn.getcwd(),
            type = 'file',
            limit = math.huge,
          })
        end,
      },
      ui = {
        winbar = true,
        keybinds = { prev = 'H', next = 'L' },
      },
      highlight = {
        enable = true,
        timeout = 750,
      },
      _log_level = vim.log.levels.WARN,
    }
  end,
}
