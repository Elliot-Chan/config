#!/usr/bin/env python3

import argparse
import json
import os
import heapq
import time
import urllib.error
import urllib.request
from html import escape
from datetime import datetime, timedelta, timezone
from pathlib import Path


HOME = Path.home()
CODEX_SESSIONS = HOME / ".codex" / "sessions"
CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "waybar"
DEEPSEEK_CACHE = CACHE_DIR / "ai_usage_deepseek.json"
DEEPSEEK_USAGE_LOG = Path(os.environ.get("AI_USAGE_DEEPSEEK_USAGE_LOG", CACHE_DIR / "ai_usage_deepseek_usage.jsonl"))
AI_USAGE_STATE = CACHE_DIR / "ai_usage_refresh.json"
AI_USAGE_DETAIL_TEXT = CACHE_DIR / "ai_usage_detail.txt"
AI_USAGE_DETAIL_WOFI = CACHE_DIR / "ai_usage_detail_wofi.txt"
DEEPSEEK_BALANCE_URL = "https://api.deepseek.com/user/balance"
DEEPSEEK_CACHE_TTL = 600
RECENT_SESSION_LIMIT = 32


def day_dir(day):
    return CODEX_SESSIONS / f"{day.year:04d}" / f"{day.month:02d}" / f"{day.day:02d}"


def compact_number(value):
    if value is None:
        return "--"
    value = int(value)
    if value >= 1_000_000:
        return f"{value / 1_000_000:.1f}M"
    if value >= 1_000:
        return f"{value / 1_000:.0f}k"
    return str(value)


def compact_seconds(seconds):
    if seconds is None:
        return "--"
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    minutes = seconds // 60
    if minutes < 60:
        return f"{minutes}m"
    hours = minutes // 60
    if hours < 48:
        return f"{hours}h{minutes % 60:02d}m"
    return f"{hours // 24}d{hours % 24}h"


def limit_bar(left_percent, width=20):
    if left_percent is None:
        return "[" + ("░" * width) + "]"
    filled = round(max(0, min(100, float(left_percent))) / 100 * width)
    return "[" + ("█" * filled) + ("░" * (width - filled)) + "]"


def markup_bar(left_percent, width=10):
    if left_percent is None:
        return "<span color='#6c7086'>" + ("░" * width) + "</span>"
    filled = round(max(0, min(100, float(left_percent))) / 100 * width)
    return (
        "<span color='#a6e3a1'>" + ("█" * filled) + "</span>"
        "<span color='#6c7086'>" + ("░" * (width - filled)) + "</span>"
    )


def reset_at(now, seconds):
    if seconds is None:
        return "--"
    target = now + timedelta(seconds=int(seconds))
    if target.date() == now.date():
        return target.strftime("%H:%M")
    if target.year == now.year:
        return target.strftime("%H:%M on %-d %b")
    return target.strftime("%H:%M on %-d %b %Y")


def reset_value_seconds(rate_limit, now):
    if rate_limit.get("resets_in_seconds") is not None:
        return int(rate_limit["resets_in_seconds"])
    if rate_limit.get("resets_at") is not None:
        return max(0, int(rate_limit["resets_at"]) - int(now.timestamp()))
    return None


def displayable_rate_limits(limits):
    if not (limits.get("primary") or limits.get("secondary")):
        return False
    if limits.get("limit_id") == "codex":
        return True

    credits = limits.get("credits")
    if isinstance(credits, dict) and credits.get("has_credits") is False:
        return False

    primary_used = (limits.get("primary") or {}).get("used_percent")
    secondary_used = (limits.get("secondary") or {}).get("used_percent")
    used_values = [value for value in (primary_used, secondary_used) if value is not None]
    return any(float(value) > 0 for value in used_values)


def limit_line(label, rate_limit, now):
    used = rate_limit.get("used_percent")
    if used is None:
        return f"{label:<13} {limit_bar(None)} -- left (resets --)"
    left = max(0.0, 100.0 - float(used))
    return (
        f"{label:<13} "
        f"{limit_bar(left)} "
        f"{left:.0f}% left "
        f"(resets {reset_at(now, reset_value_seconds(rate_limit, now))})"
    )


