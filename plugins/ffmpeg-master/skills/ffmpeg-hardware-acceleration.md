---
name: ffmpeg-hardware-acceleration
description: Complete GPU-accelerated encoding/decoding system. PROACTIVELY activate for: (1) NVIDIA NVENC/NVDEC encoding, (2) Intel Quick Sync Video (QSV), (3) AMD AMF encoding, (4) Apple VideoToolbox, (5) Linux VAAPI setup, (6) Vulkan Video (FFmpeg 7.1+/8.0), (7) GPU pipeline optimization, (8) Hardware decoder + encoder chains, (9) Docker GPU containers, (10) Performance benchmarking. Provides: Platform-specific commands, preset comparisons, quality tuning, full GPU pipeline examples, troubleshooting guides. Ensures: Maximum encoding speed with optimal quality using GPU acceleration.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

## Quick Reference

| Platform | Encoder | Decoder | Detect Command |
|----------|---------|---------|----------------|
| NVIDIA | `h264_nvenc`, `hevc_nvenc`, `av1_nvenc` | `h264_cuvid`, `hevc_cuvid` | `ffmpeg -encoders \| grep nvenc` |
| Intel QSV | `h264_qsv`, `hevc_qsv`, `av1_qsv` | `h264_qsv`, `hevc_qsv` | `ffmpeg -encoders \| grep qsv` |
| AMD AMF | `h264_amf`, `hevc_amf`, `av1_amf` | N/A (use software) | `ffmpeg -encoders \| grep amf` |
| Apple | `h264_videotoolbox`, `hevc_videotoolbox` | `h264_videotoolbox` | macOS only |
| VAAPI | `h264_vaapi`, `hevc_vaapi`, `av1_vaapi` | with `-hwaccel vaapi` | Linux only |

## When to Use This Skill

Use when **GPU acceleration is needed**:
- Encoding speed is critical (10-30x faster than CPU)
- Processing large batches of videos
- Real-time encoding for streaming
- Server-side transcoding at scale
- Docker containers with GPU passthrough

**Key decision**: GPU encoding trades some quality for massive speed. Use `-cq` or `-qp` for quality control.

---

# FFmpeg Hardware Acceleration (2025)

Comprehensive guide to GPU-accelerated encoding and decoding with NVIDIA, Intel, AMD, Apple, and Vulkan.

## Hardware Acceleration Overview

Hardware acceleration uses dedicated GPU/SoC components for video processing:
- **NVENC/NVDEC** (NVIDIA): Dedicated video encode/decode engines
- **QSV** (Intel): Quick Sync Video on Intel CPUs with integrated graphics
- **AMF** (AMD): Advanced Media Framework for AMD GPUs
- **VideoToolbox** (Apple): macOS/iOS hardware acceleration
- **VAAPI** (Linux): Video Acceleration API (Intel, AMD on Linux)
- **Vulkan Video** (Cross-platform): FFmpeg 7.1+/8.0 GPU acceleration

### Performance Comparison (2025 Benchmarks)

| Method | Speed | Quality | Power | Use Case |
|--------|-------|---------|-------|----------|
| libx264 (CPU) | 1x | Best | High | Quality-critical |
| libx265 (CPU) | 0.3x | Best | Very High | Archival |
| h264_nvenc | 10-20x | Good | Low | Real-time, streaming |
| hevc_nvenc | 8-15x | Good | Low | 4K streaming |
| h264_qsv | 8-15x | Good | Very Low | Laptop, efficiency |
| h264_amf | 8-15x | Good | Low | AMD systems |

## NVIDIA NVENC/NVDEC

### Requirements
- NVIDIA GPU (GTX 600+ / Quadro K series+)
- NVIDIA drivers 450+
- FFmpeg built with `--enable-nvenc --enable-cuda --enable-cuvid`

### Check NVIDIA Support
```bash
# Check available NVIDIA codecs
ffmpeg -encoders | grep nvenc
ffmpeg -decoders | grep cuvid

# Check GPU info
nvidia-smi

# List hardware accelerators
ffmpeg -hwaccels
```

### Basic NVENC Encoding

