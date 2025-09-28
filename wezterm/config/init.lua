local wezterm = require('wezterm')

---@class Config
---@field options table
local Config = {}
Config.__index = Config

---Initialize Config
---@return Config
function Config:init()
   local config = setmetatable({ options = {} }, self)
   return config
end


wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
  local title = tab.active_pane.title
  if string.match(title, "nvim") then
    return title
  else
    local cwd = tab.active_pane.current_working_dir
    if cwd then
      return wezterm.format({
        { Text = "WEZTERM_DIR" .. cwd.file_path }, -- 完整路径
      })
    end
  end
end)

---Append to `Config.options`
---@param new_options table new options to append
---@return Config
function Config:append(new_options)
   for k, v in pairs(new_options) do
      if self.options[k] ~= nil then
         wezterm.log_warn(
            'Duplicate config option detected: ',
            { old = self.options[k], new = new_options[k] }
         )
         goto continue
      end
      self.options[k] = v
      ::continue::
   end
   return self
end

return Config