def limit_segment(label, rate_limit, now, color):
    used = rate_limit.get("used_percent")
    left = None if used is None else max(0.0, 100.0 - float(used))
    percent = "--" if left is None else f"{left:.0f}%"
    reset = reset_at(now, reset_value_seconds(rate_limit, now))
    return (
        f"<span color='{color}'>{escape(label)}</span> "
        f"{markup_bar(left)} "
        f"<span color='#cdd6f4'>{percent}</span> "
        f"<span color='#a6adc8'>{escape(reset)}</span>"
    )


def parse_timestamp(raw):
    if not raw:
        return None
    try:
        return datetime.fromisoformat(raw.replace("Z", "+00:00")).astimezone()
    except ValueError:
        return None


def parse_usage_timestamp(record):
    for key in ("timestamp", "created_at", "time", "date"):
        ts = parse_timestamp(record.get(key))
        if ts:
            return ts

    created = record.get("created")
    if isinstance(created, (int, float)):
        return datetime.fromtimestamp(created, timezone.utc).astimezone()
    return None


def usage_value(usage, key):
    try:
        return int(usage.get(key) or 0)
    except (TypeError, ValueError):
        return 0


def extract_deepseek_usage(record):
    if not isinstance(record, dict):
        return None

    usage = record.get("usage") if isinstance(record.get("usage"), dict) else record
    total = usage_value(usage, "total_tokens")
    prompt = usage_value(usage, "prompt_tokens")
    completion = usage_value(usage, "completion_tokens")
    cache_hit = usage_value(usage, "prompt_cache_hit_tokens")
    cache_miss = usage_value(usage, "prompt_cache_miss_tokens")
    reasoning = usage_value(usage, "reasoning_tokens")

    completion_details = usage.get("completion_tokens_details")
    if isinstance(completion_details, dict):
        reasoning += usage_value(completion_details, "reasoning_tokens")

    prompt_details = usage.get("prompt_tokens_details")
    if isinstance(prompt_details, dict) and not cache_hit:
        cache_hit = usage_value(prompt_details, "cached_tokens")

    if total <= 0:
        total = prompt + completion
    if total <= 0:
        return None

    return {
        "total": total,
        "prompt": prompt,
        "completion": completion,
        "cache_hit": cache_hit,
        "cache_miss": cache_miss,
        "reasoning": reasoning,
    }


def deepseek_usage_records():
    if not DEEPSEEK_USAGE_LOG.is_file():
        return []

    try:
        text = DEEPSEEK_USAGE_LOG.read_text(encoding="utf-8", errors="replace").strip()
    except OSError:
        return []
    if not text:
        return []

    if DEEPSEEK_USAGE_LOG.suffix == ".json":
        try:
            data = json.loads(text)
        except json.JSONDecodeError:
            return []
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            for key in ("records", "items", "requests"):
                if isinstance(data.get(key), list):
                    return data[key]
            return [data]
        return []

    records = []
    for line in text.splitlines():
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return records


