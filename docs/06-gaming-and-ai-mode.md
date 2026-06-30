# 06 — Gaming and AI Mode Specification

## 1. Problem

The machine uses the same RTX 3090 for:

- AI inference
- image generation
- desktop rendering
- gaming

Large AI models can occupy VRAM and reduce gaming performance or prevent games from launching correctly.

## 2. Modes

### AI mode

Use when running local AI tools.

Services running:

```text
ollama
open-webui
qdrant
comfyui
hermes-agent
```

Good for:

- local LLMs
- RAG experiments
- ComfyUI
- Hermes workflows
- synthetic data generation
- document summarization

### Gaming mode

Use before launching games.

Services stopped:

```text
ollama
open-webui
comfyui
hermes-agent
```

Can keep running:

```text
qdrant
```

But simplest is to stop all heavy AI services.

Command:

```bash
cd ~/ai-lab
docker compose stop comfyui ollama hermes-agent open-webui
```

### Mixed mode

Possible if you only need light AI in the background.

Services running:

```text
qdrant
open-webui optional
ollama optional with small model only
```

Avoid:

- ComfyUI rendering while gaming
- large LLMs loaded during gaming

## 3. Gaming software

Install on Kubuntu host:

```text
Steam
Proton
MangoHud optional
CoreCtrl optional
```

Before relying on Linux gaming, check must-play games for anti-cheat compatibility.

## 4. Recommended scripts

### `gaming-mode.sh`

```bash
#!/usr/bin/env bash
set -e
cd ~/ai-lab

echo "Stopping heavy AI services..."
docker compose stop comfyui ollama hermes-agent open-webui

echo "Current GPU status:"
nvidia-smi

echo "Gaming mode ready."
```

### `ai-mode.sh`

```bash
#!/usr/bin/env bash
set -e
cd ~/ai-lab

echo "Starting AI services..."
docker compose up -d

echo "Current status:"
docker compose ps
nvidia-smi
```

## 5. Practical workflow

Before AI session:

```bash
~/ai-lab/scripts/ai-mode.sh
```

Before gaming:

```bash
~/ai-lab/scripts/gaming-mode.sh
```

After gaming, restart AI mode when needed.

## 6. VRAM expectations

RTX 3090 has 24GB VRAM. That is strong for local AI, but not infinite.

Approximate pressure:

| Workload | VRAM pressure |
|---|---:|
| 7B/8B quantized LLM | low/medium |
| 14B quantized LLM | medium |
| 30B+ quantized LLM | high |
| SDXL/Flux image workflow | medium/high |
| Game at high settings | medium/high |
| AI + gaming at same time | risky |

## 7. Recommendation

Treat gaming and serious AI work as separate modes. Do not try to run big image generation or large LLM inference during gaming unless experimenting.
