#!/usr/bin/env python3

import json
import os
import stat
import time
from pathlib import Path

import jwt
import requests


# 配置参数
API_HOST = os.getenv("QWEATHER_API_HOST", "nn3qqqaj4u.re.qweatherapi.com")
LOCATION_ID = os.getenv("QWEATHER_LOCATION", "118.77,31.97")
DEBUG = os.getenv("WAYBAR_WEATHER_DEBUG") == "1"
TOKEN_FILE = Path(os.path.expanduser("~/.config/waybar/.qweather_token"))
PRIVATE_KEY_FILE = Path(os.path.expanduser("~/.config/waybar/.qweather_private_key"))
WEATHER_MODE_FILE = Path(os.path.expanduser("~/.cache/waybar/weather.mode"))

# 图标映射字典
WEATHER_ICON_BY_CATEGORY = {
    "clear": "☀️",
    "cloudy": "⛅️",
    "overcast": "☁️",
    "shower": "🌦️",
    "rain": "🌧️",
    "thunder": "⛈️",
    "hail": "🌨️",
    "sleet": "🌨️",
    "snow": "🌨️",
    "fog": "🌫️",
    "haze": "🌫️",
    "dust": "🌪️",
    "heat": "🥵",
    "cold": "🥶",
    "unknown": "❓",
}

WEATHER_CATEGORY_BY_CODE = {
    "100": "clear",
    "101": "cloudy",
    "102": "cloudy",
    "103": "cloudy",
    "104": "overcast",
    "300": "shower",
    "301": "shower",
    "302": "thunder",
    "303": "thunder",
    "304": "hail",
    "305": "rain",
    "306": "rain",
    "307": "rain",
    "308": "rain",
    "309": "rain",
    "310": "rain",
    "311": "rain",
    "312": "rain",
    "313": "sleet",
    "400": "snow",
    "401": "snow",
    "402": "snow",
    "403": "snow",
    "404": "sleet",
    "405": "sleet",
    "406": "sleet",
    "407": "snow",
    "500": "fog",
    "501": "fog",
    "502": "haze",
    "503": "dust",
    "504": "dust",
    "507": "dust",
    "508": "dust",
    "900": "heat",
    "901": "cold",
}

WEATHER_INTENSITY_BY_CODE = {
    "300": 1,
    "301": 2,
    "302": 2,
    "303": 3,
    "304": 3,
    "305": 1,
    "306": 2,
    "307": 3,
    "308": 3,
    "309": 1,
    "310": 3,
    "311": 3,
    "312": 3,
    "313": 2,
    "400": 1,
    "401": 2,
    "402": 3,
    "403": 3,
    "404": 2,
    "405": 2,
    "406": 2,
    "407": 1,
    "500": 1,
    "501": 2,
    "502": 3,
    "503": 1,
    "504": 2,
    "507": 3,
    "508": 3,
    "900": 3,
    "901": 3,
}

WEATHER_EXTREME_CODES = {
    "308",
    "312",
    "403",
    "508",
    "900",
    "901",
}

WEATHER_TEXT_TO_CATEGORY = {
    "晴": "clear",
    "云": "cloudy",
    "阴": "overcast",
    "阵雨": "shower",
    "雨": "rain",
    "雷": "thunder",
    "雹": "hail",
    "雪": "snow",
    "雾": "fog",
    "霾": "haze",
    "沙": "dust",
    "尘": "dust",
    "热": "heat",
    "冷": "cold",
}


def classify_weather(icon_code, weather_text=""):
    icon_code = str(icon_code)
    category = WEATHER_CATEGORY_BY_CODE.get(icon_code, "unknown")
    if category == "unknown" and weather_text:
        for needle, matched_category in WEATHER_TEXT_TO_CATEGORY.items():
            if needle in weather_text:
                category = matched_category
                break

    icon = WEATHER_ICON_BY_CATEGORY.get(category, WEATHER_ICON_BY_CATEGORY["unknown"])
    intensity = WEATHER_INTENSITY_BY_CODE.get(icon_code, 0)
    is_extreme = icon_code in WEATHER_EXTREME_CODES
    return icon, category, intensity, is_extreme


def debug_log(message):
    if not DEBUG:
        return
    with open("/tmp/weather.log", "a", encoding="utf-8") as f:
        f.write(f"{message}\n")


def validate_private_key_file():
    if not PRIVATE_KEY_FILE.is_file():
        return

    mode = stat.S_IMODE(PRIVATE_KEY_FILE.stat().st_mode)
    if mode & 0o077:
        debug_log(
            f"private key permissions are too broad: {oct(mode)} for {PRIVATE_KEY_FILE}"
        )