def read_deepseek_token_usage():
    now = datetime.now().astimezone()
    today = now.date()
    week_start = today - timedelta(days=today.weekday())
    month_start = today.replace(day=1)
    totals = {
        "today": 0,
        "week": 0,
        "month": 0,
        "today_requests": 0,
        "week_requests": 0,
        "month_requests": 0,
        "prompt": 0,
        "completion": 0,
        "cache_hit": 0,
        "cache_miss": 0,
        "reasoning": 0,
        "latest": None,
    }

    for record in deepseek_usage_records():
        ts = parse_usage_timestamp(record)
        usage = extract_deepseek_usage(record)
        if not ts or not usage:
            continue

        event_day = ts.date()
        if not (month_start <= event_day <= today):
            continue

        totals["month"] += usage["total"]
        totals["month_requests"] += 1
        if event_day >= week_start:
            totals["week"] += usage["total"]
            totals["week_requests"] += 1
        if event_day == today:
            totals["today"] += usage["total"]
            totals["today_requests"] += 1

        for key in ("prompt", "completion", "cache_hit", "cache_miss", "reasoning"):
            totals[key] += usage[key]
        if totals["latest"] is None or ts > totals["latest"]:
            totals["latest"] = ts

    if totals["month_requests"] == 0:
        return {
            "available": False,
            "tooltip": f"DeepSeek tokens: no local usage log at {DEEPSEEK_USAGE_LOG}",
        }

    tooltip = "\n".join(
        [
            f"DeepSeek tokens today: {compact_number(totals['today'])} / {totals['today_requests']} requests",
            f"DeepSeek tokens week:  {compact_number(totals['week'])} / {totals['week_requests']} requests",
            f"DeepSeek tokens month: {compact_number(totals['month'])} / {totals['month_requests']} requests",
            f"Prompt/completion: {compact_number(totals['prompt'])} / {compact_number(totals['completion'])}",
            f"Cache hit/miss: {compact_number(totals['cache_hit'])} / {compact_number(totals['cache_miss'])}",
            f"Reasoning: {compact_number(totals['reasoning'])}",
            f"Latest: {totals['latest']:%Y-%m-%d %H:%M:%S %z}",
        ]
    )
    return {
        "available": True,
        "tooltip": tooltip,
        "today_tokens": compact_number(totals["today"]),
        "week_tokens": compact_number(totals["week"]),
        "month_tokens": compact_number(totals["month"]),
    }


def session_label(path, meta):
    session_id = (meta.get("id") or "").strip()
    if not session_id:
        stem = path.stem
        session_id = stem.rsplit("-", 1)[-1] if "-" in stem else stem

    cwd = (meta.get("cwd") or "").strip()
    cwd_name = Path(cwd).name if cwd else ""
    if cwd_name:
        return f"{session_id[:8]} {cwd_name}"
    return session_id[:8]


def codex_session_paths(now):
    today = now.date()
    month_start = today.replace(day=1)
    paths = set()
    day = month_start
    while day <= today:
        current_day_dir = day_dir(day)
        if current_day_dir.is_dir():
            paths.update(current_day_dir.glob("*.jsonl"))
        day += timedelta(days=1)

    if CODEX_SESSIONS.is_dir():
        recent = []
        month_start_ts = datetime.combine(month_start, datetime.min.time(), now.tzinfo).timestamp()
        for path in CODEX_SESSIONS.rglob("*.jsonl"):
            try:
                mtime = path.stat().st_mtime
            except OSError:
                continue
            recent.append((mtime, path))
            if mtime >= month_start_ts:
                paths.add(path)
        paths.update(path for _, path in heapq.nlargest(RECENT_SESSION_LIMIT, recent))
    return sorted(paths, key=lambda path: path.stat().st_mtime, reverse=True)


