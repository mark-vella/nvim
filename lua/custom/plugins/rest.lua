--[[
rest.nvim Configuration & Reference
===================================

A fast, powerful and extensible HTTP client for Neovim, written in pure Lua.
• Async HTTP via a pure-Lua curl wrapper
• Tree-sitter parsing & syntax highlighting for .http files
• Named requests, environment/dynamic variables, Lua/JS scripting
• Automatic cookie handling & persistent storage
• Pre/post request hooks, SSL skip, header management
• Winbar & lualine integration, Telescope extension
• Response formatting via gq, logs & statistics in result pane

Requirements
------------
• Neovim ≥ 0.10.1
• curl
• nvim-treesitter + tree-sitter-http

Installation (lazy.nvim)
------------------------
In your lazy.nvim plugin list:
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

HTTP File Syntax (IntelliJ spec)
--------------------------------
Example .http file:
  ### GetUsers
  GET https://api.example.com/users HTTP/1.1
  Authorization: Bearer {{token}}

  { "name": "foo" }

Basic Usage
-----------
:Rest run         → Run current request under cursor
:Rest run <name>  → Run named request block
:Rest last        → Re-run last request
:Rest open        → Toggle result pane
:Rest logs        → Edit logs file
:Rest cookies     → Edit cookies file
:Rest env show    → Show registered .env
:Rest env select  → Pick .env via vim.ui.select()
:Rest env set <p> → Register specific .env

Result Window Key Mappings
--------------------------
H → Cycle to previous result pane
L → Cycle to next result pane

Lua Scripting in .http
----------------------
Use a Lua block to manipulate response:
  # @lang=lua
  > {%
  local data = vim.json.decode(response.body)
  data.modified = true
  response.body = vim.json.encode(data)
  %}

Extensions
----------
• Telescope:  
    require("telescope").load_extension("rest")  
    :Telescope rest select_env

• Lualine: add "rest" to sections.lualine_x to show active .env in HTTP files

Configuration Options
---------------------
Set options via vim.g.rest_nvim:

  custom_dynamic_variables = {}        -- functions to inject {{vars}}
  request = {
    skip_ssl_verification = false,     -- skip SSL cert check
    hooks = {
      encode_url       = true,         -- URL-encode before request
      user_agent       = "rest.nvim v" .. require("rest-nvim.api").VERSION,
      set_content_type = true,         -- auto-set Content-Type if body exists
    },
  },
  response = {
    hooks = { decode_url = true, format = true },
  },
  clients = {
    curl = {
      statistics = {
        { id = "time_total",    winbar = "take", title = "Time taken" },
        { id = "size_download", winbar = "size", title = "Download size" },
      },
      opts = {
        set_compressed = false,         -- add --compressed for gzip
        certificates   = {},            -- domain → certfile map
      },
    },
  },
  cookies = {
    enable = true,                     -- enable persistent cookies
    path   = vim.fs.joinpath(vim.fn.stdpath("data"), "rest-nvim.cookies"),
  },
  env = {
    enable  = true,                    -- .env support
    pattern = ".*%.env.*",             -- lua-pattern for env files
    find    = function()
      local cfg = require("rest-nvim.config")
      return vim.fs.find(function(name)
        return name:match(cfg.env.pattern)
      end, { path = vim.fn.getcwd(), type = "file", limit = math.huge })
    end,
  },
  ui = {
    winbar  = true,                    -- show winbar in result panes
    keybinds = { prev = "H", next = "L" },
  },
  highlight = {
    enable  = true,                    -- highlight request on run
    timeout = 750,                     -- ms
  },
  _log_level = vim.log.levels.WARN,   -- TRACE/DEBUG/INFO/WARN/ERROR

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
        hooks = { decode_url = true, format = true },
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
          end, { path = vim.fn.getcwd(), type = 'file', limit = math.huge })
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
