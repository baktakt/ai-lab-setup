#!/usr/bin/env bash
# =============================================================================
# Apex Lab — AI Lab Setup Script
#
# Installs the full AI lab stack on Kubuntu 24.04 LTS with an NVIDIA GPU.
# Safe to re-run: checks before installing, upgrades what's already there.
#
# Usage:
#   bash setup.sh              # interactive (prompts for install path)
#   INSTALL_DIR=~/mylab bash setup.sh   # non-interactive
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_LAB_SRC="$REPO_DIR/ai-lab"
DEFAULT_INSTALL_DIR="$HOME/ai-lab"
DEFAULT_HERMES_WORKSPACE_DIR="$HOME/workspace"
DEFAULT_COMFYUI_ROOT="$HOME/.local/share/comfyui"
INSTALL_DIR="${INSTALL_DIR:-}"  # can be pre-set via env var
HERMES_WORKSPACE_DIR="${HERMES_WORKSPACE_DIR:-}"  # can be pre-set via env var
COMFYUI_ROOT="${COMFYUI_ROOT:-$DEFAULT_COMFYUI_ROOT}"
PYPI_INDEX_URL="${PYPI_INDEX_URL:-https://pypi.org/simple}"
PYTORCH_INDEX_URL="${PYTORCH_INDEX_URL:-https://download.pytorch.org/whl/cu130}"
INSTALL_HOME_ASSISTANT="${INSTALL_HOME_ASSISTANT:-}"  # true/false
CONBEE_DEVICE="${CONBEE_DEVICE:-/dev/ttyACM0}"
CONBEE_CONTAINER_DEVICE="${CONBEE_CONTAINER_DEVICE:-/dev/ttyACM0}"
TZ_VALUE="${TZ_VALUE:-UTC}"

log()     { echo -e "${GREEN}[setup]${NC} $1"; }
warn()    { echo -e "${YELLOW}[warn]${NC}  $1"; }
error()   { echo -e "${RED}[error]${NC} $1"; exit 1; }
section() { echo -e "\n${BLUE}${BOLD}══════════════════════════════════════${NC}"; \
            echo -e "${BLUE}${BOLD}  $1${NC}"; \
            echo -e "${BLUE}${BOLD}══════════════════════════════════════${NC}"; }
step()    { echo -e "  ${BOLD}→${NC} $1"; }

generate_secret() {
  if command -v openssl &>/dev/null; then
    openssl rand -base64 24 | tr '+/' '-_' | tr -d '='
  else
    date +%s%N
  fi
}

env_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" 2>/dev/null | tail -n1 | cut -d= -f2-
}

set_env_value() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -qE "^${key}=" "$file"; then
    sed -i "s|^${key}=.*|${key}=${value}|" "$file"
  else
    printf '\n%s=%s\n' "$key" "$value" >> "$file"
  fi
}

ensure_env_defaults() {
  local file="$1"
  local hermes_password

  if ! grep -qE '^HERMES_DASHBOARD_BASIC_AUTH_USERNAME=' "$file"; then
    set_env_value "$file" "HERMES_DASHBOARD_BASIC_AUTH_USERNAME" "admin"
    log "Added missing HERMES_DASHBOARD_BASIC_AUTH_USERNAME to .env."
  fi

  hermes_password="$(env_value "$file" "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD")"
  if [[ -z "$hermes_password" || "$hermes_password" == "change-this" ]]; then
    set_env_value "$file" "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD" "$(generate_secret)"
    log "Set HERMES_DASHBOARD_BASIC_AUTH_PASSWORD in .env."
  fi

  if ! grep -qE '^HERMES_WORKSPACE_DIR=' "$file"; then
    set_env_value "$file" "HERMES_WORKSPACE_DIR" "$HERMES_WORKSPACE_DIR"
    log "Added missing HERMES_WORKSPACE_DIR to .env."
  fi

  if ! grep -qE '^AI_BIND_ADDRESS=' "$file"; then
    set_env_value "$file" "AI_BIND_ADDRESS" "127.0.0.1"
    log "Added loopback-only AI_BIND_ADDRESS to .env."
  fi

  chmod 600 "$file"
}

# =============================================================================
# Pre-flight checks
# =============================================================================
section "Pre-flight checks"

if [[ "$EUID" -eq 0 ]]; then
  error "Do not run this script as root. Run as your normal user; sudo will be used where needed."
