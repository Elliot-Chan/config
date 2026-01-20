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

local function compute_title(tab, isWindow)
   if isWindow then
      local cwd = tab.active_pane.current_working_dir
      return cwd.filename
   end
   local title = tab.tab_title
   if title == nil or title == '' then
      title = tab.active_pane.title
   end

   -- 约定：手动起名用 @ 开头，窗口/tab 显示时去掉 @
   if title:sub(1, 1) == '@' then
      return title:sub(2)
   end

   local cwd = tab.active_pane.current_working_dir
   local process_name = tab.active_pane.foreground_process_name
   if process_name:find('nvim') or process_name:find('vim') then
      if process_name:find('nvim') then
         title = title:gsub('%s*%-*%s*nvim$', '')
      elseif process_name:find('vim') then
         title = title:gsub('%s*%-*%s*vim$', '')
      end
      if cwd and cwd.file_path then
         local filename = title:match('([^/\\]+)$') or title
         return '  ' .. filename
      end
   end

   -- 否则用当前工作目录
   if cwd and cwd.file_path then
      local name = cwd.file_path:gsub('.*/', '')
      return '  ' .. name
      -- return cwd.file_path
   end

   -- fallback
   return title
end

-- tab 标题：用格式化 API，返回 fragments
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
   local title = compute_title(tab)
   return {
      { Text = ' ' .. title .. ' ' },
   }
end)

-- window 标题：这里需要返回字符串
wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
   local title = tab.tab_title
   if title == nil or title == '' then
      title = tab.active_pane.title
   end
   wezterm.log_error(title)
   if title:sub(1, 1) == '@' then
      return title:sub(2)
   end
   if string.match(title, 'nvim') then
      return title
   else
      local cwd = tab.active_pane.current_working_dir
      if cwd then
         return wezterm.format({
            { Text = 'WEZTERM_DIR' .. cwd.file_path }, -- 完整路径
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

Config.use_ime = true
Config.xim_im_name = 'fcitx'

return Config