```bash
# H.264 NVENC encoding
ffmpeg -i input.mp4 -c:v h264_nvenc -preset p4 -b:v 5M output.mp4

# H.265/HEVC NVENC encoding
ffmpeg -i input.mp4 -c:v hevc_nvenc -preset p4 -b:v 4M output.mp4

# AV1 NVENC (RTX 40 series+)
ffmpeg -i input.mp4 -c:v av1_nvenc -preset p4 -b:v 3M output.mp4
```

### NVENC Presets (FFmpeg 7+)

| Preset | Speed | Quality | Use Case |
|--------|-------|---------|----------|
| p1 | Fastest | Lowest | Real-time capture |
| p2 | Faster | Low | Screen recording |
| p3 | Fast | Medium | General streaming |
| p4 | Medium | Good | **Recommended** |
| p5 | Slow | Better | High-quality streaming |
| p6 | Slower | Best | Offline encoding |
| p7 | Slowest | Highest | Maximum quality |

### Full GPU Pipeline (Decode + Encode)

```bash
# Keep frames in GPU memory (fastest)
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -c:v h264_nvenc \
  -preset p4 \
  -b:v 5M \
  -c:a copy \
  output.mp4
```

### GPU Scaling and Filtering

```bash
# GPU-based scaling with scale_cuda
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -c:v h264_nvenc \
  -preset p4 \
  output.mp4

# GPU overlay with overlay_cuda
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i overlay.mp4 \
  -filter_complex "[0:v][1:v]overlay_cuda=10:10" \
  -c:v h264_nvenc output.mp4
```

### NVENC Quality Optimization

```bash
# High quality with lookahead
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc \
  -preset p5 \
  -tune hq \
  -rc vbr \
  -cq 23 \
  -b:v 0 \
  -rc-lookahead 32 \
  -spatial-aq 1 \
  -temporal-aq 1 \
  -c:a copy \
  output.mp4

# Constant quality mode (CQP)
ffmpeg -i input.mp4 \
  -c:v h264_nvenc \
  -preset p4 \
  -rc constqp \
  -qp 23 \
  -c:a copy \
  output.mp4
```

### NVENC Two-Pass Encoding

```bash
# Two-pass for best quality (ABR)
ffmpeg -i input.mp4 \
  -c:v h264_nvenc \
  -preset p5 \
  -2pass 1 \
  -b:v 5M \
  -c:a copy \
  output.mp4
```

### NVENC B-Frames and GOP

```bash
# Enable B-frames for better compression
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc \
  -preset p4 \
  -bf 4 \
  -b_ref_mode 2 \
  -g 250 \
  -c:a copy \
  output.mp4
```

## Intel Quick Sync Video (QSV)

### Requirements
- Intel CPU with integrated graphics (Sandy Bridge+)
- Intel Media SDK or oneVPL
- FFmpeg built with `--enable-libmfx` or `--enable-libvpl`

### Check QSV Support
```bash
# Check available QSV codecs
ffmpeg -encoders | grep qsv
ffmpeg -decoders | grep qsv

# Verify Intel GPU access (Linux)
ls /dev/dri/
vainfo  # Check VAAPI support
```

### Basic QSV Encoding

```bash
# Initialize QSV device
ffmpeg -init_hw_device qsv=hw \
  -filter_hw_device hw \
  -i input.mp4 \
  -c:v h264_qsv \
  -preset medium \
  -b:v 5M \
  output.mp4

# H.265/HEVC QSV
ffmpeg -init_hw_device qsv=hw \
  -filter_hw_device hw \
  -i input.mp4 \
  -c:v hevc_qsv \
  -preset medium \
  -b:v 4M \
  output.mp4

# AV1 QSV (Intel Arc, 12th gen+)
ffmpeg -init_hw_device qsv=hw \
  -filter_hw_device hw \
  -i input.mp4 \
  -c:v av1_qsv \
  -preset medium \
  -b:v 3M \
  output.mp4
```

### Full QSV Pipeline

```bash
# Decode and encode on GPU
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -i input.mp4 \
  -c:v h264_qsv \
  -preset medium \
  -b:v 5M \
  output.mp4
```

### QSV with Scaling