def read_codex_usage():
    now = datetime.now().astimezone()
    today = now.date()
    week_start = today - timedelta(days=today.weekday())
    month_start = today.replace(day=1)
    latest = None
    latest_limits = None
    latest_display_limits = None
    today_tokens = 0
    today_turns = 0
    week_tokens = 0
    week_turns = 0
    month_tokens = 0
    month_turns = 0
    today_sessions = {}

    for path in codex_session_paths(now):
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            continue

        meta = {}
        session_tokens = 0
        session_turns = 0
        session_latest = None
        session_total = None

        for line in lines:
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            payload = event.get("payload") or {}
            if event.get("type") == "session_meta":
                meta = payload
                continue

            if event.get("type") != "event_msg" or payload.get("type") != "token_count":
                continue

            ts = parse_timestamp(event.get("timestamp"))
            if not ts:
                continue

            event_day = ts.date()
            if month_start <= event_day <= today:
                last_usage = ((payload.get("info") or {}).get("last_token_usage") or {})
                last_tokens = int(last_usage.get("total_tokens") or 0)
                month_tokens += last_tokens
                month_turns += 1
                if event_day >= week_start:
                    week_tokens += last_tokens
                    week_turns += 1
                if event_day == today:
                    today_tokens += last_tokens
                    today_turns += 1
                    session_tokens += last_tokens
                    session_turns += 1
                    session_latest = ts
                    session_total = ((payload.get("info") or {}).get("total_token_usage") or {}).get("total_tokens")

            if latest is None or (ts and ts > latest["timestamp"]):
                latest = {"timestamp": ts or datetime.fromtimestamp(0, timezone.utc), "payload": payload}

            limits = payload.get("rate_limits") or {}
            if limits.get("primary") or limits.get("secondary"):
                if latest_limits is None or (ts and ts > latest_limits["timestamp"]):
                    latest_limits = {
                        "timestamp": ts or datetime.fromtimestamp(0, timezone.utc),
                        "limits": limits,
                    }
                if displayable_rate_limits(limits):
                    if latest_display_limits is None or (ts and ts > latest_display_limits["timestamp"]):
                        latest_display_limits = {
                            "timestamp": ts or datetime.fromtimestamp(0, timezone.utc),
                            "limits": limits,
                        }

        if session_turns:
            today_sessions[str(path)] = {
                "label": session_label(path, meta),
                "tokens": session_tokens,
                "turns": session_turns,
                "latest": session_latest or datetime.fromtimestamp(0, timezone.utc),
                "total": session_total,
            }

    if latest is None:
        return {
            "text": "C--",
            "tooltip": "Codex: no local token_count events found",
            "class": "unknown",
        }

    payload = latest["payload"]
    info = payload.get("info") or {}
    limits = payload.get("rate_limits") or {}
    if latest_display_limits is not None and not displayable_rate_limits(limits):
        limits = latest_display_limits["limits"]
    elif not (limits.get("primary") or limits.get("secondary")) and latest_limits is not None:
        limits = latest_limits["limits"]
    primary = limits.get("primary") or {}
    secondary = limits.get("secondary") or {}
    total_usage = info.get("total_token_usage") or {}
    primary_used = primary.get("used_percent")
    limit_class = "ok"
    if primary_used is not None and float(primary_used) >= 90:
        limit_class = "critical"
    elif primary_used is not None and float(primary_used) >= 75:
        limit_class = "warn"

    primary_left = None if primary_used is None else max(0.0, 100.0 - float(primary_used))
    if primary_used is None:
        text = f"C{compact_number(today_tokens)}"
    else:
        text = f"C{primary_left:.0f}%"

    display = "  ".join(
        [
            "<span color='#cba6f7'>Codex</span>",
            limit_segment("5h", primary, now, "#89b4fa"),
            limit_segment("Week", secondary, now, "#f9e2af"),
        ]
    )

    session_lines = [
        f"  {item['label']}: {compact_number(item['tokens'])} / {item['turns']} updates; "
        f"total {compact_number(item['total'])}"
        for item in sorted(today_sessions.values(), key=lambda value: value["latest"], reverse=True)
    ]
    session_items = [
        {
            "label": item["label"],
            "tokens": compact_number(item["tokens"]),
            "turns": item["turns"],
            "total": compact_number(item["total"]),
        }
        for item in sorted(today_sessions.values(), key=lambda value: value["latest"], reverse=True)
    ]
    tooltip_parts = [
        "Codex",
        limit_line("5h limit:", primary, now),
        limit_line("Weekly limit:", secondary, now),
        f"Today tokens: {compact_number(today_tokens)} / {today_turns} updates",
        f"Week tokens:  {compact_number(week_tokens)} / {week_turns} updates",
        f"Month tokens: {compact_number(month_tokens)} / {month_turns} updates",
        f"Current thread: {compact_number(total_usage.get('total_tokens'))} tokens",
    ]
    if session_lines:
        tooltip_parts.extend(["", "Today by thread:", *session_lines])
    tooltip = "\n".join(tooltip_parts)
    return {
        "text": text,
        "display": display,
        "tooltip": tooltip,
        "class": limit_class,
        "primary_left": primary_left,
        "primary_reset": reset_at(now, reset_value_seconds(primary, now)),
        "secondary_left": None if secondary.get("used_percent") is None else max(0.0, 100.0 - float(secondary["used_percent"])),
        "secondary_reset": reset_at(now, reset_value_seconds(secondary, now)),
        "today_tokens": compact_number(today_tokens),
        "today_turns": today_turns,
        "week_tokens": compact_number(week_tokens),
        "week_turns": week_turns,
        "month_tokens": compact_number(month_tokens),
        "month_turns": month_turns,
        "current_thread": compact_number(total_usage.get("total_tokens")),
        "sessions": session_items,
    }


