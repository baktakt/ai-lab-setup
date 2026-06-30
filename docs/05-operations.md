# 05 — Operations Specification

## 1. Daily startup

From the host:

```bash
cd ~/ai-lab
docker compose up -d
```

Open:

```text
Open WebUI: http://localhost:3000
ComfyUI:    http://localhost:8188
Hermes:     http://localhost:8080
```

## 2. Daily shutdown

```bash
cd ~/ai-lab
docker compose down
```

## 3. Suggested scripts

Create folder:

```bash
mkdir -p ~/ai-lab/scripts
```

### `scripts/ai-start.sh`

```bash
#!/usr/bin/env bash
set -e
cd ~/ai-lab
docker compose up -d
```

### `scripts/ai-stop.sh`

```bash
#!/usr/bin/env bash
set -e
cd ~/ai-lab
docker compose down
```

### `scripts/ai-status.sh`

```bash
#!/usr/bin/env bash
cd ~/ai-lab
docker compose ps
nvidia-smi
```

### `scripts/gaming-mode.sh`

```bash
#!/usr/bin/env bash
set -e
cd ~/ai-lab
docker compose stop comfyui ollama hermes-agent open-webui
nvidia-smi
```

### `scripts/pull-models.sh`

```bash
#!/usr/bin/env bash
set -e

docker exec -it ai-ollama ollama pull llama3.1:8b
docker exec -it ai-ollama ollama pull qwen2.5-coder:14b
docker exec -it ai-ollama ollama pull mistral-nemo
docker exec -it ai-ollama ollama pull nomic-embed-text
```

Make scripts executable:

```bash
chmod +x ~/ai-lab/scripts/*.sh
```

## 4. Model management

List installed Ollama models:

```bash
docker exec -it ai-ollama ollama list
```

Run a model directly:

```bash
docker exec -it ai-ollama ollama run llama3.1:8b
```

Remove a model:

```bash
docker exec -it ai-ollama ollama rm model-name
```

## 5. Logs

All logs:

```bash
cd ~/ai-lab
docker compose logs -f
```

Specific service:

```bash
docker compose logs -f ollama
docker compose logs -f open-webui
docker compose logs -f comfyui
docker compose logs -f hermes-agent
docker compose logs -f qdrant
```

## 6. Updating containers

```bash
cd ~/ai-lab
docker compose pull
docker compose up -d
```

If using local Hermes build:

```bash
docker compose build hermes-agent
docker compose up -d hermes-agent
```

## 7. Backups

Important folders to back up:

```text
~/ai-lab/docker-compose.yml
~/ai-lab/.env, excluding secrets if storing externally
~/ai-lab/hermes
~/ai-lab/data/open-webui
~/ai-lab/data/qdrant
~/ai-lab/data/hermes
~/ai-lab/workspace
```

Optional but large:

```text
~/ai-lab/data/ollama
~/ai-lab/models/comfyui
~/ai-lab/output/comfyui
```

Models can often be re-downloaded, so they do not always need full backup.

## 8. Health troubleshooting

### GPU not visible in containers

Check host:

```bash
nvidia-smi
```

Check container:

```bash
docker exec -it ai-ollama nvidia-smi
```

If container check fails:

- reinstall/check NVIDIA Container Toolkit
- restart Docker
- check Docker Compose device reservation syntax

### Open WebUI cannot reach Ollama

Check that Open WebUI has:

```text
OLLAMA_BASE_URL=http://ollama:11434
```

Then restart:

```bash
docker compose restart open-webui
```

### ComfyUI slow or failing

Possible causes:

- insufficient VRAM
- too large model/workflow
- missing model files
- AI services competing for GPU with Ollama

Try:

```bash
docker compose stop ollama open-webui hermes-agent
```

Then rerun the ComfyUI workflow.
