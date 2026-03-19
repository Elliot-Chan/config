#!/usr/bin/env python3

import copy
import json
from pathlib import Path


OUTPUT = Path(__file__).with_name("config.jsonc")
ACTION_SCRIPT = "~/.config/waybar/scripts/module_action.sh"


def clone(value):
    return copy.deepcopy(value)


def base_bar(output, modules_left, modules_center, modules_right, extra=None):
    bar = {
        "height": 30,
        "spacing": 4,
        "output": output,
        "modules-left": modules_left,
        "modules-center": modules_center,
        "modules-right": modules_right,
    }
    if extra:
        bar.update(extra)
    return bar


WINDOW = {
    "format": "{title}",
    "icon": False,
    "rewrite": {
        "(.*) - Visual Studio Code": "  $1",
        "(.*) - Google Chrome": "  $1",
        "(.*) - nvim": "  $1",
        "WEZTERM_DIR(.*)": "📂 $1",
    },
}

SCRATCHPAD = {
    "format": "{icon}   {count}",
    "show-empty": False,
    "format-icons": ["", ""],
    "tooltip": True,
    "tooltip-format": "{app}: {title}",
}

MODE = {
    "format": "<span style=\"italic\">{}</span>",
}

TRAY = {
    "spacing": 10,
}

CLOCK = {
    "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>",
    "format-alt": "{:%Y-%m-%d}",
}

WEATHER = {
    "interval": 3600,
    "format": "{} ",
    "format-alt": "{}",
    "exec": "zsh -lc '[[ -f ~/.custom.zsh ]] && source ~/.custom.zsh; python3 ~/.config/waybar/scripts/weather.py'",
    "signal": 8,
    "on-click": f"{ACTION_SCRIPT} weather-refresh",
    "on-click-middle": f"{ACTION_SCRIPT} weather-toggle-mode",
    "on-click-right": f"{ACTION_SCRIPT} weather-copy",
    "max-length": 100,
    "tooltip": True,
    "return-type": "json",
}

CPU_WITH_STATES = {
    "format": "  {usage}%",
    "tooltip": False,
    "on-click": "~/.config/waybar/scripts/open_terminal_tool.sh btop",
    "states": {
        "warning": 50,
        "critical": 80,
    },
}

CPU_SIMPLE = {
    "format": "  {usage}%",
    "tooltip": False,
    "on-click": "~/.config/waybar/scripts/open_terminal_tool.sh btop",
}

MEMORY = {
    "format": "  {}% ",
    "on-click": "~/.config/waybar/scripts/open_terminal_tool.sh btop",
    "states": {
        "info": 20,
        "warning": 50,
        "critical": 80,
    },
}

MPD = {
    "format": "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ",
    "format-disconnected": "Disconnected ",
    "format-stopped": "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ",
    "unknown-tag": "N/A",
    "interval": 5,
    "consume-icons": {
        "on": " ",
    },
    "random-icons": {
        "off": "<span color=\"#f53c3c\"></span> ",
        "on": " ",
    },
    "repeat-icons": {
        "on": " ",
    },
    "single-icons": {
        "on": "1 ",
    },
    "state-icons": {
        "paused": "",
        "playing": "",
    },
    "tooltip-format": "MPD (connected)",
    "tooltip-format-disconnected": "MPD (disconnected)",
}

UPDATES = {
    "format": "{} {icon} ",
    "return-type": "json",
    "format-icons": {
        "has-updates": "󱍷",
        "updated": "󰂪",
    },
    "exec-if": "which waybar-module-pacman-updates",
    "exec": "waybar-module-pacman-updates --interval-seconds 5 --network-interval-seconds 300",
}

NETWORK_SPEED = {
    "tooltip": True,
    "exec": "~/.config/waybar/scripts/network_speed.sh",
    "interval": 1,
    "signal": 9,
    "format": "{}",
    "format-alt": "{}",
    "on-click": f"{ACTION_SCRIPT} network-copy-ip",
    "on-click-middle": f"{ACTION_SCRIPT} network-toggle-mode",
    "on-click-right": f"{ACTION_SCRIPT} network-copy-iface",
    "return-type": "json",
}

GCCLIP = {
    "format": "󰅌",
    "tooltip": False,
    "on-click": "bash -lc '$HOME/.config/waybar/scripts/gcclip_waybar.sh copy'",
    "on-click-middle": "bash -lc '$HOME/.config/waybar/scripts/gcclip_waybar.sh copy-image'",
    "on-click-right": "bash -lc '$HOME/.config/waybar/scripts/gcclip_waybar.sh paste'",
}

MEDIA = {
    "format": "{icon} {text}",
    "return-type": "json",
    "max-length": 40,
    "format-icons": {
        "spotify": "",
        "default": "🎜",
    },
    "escape": True,
    "exec": "$HOME/.config/waybar/mediaplayer.py 2> /dev/null",
}

POWER = {
    "format": "",
    "tooltip": False,
    "on-click": "wlogout -C ~/.config/wlogout/style.css -l  ~/.config/wlogout/layout.json  -b 6 --protocol layer-shell",
    "on-click-right": "~/.config/waybar/scripts/open_terminal_tool.sh btop",
}