def read_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def write_json(path, value):
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, ensure_ascii=False), encoding="utf-8")
    except OSError:
        pass


def write_text(path, value):
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding="utf-8")
    except OSError:
        pass


def write_refresh_state():
    now = datetime.now().astimezone()
    write_json(
        AI_USAGE_STATE,
        {
            "updated_at": int(now.timestamp()),
            "updated_at_text": now.strftime("%Y-%m-%d %H:%M:%S %z"),
        },
    )


def cached_deepseek_balance():
    cached = read_json(DEEPSEEK_CACHE)
    if not cached:
        return None
    age = time.time() - float(cached.get("fetched_at", 0))
    if age <= DEEPSEEK_CACHE_TTL:
        return cached
    return None


def select_balance(balance_infos):
    if not isinstance(balance_infos, list) or not balance_infos:
        return None
    for currency in ("CNY", "USD"):
        for item in balance_infos:
            if item.get("currency") == currency:
                return item
    return balance_infos[0]


def fetch_deepseek_balance():
    if os.environ.get("AI_USAGE_SKIP_DEEPSEEK") == "1":
        return cached_deepseek_balance()

    key = (
        os.environ.get("DEEPSEEK_API_KEY")
        or os.environ.get("DS_AK")
        or os.environ.get("DEEPSEEK_KEY")
    )
    if not key:
        return {"status": "missing-key", "message": "DeepSeek: API key not found"}

    request = urllib.request.Request(
        DEEPSEEK_BALANCE_URL,
        headers={"Authorization": f"Bearer {key}", "Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=2.5) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (OSError, urllib.error.URLError, urllib.error.HTTPError, json.JSONDecodeError) as exc:
        cached = read_json(DEEPSEEK_CACHE)
        if cached:
            cached["stale"] = True
            cached["message"] = f"DeepSeek: using cached balance ({exc.__class__.__name__})"
            return cached
        return {"status": "error", "message": f"DeepSeek: {exc.__class__.__name__}"}

    selected = select_balance(data.get("balance_infos"))
    result = {
        "status": "ok" if data.get("is_available") else "unavailable",
        "is_available": bool(data.get("is_available")),
        "balance": selected or {},
        "fetched_at": time.time(),
    }
    write_json(DEEPSEEK_CACHE, result)
    return result


def read_deepseek_usage():
    data = fetch_deepseek_balance()
    token_usage = read_deepseek_token_usage()
    if not data:
        return {"text": "D--", "tooltip": "DeepSeek: skipped, no cache", "class": "unknown"}

    if data.get("status") == "missing-key":
        return {"text": "D--", "tooltip": data["message"], "class": "warn"}

    if data.get("status") == "error":
        return {"text": "D?", "tooltip": data["message"], "class": "warn"}

    balance = data.get("balance") or {}
    currency = balance.get("currency") or "--"
    total = balance.get("total_balance") or "--"
    prefix = "¥" if currency == "CNY" else "$" if currency == "USD" else f"{currency} "
    text = f"D{prefix}{total}"
    if len(text) > 9:
        text = f"D{prefix}{total[:5]}"

    tooltip = "\n".join(
        [
            f"DeepSeek balance: {currency} {total}",
            f"Granted: {balance.get('granted_balance', '--')}",
            f"Topped up: {balance.get('topped_up_balance', '--')}",
            f"Available: {data.get('is_available', '--')}",
            "",
            token_usage["tooltip"],
            data.get("message", ""),
        ]
    ).strip()
    status_class = "ok" if data.get("is_available") else "critical"
    if data.get("stale"):
        status_class = "warn"
    display = (
        "<span color='#94e2d5'>DeepSeek</span> "
        f"<span color='#cdd6f4'>{escape(prefix + str(total))}</span>"
    )
    if token_usage.get("available"):
        display += (
            " "
            f"<span color='#6c7086'>T</span><span color='#cdd6f4'>{escape(token_usage['today_tokens'])}</span>"
        )
    return {"text": text, "display": display, "tooltip": tooltip, "class": status_class}


def build_detail(codex, deepseek):
    now = datetime.now().astimezone()
    return "\n".join(
        [
            "AI Usage",
            f"Updated: {now:%Y-%m-%d %H:%M:%S %z}",
            "",
            codex["tooltip"],
            "",
            deepseek["tooltip"],
        ]
    )


def percent_text(value):
    if value is None:
        return "--"
    return f"{float(value):.0f}%"


def pango_line(left, right="", color="#cdd6f4", weight="normal"):
    if right:
        return (
            f"<span color='{color}' weight='{weight}'>{escape(str(left))}</span>"
            f"<span color='#6c7086'>  ·  </span>"
            f"<span color='#a6adc8'>{escape(str(right))}</span>"
        )
    return f"<span color='{color}' weight='{weight}'>{escape(str(left))}</span>"


def pango_text(text, color="#cdd6f4", weight="normal"):
    return f"<span color='{color}' weight='{weight}'>{escape(str(text))}</span>"


def pango_rule(width=74):
    return pango_text("━" * width, "#45475a")


def pango_progress(left_percent, width=22):
    if left_percent is None:
        return pango_text("░" * width, "#6c7086")
    left = max(0, min(100, float(left_percent)))
    filled = round(left / 100 * width)
    empty = width - filled
    color = "#a6e3a1"
    if left < 15:
        color = "#f38ba8"
    elif left < 35:
        color = "#f9e2af"
    return pango_text("█" * filled, color, "bold") + pango_text("░" * empty, "#45475a")


def pango_table_header(columns):
    return pango_text("  ".join(label.ljust(width) for label, width in columns), "#6c7086", "bold")


def pango_table_row(values, columns, color="#cdd6f4", weight="normal"):
    cells = []
    for value, (_, width) in zip(values, columns):
        raw = str(value)
        if len(raw) > width:
            raw = raw[: max(1, width - 1)] + "…"
        cells.append(raw.ljust(width))
    return pango_text("  ".join(cells), color, weight)


def build_detail_wofi(codex, deepseek):
    now = datetime.now().astimezone()
    deepseek_lines = (deepseek.get("tooltip") or "").splitlines()
    balance = deepseek_lines[0].replace("DeepSeek balance: ", "") if deepseek_lines else "--"
    available = next((line.replace("Available: ", "") for line in deepseek_lines if line.startswith("Available: ")), "--")
    deepseek_token_lines = [
        line
        for line in deepseek_lines
        if line.startswith("DeepSeek tokens") or line.startswith("Prompt/") or line.startswith("Cache ") or line.startswith("Reasoning:")
    ]
    summary_columns = [("Scope", 13), ("Tokens", 10), ("Updates", 8), ("Reset", 17)]
    thread_columns = [("Thread", 25), ("Tokens", 9), ("Updates", 8), ("Total", 9)]
    lines = [
        pango_line("󰚩  AI Usage", f"updated {now:%H:%M:%S}", "#cba6f7", "bold"),
        pango_rule(),
        pango_line("  Codex", "remaining quota", "#89b4fa", "bold"),
        (
            pango_text("5h   ", "#a6e3a1", "bold")
            + pango_progress(codex.get("primary_left"))
            + pango_text(f"  {percent_text(codex.get('primary_left')).rjust(4)}  reset {codex.get('primary_reset', '--')}", "#a6adc8")
        ),
        (
            pango_text("week ", "#f9e2af", "bold")
            + pango_progress(codex.get("secondary_left"))
            + pango_text(f"  {percent_text(codex.get('secondary_left')).rjust(4)}  reset {codex.get('secondary_reset', '--')}", "#a6adc8")
        ),
        pango_line(""),
        pango_table_header(summary_columns),
        pango_table_row(["Today", codex.get("today_tokens", "--"), codex.get("today_turns", "--"), "-"], summary_columns),
        pango_table_row(["This week", codex.get("week_tokens", "--"), codex.get("week_turns", "--"), codex.get("secondary_reset", "--")], summary_columns),
        pango_table_row(["This month", codex.get("month_tokens", "--"), codex.get("month_turns", "--"), "-"], summary_columns),
        pango_table_row(["Current", codex.get("current_thread", "--"), "thread", "-"], summary_columns, "#fab387", "bold"),
    ]
    sessions = codex.get("sessions") or []
    if sessions:
        lines.extend(
            [
                pango_line(""),
                pango_line("󰓩  Today by thread", "top local sessions", "#cba6f7", "bold"),
                pango_table_header(thread_columns),
            ]
        )
        for item in sessions[:6]:
            lines.append(
                pango_table_row(
                    [item["label"], item["tokens"], item["turns"], item["total"]],
                    thread_columns,
                    "#bac2de",
                )
            )
    lines.extend(
        [
            pango_line(""),
            pango_rule(),
            pango_line("󰢹  DeepSeek", balance, "#94e2d5", "bold"),
            (
                pango_text("status ", "#94e2d5", "bold")
                + pango_progress(100 if available == "True" else 0, 10)
                + pango_text(f"  available: {available}", "#a6adc8")
            ),
            *[pango_text(line, "#bac2de") for line in deepseek_token_lines],
            pango_line("󰜷  middle/right click refresh", color="#6c7086"),
        ]
    )
    return "\n".join(lines)


def strip_ansi_width(text):
    return len(text)


def ansi_card(title, body, color):
    reset = "\033[0m"
    border_color = "\033[38;5;240m"
    title_style = f"{color}\033[1m"
    lines = body.splitlines() or ["--"]
    width = min(96, max(54, len(title) + 4, *(strip_ansi_width(line) for line in lines)))
    top_fill = "─" * max(1, width - len(title) - 2)
    output = [
        f"{border_color}╭─ {title_style}{title}{reset}{border_color} {top_fill}╮{reset}",
    ]
    for line in lines:
        output.append(f"{border_color}│{reset} {line:<{width}} {border_color}│{reset}")
    output.append(f"{border_color}╰{'─' * (width + 2)}╯{reset}")
    return "\n".join(output)


def build_detail_ansi(codex, deepseek):
    now = datetime.now().astimezone()
    reset = "\033[0m"
    title = "\033[1;38;5;183mAI Usage\033[0m"
    updated = f"\033[38;5;245mUpdated {now:%Y-%m-%d %H:%M:%S %z}{reset}"
    hint = "\033[38;5;245mMiddle or right click the Waybar module to refresh. Press Enter to close.\033[0m"
    return "\n\n".join(
        [
            f"{title}\n{updated}",
            ansi_card("Codex", codex["tooltip"], "\033[38;5;183m"),
            ansi_card("DeepSeek", deepseek["tooltip"], "\033[38;5;116m"),
            hint,
        ]
    )


def build_detail_html(codex, deepseek):
    now = datetime.now().astimezone()
    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>AI Usage</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #11111b;
      --panel: #181825;
      --panel2: #1e1e2e;
      --border: #313244;
      --text: #cdd6f4;
      --muted: #a6adc8;
      --mauve: #cba6f7;
      --blue: #89b4fa;
      --teal: #94e2d5;
      --yellow: #f9e2af;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      min-height: 100vh;
      background: var(--bg);
      color: var(--text);
      font: 14px/1.45 "Inter", "Noto Sans", system-ui, sans-serif;
    }}
    main {{
      width: min(780px, 100vw);
      min-height: 100vh;
      padding: 22px;
      background:
        linear-gradient(135deg, rgba(137, 180, 250, 0.10), transparent 34%),
        linear-gradient(315deg, rgba(148, 226, 213, 0.08), transparent 30%),
        var(--bg);
    }}
    header {{
      display: flex;
      justify-content: space-between;
      align-items: baseline;
      gap: 16px;
      margin-bottom: 18px;
      padding-bottom: 14px;
      border-bottom: 1px solid var(--border);
    }}
    h1 {{
      margin: 0;
      font-size: 24px;
      font-weight: 750;
      letter-spacing: 0;
    }}
    time {{
      color: var(--muted);
      font-size: 12px;
      white-space: nowrap;
    }}
    .grid {{
      display: grid;
      grid-template-columns: 1.35fr 0.9fr;
      gap: 14px;
    }}
    section {{
      overflow: hidden;
      border: 1px solid var(--border);
      border-radius: 10px;
      background: color-mix(in srgb, var(--panel) 94%, transparent);
      box-shadow: 0 14px 34px rgba(0, 0, 0, 0.28);
    }}
    .wide {{ grid-column: 1 / -1; }}
    h2 {{
      margin: 0;
      padding: 12px 14px;
      background: var(--panel2);
      border-bottom: 1px solid var(--border);
      font-size: 13px;
      font-weight: 750;
      letter-spacing: 0;
    }}
    h2.codex {{ color: var(--mauve); }}
    h2.deepseek {{ color: var(--teal); }}
    pre {{
      margin: 0;
      padding: 14px;
      white-space: pre-wrap;
      overflow-wrap: anywhere;
      color: var(--text);
      font: 13px/1.55 "JetBrains Mono", "SFMono-Regular", "Cascadia Mono", monospace;
    }}
    .hint {{
      margin-top: 14px;
      color: var(--muted);
      font-size: 12px;
    }}
    @media (max-width: 720px) {{
      main {{ padding: 16px; }}
      header {{ display: block; }}
      time {{ display: block; margin-top: 6px; }}
      .grid {{ grid-template-columns: 1fr; }}
    }}
  </style>
