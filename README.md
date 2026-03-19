# Config Notes

This repository stores shareable configuration only.

## Keep Out Of Git

Do not place secrets or private keys inside this repository.

Use these private locations instead:

- `~/.secrets.zsh`
  - shell secrets such as `DS_AK`
  - multiline secrets such as `QWEATHER_PRIVATE_KEY`
- `~/.config/waybar/.qweather_private_key`
  - QWeather JWT signing private key
- `~/.config/waybar/.qweather_token`
  - optional static weather token override

The repo-level [`.gitignore`](/home/elliot/config/.gitignore) already ignores the most common local secret files, but that is only a safety net.

## Current Secret Loading

- [`.custom.zsh`](/home/elliot/.custom.zsh) loads `~/.secrets.zsh` if present.
- [`zsh/custom.zsh`](/home/elliot/config/zsh/custom.zsh) also loads `~/.secrets.zsh` if present.
- [`waybar/scripts/weather.py`](/home/elliot/config/waybar/scripts/weather.py) reads:
  - `QWEATHER_API_TOKEN` / `WEATHER_API_TOKEN`
  - or `QWEATHER_KID` + `QWEATHER_SUB` + `QWEATHER_PRIVATE_KEY`
  - or `~/.config/waybar/.qweather_private_key`

## Suggested Local Setup

1. Put reusable shell secrets in `~/.secrets.zsh`.
2. Keep file-based keys under `~/.config/...` with strict permissions.
3. Use `chmod 600` for private key files.
4. Avoid testing secrets from inside the repo tree.

## Secret Migration Checklist

Move these out of `~/.custom.zsh` over time:

- `DS_AK`
  - put into `~/.secrets.zsh`
- `QWEATHER_KID`
  - move to `~/.secrets.zsh` if you want all weather credentials together
- `QWEATHER_SUB`
  - move to `~/.secrets.zsh` if you want all weather credentials together
- `QWEATHER_PRIVATE_KEY`
  - prefer `~/.config/waybar/.qweather_private_key`

Recommended split:

- `~/.custom.zsh`
  - local PATH tweaks
  - non-secret aliases and functions
- `~/.secrets.zsh`
  - tokens
  - access keys
  - secret IDs
  - multiline private keys only when file-based storage is not practical
