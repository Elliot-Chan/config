local wezterm = require('wezterm')
local colors = require('utils.theme').colors()

local background = {}

background.__index = background
function background:_create_opts()
   return {
      {
         source = { File = '/home/elliot/Pictures/background6.jpeg' },
         horizontal_align = 'Center',
         repeat_x = 'Mirror',
      },
      {
         source = { Color = colors.background },
         height = '100%',
         width = '100%',
         -- vertical_offset = '-10%',
         -- horizontal_offset = '-10%',
         opacity = 0.9,
      },
   }
end

function background:set(window)
   window:set_config_overrides({
      --      background = background:_create_opts(),
      color_scheme = 'Catppuccin Frappé (Gogh)',
   })
   return self
end

function background:init()
   local inital = {
      focus_color = colors.background,
      focus_on = false,
   }
   return setmetatable(inital, self)
end

return background:init()
