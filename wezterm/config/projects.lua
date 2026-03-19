local wezterm = require("wezterm")

local json_path = wezterm.config_dir .. "/config/projects.json"
local fallback = {
   { id = "config", label = "config", cwd = "/home/elliot/config" },
   { id = "cangjie-runtime", label = "cangjie runtime", cwd = "/home/elliot/Code/working/cangjie_runtime/stdlib" },
   { id = "cangjie-stdx", label = "cangjie stdx", cwd = "/home/elliot/Code/working/cangjie_stdx" },
}

local ok, content = pcall(wezterm.read_file, json_path)
if not ok then
   return fallback
end

local parsed_ok, projects = pcall(wezterm.json_parse, content)
if not parsed_ok or type(projects) ~= "table" then
   wezterm.log_error("failed to parse projects.json, using fallback list")
   return fallback
end

return projects
