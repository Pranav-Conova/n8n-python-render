#!/usr/bin/env bash
set -euo pipefail

# FastAPI is internal-only and stays on 8000 inside the container.
API_PORT="${API_PORT:-8000}"

# Render assigns the public port via $PORT; fall back to the default n8n port.
N8N_PORT="${PORT:-5678}"
export N8N_PORT

# Propagate remaining n8n settings from environment (Dockerfile defaults apply).
export N8N_HOST="${N8N_HOST:-0.0.0.0}"
export N8N_LISTEN_ADDRESS="${N8N_LISTEN_ADDRESS:-0.0.0.0}"
export N8N_PROTOCOL="${N8N_PROTOCOL:-https}"
export N8N_SECURE_COOKIE="${N8N_SECURE_COOKIE:-false}"

# N8N_ENCRYPTION_KEY must be a stable, operator-supplied secret.
# n8n uses this key to encrypt/decrypt saved credentials; if it changes
# between restarts all stored credentials become unreadable, causing
# "Wrong username or password" errors on login.
if [ -z "${N8N_ENCRYPTION_KEY:-}" ]; then
  echo "ERROR: N8N_ENCRYPTION_KEY is not set. Set a fixed random secret in your" >&2
  echo "       deployment environment and never change it after first deploy." >&2
  echo "       Generate one with: openssl rand -hex 32" >&2
  exit 1
fi
export N8N_ENCRYPTION_KEY

# If Render provides the public URL, use it so webhook URLs are correct.
if [ -n "${RENDER_EXTERNAL_URL:-}" ]; then
  export WEBHOOK_URL="${RENDER_EXTERNAL_URL}"
  export N8N_EDITOR_BASE_URL="${RENDER_EXTERNAL_URL}"
fi

echo "Starting Python FastAPI (internal) on :${API_PORT}..."
python3 -m uvicorn app:app --host 0.0.0.0 --port "${API_PORT}" --proxy-headers &
API_PID=$!

cleanup() {
  kill -TERM "${API_PID}" 2>/dev/null || true
  wait "${API_PID}" 2>/dev/null || true
}
trap cleanup SIGINT SIGTERM

echo "Starting n8n (public) on :${N8N_PORT}..."
exec n8n start
