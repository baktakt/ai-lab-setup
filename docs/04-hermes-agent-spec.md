# 04 — Hermes Agent Specification

## 1. Role

Hermes Agent is the orchestration layer for the AI home lab.

It should be treated as a local/private AI command center that can run repeatable workflows using local models, vector search, files, image generation and optional cloud LLMs.

Hermes should not try to do everything itself. Instead, it should coordinate existing services.

```text
Hermes Agent
├── Ollama for local reasoning
├── Qdrant for semantic memory and document search
├── ComfyUI for image generation
├── Workspace files for input/output
└── Cloud APIs when quality is more important than locality
```

## 2. Primary use cases

### Research workflows

Examples:

- research a market
- summarize sources
- compare competitors
- generate opportunity areas
- score ideas
- produce a short report

### Dog Walk Ventures pipeline

Suggested workflow stages:

```text
Research
→ Validation
→ Selection
→ Service Design
→ Technical Architecture
→ Product/UX Design
→ Build/Launch
```

Hermes should help move ideas through these stages, but should also be able to kill weak ideas early.

### Furniture/startup workflows

Examples:

- research furniture e-commerce trends
- generate product page copy
- analyze customer segments
- create synthetic furniture order datasets
- produce product naming ideas
- create image prompts for concept visuals

### AI lab workflows

Examples:

- test model quality across prompts
- compare response quality between models
- generate synthetic datasets
- run RAG experiments
- summarize documents in `workspace/documents`
- export experiment reports

### Newsletter/content workflows

Examples:

- gather AI/AEC news
- summarize articles
- select top items
- create draft commentary
- generate cover image prompts
- export final draft

## 3. Interfaces

Hermes should expose:

| Interface | Purpose |
|---|---|
| Web UI | Human-friendly command center |
| HTTP API | Allow scripts/tools to trigger workflows |
| CLI optional | Quick terminal workflows |
| File watcher optional | Process files dropped into workspace folders |

## 4. Internal modules

Suggested modules:

```text
app/
├── main.py
├── config.py
├── routers/
│   ├── workflows.py
│   ├── documents.py
│   ├── models.py
│   └── health.py
├── services/
│   ├── ollama_client.py
│   ├── qdrant_client.py
│   ├── comfyui_client.py
│   ├── cloud_llm_client.py
│   └── file_store.py
├── workflows/
│   ├── research.py
│   ├── synthetic_data.py
│   ├── rag_index.py
│   ├── model_eval.py
│   └── dog_walk_pipeline.py
└── prompts/
    ├── research.md
    ├── validation.md
    ├── summarization.md
    └── scoring.md
```

## 5. Configuration

Hermes should read these environment variables:

```text
HERMES_ENV=local
OLLAMA_BASE_URL=http://ollama:11434
QDRANT_URL=http://qdrant:6333
COMFYUI_URL=http://host.docker.internal:8188
DEFAULT_CHAT_MODEL=qwen2.5-coder:14b
DEFAULT_FAST_MODEL=llama3.1:8b
DEFAULT_EMBEDDING_MODEL=nomic-embed-text
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
```

## 6. Local/cloud model routing

Suggested rule:

| Task type | Default model source |
|---|---|
| private document summarization | local |
| quick brainstorming | local |
| code/debugging | local or cloud fallback |
| important final writing | cloud fallback optional |
| large research synthesis | local first, cloud optional |
| embeddings | local embedding model |

## 7. Workspace contract

Hermes should use `/workspace` for user-facing files.

Suggested folders:

```text
/workspace/documents
/workspace/experiments
/workspace/datasets
/workspace/reports
/workspace/exports
/workspace/inbox
```

Pattern:

- User drops files into `inbox` or `documents`.
- Hermes indexes/summarizes/processes them.
- Hermes writes outputs to `reports` or `exports`.

## 8. Health checks

Hermes should provide a `/health` endpoint checking:

- Hermes web process is alive.
- Ollama reachable.
- Qdrant reachable.
- ComfyUI reachable.
- Workspace writable.

Example response:

```json
{
  "hermes": "ok",
  "ollama": "ok",
  "qdrant": "ok",
  "comfyui": "ok",
  "workspace": "ok"
}
```
