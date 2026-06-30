# 08 — Build Roadmap

## Phase 1 — Base machine

Goal: Stable Kubuntu gaming/AI desktop.

Tasks:

- Install Kubuntu 24.04 LTS.
- Install NVIDIA proprietary driver.
- Confirm `nvidia-smi` works.
- Install Steam and test a game.
- Install SSH and Tailscale.
- Upgrade RAM to 64GB if not already done.
- Confirm thermals under GPU load.

Success criteria:

```text
Desktop works
GPU driver works
Games launch
Remote access works
Thermals acceptable
```

## Phase 2 — Docker and GPU containers

Goal: Docker can access the RTX 3090.

Tasks:

- Install Docker Engine.
- Install NVIDIA Container Toolkit.
- Test GPU in a container.
- Create `~/ai-lab` folder structure.
- Add `docker-compose.yml` and `.env`.

Success criteria:

```text
docker compose up -d works
Ollama starts
Container can run nvidia-smi
```

## Phase 3 — Local LLM stack

Goal: Local chat models working.

Tasks:

- Start Ollama.
- Pull starter models.
- Start Open WebUI.
- Connect Open WebUI to Ollama.
- Test chat with local models.

Starter models:

```text
llama3.1:8b
qwen2.5-coder:14b
mistral-nemo
nomic-embed-text
```

Success criteria:

```text
Open WebUI works
Local models respond
GPU usage visible in nvidia-smi
```

## Phase 4 — Vector search/RAG

Goal: Qdrant available for document experiments.

Tasks:

- Start Qdrant.
- Create test collection.
- Build small indexing script or Hermes workflow.
- Index files from `workspace/documents`.
- Query semantic search results.

Success criteria:

```text
Documents can be embedded
Qdrant stores vectors
Hermes or script can retrieve relevant chunks
```

## Phase 5 — Image generation

Goal: ComfyUI working locally.

Tasks:

- Start ComfyUI.
- Add model/checkpoint files.
- Run simple workflow.
- Test output folder.
- Add useful workflows for newsletter/product imagery.

Success criteria:

```text
ComfyUI UI loads
Workflow runs on RTX 3090
Generated images saved to output folder
```

## Phase 6 — Hermes Agent MVP

Goal: Hermes can orchestrate useful local workflows.

MVP workflows:

1. Health check all services.
2. Summarize a document from `/workspace/documents`.
3. Run a local LLM prompt through Ollama.
4. Store/retrieve embeddings through Qdrant.
5. Export a markdown report.

Success criteria:

```text
Hermes UI loads
Hermes talks to Ollama
Hermes talks to Qdrant
Hermes writes files to workspace
```

## Phase 7 — Personal workflows

Goal: Turn the lab into a practical daily tool.

Candidate workflows:

- Dog Walk Ventures idea research.
- Furniture market/product concept research.
- AI/AEC newsletter draft generation.
- Synthetic data generation.
- Local model evaluation.
- Document Q&A.
- Product brief creation.

Success criteria:

```text
At least 3 repeatable workflows save real time
Outputs are easy to inspect and edit
Workflow inputs/outputs are stored clearly
```

## Phase 8 — Polish

Goal: Make the system easy to use and maintain.

Tasks:

- Add desktop shortcuts for AI mode and gaming mode.
- Add status dashboard.
- Add backup routine.
- Add simple auth for Hermes.
- Add model usage notes.
- Add update checklist.

Success criteria:

```text
Easy to start
Easy to stop
Easy to troubleshoot
Easy to recover after updates
```
