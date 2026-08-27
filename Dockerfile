# 基础镜像：CUDA 13.0
FROM nvidia/cuda:13.0.0-base-ubuntu22.04

# 构建参数：用于访问 Hugging Face 的私有模型
ARG HF_TOKEN=""

# --- 安装基础环境和 ComfyUI（一次性完成）---
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 创建 python 软链接
RUN ln -s /usr/bin/python3 /usr/bin/python

# 克隆 ComfyUI 并安装核心依赖
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    pip install --upgrade pip && \
    pip install -r /comfyui/requirements.txt && \
    pip install comfy-cli

# --- 固定 ComfyUI 版本为 master 分支（最新版）---
RUN cd /comfyui && \
    git checkout master && \
    git pull && \
    pip install -r requirements.txt

# --- 1. 安装自定义节点 (Custom Nodes) ---
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && \
    cd /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && \
    (git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca 2>/dev/null || (git fetch origin d78b780ae43fcf8c6b7c6505e6ffb4584281ceca --depth=1 && git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca) || echo "WARN: commit d78b780... unreachable, falling back to default branch HEAD")

RUN git clone https://github.com/ltdrdata/was-node-suite-comfyui /comfyui/custom_nodes/was-node-suite-comfyui && \
    cd /comfyui/custom_nodes/was-node-suite-comfyui && \
    (git checkout 44de705818d4663fefefde57ffe0ea5a9ea39df4 2>/dev/null || (git fetch origin 44de705818d4663fefefde57ffe0ea5a9ea39df4 --depth=1 && git checkout 44de705818d4663fefefde57ffe0ea5a9ea39df4) || echo "WARN: commit 44de705... unreachable, falling back to default branch HEAD")

RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && \
    (git checkout fca78c93f034c6e36080d64da83afe00bd5dbba6 2>/dev/null || (git fetch origin fca78c93f034c6e36080d64da83afe00bd5dbba6 --depth=1 && git checkout fca78c93f034c6e36080d64da83afe00bd5dbba6) || echo "WARN: commit fca78c9... unreachable, falling back to default branch HEAD")

RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && \
    cd /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && \
    (git checkout 4ee72c065db22c9d96c2427954dc69e7b908444b 2>/dev/null || (git fetch origin 4ee72c065db22c9d96c2427954dc69e7b908444b --depth=1 && git checkout 4ee72c065db22c9d96c2427954dc69e7b908444b) || echo "WARN: commit 4ee72c0... unreachable, falling back to default branch HEAD")

RUN git clone https://github.com/yolain/ComfyUI-Easy-Use /comfyui/custom_nodes/ComfyUI-Easy-Use && \
    cd /comfyui/custom_nodes/ComfyUI-Easy-Use && \
    (git checkout 625efbfa2fc20c31797dfffcbb41a26b6d91ab7b 2>/dev/null || (git fetch origin 625efbfa2fc20c31797dfffcbb41a26b6d91ab7b --depth=1 && git checkout 625efbfa2fc20c31797dfffcbb41a26b6d91ab7b) || echo "WARN: commit 625efbf... unreachable, falling back to default branch HEAD")

RUN rm -rf /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox && \
    git clone https://github.com/FX-FeiHou/ComfyUI-FeiHou-Toolbox /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox || exit 1

RUN rm -rf /comfyui/custom_nodes/ComfyUI-Crystools && \
    git clone https://github.com/crystian/ComfyUI-Crystools.git /comfyui/custom_nodes/ComfyUI-Crystools || exit 1

RUN git clone https://github.com/Brobert-in-aus/scail-auto-extend.git /comfyui/custom_nodes/scail-auto-extend

# 安装所有自定义节点的 Python 依赖
RUN cd /comfyui/custom_nodes/ComfyUI-Easy-Use && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/was-node-suite-comfyui && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-Crystools && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/scail-auto-extend && pip install -r requirements.txt || true

RUN pip install comfy-aimdo

# --- 2. 下载模型文件 (Models) ---
RUN mkdir -p /comfyui/models/text_encoders /comfyui/models/clip_vision /comfyui/models/vae /comfyui/models/diffusion_models /comfyui/models/checkpoints /comfyui/models/loras /comfyui/input

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 600 -o /comfyui/models/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 600 -o /comfyui/models/clip_vision/clip_vision_h.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 600 -o /comfyui/models/vae/wan_2.1_vae.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 1200 -o /comfyui/models/diffusion_models/wan2.1_14B_SCAIL_2_fp8_scaled.safetensors "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 600 -o /comfyui/models/checkpoints/sam3.1_multiplex_fp16.safetensors "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/sam3.1_multiplex_fp16.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 300 -o /comfyui/models/loras/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 300 -o /comfyui/models/loras/"Q弹 低.safetensors" "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Q%E5%BC%B93.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 300 -o /comfyui/models/loras/wan2.1_SCAIL_2_DPO_lora_bf16.safetensors "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/wan2.1_SCAIL_2_DPO_lora_bf16.safetensors" && break || sleep 30; \
    done

RUN for i in 1 2 3 4 5; do \
    curl -L --connect-timeout 60 --max-time 300 -o /comfyui/models/loras/Scail2-relighting-lora.safetensors "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Scail2-relighting-lora.safetensors" && break || sleep 30; \
    done

# --- 3. 复制输入文件和工作流 ---
RUN wget --progress=dot:giga -O '/comfyui/input/00820.png' "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/00820.png" || echo "WARN: 00820.png download failed, continuing..."

COPY "SCAIL-2动作迁移&角色替换工作流.json" /comfyui/input/workflow.json

RUN rm -rf /tmp/*

CMD python /comfyui/main.py --listen 0.0.0.0 --port 8188