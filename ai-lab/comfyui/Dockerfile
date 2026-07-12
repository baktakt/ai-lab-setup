FROM python:3.12-slim-bookworm

ARG COMFYUI_REPO=https://github.com/Comfy-Org/ComfyUI.git
ARG COMFYUI_REF=master
ARG COMFYUI_MANAGER_REPO=https://github.com/ltdrdata/ComfyUI-Manager.git
ARG PYTORCH_INDEX_URL=https://download.pytorch.org/whl/cu130

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        libgl1 \
        libglib2.0-0 \
        libgomp1 \
        libsm6 \
        libxext6 \
        libxrender1 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${COMFYUI_REF}" "${COMFYUI_REPO}" /opt/ComfyUI

WORKDIR /opt/ComfyUI

RUN pip install --upgrade pip setuptools wheel \
    && pip install torch torchvision torchaudio --extra-index-url "${PYTORCH_INDEX_URL}" \
    && pip install -r requirements.txt

RUN git clone --depth 1 "${COMFYUI_MANAGER_REPO}" custom_nodes/ComfyUI-Manager \
    && cp -a custom_nodes /opt/ComfyUI/custom_nodes.default

EXPOSE 8188

COPY entrypoint.sh /usr/local/bin/comfyui-entrypoint
RUN chmod +x /usr/local/bin/comfyui-entrypoint

ENTRYPOINT ["comfyui-entrypoint"]
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