</head>
<body>
  <main>
    <header>
      <h1>AI Usage</h1>
      <time>{escape(now.strftime("%Y-%m-%d %H:%M:%S %z"))}</time>
    </header>
    <div class="grid">
      <section class="wide">
        <h2 class="codex">Codex</h2>
        <pre>{escape(codex["tooltip"])}</pre>
      </section>
      <section class="wide">
        <h2 class="deepseek">DeepSeek</h2>
        <pre>{escape(deepseek["tooltip"])}</pre>
      </section>
    </div>
    <div class="hint">Middle or right click the Waybar module to refresh.</div>
  </main>
</body>
</html>
"""


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--detail",
        action="store_true",
        help="print plain text details for popup dialogs instead of Waybar JSON",
    )
    parser.add_argument(
        "--detail-html",
        action="store_true",
        help="print HTML details for the popup panel instead of Waybar JSON",
    )
    parser.add_argument(
        "--detail-ansi",
        action="store_true",
        help="print ANSI styled details for terminal popup panels instead of Waybar JSON",
    )
    parser.add_argument(
        "--detail-wofi",
        action="store_true",
        help="print Pango markup details for the wofi popup panel instead of Waybar JSON",
    )
    return parser.parse_args()


def main():
    args = parse_args()
    codex = read_codex_usage()
    deepseek = read_deepseek_usage()

    if args.detail:
        print(build_detail(codex, deepseek))
        return

    if args.detail_html:
        print(build_detail_html(codex, deepseek))
        return

    if args.detail_ansi:
        print(build_detail_ansi(codex, deepseek))
        return

    if args.detail_wofi:
        print(build_detail_wofi(codex, deepseek))
        return

    classes = {codex["class"], deepseek["class"]}
    css_class = "ok"
    if "critical" in classes:
        css_class = "critical"
    elif "warn" in classes:
        css_class = "warn"
    elif "unknown" in classes:
        css_class = "unknown"

    output = {
        "text": f"{codex.get('display', codex['text'])}  <span color='#6c7086'>|</span>  {deepseek.get('display', deepseek['text'])}",
        "tooltip": f"{codex['tooltip']}\n\n{deepseek['tooltip']}\n\nUpdated: {datetime.now().astimezone():%H:%M:%S}",
        "class": css_class,
    }
    write_refresh_state()
    write_text(AI_USAGE_DETAIL_TEXT, build_detail(codex, deepseek))
    write_text(AI_USAGE_DETAIL_WOFI, build_detail_wofi(codex, deepseek))
    print(json.dumps(output, ensure_ascii=False))


if __name__ == "__main__":
    main()
