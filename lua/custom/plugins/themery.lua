return {
  'zaldih/themery.nvim',
  config = function()
    require('themery').setup {
      themes = {
        -- Dark Colorschemes
        'darcula-solid',
        {
          name = 'vscode-dark',
          colorscheme = 'vscode',
          before = [[ vim.opt.background = "dark" ]],
        },
        'kanagawa-wave',
        'kanagawa-dragon',
        'catppuccin-frappe',
        'catppuccin-macchiato',
        'catppuccin-mocha',
        'rose-pine-main',
        'rose-pine-moon',
        'github_dark_default',
        'github_dark_high_contrast',
        {
          name = 'melange-dark',
          colorscheme = 'melange',
          before = [[ vim.opt.background = "dark" ]],
        },
        {
          name = 'gruvbox-dark',
          colorscheme = 'gruvbox',
          before = [[ vim.opt.background = "dark" ]],
        },
        {
          name = 'miasma',
          colorscheme = 'miasma',
        },
        {
          name = 'adwaita-dark',
          colorscheme = 'adwaita',
          before = [[
          vim.opt.background = "dark"
          vim.g.adwaita_darker = false 
          ]],
        },
        {
          name = 'adwaita-darker',
          colorscheme = 'adwaita',
          before = [[
          vim.opt.background = "dark"
          vim.g.adwaita_darker = true
          ]],
        },
        {
          name = 'modus-dark',
          colorscheme = 'modus',
          before = [[ vim.opt.background = "dark" ]],
        },
        -- Light Colorschemes
        'kanagawa-lotus',
        'catppuccin-latte',
        'rose-pine-dawn',
        'github_light_default',
        'github_light_high_contrast',
        {
          name = 'vscode-light',
          colorscheme = 'vscode',
          before = [[ vim.opt.background = "light" ]],
        },
        {
          name = 'melange-light',
          colorscheme = 'melange',
          before = [[ vim.opt.background = "light" ]],
        },
        {
          name = 'gruvbox-light',
          colorscheme = 'gruvbox',
          before = [[ vim.opt.background = "light" ]],
        },
        {
          name = 'adwaita-light',
          colorscheme = 'adwaita',
          before = [[ vim.opt.background = "light" ]],
        },
        {
          name = 'modus-light',
          colorscheme = 'modus',
          before = [[ vim.opt.background = "light" ]],
        },
      },
    }
  end,
}