fi

if ! grep -qi "ubuntu" /etc/os-release 2>/dev/null; then
  warn "This script targets Ubuntu/Kubuntu 24.04. Proceeding anyway, but results may vary."
fi

UBUNTU_VERSION=$(grep "^VERSION_ID" /etc/os-release | cut -d= -f2 | tr -d '"')
if [[ "$UBUNTU_VERSION" != "24.04" ]]; then
  warn "Detected Ubuntu $UBUNTU_VERSION — script is tested on 24.04."
fi

if ! lspci | grep -qi nvidia; then
  warn "No NVIDIA GPU detected via lspci. NVIDIA-specific steps will still run but may be no-ops."
fi

log "Running as: $(whoami)"
log "Repo dir:   $REPO_DIR"

# =============================================================================
# Install path
# =============================================================================
section "Install path"

echo ""
echo -e "  AI lab files (docker-compose, scripts) will be installed to a directory"
echo -e "  on your machine. This is separate from this repo and not committed to git."
echo ""
if [[ -z "$INSTALL_DIR" ]]; then
  read -r -p "  Install path [$DEFAULT_INSTALL_DIR]: " user_input
  INSTALL_DIR="${user_input:-$DEFAULT_INSTALL_DIR}"
fi
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"  # expand leading tilde

if [[ -d "$INSTALL_DIR" && -f "$INSTALL_DIR/docker-compose.yml" ]]; then
  UPGRADE_MODE=true
  log "Existing install found at $INSTALL_DIR — running in upgrade mode."
else
  UPGRADE_MODE=false
  log "Installing to: $INSTALL_DIR"
fi

# =============================================================================
# Hermes workspace
# =============================================================================
section "Hermes workspace"

echo ""
echo -e "  Hermes will see this host folder as /workspace inside the container."
echo -e "  Use this for project files Hermes should read, write and process."
echo ""
if [[ -z "$HERMES_WORKSPACE_DIR" ]]; then
  read -r -p "  Hermes workspace path [~/workspace]: " workspace_input
  HERMES_WORKSPACE_DIR="${workspace_input:-$DEFAULT_HERMES_WORKSPACE_DIR}"
fi
HERMES_WORKSPACE_DIR="${HERMES_WORKSPACE_DIR/#\~/$HOME}"  # expand leading tilde
log "Hermes workspace: $HERMES_WORKSPACE_DIR"

# =============================================================================
# Optional components
# =============================================================================
section "Optional components"

if [[ -z "$INSTALL_HOME_ASSISTANT" ]]; then
  read -r -p "  Enable optional Home Assistant + ConBee setup? [y/N] " choice
  if [[ "$choice" =~ ^[Yy]$ ]]; then
    INSTALL_HOME_ASSISTANT=true
  else
    INSTALL_HOME_ASSISTANT=false
  fi
fi

if [[ "$INSTALL_HOME_ASSISTANT" =~ ^([Tt][Rr][Uu][Ee]|1|[Yy][Ee][Ss]|[Yy])$ ]]; then
  INSTALL_HOME_ASSISTANT=true
  read -r -p "  ConBee host device path [$CONBEE_DEVICE]: " conbee_input
  CONBEE_DEVICE="${conbee_input:-$CONBEE_DEVICE}"
  read -r -p "  Container device path [$CONBEE_CONTAINER_DEVICE]: " conbee_container_input
  CONBEE_CONTAINER_DEVICE="${conbee_container_input:-$CONBEE_CONTAINER_DEVICE}"
  read -r -p "  Timezone for Home Assistant [$TZ_VALUE]: " tz_input
  TZ_VALUE="${tz_input:-$TZ_VALUE}"
  log "Home Assistant profile will be enabled."
else
  INSTALL_HOME_ASSISTANT=false
  log "Home Assistant profile will be disabled (can be enabled later in .env)."
fi

# =============================================================================
# System update
# =============================================================================
section "System update"

step "Updating apt package lists..."
sudo apt-get update -qq

step "Upgrading installed packages..."
sudo apt-get upgrade -y -qq

# =============================================================================
# Base packages
# =============================================================================
section "Base packages"

BASE_PKGS=(
  curl
  wget
  git
  htop
  btop
  nvtop
  build-essential
  ca-certificates
  gnupg
  lsb-release
  apt-transport-https
  software-properties-common
  openssh-server
  unzip
  jq
  rsync
  python3
  python3-venv
  python3-pip
  libgl1
  libglib2.0-0
  libgomp1
)

