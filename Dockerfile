FROM nvidia/cuda:13.0.0-base-ubuntu22.04

ARG HF_TOKEN=""

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-dev git wget curl ffmpeg \
    libgl1-mesa-glx libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/bin/python3 /usr/bin/python

RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    git checkout master && \
    pip install --upgrade pip && \
    pip install -r requirements.txt && \
    pip install comfy-cli

RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes
RUN git clone https://github.com/ltdrdata/was-node-suite-comfyui /comfyui/custom_nodes/was-node-suite-comfyui
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/ComfyUI-VideoHelperSuite
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use /comfyui/custom_nodes/ComfyUI-Easy-Use
RUN git clone https://github.com/FX-FeiHou/ComfyUI-FeiHou-Toolbox /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox
RUN git clone https://github.com/crystian/ComfyUI-Crystools.git /comfyui/custom_nodes/ComfyUI-Crystools
RUN git clone https://github.com/Brobert-in-aus/scail-auto-extend.git /comfyui/custom_nodes/scail-auto-extend

RUN cd /comfyui/custom_nodes/ComfyUI-Easy-Use && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/was-node-suite-comfyui && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/ComfyUI-Crystools && pip install -r requirements.txt 2>/dev/null || true && \
    cd /comfyui/custom_nodes/scail-auto-extend && pip install -r requirements.txt 2>/dev/null || true

RUN pip install comfy-aimdo
RUN pip install sageattention

RUN mkdir -p /comfyui/models/text_encoders \
    /comfyui/models/clip_vision \
    /comfyui/models/vae \
    /comfyui/models/diffusion_models \
    /comfyui/models/checkpoints \
    /comfyui/models/loras \
    /comfyui/input \
    /comfyui/user/default/workflows

# ============================================================
# 下载模型
# ============================================================

RUN wget -nv -P /comfyui/models/text_encoders/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors"

RUN wget -nv -P /comfyui/models/clip_vision/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors"

RUN wget -nv -P /comfyui/models/vae/ "https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors"

RUN wget -nv -P /comfyui/models/diffusion_models/ "https://huggingface.co/Comfy-Org/SCAIL-2/resolve/main/diffusion_models/wan2.1_14B_SCAIL_2_fp8_scaled.safetensors"

RUN wget -nv -P /comfyui/models/checkpoints/ "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/sam3.1_multiplex_fp16.safetensors"

RUN wget -nv -P /comfyui/models/loras/ "https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors"

RUN wget -nv -O /comfyui/models/loras/"Q弹 低.safetensors" "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Q%E5%BC%B93.safetensors"

RUN wget -nv -P /comfyui/models/loras/ "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/wan2.1_SCAIL_2_DPO_lora_bf16.safetensors"

RUN wget -nv -P /comfyui/models/loras/ "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Scail2-relighting-lora.safetensors"

# ============================================================
# 下载参考图（保留原文件）
# ============================================================
RUN wget -nv -O /comfyui/input/00820.png "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/00820.png" || echo "WARN: 00820.png download failed"

# ============================================================
# 下载工作流（放到 workflows 目录）
# ============================================================
RUN wget -O /comfyui/user/default/workflows/workflow.json "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/SCAIL-2%E5%8A%A8%E4%BD%9C%E8%BF%81%E7%A7%BB%26%E8%A7%92%E8%89%B2%E6%9B%BF%E6%8D%A2%E6%94%AF%E6%8C%81%E5%A4%9A%E5%8F%82%E5%B7%A5%E4%BD%9C%E6%B5%81%E6%96%B0.json"

# ============================================================
# 验证
# ============================================================
RUN echo "===== 验证模型文件 =====" && \
    du -sh /comfyui/models/ && \
    ls -lh /comfyui/models/text_encoders/ 2>/dev/null || echo "text_encoders empty" && \
    ls -lh /comfyui/models/clip_vision/ 2>/dev/null || echo "clip_vision empty" && \
    ls -lh /comfyui/models/vae/ 2>/dev/null || echo "vae empty" && \
    ls -lh /comfyui/models/diffusion_models/ 2>/dev/null || echo "diffusion_models empty" && \
    ls -lh /comfyui/models/checkpoints/ 2>/dev/null || echo "checkpoints empty" && \
    ls -lh /comfyui/models/loras/ 2>/dev/null || echo "loras empty" && \
    echo "===== 验证完成 ====="

CMD python /comfyui/main.py --listen 0.0.0.0 --port 8188
