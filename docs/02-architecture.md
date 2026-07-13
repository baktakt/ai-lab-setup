# 02 — Architecture Specification

## 1. High-level architecture

```text
User
├── Open WebUI
│   └── talks to Ollama for local chat models
│
├── ComfyUI
│   └── runs image generation workflows on the GPU
│
└── Hermes Agent UI
    ├── talks to Ollama for local reasoning
    ├── talks to Qdrant for vector search and memory
    ├── talks to ComfyUI for image generation jobs
    ├── can optionally call cloud LLMs
    └── reads/writes files in the workspace
```

## 2. Service responsibilities

### Ollama

Purpose:

- Download local LLMs.
- Serve local models over an HTTP API.
- Run GPU-accelerated inference on the RTX 3090.

Used by:

- Open WebUI
- Hermes Agent
- scripts and experiments

### Open WebUI

Purpose:

- ChatGPT-like browser interface.
- Test and compare local models.
- Provide a friendly UI for family/team use.
- Optional document chat and local assistant workflows.

Used for:

- daily local chat
- model testing
- quick prototyping

### Qdrant

Purpose:

- Vector database for embeddings.
- Semantic search over documents.
- Long-term project memory.
- Retrieval-augmented generation workflows.

Used by:

- Hermes Agent
- future RAG pipelines
- document indexing scripts

### ComfyUI

Purpose:

- Local image generation.
- Node-based image workflows.
- SDXL/Flux/image-to-image/upscaling workflows.
- Product concepts, newsletter images, visual experiments.

Used by:

- user directly through browser
- Hermes Agent through API/workflow triggers

### Hermes Agent

Purpose:

- Local AI command center.
- Workflow orchestration.
- Agentic workflows for research, validation and automation.
- Connects local models, vector memory, image generation and files.

Hermes should not replace Open WebUI or ComfyUI. It should orchestrate them.

## 3. Network topology

Ollama, Open WebUI, Qdrant, Hermes and Portainer run on a Docker network.
ComfyUI runs directly on the host in a Python virtual environment managed by a
systemd user service. Hermes reaches it through Docker's private host gateway.

Internal service names:

```text
ollama:11434
open-webui:8080
qdrant:6333
host.docker.internal:8188 (ComfyUI, from Hermes)
hermes-agent:8080
```

Host ports:

```text
localhost:11434 → Ollama
localhost:3000  → Open WebUI
localhost:6333  → Qdrant
localhost:8188  → ComfyUI host service
localhost:9119  → Hermes Agent dashboard
```

## 4. Data persistence

Persistent data is mounted into local folders:

```text
./data/ollama       Ollama models and settings
./data/open-webui   Open WebUI database and uploads
./data/qdrant       Qdrant vector storage
./data/hermes       Hermes internal data
./models/comfyui    Image model/checkpoint storage
./output/comfyui    Generated images
./workspace         Shared working files
```

## 5. GPU sharing model

The RTX 3090 is shared between:

- Ollama
- ComfyUI on the host
- possibly Hermes, if Hermes runs local ML directly
- games through the desktop session

Because VRAM is finite, there should be clear operating modes:

```text
AI mode      → AI services running
Gaming mode  → heavy AI services stopped
Mixed mode   → lightweight AI services only
```

## 6. Model strategy

Use Ollama for simple model management first.

Recommended starter models:

```text
llama3.1:8b
qwen2.5-coder:14b
mistral-nemo
nomic-embed-text
```

Later additions:

```text
larger quantized models
vLLM
llama.cpp server
specialized code models
specialized embedding/reranking models
```
