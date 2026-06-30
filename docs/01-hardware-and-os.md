# 01 — Hardware and Operating System Specification

## 1. Target machine

The target machine is a reused/refurbished gaming workstation with an **RTX 3090 24GB**. This is well suited for local AI because VRAM is usually the main limiter when running local LLMs and image models.

Example target configuration:

| Component | Example spec | Notes |
|---|---:|---|
| GPU | RTX 3090 24GB | Main reason to buy/build the machine |
| CPU | Intel i7-9700K or similar | Fine for GPU-based inference; older but usable |
| RAM | 16GB included | Upgrade to 64GB recommended |
| Storage | 1TB SSD + 500GB SSD | OK to start; 2TB+ preferred |
| PSU | 850W Gold | Good match for RTX 3090 |
| Case | Airflow-focused gaming case | Important for RTX 3090 thermals |

## 2. Recommended upgrades

### RAM

Recommended upgrade:

```text
64GB DDR4
```

Why:

- Docker services need host RAM.
- Open WebUI, Qdrant, ComfyUI, browsers and dev tools all add overhead.
- Large datasets and RAG workflows benefit from RAM.
- Some models can partially offload or require system memory during load.

### Storage

Preferred final storage:

```text
2TB NVMe/SSD minimum
4TB nice-to-have
```

Suggested split:

| Purpose | Size |
|---|---:|
| OS/apps | 500GB–1TB |
| Docker data | 1TB+ |
| Models/checkpoints | 1TB+ |
| Workspace/datasets | As needed |

### Cooling

RTX 3090 cards can run hot, especially memory junction temperature. Prefer:

- mesh front case
- at least 2 front intake fans
- at least 1 rear exhaust fan
- clean cable routing
- regular dust cleaning

## 3. Operating system

Recommended OS:

```text
Kubuntu 24.04 LTS
```

Why Kubuntu:

- Ubuntu base works well with NVIDIA/CUDA/AI tooling.
- KDE desktop is pleasant for daily use and gaming.
- Good compromise between desktop/gaming and server-like AI use.
- Supports Docker, Steam, Proton, development tools and remote access.

## 4. Host-level software

Install on the host:

```text
NVIDIA proprietary driver
Docker Engine
NVIDIA Container Toolkit
Git
curl
htop / btop
nvtop
Tailscale
OpenSSH Server
Steam
VS Code or Cursor
```

Avoid installing heavy AI frameworks directly on the host unless necessary. Prefer containers.

## 5. BIOS/firmware settings

Recommended checks:

- Enable XMP/DOCP for RAM speed.
- Enable Above 4G Decoding if available.
- Keep Resize BAR enabled if stable.
- Ensure fans are not set to silent-only curves.
- Update BIOS only if needed; do not update firmware casually on a stable system.

## 6. Partitioning suggestion

Simple layout:

```text
/                 main OS partition
/home             user data and ai-lab folder
swap              optional, or swapfile
```

For simplicity, keep Docker data inside `~/ai-lab/data` rather than relying only on default Docker volumes. This makes backups and migration easier.