NOTIFICATION = {
    "tooltip": False,
    "format": "{icon}",
    "format-icons": {
        "notification": "<span foreground='red'><sup></sup></span>",
        "none": "",
        "dnd-notification": "<span foreground='red'><sup></sup></span>",
        "dnd-none": "",
        "inhibited-notification": "<span foreground='red'><sup></sup></span>",
        "inhibited-none": "",
        "dnd-inhibited-notification": "<span foreground='red'><sup></sup></span>",
        "dnd-inhibited-none": "",
    },
    "return-type": "json",
    "exec-if": "which swaync-client",
    "exec": "swaync-client -swb",
    "on-click": "swaync-client -t -sw",
    "on-click-middle": "swaync-client -C",
    "on-click-right": "swaync-client -d -sw",
    "escape": True,
}

CUSTOM_CLOCK = {
    "exec": "date +%c",
    "interval": 1,
    "format": "{}",
    "format-alt": "{}",
}

WORKSPACES_PRIMARY = {
    "disable-scroll": True,
    "all-outputs": False,
    "warp-on-scroll": False,
    "format": "{icon}",
}

WORKSPACES_SHARED = {
    "disable-scroll": True,
    "all-outputs": True,
    "warp-on-scroll": False,
    "format": "{name}: {icon}",
    "format-icons": {
        "urgent": "",
        "focused": "",
        "default": "",
    },
}


def primary_bar():
    bar = base_bar(
        output="HDMI-A-2",
        modules_left=[
            "sway/workspaces",
            "sway/mode",
            "sway/scratchpad",
            "custom/media",
        ],
        modules_center=["sway/window"],
        modules_right=[
            "mpd",
            "custom/weather",
            "custom/network_speed",
            "custom/gcclip",
            "cpu",
            "memory",
            "custom/notification",
            "clock",
            "tray",
            "custom/updates",
            "custom/power",
        ],
    )
    bar.update(
        {
            "sway/window": clone(WINDOW),
            "sway/workspaces": clone(WORKSPACES_PRIMARY),
            "sway/mode": clone(MODE),
            "sway/scratchpad": clone(SCRATCHPAD),
            "mpd": clone(MPD),
            "tray": clone(TRAY),
            "clock": clone(CLOCK),
            "custom/updates": clone(UPDATES),
            "custom/weather": clone(WEATHER),
            "cpu": clone(CPU_WITH_STATES),
            "memory": clone(MEMORY),
            "custom/network_speed": clone(NETWORK_SPEED),
            "custom/gcclip": clone(GCCLIP),
            "custom/media": clone(MEDIA),
            "custom/power": clone(POWER),
            "custom/notification": clone(NOTIFICATION),
        }
    )
    return bar


def bottom_bar():
    bar = base_bar(
        output="HDMI-A-3",
        modules_left=[
            "sway/workspaces",
            "sway/scratchpad",
        ],
        modules_center=["sway/window"],
        modules_right=[
            "custom/weather",
            "cpu",
            "custom/gcclip",
            "custom/notification",
            "custom/clock",
        ],
        extra={"position": "bottom"},
    )
    bar.update(
        {
            "sway/window": clone(WINDOW),
            "sway/workspaces": clone(WORKSPACES_SHARED),
            "sway/mode": clone(MODE),
            "sway/scratchpad": clone(SCRATCHPAD),
            "custom/clock": clone(CUSTOM_CLOCK),
            "custom/weather": clone(WEATHER),
            "cpu": clone(CPU_SIMPLE),
            "custom/gcclip": clone(GCCLIP),
            "custom/notification": clone(NOTIFICATION),
        }
    )
    return bar


def headless_bar():
    bar = base_bar(
        output="HEADLESS-1",
        modules_left=[
            "sway/workspaces",
            "sway/mode",
            "sway/scratchpad",
            "custom/media",
        ],
        modules_center=["sway/window"],
        modules_right=[
            "custom/network_speed",
            "custom/gcclip",
            "cpu",
            "memory",
            "clock",
            "tray",
        ],
    )
    bar.update(
        {
            "sway/window": clone(WINDOW),
            "sway/workspaces": clone(WORKSPACES_SHARED),
            "sway/mode": clone(MODE),
            "sway/scratchpad": clone(SCRATCHPAD),
            "tray": clone(TRAY),
            "clock": clone(CLOCK),
            "cpu": clone(CPU_WITH_STATES),
            "memory": clone(MEMORY),
            "custom/network_speed": clone(NETWORK_SPEED),
            "custom/gcclip": clone(GCCLIP),
            "custom/media": clone(MEDIA),
        }
    )
    return bar


def render():
    bars = [
        primary_bar(),
        bottom_bar(),
        headless_bar(),
    ]
    return "// Generated by waybar/generate_config.py\n" + json.dumps(
        bars, ensure_ascii=False, indent=2
    ) + "\n"


def main():
    OUTPUT.write_text(render(), encoding="utf-8")


if __name__ == "__main__":
    main()
