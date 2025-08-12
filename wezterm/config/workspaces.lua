local wezterm = require('wezterm')
local mux = wezterm.mux

local config = {}

-- 1. 开启一个本地 unix mux 域
config.unix_domains = {
   {
      name = 'unix',
   },
}

-- 2. GUI 启动时默认就等价于：wezterm connect unix
config.default_gui_startup_args = { 'connect', 'unix' }

-- 3. Leader 键（类似 tmux 前缀）
config.leader = { key = 'a', mods = 'CTRL' }

local act = wezterm.action

config.keys = {
   -- Attach 到 mux：<C-a> a
   {
      key = 'a',
      mods = 'LEADER',
      action = act.AttachDomain('unix'),
   },
   -- 从 mux detach：<C-a> d
   {
      key = 'd',
      mods = 'LEADER',
      action = act.DetachDomain({ DomainName = 'unix' }),
   },
   -- workspace 启动器：<C-a> s
   {
      key = 's',
      mods = 'LEADER',
      action = act.ShowLauncherArgs({ flags = 'WORKSPACES' }),
   },
}

-- ...上面的 config 省略...

-- 简单的“声明式布局”描述
local WORKSPACES = {
   cangjie = {
      -- 每个 item 是一个 window/tab（先 window，再在里面 split 也行）
      {
         cwd = '/home/elliot/Code/working/cangjie_runtime/stdlib',
         title = 'runtime',
         args = { 'zsh' },
      },
      {
         cwd = '/home/elliot/Code/working/cangjie_stdx',
         title = 'stdx',
         args = { 'zsh' },
      },
   },
}

local function ensure_workspace(name)
   local windows = mux.all_windows()
   for _, win in ipairs(windows) do
      if win:get_workspace() == name then
         -- 已经有这个 workspace，就认为是“已恢复”
         mux.set_active_workspace(name)
         return
      end
   end

   local spec = WORKSPACES[name]
   if not spec then
      wezterm.log_error('no workspace spec for ' .. name)
      return
   end

   -- 没有就创建
   local first_window
   for i, entry in ipairs(spec) do
      local w, p, t
      if i == 1 then
         w, p, t = mux.spawn_window({
            workspace = name,
            cwd = entry.cwd,
            args = entry.args,
         })
         first_window = w
      else
         w, p, t = mux.spawn_window({
            workspace = name,
            cwd = entry.cwd,
            args = entry.args,
         })
      end
      if entry.title then
         t:set_title(entry.title)
      end
   end

   mux.set_active_workspace(name)
end

-- GUI 启动时自动载入一个默认 workspace（比如 cangjie）
-- wezterm.on('gui-startup', function(cmd)
-- ensure_workspace('cangjie')
-- end)

-- 绑定一个快捷键：<C-a> w 弹出 workspace 选择，并按需创建
table.insert(config.keys, {
   key = 'w',
   mods = 'LEADER',
   action = wezterm.action_callback(function(win, pane)
      win:perform_action(
         act.PromptInputLine({
            description = 'Switch/Create workspace:',
            action = wezterm.action_callback(function(inner_win, inner_pane, line)
               if not line or line == '' then
                  return
               end
               ensure_workspace(line)
            end),
         }),
         pane
      )
   end),
})

return config