step "Installing base packages..."
sudo apt-get install -y -qq "${BASE_PKGS[@]}"

log "Base packages installed."

# =============================================================================
# NVIDIA drivers
# =============================================================================
section "NVIDIA drivers"

if nvidia-smi &>/dev/null; then
  log "NVIDIA driver already installed and working ($(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -1))."
else
  step "Installing ubuntu-drivers-common..."
  sudo apt-get install -y -qq ubuntu-drivers-common

  step "Auto-detecting and installing recommended NVIDIA driver..."
  sudo ubuntu-drivers install

  warn "NVIDIA driver installed. A reboot is required before the driver is active."
  warn "After reboot, re-run this script to continue remaining steps."
  echo ""
  echo -e "  Run: ${BOLD}sudo reboot${NC}"
  echo ""
  read -r -p "Continue without rebooting now? (not recommended) [y/N] " choice
  if [[ ! "$choice" =~ ^[Yy]$ ]]; then
    log "Exiting. Please reboot and re-run setup.sh."
    exit 0
  fi
fi

# =============================================================================
# Docker Engine (official apt repo, not snap)
# =============================================================================
section "Docker Engine"

if command -v docker &>/dev/null && docker info &>/dev/null; then
  log "Docker already installed: $(docker --version)"
else
  step "Removing any old Docker packages..."
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get remove -y -qq "$pkg" 2>/dev/null || true
  done

  step "Adding Docker's official GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  step "Adding Docker apt repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq

  step "Installing Docker Engine..."
  sudo apt-get install -y -qq \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  log "Docker installed: $(docker --version)"
fi

# Add current user to docker group (takes effect on next login)
if groups "$(whoami)" | grep -q docker; then
  log "User already in docker group."
else
  step "Adding $(whoami) to docker group..."
  sudo usermod -aG docker "$(whoami)"
  warn "User added to docker group. This takes effect after your next login (or run: newgrp docker)."
fi

# Enable Docker service
sudo systemctl enable docker --now &>/dev/null
log "Docker service enabled and running."

# =============================================================================
# NVIDIA Container Toolkit
# =============================================================================
section "NVIDIA Container Toolkit"

if dpkg -s nvidia-container-toolkit &>/dev/null; then
  log "NVIDIA Container Toolkit already installed."
else
  step "Adding NVIDIA Container Toolkit repository..."
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
    | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
    | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
    | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null

  sudo apt-get update -qq

  step "Installing NVIDIA Container Toolkit..."
  sudo apt-get install -y -qq nvidia-container-toolkit

  step "Configuring Docker to use NVIDIA runtime..."
  sudo nvidia-ctk runtime configure --runtime=docker
  sudo systemctl restart docker

  log "NVIDIA Container Toolkit installed and Docker restarted."
fi

# =============================================================================
# Tailscale
# =============================================================================
section "Tailscale"

if command -v tailscale &>/dev/null; then
  log "Tailscale already installed: $(tailscale version | head -1)"
else
  step "Installing Tailscale..."
  curl -fsSL https://tailscale.com/install.sh | sh
  log "Tailscale installed."
fi

if tailscale status &>/dev/null; then
  log "Tailscale already connected."
else
  warn "Tailscale installed but not authenticated."
  warn "After this script finishes, run:  sudo tailscale up"
  warn "Then open the auth URL in your browser."
fi

# =============================================================================
# OpenSSH Server
# =============================================================================
section "OpenSSH Server"

if systemctl is-active --quiet ssh; then
  log "OpenSSH server already running."
else
  step "Installing and enabling OpenSSH server..."
  sudo apt-get install -y -qq openssh-server
  sudo systemctl enable ssh --now
  log "OpenSSH server running."
fi

# =============================================================================
# Steam
# =============================================================================
section "Steam"

if command -v steam &>/dev/null; then
  log "Steam already installed."
else
  step "Enabling 32-bit architecture for Steam..."
  sudo dpkg --add-architecture i386
  sudo apt-get update -qq

  step "Installing Steam..."
  sudo apt-get install -y -qq steam-installer || {
    warn "steam-installer not found in apt. Downloading from Valve..."
    TMPDIR=$(mktemp -d)
    wget -q -O "$TMPDIR/steam.deb" "https://cdn.akamai.steamstatic.com/client/installer/steam.deb"
    sudo apt-get install -y -qq "$TMPDIR/steam.deb"
    rm -rf "$TMPDIR"
  }
  log "Steam installed."