```bash
# GPU scaling with vpp_qsv
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -i input.mp4 \
  -vf "vpp_qsv=w=1280:h=720" \
  -c:v h264_qsv \
  -preset medium \
  output.mp4
```

### VVC/H.266 QSV Decoding (FFmpeg 7.1+)

```bash
# Hardware VVC decoding
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -c:v vvc_qsv \
  -i input.vvc \
  -c:v h264_qsv \
  output.mp4
```

## AMD AMF

### Requirements
- AMD GPU (GCN or newer)
- AMD drivers with AMF support
- FFmpeg built with `--enable-amf`

### Check AMF Support
```bash
ffmpeg -encoders | grep amf
```

### Basic AMF Encoding

```bash
# H.264 AMF
ffmpeg -i input.mp4 \
  -c:v h264_amf \
  -quality balanced \
  -b:v 5M \
  output.mp4

# H.265/HEVC AMF
ffmpeg -i input.mp4 \
  -c:v hevc_amf \
  -quality balanced \
  -b:v 4M \
  output.mp4

# AV1 AMF (RDNA3+)
ffmpeg -i input.mp4 \
  -c:v av1_amf \
  -quality balanced \
  -b:v 3M \
  output.mp4
```

### AMF Quality Presets

| Preset | Description |
|--------|-------------|
| speed | Fastest encoding |
| balanced | **Recommended** |
| quality | Best quality |

### AMD Hardware Upscaling (FFmpeg 8.0+)

```bash
# Super resolution upscaling
ffmpeg -i input.mp4 \
  -vf "sr_amf=4096:2160:algorithm=sr1-1" \
  -c:v hevc_amf \
  output.mp4
```

## VAAPI (Linux)

### Requirements
- Intel, AMD, or NVIDIA GPU on Linux
- VAAPI drivers (intel-media-driver, mesa-va-drivers)
- FFmpeg built with `--enable-vaapi`

### Check VAAPI Support
```bash
# Check VAAPI info
vainfo

# List VAAPI codecs
ffmpeg -encoders | grep vaapi
ffmpeg -decoders | grep vaapi
```

### Basic VAAPI Encoding

```bash
# H.264 VAAPI
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 \
  -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi \
  -b:v 5M \
  output.mp4

# H.265/HEVC VAAPI
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 \
  -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi \
  -b:v 4M \
  output.mp4
```

### Full VAAPI Pipeline

```bash
# Decode and encode on GPU
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 \
  -c:v h264_vaapi \
  -b:v 5M \
  output.mp4
```

### VAAPI Scaling

```bash
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 \
  -vf 'scale_vaapi=w=1280:h=720' \
  -c:v h264_vaapi \
  output.mp4
```

### VVC VAAPI Decoding (FFmpeg 8.0+)

```bash
# Hardware VVC/H.266 decoding
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -c:v vvc \
  -i input.vvc \
  output.mp4
```

## Apple VideoToolbox

### Requirements
- macOS 10.8+ or iOS 8+
- FFmpeg built with `--enable-videotoolbox`

### Check VideoToolbox Support
```bash
ffmpeg -encoders | grep videotoolbox
ffmpeg -decoders | grep videotoolbox
```

### Basic VideoToolbox Encoding

```bash
# H.264 VideoToolbox
ffmpeg -i input.mp4 \
  -c:v h264_videotoolbox \
  -b:v 5M \
  output.mp4

# H.265/HEVC VideoToolbox
ffmpeg -i input.mp4 \
  -c:v hevc_videotoolbox \
  -b:v 4M \
  -tag:v hvc1 \
  output.mp4

# ProRes VideoToolbox
ffmpeg -i input.mp4 \
  -c:v prores_videotoolbox \
  -profile:v 3 \
  output.mov
```

### VideoToolbox Quality Settings

```bash
# Quality-based encoding
ffmpeg -i input.mp4 \
  -c:v h264_videotoolbox \
  -q:v 65 \
  output.mp4

# Hardware accelerated decode + encode
ffmpeg -hwaccel videotoolbox \
  -i input.mp4 \
  -c:v h264_videotoolbox \
  -b:v 5M \
  output.mp4
```

## Vulkan Video (FFmpeg 7.1+/8.0)

### Overview
Vulkan Video provides cross-platform GPU acceleration using Vulkan compute shaders.

