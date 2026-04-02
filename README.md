# n8n-python-render

Deploy [n8n](https://n8n.io) on [Render](https://render.com) alongside a FastAPI Python sidecar for running arbitrary Python/shell commands from n8n workflows.

## Architecture

| Service | Internal port | Purpose |
|---------|--------------|---------|
| n8n | `$PORT` (Render assigns this) | Workflow automation UI & webhook engine |
| FastAPI | `8000` (container-internal only) | Python command-runner sidecar |

Render routes all public HTTPS traffic to n8n on `$PORT`.  
The FastAPI sidecar is reachable inside the container at `http://localhost:8000`.

## Quick deploy

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

1. Click the button above, or create a new **Web Service** on Render pointed at this repo.
2. Select **Docker** as the runtime.
3. Set the required environment variables listed below.
4. Deploy.

## Environment variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `N8N_ENCRYPTION_KEY` | **Yes** | — | Strong random string used to encrypt saved credentials. Generate with `openssl rand -hex 32`. **Must remain the same across all restarts and redeploys** — changing it makes existing credentials unreadable (login fails). |
| `N8N_PROTOCOL` | No | `https` | Protocol used in generated URLs (`https` for Render). |
| `N8N_SECURE_COOKIE` | No | `false` | Set to `false` so session cookies work when Render terminates TLS before reaching the container. |
| `WEBHOOK_URL` | No | auto-detected from `RENDER_EXTERNAL_URL` | Override the base URL used for webhook endpoints. |
| `N8N_EDITOR_BASE_URL` | No | auto-detected from `RENDER_EXTERNAL_URL` | Override the base URL used for the n8n editor. |

### Persistent storage (recommended)

By default n8n uses SQLite stored on the container's **ephemeral filesystem** — because Render's container filesystem is not persisted, **all workflows, credentials, and execution history are lost on every redeploy**.

To persist data you have two options:

**Option A – Render PostgreSQL (recommended for production)**  
Provision a Render PostgreSQL database and set:

| Variable | Value |
|----------|-------|
| `DB_TYPE` | `postgresdb` |
| `DB_POSTGRESDB_HOST` | from your Render database |
| `DB_POSTGRESDB_PORT` | `5432` |
| `DB_POSTGRESDB_DATABASE` | from your Render database |
| `DB_POSTGRESDB_USER` | from your Render database |
| `DB_POSTGRESDB_PASSWORD` | from your Render database |
| `DB_POSTGRESDB_SSL_ENABLED` | `true` |

See `render.yaml` for a ready-made configuration with a linked database (commented out by default).

**Option B – Render Persistent Disk**  
Attach a [Render Persistent Disk](https://render.com/docs/disks) mounted at `/home/node/.n8n` to keep the default SQLite database across redeploys without any extra configuration. The `render.yaml` blueprint in this repo already includes this disk definition (requires a paid Render instance type).

## FastAPI sidecar (`/run` endpoint)

The Python sidecar exposes a single endpoint that n8n workflows can call via an HTTP Request node:

```
POST http://localhost:8000/run
Content-Type: application/json

{
  "command": "python3 my_script.py",
  "timeout": 60
}
```

Response:

```json
{
  "command": "python3 my_script.py",
  "returncode": 0,
  "stdout": "...",
  "stderr": ""
}
```

## Local development

```bash
docker build -t n8n-python-render .
docker run --rm -p 5678:5678 -p 8000:8000 \
  -e N8N_ENCRYPTION_KEY=changeme \
  -e N8N_SECURE_COOKIE=false \
  -v n8n_data:/home/node/.n8n \
  n8n-python-render
```

> **Note:** The `-v n8n_data:/home/node/.n8n` mount persists n8n data (credentials, workflows) between `docker run` invocations. Replace `changeme` with a real secret generated via `openssl rand -hex 32`, and use the same `N8N_ENCRYPTION_KEY` value every time — changing it makes stored credentials unreadable.

Open <http://localhost:5678> to access n8n.