fi

# =============================================================================
# VS Code
# =============================================================================
section "VS Code"

if command -v code &>/dev/null; then
  log "VS Code already installed: $(code --version | head -1)"
else
  step "Adding Microsoft apt repository..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null

  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
    https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq code
  log "VS Code installed: $(code --version | head -1)"
fi

# =============================================================================
# AI lab install
# =============================================================================
section "AI lab install"

step "Copying AI lab files to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
rsync -a \
  --exclude='.env' \
  --exclude='data/' \
  --exclude='models/' \
  --exclude='output/' \
  --exclude='workspace/' \
  "$AI_LAB_SRC/" "$INSTALL_DIR/"

# Make scripts executable
chmod +x "$INSTALL_DIR/scripts/"*.sh
log "Files copied to $INSTALL_DIR."

# Create data directories and Hermes workspace folders (bind-mounted by docker compose)
DATA_DIRS=(
  "$INSTALL_DIR/data/ollama"
  "$INSTALL_DIR/data/open-webui"
  "$INSTALL_DIR/data/qdrant"
  "$INSTALL_DIR/data/comfyui"
  "$INSTALL_DIR/data/comfyui/custom_nodes"
  "$INSTALL_DIR/data/comfyui/input"
  "$INSTALL_DIR/data/comfyui/user"
  "$INSTALL_DIR/models/comfyui"
  "$INSTALL_DIR/models/comfyui/checkpoints"
  "$INSTALL_DIR/models/comfyui/clip"
  "$INSTALL_DIR/models/comfyui/clip_vision"
  "$INSTALL_DIR/models/comfyui/controlnet"
  "$INSTALL_DIR/models/comfyui/diffusion_models"
  "$INSTALL_DIR/models/comfyui/loras"
  "$INSTALL_DIR/models/comfyui/text_encoders"
  "$INSTALL_DIR/models/comfyui/unet"
  "$INSTALL_DIR/models/comfyui/upscale_models"
  "$INSTALL_DIR/models/comfyui/vae"
  "$INSTALL_DIR/output/comfyui"
  "$HERMES_WORKSPACE_DIR/documents"
  "$HERMES_WORKSPACE_DIR/experiments"
  "$HERMES_WORKSPACE_DIR/datasets"
  "$HERMES_WORKSPACE_DIR/reports"
  "$HERMES_WORKSPACE_DIR/exports"
  "$HERMES_WORKSPACE_DIR/inbox"
)

if [[ "$INSTALL_HOME_ASSISTANT" == true ]]; then
  DATA_DIRS+=("$INSTALL_DIR/data/home-assistant")
fi

step "Creating data/workspace directories..."
for dir in "${DATA_DIRS[@]}"; do
  mkdir -p "$dir"
done
log "Directories ready."

# Create .env if it doesn't exist yet
if [[ ! -f "$INSTALL_DIR/.env" ]]; then
  step "Creating .env from template..."
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
  sed -i "s|^ENABLE_HOME_ASSISTANT=.*|ENABLE_HOME_ASSISTANT=$INSTALL_HOME_ASSISTANT|" "$INSTALL_DIR/.env"
  sed -i "s|^CONBEE_DEVICE=.*|CONBEE_DEVICE=$CONBEE_DEVICE|" "$INSTALL_DIR/.env"
  sed -i "s|^CONBEE_CONTAINER_DEVICE=.*|CONBEE_CONTAINER_DEVICE=$CONBEE_CONTAINER_DEVICE|" "$INSTALL_DIR/.env"
  sed -i "s|^TZ=.*|TZ=$TZ_VALUE|" "$INSTALL_DIR/.env"
  sed -i "s|^HERMES_WORKSPACE_DIR=.*|HERMES_WORKSPACE_DIR=$HERMES_WORKSPACE_DIR|" "$INSTALL_DIR/.env"
  ensure_env_defaults "$INSTALL_DIR/.env"
  warn ".env created — edit $INSTALL_DIR/.env to add your API keys before starting services."
