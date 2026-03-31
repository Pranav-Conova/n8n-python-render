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

The included `render.yaml` now defines all required n8n, auth, and PostgreSQL variables for this deployment (including host/port/protocol, webhook/editor URLs, telemetry flags, and Neon Postgres settings).

If you run locally without Render, set at least:

| Variable | Required | Description |
|----------|----------|-------------|
| `N8N_ENCRYPTION_KEY` | **Yes** | Credential encryption key used by n8n. |
| `N8N_HOST` | No | Defaults to `0.0.0.0`. |
| `N8N_PORT` or `PORT` | No | Defaults to `5678`. |
| `N8N_PROTOCOL` | No | Defaults to `https`. |

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
Attach a [Render Persistent Disk](https://render.com/docs/disks) mounted at `/root/.n8n` to keep the default SQLite database across redeploys without any extra configuration.

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
  n8n-python-render
```

Open <http://localhost:5678> to access n8n.
