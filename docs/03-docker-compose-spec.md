# 03 — Docker Compose Specification

This file defines the intended Docker Compose stack for the AI home lab.

## 1. `docker-compose.yml`

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: ai-ollama
    restart: unless-stopped
    ports:
      - "11434:11434"
    volumes:
      - ./data/ollama:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: ai-open-webui
    restart: unless-stopped
    ports:
      - "3000:8080"
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_NAME=Hermes AI Lab
    volumes:
      - ./data/open-webui:/app/backend/data
    depends_on:
      - ollama

  qdrant:
    image: qdrant/qdrant:latest
    container_name: ai-qdrant
    restart: unless-stopped
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - ./data/qdrant:/qdrant/storage

  comfyui:
    build:
      context: ./comfyui
    container_name: ai-comfyui
    restart: unless-stopped
    ports:
      - "8188:8188"
    volumes:
      - ./data/comfyui/custom_nodes:/opt/ComfyUI/custom_nodes
      - ./data/comfyui/input:/opt/ComfyUI/input
      - ./data/comfyui/user:/opt/ComfyUI/user
      - ./models/comfyui:/opt/ComfyUI/models
      - ./output/comfyui:/opt/ComfyUI/output
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

  hermes-agent:
    build:
      context: ./hermes
      dockerfile: Dockerfile
    container_name: ai-hermes-agent
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - HERMES_ENV=local
      - OLLAMA_BASE_URL=http://ollama:11434
      - QDRANT_URL=http://qdrant:6333
      - COMFYUI_URL=http://comfyui:8188
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - DEFAULT_CHAT_MODEL=qwen2.5-coder:14b
      - DEFAULT_FAST_MODEL=llama3.1:8b
      - DEFAULT_EMBEDDING_MODEL=nomic-embed-text
    volumes:
      - ./hermes:/app
      - ./workspace:/workspace
      - ./data/hermes:/data
    depends_on:
      - ollama
      - qdrant

  home-assistant:
    image: ghcr.io/home-assistant/home-assistant:stable
    container_name: ai-home-assistant
    restart: unless-stopped
    profiles:
      - home-assistant
    network_mode: host
    privileged: true
    environment:
      - TZ=${TZ:-UTC}
    volumes:
      - ./data/home-assistant:/config
      - /run/dbus:/run/dbus:ro
    devices:
      - ${CONBEE_DEVICE:-/dev/ttyACM0}:${CONBEE_CONTAINER_DEVICE:-/dev/ttyACM0}
    group_add:
      - dialout
      - comfyui
```

## 2. `.env`

```bash
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
ENABLE_HOME_ASSISTANT=false
CONBEE_DEVICE=/dev/ttyACM0
CONBEE_CONTAINER_DEVICE=/dev/ttyACM0
TZ=UTC
```

Optional future values:

```bash
GOOGLE_API_KEY=
GITHUB_TOKEN=
NOTION_API_KEY=
SLACK_BOT_TOKEN=
```

## 3. Hermes Dockerfile placeholder

If Hermes is Python-based:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080

CMD ["python", "-m", "app.main"]
```

## 4. Suggested `requirements.txt` placeholder

```text
fastapi
uvicorn[standard]
pydantic
python-dotenv
httpx
qdrant-client
openai
anthropic
```

## 5. Startup

```bash
cd ~/ai-lab
docker compose up -d

# Optional Home Assistant profile:
docker compose --profile home-assistant up -d
```

## 6. Shutdown

```bash
cd ~/ai-lab
docker compose down
```

## 7. View logs

```bash
docker compose logs -f
```

Service-specific logs:

```bash
docker compose logs -f ollama
docker compose logs -f open-webui
docker compose logs -f comfyui
docker compose logs -f hermes-agent
docker compose logs -f qdrant
docker compose logs -f home-assistant
```

## 8. Pull starter models

```bash
docker exec -it ai-ollama ollama pull llama3.1:8b
docker exec -it ai-ollama ollama pull qwen2.5-coder:14b
docker exec -it ai-ollama ollama pull mistral-nemo
docker exec -it ai-ollama ollama pull nomic-embed-text
```

## 9. Verify GPU inside containers

```bash
docker exec -it ai-ollama nvidia-smi
```

If this fails, check:

- NVIDIA driver installed on host
- NVIDIA Container Toolkit installed
- Docker restarted after toolkit install
- Compose syntax supported by the installed Docker version
