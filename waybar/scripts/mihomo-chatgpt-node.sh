#!/usr/bin/env bash

# mihomo external-controller
CTRL="${MIHOMO_CTRL:-http://127.0.0.1:9191}"

# 如果 mihomo 配置里有 secret，可以：
# export MIHOMO_SECRET="xxxx"
SECRET="${MIHOMO_SECRET:-}"

# 需要识别的 ChatGPT/OpenAI 相关域名
DOMAIN_RE='chatgpt\.com|openai\.com|oaistatic\.com|oaiusercontent\.com|statsigapi\.net'

AUTH_ARGS=()
if [[ -n "$SECRET" ]]; then
  AUTH_ARGS=(-H "Authorization: Bearer $SECRET")
fi

json="$(
  curl -s --max-time 1 "${AUTH_ARGS[@]}" "$CTRL/connections"
)"

if [[ -z "$json" || "$json" == "Unauthorized" ]]; then
  jq -cn --arg text "󰖪 mihomo?" \
    --arg tooltip "无法访问 mihomo API：$CTRL/connections。检查 external-controller / secret。" \
    '{text:$text, tooltip:$tooltip, class:"error"}'
  exit 0
fi

result="$(
  jq -r --arg re "$DOMAIN_RE" '
    .connections // []
    | map(
        . as $c
        | ($c.metadata.host // $c.metadata.destinationIP // "") as $host
        | select($host | test($re; "i"))
        | {
            host: ($c.metadata.host // "-"),
            ip: ($c.metadata.destinationIP // "-"),
            rule: ($c.rule // "-"),
            payload: ($c.rulePayload // "-"),
            chains: (($c.chains // []) | join(" -> ")),
            node: (($c.chains // []) | last // "-"),
            process: ($c.metadata.process // "-")
          }
      )
    | .[0] // empty
    | @base64
  ' <<<"$json"
)"

if [[ -z "$result" ]]; then
  jq -cn --arg text "󰖪 ChatGPT: -" \
    --arg tooltip "当前没有检测到 chatgpt.com / openai.com 连接。打开或刷新 ChatGPT 页面后再看。" \
    '{text:$text, tooltip:$tooltip, class:"idle"}'
  exit 0
fi

decode() {
  echo "$result" | base64 -d | jq -r "$1"
}

host="$(decode '.host')"
ip="$(decode '.ip')"
rule="$(decode '.rule')"
payload="$(decode '.payload')"
chains="$(decode '.chains')"
node="$(decode '.node')"
process="$(decode '.process')"

# Waybar 正文尽量短

chain_prefix="$(
  printf '%s\n' "$chains" |
    sed 's/[[:space:]]*家宽.*//'
)"

# 如果提取失败，回退到 node
if [[ -z "$chain_prefix" ]]; then
  chain_prefix="$node"
fi

text="${chain_prefix}"

tooltip="$(
  cat <<EOF
Host: ${host}
IP: ${ip}
Rule: ${rule}
Payload: ${payload}
Chains: ${chains}
Process: ${process}
EOF
)"

jq -cn \
  --arg text "$text" \
  --arg tooltip "$tooltip" \
  --arg node "$node" \
  '{
    text: $text,
    tooltip: $tooltip,
    class: (if $node == "-" then "idle" else "active" end)
  }'