else
  log ".env already exists — not overwriting."
  ensure_env_defaults "$INSTALL_DIR/.env"
  set_env_value "$INSTALL_DIR/.env" "HERMES_WORKSPACE_DIR" "$HERMES_WORKSPACE_DIR"
  warn "If needed, set ENABLE_HOME_ASSISTANT/CONBEE_DEVICE/TZ in $INSTALL_DIR/.env."
fi

# =============================================================================
# ComfyUI (native host install)
# =============================================================================
section "ComfyUI host install"

COMFYUI_REPO_DIR="$COMFYUI_ROOT/ComfyUI"
COMFYUI_VENV="$COMFYUI_ROOT/.venv"

# Release port 8188 during migration from the previous Docker-based install.
# The later Compose run removes this stopped container as an orphan.
if docker container inspect ai-comfyui &>/dev/null; then
  step "Stopping the old ComfyUI container for host migration..."
  docker stop ai-comfyui >/dev/null
fi

# The former container ran as root and may have left runtime files that the
# native user service cannot update.
sudo chown -R "$(id -u):$(id -g)" \
  "$INSTALL_DIR/data/comfyui" \
  "$INSTALL_DIR/output/comfyui"

mkdir -p "$COMFYUI_ROOT"
if [[ -d "$COMFYUI_REPO_DIR/.git" ]]; then
  step "Updating the existing ComfyUI checkout..."
  git -C "$COMFYUI_REPO_DIR" pull --ff-only
elif [[ -e "$COMFYUI_REPO_DIR" ]]; then
  error "$COMFYUI_REPO_DIR exists but is not a Git checkout. Move it aside or set COMFYUI_ROOT."
else
  step "Cloning the latest ComfyUI source..."
  git clone https://github.com/Comfy-Org/ComfyUI.git "$COMFYUI_REPO_DIR"
fi

if [[ ! -x "$COMFYUI_VENV/bin/python" ]]; then
  step "Creating the ComfyUI Python virtual environment..."
  python3 -m venv "$COMFYUI_VENV"
fi

step "Installing the latest supported GPU and ComfyUI dependencies..."
"$COMFYUI_VENV/bin/python" -m pip --isolated install --upgrade --no-cache-dir \
  --index-url "$PYPI_INDEX_URL" \
  pip setuptools wheel
# Use PyTorch's pages only for the three top-level wheels. Its full CUDA index
# can redirect transitive NVIDIA packages to a mirror with stale file hashes.
"$COMFYUI_VENV/bin/python" -m pip --isolated install --upgrade --no-cache-dir \
  --index-url "$PYPI_INDEX_URL" \
  --find-links "${PYTORCH_INDEX_URL%/}/torch/" \
  --find-links "${PYTORCH_INDEX_URL%/}/torchvision/" \
  --find-links "${PYTORCH_INDEX_URL%/}/torchaudio/" \
  torch torchvision torchaudio
"$COMFYUI_VENV/bin/python" -m pip --isolated install --upgrade --no-cache-dir \
  --index-url "$PYPI_INDEX_URL" \
  -r "$COMFYUI_REPO_DIR/requirements.txt"

DOCKER_BRIDGE_ADDRESS="$(ip -4 -o addr show docker0 2>/dev/null | awk '{split($4, a, "/"); print a[1]; exit}')"
COMFYUI_LISTEN_ADDRESS="${COMFYUI_LISTEN_ADDRESS:-127.0.0.1${DOCKER_BRIDGE_ADDRESS:+,$DOCKER_BRIDGE_ADDRESS}}"

step "Installing the ComfyUI user service..."
mkdir -p "$HOME/.local/bin" "$HOME/.config/ai-lab" "$HOME/.config/systemd/user"
install -m 0755 "$INSTALL_DIR/scripts/comfyui-run.sh" "$HOME/.local/bin/ai-lab-comfyui-run"
install -m 0644 "$INSTALL_DIR/systemd/comfyui.service" "$HOME/.config/systemd/user/comfyui.service"
{
  printf 'COMFYUI_REPO_DIR=%q\n' "$COMFYUI_REPO_DIR"
  printf 'COMFYUI_VENV=%q\n' "$COMFYUI_VENV"
  printf 'COMFYUI_DATA_DIR=%q\n' "$INSTALL_DIR/data/comfyui"
  printf 'COMFYUI_MODELS_DIR=%q\n' "$INSTALL_DIR/models/comfyui"
  printf 'COMFYUI_OUTPUT_DIR=%q\n' "$INSTALL_DIR/output/comfyui"
  printf 'COMFYUI_LISTEN_ADDRESS=%q\n' "$COMFYUI_LISTEN_ADDRESS"
  printf 'COMFYUI_PORT=%q\n' "8188"
  printf 'PYPI_INDEX_URL=%q\n' "$PYPI_INDEX_URL"
  printf 'PYTORCH_INDEX_URL=%q\n' "$PYTORCH_INDEX_URL"
} > "$HOME/.config/ai-lab/comfyui.env"
chmod 600 "$HOME/.config/ai-lab/comfyui.env"

