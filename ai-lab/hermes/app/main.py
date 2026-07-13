import os
import httpx
from fastapi import FastAPI

app = FastAPI(title="Hermes Agent", version="0.1.0")

OLLAMA_URL = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
COMFYUI_URL = os.getenv("COMFYUI_URL", "http://host.docker.internal:8188")


async def _check(url: str) -> str:
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            r = await client.get(url)
            return "ok" if r.status_code < 500 else "degraded"
    except Exception:
        return "unreachable"


@app.get("/health")
async def health():
    workspace_ok = os.path.isdir("/workspace") and os.access("/workspace", os.W_OK)
    return {
        "hermes": "ok",
        "ollama": await _check(f"{OLLAMA_URL}/api/tags"),
        "qdrant": await _check(f"{QDRANT_URL}/healthz"),
        "comfyui": await _check(f"{COMFYUI_URL}/"),
        "workspace": "ok" if workspace_ok else "not writable",
    }


@app.get("/")
async def root():
    return {"message": "Hermes Agent is running. See /health for service status."}
