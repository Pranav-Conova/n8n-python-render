FROM node:20-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    N8N_PORT=5678 \
    API_PORT=8000 \
    N8N_HOST=0.0.0.0 \
    N8N_PROTOCOL=https \
    N8N_LISTEN_ADDRESS=0.0.0.0 \
    N8N_SECURE_COOKIE=false \
    N8N_DIAGNOSTICS_ENABLED=false \
    N8N_VERSION_NOTIFICATIONS_ENABLED=false \
    N8N_TEMPLATES_ENABLED=false

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    bash \
    curl \
    tini \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g n8n

COPY requirements.txt /app/requirements.txt
RUN pip3 install --no-cache-dir -r /app/requirements.txt

COPY app.py /app/app.py
COPY start.sh /app/start.sh

RUN chmod +x /app/start.sh

EXPOSE 5678 8000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/start.sh"]