def load_api_token():
    token = os.getenv("QWEATHER_API_TOKEN") or os.getenv("WEATHER_API_TOKEN")
    if token:
        return token.strip()

    if TOKEN_FILE.is_file():
        return TOKEN_FILE.read_text(encoding="utf-8").strip()

    kid = os.getenv("QWEATHER_KID")
    sub = os.getenv("QWEATHER_SUB")
    private_key = os.getenv("QWEATHER_PRIVATE_KEY")

    if not private_key and PRIVATE_KEY_FILE.is_file():
        validate_private_key_file()
        private_key = PRIVATE_KEY_FILE.read_text(encoding="utf-8").strip()

    if kid and sub and private_key:
        payload = {
            "iat": int(time.time()) - 30,
            "exp": int(time.time()) + 900,
            "sub": sub,
        }
        headers = {
            "kid": kid,
        }
        token = jwt.encode(payload, private_key, algorithm="EdDSA", headers=headers)
        return token.strip()

    missing = []
    if not kid:
        missing.append("QWEATHER_KID")
    if not sub:
        missing.append("QWEATHER_SUB")
    if not private_key:
        missing.append("QWEATHER_PRIVATE_KEY or ~/.config/waybar/.qweather_private_key")
    if missing:
        debug_log("missing JWT inputs: " + ", ".join(missing))

    return ""

def get_weather(endpoint):
    """获取天气信息"""
    api_token = load_api_token()
    if not api_token:
        debug_log("missing QWEATHER_API_TOKEN")
        return None

    url = f"https://{API_HOST}/v7/weather/{endpoint}?location={LOCATION_ID}"
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Accept-Encoding": "gzip"  # 支持压缩
    }

    try:
        response = requests.get(url, headers=headers, timeout=30)
        response.raise_for_status()  # 如果响应状态码不是200，抛出异常
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        debug_log(f"requests: {e}")
        return None
    except json.JSONDecodeError as e:
        debug_log(f"json: {e}")
        return None

def build_sparkline(values, width=12, symbols="▁▂▃▄▅▆▇█"):
    if not values:
        return ""
    if width <= 0:
        width = len(values)
    if len(values) > width:
        step = len(values) / width
        values = [values[int(i * step)] for i in range(width)]

    min_val = min(values)
    max_val = max(values)
    if max_val == min_val:
        return symbols[len(symbols) // 2] * len(values)

    span = max_val - min_val
    out = []
    for val in values:
        idx = int((val - min_val) / span * (len(symbols) - 1))
        out.append(symbols[idx])
    return "".join(out)


def format_weather_output(data, hourly_data=None):
    now = data.get('now', {})
    if not now:
        return None
        
    icon_code = now.get('icon', '999')
    temp = now.get('temp', 'N/A')
    text = now.get('text', 'N/A')
    
    icon, category, intensity, is_extreme = classify_weather(icon_code, text)
    
    # 可以添加更多信息到tooltip
    feels_like = now.get('feelsLike', 'N/A')
    humidity = now.get('humidity', 'N/A')
    wind_scale = now.get('windScale', 'N/A')
    wind_dir = now.get('windDir', 'N/A')
    
    hourly_temps = []
    if hourly_data:
        for item in hourly_data.get("hourly", []):
            try:
                hourly_temps.append(float(item.get("temp")))
            except (TypeError, ValueError):
                continue

    hourly_chart = ""
    if hourly_temps:
        hourly_min = int(min(hourly_temps))
        hourly_max = int(max(hourly_temps))
        chart = build_sparkline(hourly_temps, width=12)
        hourly_chart = f"24h: {chart} ({hourly_min}-{hourly_max}°C)\n"

    mode = "temp"
    if WEATHER_MODE_FILE.is_file():
        mode = WEATHER_MODE_FILE.read_text(encoding="utf-8").strip() or "temp"

    tooltip = f"""{hourly_chart}温度: {temp}°C
体感: {feels_like}°C
天气: {text}
湿度: {humidity}%
风力: {wind_scale}级 {wind_dir}
更新时间: {data.get('updateTime', 'N/A')}"""
    
    # 返回Waybar JSON格式
    classes = ["weather", f"weather-{category}"]
    if intensity:
        classes.append(f"weather-lvl-{intensity}")
    if is_extreme:
        classes.append("weather-extreme")

    waybar_json = {
        "text": f"{icon} {text}" if mode == "text" else f"{icon} {temp}°C",
        "tooltip": tooltip,
        "class": " ".join(classes)
    }
    
    # 根据温度设置不同的class（用于CSS样式）
    try:
        temp_num = float(temp)
        if temp_num >= 35:
            classes.append("temp-hot")
        elif temp_num <= 0:
            classes.append("temp-cold")
    except (ValueError, TypeError):
        pass
    waybar_json["class"] = " ".join(classes)
    return waybar_json

def main():
    data = get_weather("now")
    hourly_data = get_weather("24h")
    debug_log(json.dumps(data, ensure_ascii=False) if data else "weather: no data")
    if not data:
        error_output = {
            "text": "❌ 天气获取失败",
            "tooltip": "请检查网络连接、TLS 证书，以及 QWEATHER_API_TOKEN 或 JWT 配置（QWEATHER_KID/QWEATHER_SUB/私钥文件）",
            "class": "weather-error"
        }
        print(json.dumps(error_output))
        return
    
    output = format_weather_output(data, hourly_data)
    if output:
        print(json.dumps(output))
    else:
        error_output = {
            "text": "❌ 数据解析失败",
            "tooltip": "天气数据格式不正确",
            "class": "weather-error"
        }
        print(json.dumps(error_output))

main()
