# clean base image containing only comfyui, comfy-cli and comfyui-manager
FROM runpod/worker-comfyui:5.10.0-base

# build-time tokens for gated downloads are read from BuildKit secret
# mounts — they are never written to a layer or to image history.
# pass via: docker buildx build --secret id=hf_token,env=HF_TOKEN .

# install custom nodes into comfyui
RUN comfy node install --exit-on-fail comfyui-videohelpersuite --mode remote
RUN comfy node install --exit-on-fail comfyui-depthanythingv2

# download models into comfyui
RUN --mount=type=secret,id=hf_token BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN="$(cat /run/secrets/hf_token 2>/dev/null || true)" comfy model download --url 'https://huggingface.co/Kijai/DepthAnythingV2-safetensors/resolve/main/depth_anything_v2_vitl_fp32.safetensors' --relative-path models/annotators --filename 'depth_anything_v2_vitl_fp32.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