systemctl --user daemon-reload
systemctl --user enable --now comfyui.service
if command -v loginctl &>/dev/null; then
  sudo loginctl enable-linger "$(whoami)"
fi
log "ComfyUI installed from the latest source and running as a host service."

# Upgrade: pull latest images and restart running stack
if [[ "$UPGRADE_MODE" == true ]]; then
  step "Pulling latest Docker images..."
  (cd "$INSTALL_DIR" && docker compose pull)
  step "Restarting stack with updated images..."
  (cd "$INSTALL_DIR" && docker compose up -d --remove-orphans)
  log "Stack upgraded and restarted."
fi

# =============================================================================
# Verify GPU access in Docker (quick smoke test)
# =============================================================================
section "GPU Docker smoke test"

if nvidia-smi &>/dev/null; then
  step "Testing GPU access inside Docker..."
  if docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi &>/dev/null; then
    log "GPU access inside Docker: OK"
  else
    warn "GPU inside Docker failed. Check NVIDIA Container Toolkit install and that Docker was restarted."
    warn "Run manually: docker run --rm --gpus all nvidia/cuda:12.3.2-base-ubuntu22.04 nvidia-smi"
  fi
else
  warn "Skipping GPU Docker test — nvidia-smi not available (driver may need a reboot)."
fi

# =============================================================================
# Done
# =============================================================================
section "Setup complete"

echo ""
echo -e "${BOLD}Next steps:${NC}"
echo ""
echo -e "  1. ${BOLD}Add API keys${NC} (if you want cloud LLM fallback):"
echo -e "     nano $INSTALL_DIR/.env"
echo ""
echo -e "  2. ${BOLD}Set up Hermes dashboard auth${NC} (first-time only):"
echo -e "     mkdir -p ~/.hermes"
echo -e "     docker run -it --rm -v ~/.hermes:/opt/data nousresearch/hermes-agent setup"
echo ""
echo -e "  3. ${BOLD}Authenticate Tailscale${NC}:"
echo -e "     sudo tailscale up"
echo ""
echo -e "  4. ${BOLD}Start the AI stack${NC}:"
echo -e "     $INSTALL_DIR/scripts/ai-start.sh"
echo ""
echo -e "  5. ${BOLD}Pull starter models${NC} (after stack is up):"
echo -e "     $INSTALL_DIR/scripts/pull-models.sh"
echo ""
echo -e "  6. ${BOLD}Use the Hermes workspace${NC}:"
echo -e "     Host path: $HERMES_WORKSPACE_DIR"
echo -e "     Container path: /workspace"
echo ""
echo -e "  7. ${BOLD}Open the UIs${NC}:"
echo -e "     Open WebUI    → http://localhost:3000"
echo -e "     ComfyUI       → http://localhost:8188"
echo -e "     Hermes API    → http://localhost:8642"
echo -e "     Hermes UI     → http://localhost:9119"
echo -e "     Qdrant        → http://localhost:6333"
echo -e "     Portainer     → https://localhost:9443"
if [[ "$INSTALL_HOME_ASSISTANT" == true ]]; then
  echo -e "     Home Assistant → http://localhost:8123"
fi
echo ""
echo -e "  8. ${BOLD}Before gaming${NC}:"
echo -e "     $INSTALL_DIR/scripts/gaming-mode.sh"
echo ""
echo -e "  9. ${BOLD}Update the running stack and ComfyUI${NC}:"
echo -e "     $INSTALL_DIR/scripts/update.sh"
echo ""

if groups "$(whoami)" | grep -q docker; then
  log "Docker group: active for this session."
else
  warn "You were just added to the docker group. Log out and back in, or run:"
  echo -e "     ${BOLD}newgrp docker${NC}"
fi

echo ""
log "Done."
