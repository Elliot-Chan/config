local Config = require('config')
local wezterm = require('wezterm')
local color_scheme = require('colors.custom')

require('bar.tabline')

local config = Config:init()
   :append(require('config.appearance'))
   :append(require('config.bindings'))
   :append(require('config.domains'))
   :append(require('config.fonts'))
   :append(require('config.general'))
   :append(require('config.launch')).options
require('utils.background')

return config
