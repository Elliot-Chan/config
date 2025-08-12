local wezterm = require('wezterm')
local platform = require('utils.platform')

-- local font = 'Maple Mono SC NF'
local font_size = platform.is_mac and 15 or 14

return {
   font = wezterm.font_with_fallback({
      'Maple Mono Normal NL CN',
      'FiraCode Nerd Font',
      'IosevkaTerm Nerd Font Mono',
      'JetBrainsMono Nerd Font', -- 你常用的主字体
      'Font Awesome 7 Free Solid', -- 解决 U+F596 ()
      'Font Awesome 7 Free Regular',
      'Noto Color Emoji', -- emoji
      'Noto Music', -- 🎜 那类特殊符号
      'AR PL UMing HK',
      'Symbola', -- 兜底 fallback
   }),
   font_size = font_size,

   --ref: https://wezfurlong.org/wezterm/config/lua/config/freetype_pcf_long_family_names.html#why-doesnt-wezterm-use-the-distro-freetype-or-match-its-configuration
   freetype_load_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
   freetype_render_target = 'Normal', ---@type 'Normal'|'Light'|'Mono'|'HorizontalLcd'
}