### FFmpeg 7.1 Vulkan Features
- H.264 Vulkan encoding
- H.265/HEVC Vulkan encoding

### FFmpeg 8.0 Vulkan Features
- AV1 Vulkan encoding
- VP9 Vulkan decoding
- FFv1 Vulkan encode/decode
- ProRes RAW Vulkan decode

### Basic Vulkan Encoding

```bash
# H.264 Vulkan
ffmpeg -init_hw_device vulkan \
  -i input.mp4 \
  -c:v h264_vulkan \
  -b:v 5M \
  output.mp4

# AV1 Vulkan (FFmpeg 8.0+)
ffmpeg -init_hw_device vulkan \
  -i input.mp4 \
  -c:v av1_vulkan \
  -b:v 3M \
  output.mp4
```

### Full Vulkan Pipeline

```bash
# Complete Vulkan decode-filter-encode
ffmpeg -init_hw_device vulkan=vk \
  -filter_hw_device vk \
  -hwaccel vulkan \
  -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "scale_vulkan=1280:720" \
  -c:v h264_vulkan \
  output.mp4
```

## Docker with Hardware Acceleration

### NVIDIA GPU in Docker

```bash
# Run with NVIDIA GPU support
docker run --gpus all \
  --rm \
  -v $(pwd):/data \
  jrottenberg/ffmpeg:nvidia \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i /data/input.mp4 \
  -c:v h264_nvenc \
  /data/output.mp4
```

### Intel QSV in Docker

```bash
# Run with Intel GPU access
docker run --rm \
  --device=/dev/dri:/dev/dri \
  -v $(pwd):/data \
  jrottenberg/ffmpeg:vaapi \
  -hwaccel qsv \
  -i /data/input.mp4 \
  -c:v h264_qsv \
  /data/output.mp4
```

## Troubleshooting

### Common Issues

**"No NVENC capable devices found"**
```bash
# Check GPU support
nvidia-smi
# Verify driver version
nvidia-smi --query-gpu=driver_version --format=csv
# Check CUDA version
nvcc --version
```

**"Cannot load libcuda.so"**
```bash
# Set library path (Linux)
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

**QSV "Unsupported format"**
```bash
# Force pixel format conversion
ffmpeg -i input.mp4 \
  -vf "format=nv12" \
  -c:v h264_qsv \
  output.mp4
```

**VAAPI permission denied**
```bash
# Add user to video/render group
sudo usermod -aG video $USER
sudo usermod -aG render $USER
# Re-login or use newgrp
```

### Performance Debugging

```bash
# Benchmark encode speed
ffmpeg -benchmark -i input.mp4 -c:v h264_nvenc -f null -

# Show hardware decode stats
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -benchmark -i input.mp4 -f null -

# Monitor GPU usage (NVIDIA)
nvidia-smi dmon -s u

# Monitor GPU usage (Intel)
intel_gpu_top
```

## Best Practices

1. **Use full GPU pipelines** when possible to avoid CPU-GPU memory transfers
2. **Match decode and encode hardware** for best performance
3. **Use appropriate presets** - faster isn't always better for quality
4. **Enable lookahead and AQ** for quality-critical encodes
5. **Test on target hardware** - quality varies by GPU generation
6. **Monitor GPU memory** for high-resolution content
7. **Consider power efficiency** for laptops and servers
8. **Update drivers regularly** for performance and feature improvements

## Recommended Settings by Use Case

### Live Streaming
```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input \
  -c:v h264_nvenc -preset p3 -tune ll -zerolatency 1 -b:v 6M \
  -f flv rtmp://server/live/stream
```

### VOD Encoding (Quality)
```bash
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p6 -tune hq \
  -rc vbr -cq 22 -b:v 0 \
  -rc-lookahead 32 -spatial-aq 1 \
  output.mp4
```

### Batch Processing
```bash
# Multiple parallel streams on one GPU
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input1.mp4 -c:v h264_nvenc output1.mp4 &
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input2.mp4 -c:v h264_nvenc output2.mp4 &
wait
```

This guide covers hardware acceleration fundamentals. For specific platform optimizations and advanced configurations, consult the respective vendor documentation.
