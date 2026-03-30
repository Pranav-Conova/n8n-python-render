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

# Some providers return IPv6 first; prefer IPv4 to avoid ENETUNREACH in IPv4-only networks.
NODE_OPTIONS_VALUE="${NODE_OPTIONS:-}"
if [[ ${NODE_OPTIONS_VALUE} == \"*\" ]]; then
  NODE_OPTIONS_VALUE="${NODE_OPTIONS_VALUE#\"}"
  NODE_OPTIONS_VALUE="${NODE_OPTIONS_VALUE%\"}"
fi
case " ${NODE_OPTIONS_VALUE} " in
  *" --dns-result-order=ipv4first "*) ;;
  *) NODE_OPTIONS_VALUE="${NODE_OPTIONS_VALUE:+${NODE_OPTIONS_VALUE} }--dns-result-order=ipv4first" ;;
esac
export NODE_OPTIONS="${NODE_OPTIONS_VALUE}"

# Backward compatibility: map legacy SSL env var name to n8n's expected one.
if [ -n "${DB_POSTGRESDB_SSL:-}" ] && [ -z "${DB_POSTGRESDB_SSL_ENABLED:-}" ]; then
  export DB_POSTGRESDB_SSL_ENABLED="${DB_POSTGRESDB_SSL}"
fi

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
