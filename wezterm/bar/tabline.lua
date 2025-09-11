local wezterm = require('wezterm')

local tabline = wezterm.plugin.require('https://github.com/michaelbrusegard/tabline.wez')
local themes = require('utils.theme')
local colors = themes.colors()

tabline.setup({
   options = {
      icons_enabled = true,
      theme = 'Catppuccin Mocha',
      -- theme = colors,
      tabs_enabled = true,
      theme_overrides = {},
      section_separators = {
         left = wezterm.nerdfonts.pl_left_hard_divider,
         right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      component_separators = {
         left = wezterm.nerdfonts.pl_left_soft_divider,
         right = wezterm.nerdfonts.pl_right_soft_divider,
      },
      tab_separators = {
         left = wezterm.nerdfonts.pl_left_hard_divider,
         right = wezterm.nerdfonts.pl_right_hard_divider,
      },
      fmt = string.lower,
   },
   sections = {
      tabline_a = { 'mode', icons_enable = true, icons_only = true },
      tabline_b = { 'workspace' },
      tabline_c = { ' ' },
      tab_active = {
         'index',
         { 'cwd', padding = { left = 0, right = 1 } },
         { 'zoomed', padding = 0 },
         'process',
         process_to_icon = {
            ['air'] = { wezterm.nerdfonts.md_language_go, color = { fg = colors.brights[5] } },
            ['bacon'] = { wezterm.nerdfonts.dev_rust, color = { fg = colors.ansi[2] } },
            ['bat'] = { wezterm.nerdfonts.md_bat, color = { fg = colors.ansi[5] } },
            ['btm'] = { wezterm.nerdfonts.md_chart_donut_variant, color = { fg = colors.ansi[2] } },
            ['btop'] = { wezterm.nerdfonts.md_chart_areaspline, color = { fg = colors.ansi[2] } },
            ['bun'] = { wezterm.nerdfonts.md_hamburger, color = { fg = colors.cursor_bg or nil } },
            ['cargo'] = { wezterm.nerdfonts.dev_rust, color = { fg = colors.ansi[2] } },
            ['cmd.exe'] = {
               wezterm.nerdfonts.md_console_line,
               color = { fg = colors.cursor_bg or nil },
            },
            ['curl'] = wezterm.nerdfonts.md_flattr,
            ['debug'] = { wezterm.nerdfonts.cod_debug, color = { fg = colors.ansi[5] } },
            ['default'] = wezterm.nerdfonts.md_application,
            ['docker'] = { wezterm.nerdfonts.md_docker, color = { fg = colors.ansi[5] } },
            ['docker-compose'] = { wezterm.nerdfonts.md_docker, color = { fg = colors.ansi[5] } },
            ['dpkg'] = { wezterm.nerdfonts.dev_debian, color = { fg = colors.ansi[2] } },
            ['fish'] = { wezterm.nerdfonts.md_fish, color = { fg = colors.cursor_bg or nil } },
            ['git'] = { wezterm.nerdfonts.dev_git, color = { fg = colors.brights[4] or nil } },
            ['go'] = { wezterm.nerdfonts.md_language_go, color = { fg = colors.brights[5] } },
            ['kubectl'] = { wezterm.nerdfonts.md_docker, color = { fg = colors.ansi[5] } },
            ['kuberlr'] = { wezterm.nerdfonts.md_docker, color = { fg = colors.ansi[5] } },
            ['lazygit'] = {
               wezterm.nerdfonts.cod_github,
               color = { fg = colors.brights[4] or nil },
            },
            ['lua'] = { wezterm.nerdfonts.seti_lua, color = { fg = colors.ansi[5] } },
            ['make'] = wezterm.nerdfonts.seti_makefile,
            ['nix'] = { wezterm.nerdfonts.linux_nixos, color = { fg = colors.ansi[5] } },
            ['node'] = { wezterm.nerdfonts.md_nodejs, color = { fg = colors.brights[2] } },
            ['npm'] = { wezterm.nerdfonts.md_npm, color = { fg = colors.brights[2] } },
            ['nvim'] = { wezterm.nerdfonts.custom_neovim, color = { fg = colors.ansi[3] } },
            -- and more...
         },
      },
      tab_inactive = { 'index', { 'process', padding = { left = 0, right = 1 } } },
      tabline_x = { 'ram', 'cpu' },
      tabline_y = { 'datetime' },
      tabline_z = {
         'domain',
         domain_to_icon = {
            default = wezterm.nerdfonts.md_monitor,
            ssh = wezterm.nerdfonts.md_ssh,
            wsl = wezterm.nerdfonts.md_microsoft_windows,
            docker = wezterm.nerdfonts.md_docker,
            unix = wezterm.nerdfonts.cod_terminal_linux,
         },
      },
   },
   extensions = {},
})

