# Hermes AI Home Lab Specification

**Version:** 1.0  
**Target machine:** RTX 3090 24GB AI/gaming workstation  
**Target OS:** Kubuntu 24.04 LTS  
**Primary use cases:** local AI experimentation, Hermes Agent workflows, document/RAG experiments, image generation, coding, gaming

---

## 1. Goal

Build a single-machine AI home lab that can act as both:

1. A **gaming desktop** running Kubuntu, Steam and Proton.
2. A **local AI lab** running LLMs, image generation, vector search and agent workflows.
3. A **Hermes Agent command center** for research, automation, synthetic data generation, product validation and local/private AI experiments.

The setup should be powerful enough for serious hobby/prototype work, but simple enough to maintain without turning into a fragile enterprise stack.

---

## 2. Design principles

- Keep the base OS boring and stable.
- Use containers for most AI tools.
- Avoid installing random AI Python dependencies directly on the host.
- Prioritize NVIDIA/CUDA compatibility.
- Make it easy to switch between **AI mode** and **gaming mode**.
- Use local models where privacy, cost or experimentation matters.
- Allow optional cloud fallback for higher-quality reasoning.
- Store persistent data in clear local folders.
- Make the setup understandable and recoverable.

---

## 3. Core stack

| Layer | Choice | Purpose |
|---|---|---|
| OS | Kubuntu 24.04 LTS | Ubuntu base + KDE desktop for gaming/daily use |
| GPU | NVIDIA RTX 3090 24GB | Main acceleration for LLM/image workloads |
| Container runtime | Docker Engine | Runs AI services cleanly |
| GPU container support | NVIDIA Container Toolkit | Gives Docker access to the GPU |
| Local LLM server | Ollama | Downloads and serves local models |
| Chat UI | Open WebUI | Browser UI for local models |
| Vector database | Qdrant | Embeddings, semantic memory and RAG |
| Image generation UI | ComfyUI | Node-based image generation workflows |
| Agent layer | Hermes Agent | Personal workflow/orchestration layer |
| Remote access | SSH + Tailscale | Safe remote access from other devices |
| Gaming | Steam + Proton | Linux gaming layer |

---

## 4. Recommended hardware baseline

| Component | Recommended minimum | Preferred |
|---|---:|---:|
| GPU | RTX 3090 24GB | RTX 3090/4090/5090 class depending budget |
| VRAM | 24GB | 24GB+ |
| CPU | 8 cores | 8–16 cores |
| RAM | 32GB | 64GB |
| Storage | 1TB SSD | 2TB+ NVMe/SSD |
| PSU | 850W quality PSU | 850–1000W quality PSU |
| Cooling | Good airflow case | Mesh case with strong intake/exhaust |

For the discussed Reuseit-style system, the first recommended upgrade is **64GB RAM**.

---

## 5. Main user interfaces

| UI | URL | Main role |
|---|---|---|
| Open WebUI | `http://localhost:3000` | Chat with local models |
| ComfyUI | `http://localhost:8188` | Image generation workflows |
| Hermes Agent UI | `http://localhost:8080` | Run agents and custom workflows |
| Qdrant dashboard/API | `http://localhost:6333` | Vector database/API |
| Ollama API | `http://localhost:11434` | LLM API endpoint |

---

## 6. Repository/file layout

Suggested folder:

```text
~/ai-lab/
├── docker-compose.yml
├── .env
├── README.md
├── hermes/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── app/
├── scripts/
│   ├── ai-start.sh
│   ├── ai-stop.sh
│   ├── ai-status.sh
│   ├── gaming-mode.sh
│   └── pull-models.sh
├── data/
│   ├── ollama/
│   ├── open-webui/
│   ├── qdrant/
│   └── hermes/
├── models/
│   └── comfyui/
├── output/
│   └── comfyui/
└── workspace/
    ├── documents/
    ├── experiments/
    ├── datasets/
    └── exports/
```

---

## 7. Included specification files

- `README.md` — overview and stack summary.
- `01-hardware-and-os.md` — hardware assumptions and OS plan.
- `02-architecture.md` — service architecture and responsibilities.
- `03-docker-compose-spec.md` — full Docker Compose stack and environment files.
- `04-hermes-agent-spec.md` — role and expected capabilities of Hermes Agent.
- `05-operations.md` — daily operations, scripts, model pulling and maintenance.
- `06-gaming-and-ai-mode.md` — switching between gaming and AI workloads.
- `07-security-and-networking.md` — local access, Tailscale, secrets and backups.
- `08-roadmap.md` — suggested phased build plan.

---

## 8. Quick start summary

```bash
mkdir -p ~/ai-lab
cd ~/ai-lab

# Add docker-compose.yml and .env
# Then start the stack:
docker compose up -d

# Pull starter models:
docker exec -it ai-ollama ollama pull llama3.1:8b
docker exec -it ai-ollama ollama pull qwen2.5-coder:14b
docker exec -it ai-ollama ollama pull nomic-embed-text
```

Then open:

```text
Open WebUI: http://localhost:3000
ComfyUI:    http://localhost:8188
Hermes:     http://localhost:8080
```
