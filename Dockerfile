# ============================================================
# 基础镜像：CUDA 13.0
# ============================================================
FROM nvidia/cuda:13.0.0-base-ubuntu22.04

# ============================================================
# 构建参数
# ============================================================
ARG HF_TOKEN=""

# ============================================================
# 1. 安装系统工具和 Python
# ============================================================
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    git \
    wget \
    curl \
    ffmpeg \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# 2. 创建 Python 软链接
# ============================================================
RUN ln -s /usr/bin/python3 /usr/bin/python

# ============================================================
# 3. 克隆 ComfyUI 并安装核心依赖
# ============================================================
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    git checkout master && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install comfy-cli

# ============================================================
# 4. 安装自定义节点
# ============================================================
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes
RUN git clone https://github.com/ltdrdata/was-node-suite-comfyui /comfyui/custom_nodes/was-node-suite-comfyui
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/ComfyUI-VideoHelperSuite
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use /comfyui/custom_nodes/ComfyUI-Easy-Use
RUN git clone https://github.com/FX-FeiHou/ComfyUI-FeiHou-Toolbox /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox
RUN git clone https://github.com/crystian/ComfyUI-Crystools.git /comfyui/custom_nodes/ComfyUI-Crystools
RUN git clone https://github.com/Brobert-in-aus/scail-auto-extend.git /comfyui/custom_nodes/scail-auto-extend

# ============================================================
# 5. 安装自定义节点的 Python 依赖
# ============================================================
RUN cd /comfyui/custom_nodes/ComfyUI-Easy-Use && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/was-node-suite-comfyui && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-Crystools && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/scail-auto-extend && pip install -r requirements.txt 2>/dev/null || true

# ============================================================
# 6. 安装 SageAttention + comfy-aimdo
# ============================================================
RUN pip install comfy-aimdo
RUN pip install sageattention

# ============================================================
# 7. 创建模型目录
# ============================================================
RUN mkdir -p /comfyui/models/text_encoders \
    /comfyui/models/clip_vision \
    /comfyui/models/vae \
    /comfyui/models/diffusion_models \
    /comfyui/models/checkpoints \
    /comfyui/models/loras \
    /comfyui/input

# ============================================================
# 8. 下载模型文件（wget -nv 减少日志）
# ============================================================

# Text Encoder (~6.4GB)
RUN wget -nv -P /comfyui/models/text_encoders/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

# CLIP Vision (~1.2GB)
RUN wget -nv -P /comfyui/models/clip_vision/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

# VAE (~242MB)
RUN wget -nv -P /comfyui/models/vae/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

# SCAIL-2 核心模型 (~13.3GB)
RUN wget -nv -P /comfyui/models/diffusion_models/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors"

# SAM3 模型 (~1.7GB)
RUN wget -nv -P /comfyui/models/checkpoints/ "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/sam3.1_multiplex_fp16.safetensors"

# Lightx2v LoRA (~2.9GB)
RUN wget -nv -P /comfyui/models/loras/ "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"

# Q弹 LoRA — 用 curl 带 HF_TOKEN 认证下载
RUN curl -L -H "Authorization: Bearer $HF_TOKEN" -o /comfyui/models/loras/Q弹3.safetensors "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Q%E5%BC%B93.safetensors"

# DPO LoRA (~1.2GB)
RUN wget -nv -P /comfyui/models/loras/ "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/wan2.1_SCAIL_2_DPO_lora_bf16.safetensors"

# Relighting LoRA (~1.2GB)
RUN wget -nv -P /comfyui/models/loras/ "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Scail2-relighting-lora.safetensors"

# ============================================================
# 9. 下载参考图
# ============================================================
RUN wget -nv -O /comfyui/input/00820.png "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/00820.png" || echo "WARN: 00820.png download failed"

# ============================================================
# 10. 复制工作流文件
# ============================================================
COPY "SCAIL-2动作迁移&角色替换工作流.json" /comfyui/input/workflow.json

# ============================================================
# 11. 验证模型文件是否存在
# ============================================================
RUN echo "===== 验证模型文件 =====" && \
    ls -lh /comfyui/models/text_encoders/ && \
    ls -lh /comfyui/models/clip_vision/ && \
    ls -lh /comfyui/models/vae/ && \
    ls -lh /comfyui/models/diffusion_models/ && \
    ls -lh /comfyui/models/checkpoints/ && \
    ls -lh /comfyui/models/loras/ && \
    echo "===== 验证完成 ====="

# ============================================================
# 12. 清理临时文件
# ============================================================
RUN rm -rf /tmp/* /root/.cache

# ============================================================
# 13. 启动命令
# ============================================================
CMD python /comfyui/main.py --listen 0.0.0.0 --port 8188