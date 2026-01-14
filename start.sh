#!/usr/bin/env bash
set -euo pipefail

# FastAPI is internal-only and stays on 8000 inside the container.
API_PORT="${API_PORT:-8000}"

# Render public port for the Web Service -> bind n8n here
N8N_PORT="${PORT:-${N8N_PORT:-5678}}"

echo "Starting Python FastAPI (internal) on :${API_PORT}..."
python3 -m uvicorn app:app --host 0.0.0.0 --port "${API_PORT}" --proxy-headers &
API_PID=$!

cleanup() {
  kill -TERM "${API_PID}" 2>/dev/null || true
  wait "${API_PID}" 2>/dev/null || true
}
trap cleanup SIGINT SIGTERM

echo "Starting n8n (public) on :${N8N_PORT}..."
export N8N_HOST="${N8N_HOST:-0.0.0.0}"
export N8N_PORT="${N8N_PORT}"
export N8N_LISTEN_ADDRESS="${N8N_LISTEN_ADDRESS:-0.0.0.0}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-http}"

# IMPORTANT: do not pass --tunnel=false (n8n expects --tunnel as a boolean flag)
exec n8n start --port "${N8N_PORT}" --host 0.0.0.0
