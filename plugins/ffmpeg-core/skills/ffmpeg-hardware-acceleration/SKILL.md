---
name: ffmpeg-hardware-acceleration
description: |
  Complete GPU-accelerated encoding/decoding system for FFmpeg 7.1 LTS and 8.0.1 (latest stable, released 2025-11-20).
  PROACTIVELY activate for: (1) NVIDIA NVENC/NVDEC encoding, (2) Intel Quick Sync Video (QSV), (3) AMD AMF encoding, (4) Apple VideoToolbox, (5) Linux VAAPI setup, (6) Vulkan Video 8.0 (FFv1, AV1, VP9, ProRes RAW), (7) VVC/H.266 hardware decoding (VAAPI/QSV), (8) GPU pipeline optimization with pad_cuda, (9) Docker GPU containers, (10) Performance benchmarking.
  Provides: Platform-specific commands, preset comparisons, quality tuning, full GPU pipeline examples, Vulkan compute codecs, VVC decoding, troubleshooting guides.
  Ensures: Maximum encoding speed with optimal quality using GPU acceleration.
---

## When to Use This Skill

Activate when **GPU acceleration is needed**:

- Encoding speed is critical (10-30x faster than CPU)
- Processing large batches of videos
- Real-time encoding for streaming
- Server-side transcoding at scale
- Docker containers with GPU passthrough

GPU encoding trades some quality for massive speed. Use `-cq`, `-qp`, or `-global_quality` for quality control.

## Quick Reference

| Platform | Encoder | Decoder | Detect Command |
|----------|---------|---------|----------------|
| NVIDIA | `h264_nvenc`, `hevc_nvenc`, `av1_nvenc` | `h264_cuvid`, `hevc_cuvid` | `ffmpeg -encoders \| grep nvenc` |
| Intel QSV | `h264_qsv`, `hevc_qsv`, `av1_qsv` | `h264_qsv`, `hevc_qsv` | `ffmpeg -encoders \| grep qsv` |
| AMD AMF | `h264_amf`, `hevc_amf`, `av1_amf` | N/A (use software) | `ffmpeg -encoders \| grep amf` |
| Apple | `h264_videotoolbox`, `hevc_videotoolbox` | `h264_videotoolbox` | macOS only |
| VAAPI | `h264_vaapi`, `hevc_vaapi`, `av1_vaapi` | with `-hwaccel vaapi` | Linux only |
| Vulkan | `h264_vulkan`, `hevc_vulkan`, `av1_vulkan`, `ffv1_vulkan` | VP9, ProRes RAW (8.0+) | `ffmpeg -encoders \| grep vulkan` |

**Current Latest**: FFmpeg 8.0.1 (released 2025-11-20). Check with `ffmpeg -version`.

## Hardware Acceleration Overview

Hardware acceleration uses dedicated GPU/SoC components for video processing:

- **NVENC/NVDEC** (NVIDIA): dedicated encode/decode engines
- **QSV** (Intel): Quick Sync Video on Intel CPUs with integrated graphics
- **AMF** (AMD): Advanced Media Framework for AMD GPUs
- **VideoToolbox** (Apple): macOS/iOS hardware acceleration
- **VAAPI** (Linux): Video Acceleration API (Intel, AMD on Linux)
- **Vulkan Video** (Cross-platform, FFmpeg 7.1+/8.0): compute-shader-based codecs

### Performance Comparison (2025 Benchmarks)

| Method | Speed | Quality | Power | Use Case |
|--------|-------|---------|-------|----------|
| libx264 (CPU) | 1x | Best | High | Quality-critical |
| libx265 (CPU) | 0.3x | Best | Very High | Archival |
| h264_nvenc | 10-20x | Good | Low | Real-time, streaming |
| hevc_nvenc | 8-15x | Good | Low | 4K streaming |
| h264_qsv | 8-15x | Good | Very Low | Laptop, efficiency |
| h264_amf | 8-15x | Good | Low | AMD systems |

## Core Workflow

1. **Detect what you have**: `ffmpeg -hwaccels`, `ffmpeg -encoders | grep <api>`
2. **Pick a backend**: prefer the vendor-native one (NVENC on NVIDIA, QSV on Intel, AMF on AMD, VideoToolbox on Apple). Use Vulkan for cross-platform portability.
3. **Build a full-GPU pipeline** where possible:
   - Add `-hwaccel <api>` and `-hwaccel_output_format <api>` *before* `-i`
   - Use GPU-side filters (`scale_cuda`, `scale_vulkan`, `vpp_qsv`, ...)
   - Use the matching hardware encoder
4. **Tune quality**: `-preset` (NVENC `p1-p7`), `-cq`/`-qp`/`-global_quality`, lookahead, spatial/temporal AQ
5. **Verify**: benchmark with `ffmpeg -benchmark` and monitor GPU via `nvidia-smi dmon`, `intel_gpu_top`, etc.

