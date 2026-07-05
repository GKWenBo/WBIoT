#!/usr/bin/env bash
# 第 1 课 · 课后练习 1：模拟温度传感器
# 每 2 秒向 wbiot/sensor/temperature 上报一条 JSON：{"value": <温度>, "ts": <时间戳>}
# 用法：./temperature_report.sh   （Ctrl+C 停止）
set -euo pipefail

HOST="127.0.0.1"   # 明确 IPv4，避免 localhost 被解析成 ::1（见第 1 课排错说明）
PORT=1883
TOPIC="wbiot/sensor/temperature"

echo "开始上报 → ${TOPIC}（Ctrl+C 停止）"

while true; do
  # 生成 22.0 ~ 28.0 之间的随机温度，模拟真实传感器的读数波动
  value=$(awk 'BEGIN { srand(); printf "%.1f", 22 + rand() * 6 }')
  ts=$(date +%s)   # 秒级 Unix 时间戳

  payload="{\"value\": ${value}, \"ts\": ${ts}}"

  mqttx pub -t "${TOPIC}" -m "${payload}" -h "${HOST}" -p "${PORT}" > /dev/null
  echo "$(date '+%H:%M:%S') 已上报: ${payload}"

  sleep 2
done
