# 07 — Security and Networking Specification

## 1. Default security stance

This is a home lab. Keep it private by default.

Recommended rule:

```text
Expose services only to localhost/LAN/Tailscale, not the public internet.
```

Do not port-forward Open WebUI, ComfyUI, Qdrant, Ollama or Hermes directly to the internet.

## 2. Local access

Local URLs:

```text
http://localhost:3000  Open WebUI
http://localhost:8188  ComfyUI
http://localhost:8080  Hermes Agent
http://localhost:6333  Qdrant
http://localhost:11434  Ollama
```

From another device on the same LAN, use the machine IP:

```text
http://<machine-ip>:3000
```

## 3. Remote access

Recommended:

```text
Tailscale
```

Use Tailscale to access the machine remotely without opening public ports.

Suggested remote pattern:

```text
Laptop/phone → Tailscale → AI home lab
```

## 4. SSH

Install OpenSSH server:

```bash
sudo apt install openssh-server
```

Recommended:

- use SSH keys
- disable password login later if comfortable
- do not expose SSH publicly without a VPN/Tailscale

## 5. Secrets

Store secrets in `.env`:

```bash
OPENAI_API_KEY=
ANTHROPIC_API_KEY=
```

Do not commit `.env` to Git.

Use `.gitignore`:

```gitignore
.env
data/
models/
output/
workspace/private/
```

## 6. Service authentication

Minimum recommendations:

| Service | Recommendation |
|---|---|
| Open WebUI | Use login/auth if used by multiple people |
| ComfyUI | Keep LAN/Tailscale only; add auth if exposed |
| Hermes | Add login/auth before storing sensitive workflows |
| Qdrant | Do not expose publicly |
| Ollama | Do not expose publicly |

## 7. Data privacy

Local-only work is suitable for:

- private documents
- early product ideas
- business experiments
- synthetic data generation
- internal notes

But be careful with optional cloud fallback. Hermes should clearly separate:

```text
local-only workflows
cloud-allowed workflows
```

## 8. Backups

Recommended backup approach:

- Back up `workspace`, `hermes`, `data/qdrant`, `data/open-webui`, `data/hermes`.
- Avoid backing up huge model folders unless needed.
- Keep a copy of `docker-compose.yml` and this specification.

## 9. Update policy

Use a conservative update rhythm:

```text
OS security updates: regular
Docker images: manual when needed
GPU drivers: update only when stable/needed
ComfyUI/custom nodes: update carefully
Hermes: version-controlled
```

## 10. Public exposure warning

Do not expose these directly to the public internet:

```text
Ollama API
Qdrant API
ComfyUI
Open WebUI without auth
Hermes without auth
```

If public access is needed later, use:

- VPN/Tailscale
- reverse proxy with HTTPS
- authentication
- firewall rules
- service-specific auth
