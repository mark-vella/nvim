vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = "a"
vim.o.showmode = true

-- Temporarily disabled system and nvim clipboard sync
-- vim.schedule(function()
--         vim.o.clipboard = "unnamedplus"
-- end)

-- Enable break indent
vim.o.breakindent = true

-- Turn off word wrap
vim.o.wrap = false

-- Save undo history
vim.o.undofile = true

-- Case-insensitve searching unless \C, or includes one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on
vim.o.signcolumn = "yes"

-- Decrease update time (more often)
vim.o.updatetime = 250

-- Decrease mapped sequence wait time (faster)
vim.o.timeoutlen = 300

-- New split configuration, right and below by default
vim.o.splitright = true
vim.o.splitbelow = true

-- Sets how nvim will display different type of whitespace chars in the buffer
vim.o.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview %s live as you type
vim.o.inccommand = "split"

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above/below
vim.o.scrolloff = 10

-- When performing op that could fail due unsaved changes in buffer, raise dialog to confirm
vim.o.confirm = true

-- Enables 24-bit RGB color in the TUI
vim.opt.termguicolors = true

-- See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