## Minimal Examples per Backend

```bash
# NVIDIA NVENC
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -c:v h264_nvenc -preset p4 -b:v 5M output.mp4

# Intel QSV
ffmpeg -hwaccel qsv -hwaccel_output_format qsv -i input.mp4 \
  -c:v h264_qsv -preset medium -b:v 5M output.mp4

# AMD AMF
ffmpeg -i input.mp4 -c:v h264_amf -quality balanced -b:v 5M output.mp4

# Apple VideoToolbox
ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4

# Linux VAAPI
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi -i input.mp4 \
  -c:v h264_vaapi -b:v 5M output.mp4

# Vulkan (cross-platform)
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -c:v h264_vulkan -b:v 5M output.mp4
```

## Full GPU Pipeline Pattern (Critical)

```bash
ffmpeg -y -vsync 0 \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -c:v h264_nvenc -preset p4 -b:v 5M \
  -c:a copy \
  output.mp4
```

Omitting `-hwaccel_output_format` can cut throughput by up to 50% because decoded frames silently round-trip through CPU memory. See [`references/gpu-memory-and-troubleshooting.md`](references/gpu-memory-and-troubleshooting.md) for memory flow diagrams and best practices.

## Cross-Vendor Filter Quick Map

| Operation | NVIDIA | Intel | AMD/Linux | Cross-platform |
|-----------|--------|-------|-----------|----------------|
| Scale | `scale_cuda`, `scale_npp` | `vpp_qsv`, `scale_qsv` | `scale_vaapi` | `scale_vulkan`, `scale_opencl`, `libplacebo` |
| Overlay | `overlay_cuda` | - | - | `overlay_vulkan`, `overlay_opencl` |
| Deinterlace | `bwdif_cuda` | `vpp_qsv` | `deinterlace_vaapi` | `bwdif_vulkan` |
| Denoise | `bilateral_cuda` | - | - | `nlmeans_vulkan`, `nlmeans_opencl` |
| Chromakey | `chromakey_cuda` | - | - | `colorkey_opencl` |
| Tonemap (HDR->SDR) | - | - | `tonemap_vaapi` | `libplacebo`, `tonemap_opencl` |
| Pad/letterbox | `pad_cuda` (8.0+) | - | - | `pad_opencl` |

## Use-Case Quick Recipes

### Live streaming (low latency)

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input \
  -c:v h264_nvenc -preset p3 -tune ll -zerolatency 1 -b:v 6M \
  -f flv rtmp://server/live/stream
```

### VOD (quality target)

```bash
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p6 -tune hq \
  -rc vbr -cq 22 -b:v 0 \
  -rc-lookahead 32 -spatial-aq 1 \
  output.mp4
```

### Batch / parallel encoding

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input1.mp4 -c:v h264_nvenc output1.mp4 &
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input2.mp4 -c:v h264_nvenc output2.mp4 &
wait
```

### Docker (GPU passthrough)

```bash
docker run --gpus all --rm -v $(pwd):/data \
  jrottenberg/ffmpeg:nvidia \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i /data/input.mp4 -c:v h264_nvenc /data/output.mp4
```

## Best Practices

1. Use full GPU pipelines when possible to avoid CPU/GPU memory transfers
2. Match decode and encode hardware for best performance
3. Pick presets deliberately - faster is not always better for quality
4. Enable lookahead and AQ for quality-critical encodes
5. Test on target hardware - quality varies by GPU generation
6. Monitor GPU memory for high-resolution content
7. Consider power efficiency for laptops and servers
8. Update drivers regularly for performance and feature improvements

## Reference Map

For deep dives on each backend, see:

- **NVIDIA NVENC/NVDEC** (presets, CUDA filters, scale_npp, hybrid pipelines, two-pass, multi-GPU, 1:N ABR): [`references/nvidia-nvenc.md`](references/nvidia-nvenc.md)
- **Intel QSV** (full pipeline, vpp_qsv, lookahead, multi-GPU, VVC decoding): [`references/intel-qsv.md`](references/intel-qsv.md)
- **AMD AMF, VAAPI, Apple VideoToolbox** (encoders, scaling, VVC VAAPI 8.0+ SCC support): [`references/amd-amf-vaapi-videotoolbox.md`](references/amd-amf-vaapi-videotoolbox.md)
- **Vulkan Video and Vulkan filters** (h264/hevc/av1/ffv1, VP9/ProRes RAW decode, scale/overlay/blur/transitions/libplacebo): [`references/vulkan.md`](references/vulkan.md)
- **OpenCL filters** (scale, overlay, colorkey, nlmeans, deshake, unsharp, tonemap): [`references/opencl-filters.md`](references/opencl-filters.md)
- **GPU memory management, filter comparison matrix, Docker, troubleshooting**: [`references/gpu-memory-and-troubleshooting.md`](references/gpu-memory-and-troubleshooting.md)
