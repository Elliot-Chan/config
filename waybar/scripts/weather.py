#!/usr/bin/env python3

import requests
import json
import time
import os
import jwt

def getJwt():
    private_key = """
        -----BEGIN PRIVATE KEY-----
        MC4CAQAwBQYDK2VwBCIEIE0ZDOqlpyK+3oVqi9010Fk/GCnj/63cLycpxOYBMO7s
        -----END PRIVATE KEY-----
    """
    payload = {
        'iat': int(time.time()) - 30,
        'exp': int(time.time()) + 900,
        'sub': '27E53CHPMG'
    }
    headers = {
        'kid': 'C85DFER5CV'
    }
    return jwt.encode(payload, private_key, algorithm='EdDSA', headers = headers)


# 配置参数
API_TOKEN = getJwt()  # 替换为你的真实 Token
API_HOST = "nn3qqqaj4u.re.qweatherapi.com"
LOCATION_ID = "118.77,31.97"  # 例如 "api.qweather.com"

# 图标映射字典
WEATHER_ICONS = {
    "100": "☀️",   # 晴
    "101": "🌤️",   # 多云
    "102": "🌤️",   # 少云
    "103": "🌤️",   # 晴间多云
    "104": "☁️",   # 阴
    "300": "🌧️",   # 阵雨
    "301": "🌧️",   # 强阵雨
    "302": "⛈️",   # 雷阵雨
    "303": "⛈️",   # 强雷阵雨
    "304": "🌨️",   # 雷阵雨伴有冰雹
    "305": "🌧️",   # 小雨
    "306": "🌧️",   # 中雨
    "307": "🌧️",   # 大雨
    "308": "🌧️",   # 极端降雨
    "309": "🌧️",   # 毛毛雨/细雨
    "310": "🌧️",   # 暴雨
    "311": "🌧️",   # 大暴雨
    "312": "🌧️",   # 特大暴雨
    "313": "🌧️",   # 冻雨
    "400": "❄️",   # 小雪
    "401": "❄️",   # 中雪
    "402": "❄️",   # 大雪
    "403": "❄️",   # 暴雪
    "404": "🌨️",   # 雨夹雪
    "405": "🌨️",   # 雨雪天气
    "406": "🌨️",   # 阵雨夹雪
    "407": "🌨️",   # 阵雪
    "500": "🌫️",   # 薄雾
    "501": "🌫️",   # 雾
    "502": "🌫️",   # 霾
    "503": "🐫",   # 扬沙
    "504": "🐫",   # 浮尘
    "507": "🐫",   # 沙尘暴
    "508": "🐫",   # 强沙尘暴
    "900": "🌡️",   # 热
    "901": "🥶",   # 冷
    "999": "?"     # 未知
}

def get_weather():
    """获取天气信息"""
    url = f"https://{API_HOST}/v7/weather/now?location={LOCATION_ID}"
    headers = {
        "Authorization": f"Bearer {API_TOKEN}",
        "Accept-Encoding": "gzip"  # 支持压缩
    }
    
    import os
    with open("/tmp/weather.log", "a") as f:
        f.write(f"{os.environ}")
        f.write("\n")
    try:
        response = requests.get(url, headers=headers, timeout=30, verify=False)
        response.raise_for_status()  # 如果响应状态码不是200，抛出异常
        data = response.json()
        return data
    except requests.exceptions.RequestException as e:
        with open("/tmp/weather.log", "a") as f:
            f.write(f"requests: {e}")
            f.write("\n")

        return None
    except json.JSONDecodeError as e:
        with open("/tmp/weather.log", "a") as f:
            f.write(f"json: {e}")
            f.write("\n")
        return None

def format_weather_output(data):
    now = data.get('now', {})
    if not now:
        return None
        
    icon_code = now.get('icon', '999')
    temp = now.get('temp', 'N/A')
    text = now.get('text', 'N/A')
    
    # 获取图标，如果找不到则使用默认图标
    icon = WEATHER_ICONS.get(icon_code, WEATHER_ICONS["999"])
    
    # 可以添加更多信息到tooltip
    feels_like = now.get('feelsLike', 'N/A')
    humidity = now.get('humidity', 'N/A')
    wind_scale = now.get('windScale', 'N/A')
    wind_dir = now.get('windDir', 'N/A')
    
    tooltip = f"""温度: {temp}°C
体感: {feels_like}°C
天气: {text}
湿度: {humidity}%
风力: {wind_scale}级 {wind_dir}
更新时间: {data.get('updateTime', 'N/A')}"""
    
    # 返回Waybar JSON格式
    waybar_json = {
        "text": f"{icon} {temp}°C",
        "tooltip": tooltip,
        "class": "weather-normal"
    }
    
    # 根据温度设置不同的class（用于CSS样式）
    try:
        temp_num = float(temp)
        if temp_num >= 35:
            waybar_json["class"] = "weather-hot"
        elif temp_num <= 0:
            waybar_json["class"] = "weather-cold"
    except (ValueError, TypeError):
        pass
    return waybar_json

def main():
    data = get_weather()
    with open("/tmp/weather.log", "a") as f:
        f.write(json.dumps(data))
        f.write("\n")
    if not data:
        error_output = {
            "text": "❌ 天气获取失败",
            "tooltip": "请检查网络连接或API配置",
            "class": "weather-error"
        }
        print(json.dumps(error_output))
        return
    
    output = format_weather_output(data)
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
