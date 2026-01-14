#!/usr/bin/env bash
set -euo pipefail

API_PORT="${API_PORT:-8000}"
N8N_PORT="${N8N_PORT:-5678}"

# Render sets PORT for the external web service. We keep FastAPI on API_PORT (default 8000).
# n8n remains on N8N_PORT (default 5678).
export N8N_HOST="${N8N_HOST:-0.0.0.0}"
export N8N_PORT="${N8N_PORT}"
export N8N_LISTEN_ADDRESS="${N8N_LISTEN_ADDRESS:-0.0.0.0}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-http}"
export N8N_DIAGNOSTICS_ENABLED="${N8N_DIAGNOSTICS_ENABLED:-false}"
export N8N_VERSION_NOTIFICATIONS_ENABLED="${N8N_VERSION_NOTIFICATIONS_ENABLED:-false}"
export N8N_TEMPLATES_ENABLED="${N8N_TEMPLATES_ENABLED:-false}"

python3 -m uvicorn app:app --host 0.0.0.0 --port "${API_PORT}" --proxy-headers &
API_PID=$!

n8n start --tunnel=false --port "${N8N_PORT}" --host 0.0.0.0 &
N8N_PID=$!

cleanup() {
  kill -TERM "${API_PID}" "${N8N_PID}" 2>/dev/null || true
  wait "${API_PID}" "${N8N_PID}" 2>/dev/null || true
}
trap cleanup SIGINT SIGTERM EXIT

wait -n "${API_PID}" "${N8N_PID}"
exit $?
