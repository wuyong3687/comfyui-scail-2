# 基础镜像：使用 RunPod 官方最新版 ComfyUI 环境
FROM runpod/worker-comfyui:latest-base

# 构建参数：用于访问 Hugging Face 的私有模型（如果需要）
# 用法：docker build --build-arg HF_TOKEN=$HF_TOKEN ...
ARG HF_TOKEN=""

# --- 1. 安装自定义节点 (Custom Nodes) ---
# 锁定特定版本以保证稳定性，如果版本不存在则回退到默认分支
RUN git clone https://github.com/Suzie1/ComfyUI_Comfyroll_CustomNodes /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && \
    cd /comfyui/custom_nodes/ComfyUI_Comfyroll_CustomNodes && \
    (git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca 2>/dev/null || (git fetch origin d78b780ae43fcf8c6b7c6505e6ffb4584281ceca --depth=1 && git checkout d78b780ae43fcf8c6b7c6505e6ffb4584281ceca) || echo "WARN: commit d78b780... unreachable, falling back to default branch HEAD")

# was-node-suite-comfyui (提供 Image Batch 等节点)
RUN git clone https://github.com/ltdrdata/was-node-suite-comfyui /comfyui/custom_nodes/was-node-suite-comfyui && \
    cd /comfyui/custom_nodes/was-node-suite-comfyui && \
    (git checkout 44de705818d4663fefefde57ffe0ea5a9ea39df4 2>/dev/null || (git fetch origin 44de705818d4663fefefde57ffe0ea5a9ea39df4 --depth=1 && git checkout 44de705818d4663fefefde57ffe0ea5a9ea39df4) || echo "WARN: commit 44de705... unreachable, falling back to default branch HEAD")

# ComfyUI-KJNodes (提供 DiffusionModelLoaderKJ 等节点)
RUN git clone https://github.com/kijai/ComfyUI-KJNodes /comfyui/custom_nodes/ComfyUI-KJNodes && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && \
    (git checkout fca78c93f034c6e36080d64da83afe00bd5dbba6 2>/dev/null || (git fetch origin fca78c93f034c6e36080d64da83afe00bd5dbba6 --depth=1 && git checkout fca78c93f034c6e36080d64da83afe00bd5dbba6) || echo "WARN: commit fca78c9... unreachable, falling back to default branch HEAD")

# ComfyUI-VideoHelperSuite (提供 VHS_LoadVideo, VHS_VideoCombine 等节点)
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && \
    cd /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && \
    (git checkout 4ee72c065db22c9d96c2427954dc69e7b908444b 2>/dev/null || (git fetch origin 4ee72c065db22c9d96c2427954dc69e7b908444b --depth=1 && git checkout 4ee72c065db22c9d96c2427954dc69e7b908444b) || echo "WARN: commit 4ee72c0... unreachable, falling back to default branch HEAD")

# ComfyUI-Easy-Use (提供 easy loraStack 等节点)
RUN git clone https://github.com/yolain/ComfyUI-Easy-Use /comfyui/custom_nodes/ComfyUI-Easy-Use && \
    cd /comfyui/custom_nodes/ComfyUI-Easy-Use && \
    (git checkout 625efbfa2fc20c31797dfffcbb41a26b6d91ab7b 2>/dev/null || (git fetch origin 625efbfa2fc20c31797dfffcbb41a26b6d91ab7b --depth=1 && git checkout 625efbfa2fc20c31797dfffcbb41a26b6d91ab7b) || echo "WARN: commit 625efbf... unreachable, falling back to default branch HEAD")

# ComfyUI-FeiHou-Toolbox (提供 FastGroupsBypassSwitch, SCAIL2ColoredMask 等核心节点)
RUN git clone https://github.com/FX-FeiHou/ComfyUI-FeiHou-Toolbox /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox

# ComfyUI-Crystools (提供 Switch any [Crystools] 节点)
RUN git clone https://github.com/crystian/ComfyUI-Crystools.git /comfyui/custom_nodes/ComfyUI-Crystools

# scail-auto-extend (解决长视频色彩漂移问题的关键插件)
RUN git clone https://github.com/Brobert-in-aus/scail-auto-extend.git /comfyui/custom_nodes/scail-auto-extend

# 安装所有自定义节点的 Python 依赖
RUN cd /comfyui/custom_nodes/ComfyUI-Easy-Use && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-VideoHelperSuite && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-FeiHou-Toolbox && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/was-node-suite-comfyui && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-KJNodes && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/ComfyUI-Crystools && pip install -r requirements.txt || true && \
    cd /comfyui/custom_nodes/scail-auto-extend && pip install -r requirements.txt || true

# 安装缺失的 Python 核心库 (comfy-aimdo)
RUN pip install comfy-aimdo

# --- 2. 下载模型文件 (Models) ---
# 使用 comfy model download 命令，带重试机制，确保大文件下载成功
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors' --relative-path models/text_encoders --filename 'umt5_xxl_fp8_e4m3fn_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/clip_vision/clip_vision_h.safetensors' --relative-path models/clip_vision --filename 'clip_vision_vit_h.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors' --relative-path models/vae --filename 'wan_2.1_vae.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/diffusion_models/wan2.1_t2v_14B_fp8_scaled.safetensors' --relative-path models/diffusion_models --filename 'wan2.1_14B_SCAIL_2_fp8_scaled.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/sam3.1_multiplex_fp16.safetensors' --relative-path models/checkpoints --filename 'sam3.1_multiplex_fp16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Kijai/WanVideo_comfy/resolve/main/Lightx2v/lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors' --relative-path models/loras --filename 'lightx2v_I2V_14B_480p_cfg_step_distill_rank256_bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Q%E5%BC%B93.safetensors' --relative-path models/loras --filename 'Q弹3.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/wan2.1_SCAIL_2_DPO_lora_bf16.safetensors' --relative-path models/loras --filename 'wan2.1_SCAIL_2_DPO_lora_bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/Scail2-relighting-lora.safetensors' --relative-path models/loras --filename 'Scail2-relighting-lora.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# --- 3. 复制输入文件和工作流 ---
# 下载参考图 (确保 00820.png 在 Hugging Face 仓库根目录且为 resolvec 直链)
RUN wget --progress=dot:giga -O '/comfyui/input/00820.png' "https://huggingface.co/wuyong3687/DongZuoTiHuan/resolve/main/00820.png" || echo "WARN: 00820.png download failed, continuing..."

# 复制主工作流文件 (注意文件名含中文和特殊字符，用双引号括起来)
COPY "SCAIL-2动作迁移&角色替换工作流.json" /comfyui/input/workflow.json

# --- 4. 清理构建缓存，减小镜像体积 ---
RUN rm -rf /tmp/*

# --- 5. 设置容器启动命令 ---
CMD python /comfyui/main.py --listen 0.0.0.0 --port 8188

