-- Catch-all that follows the current Omarchy theme, see lua/mrk/plugins/themes.lua. Deferred
-- because Neovim ignores :colorscheme from inside a colorscheme script.
vim.schedule(MrkTheme.apply_omarchy)
