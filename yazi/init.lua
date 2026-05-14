local tokyo_night_theme = require("yatline-tokyo-night"):setup("moon") -- or moon/storm/day
local catppuccin_theme = require("yatline-catppuccin"):setup("mocha") -- or "latte" | "frappe" | "macchiato"

require("fg"):setup({
	default_action = "menu",
})

require("lastopen"):setup({
	-- cache_path = '/home/wrq/lastopencache',
})

require("mime-preview"):setup()

require("mime-ext"):setup({
	with_exts = require("mime-preview"):get_mime_data(),
	fallback_file1 = true,
})

require("easyjump"):setup({
	icon_fg = "#fda1a1",
	first_key_fg = "#df6249",
})

require("searchjump"):setup({
	unmatch_fg = "#b2a496",
	match_str_fg = "#000000",
	match_str_bg = "#73AC3A",
	first_match_str_fg = "#000000",
	first_match_str_bg = "#73AC3A",
	label_fg = "#EADFC8",
	label_bg = "#BA603D",
	only_current = false,
	show_search_in_statusbar = false,
	auto_exit_when_unmatch = false,
	enable_capital_label = true,
	mapdata = require("sjch").data,
	search_patterns = { "hell[dk]d", "%d+.1080p", "第%d+集", "第%d+话", "%.E%d+", "S%d+E%d+" },
})

require("header-hidden"):setup({
	color = "#88c2f4",
})

require("header-host"):setup({
	color = "#B5B520",
})

require("status-owner"):setup({
	color = "#d98a8a",
})

require("status-mtime"):setup({
	color = "#ba884a",
})

require("keyjump"):setup({
	icon_fg = "#fda1a1",
	first_key_fg = "#df6249",
	go_table = {
		{ on = { "y" }, run = "cd ~/.config/yazi/", desc = "Go to video" },
	},
})

require("git"):setup()

require("current-size"):setup({
	equal_ignore = { "~", "/", "/home" },
	-- sub_ignore = {"~/deskenv/master","~/deskenv/dev"} -- sub path match
})

require("autofilter"):setup({
	-- cache_path = '/home/wrq/autofiltercache',
})

require("autosort"):setup({})

require("full-border"):setup()

require("yatline"):setup({
	theme = catppuccin_theme,
	padding = { inner = 1, outer = 1 },
	tab_width = 20,

	show_background = true,

	display_header_line = true,
	display_status_line = true,

	component_positions = { "header", "tab", "status" },

	header_line = {
		left = {
			section_a = {
				{ type = "line", name = "tabs" },
			},
			section_b = {},
			section_c = {},
		},
		right = {
			section_a = {
				{ type = "string", name = "date", params = { "%A, %d %B %Y" } },
			},
			section_b = {
				{ type = "string", name = "date", params = { "%X" } },
			},
			section_c = {
				{ type = "string", name = "git_branch" },
				{ type = "coloreds", custom = false, name = "githead" },
			},
		},
	},

	status_line = {
		left = {
			section_a = {
				{ type = "string", name = "tab_mode" },
			},
			section_b = {
				{ type = "string", name = "hovered_size" },
			},
			section_c = {
				{ type = "string", name = "hovered_path" },
				{ type = "coloreds", name = "count" },
			},
		},
		right = {
			section_a = {
				{ type = "string", name = "cursor_position" },
			},
			section_b = {
				{ type = "string", name = "cursor_percentage" },
			},
			section_c = {
				{ type = "string", name = "hovered_file_extension", params = { true } },
				{ type = "coloreds", name = "permissions" },
			},
		},
	},
})

require("yatline-githead"):setup({
	theme = catppuccin_theme,

	order = {
		"branch",
		"remote",
		"tag",
		"commit",
		"behind_ahead_remote",
		"stashes",
		"state",
		"staged",
		"unstaged",
		"untracked",
	},

	show_numbers = true, -- shows staged, unstaged, untracked, stashes count

	show_branch = true,
	branch_prefix = "",
	branch_symbol = "",
	branch_borders = "",

	show_remote_branch = true, -- only shown if different from local branch
	always_show_remote_branch = false, -- always show remote branch even if it the same as local branch
	always_show_remote_repo = false, -- Adds `origin/` if `always_show_remote_branch` is enabled
	remote_branch_prefix = ":",

	show_tag = true, -- only shown if branch is not available
	always_show_tag = false,
	tag_symbol = "#",

	show_commit = true, -- only shown if branch AND tag are not available
	always_show_commit = false,
	commit_symbol = "@",

	show_behind_ahead_remote = true,
	behind_remote_symbol = "⇣",
	ahead_remote_symbol = "⇡",

	show_stashes = true,
	stashes_symbol = "$",

	show_state = true,
	show_state_prefix = true,
	state_symbol = "~",

	show_staged = true,
	staged_symbol = "+",

	show_unstaged = true,
	unstaged_symbol = "!",

	show_untracked = true,
	untracked_symbol = "?",
})
