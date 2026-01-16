# FFmpeg GPU/CUDA and filter_complex Research Summary

> Research compiled: January 2026
> Purpose: Comprehensive reference for updating ffmpeg-master plugin skills

## Table of Contents

1. [GPU Hardware Acceleration Overview](#gpu-hardware-acceleration-overview)
2. [NVIDIA NVENC/NVDEC Deep Dive](#nvidia-nvencnvdec-deep-dive)
3. [CUDA Filters Reference](#cuda-filters-reference)
4. [Intel Quick Sync Video (QSV)](#intel-quick-sync-video-qsv)
5. [AMD AMF and VAAPI](#amd-amf-and-vaapi)
6. [Vulkan Video (FFmpeg 8.0+)](#vulkan-video-ffmpeg-80)
7. [GPU Memory Management](#gpu-memory-management)
8. [Multi-GPU Encoding](#multi-gpu-encoding)
9. [filter_complex Syntax Reference](#filter_complex-syntax-reference)
10. [Common filter_complex Patterns](#common-filter_complex-patterns)
11. [Advanced Filtergraph Examples](#advanced-filtergraph-examples)
12. [Performance Optimization](#performance-optimization)

---

## GPU Hardware Acceleration Overview

### Available Hardware Acceleration Methods

| Platform | Encoder Suffix | Decoder Method | Filters | Platform |
|----------|----------------|----------------|---------|----------|
| NVIDIA | `_nvenc` | `-hwaccel cuda` | scale_cuda, overlay_cuda, pad_cuda | Windows/Linux |
| Intel QSV | `_qsv` | `-hwaccel qsv` | vpp_qsv, scale_qsv | Windows/Linux |
| AMD AMF | `_amf` | `-hwaccel d3d11va` | - | Windows/Linux |
| VAAPI | `_vaapi` | `-hwaccel vaapi` | scale_vaapi | Linux |
| Vulkan | `_vulkan` | `-hwaccel vulkan` | scale_vulkan | Cross-platform |
| Apple | `_videotoolbox` | `-hwaccel videotoolbox` | - | macOS/iOS |

### Supported Codecs by Platform (2025-2026)

| Codec | NVIDIA | Intel QSV | AMD AMF | VAAPI | Vulkan |
|-------|--------|-----------|---------|-------|--------|
| H.264 | Encode/Decode | Encode/Decode | Encode/Decode | Encode/Decode | Encode |
| H.265/HEVC | Encode/Decode | Encode/Decode | Encode/Decode | Encode/Decode | Encode |
| AV1 | Encode/Decode (40+) | Encode (Arc) | Encode (RDNA3+) | Encode/Decode | Encode (8.0+) |
| VP9 | Decode | Decode | - | Decode | Decode (8.0+) |
| VVC/H.266 | - | Decode (7.1+) | - | Decode (8.0+) | - |
| FFv1 | - | - | - | - | Encode/Decode (8.0+) |

### Detection Commands

```bash
# List all hardware accelerators
ffmpeg -hwaccels

# Check NVIDIA encoders/decoders
ffmpeg -encoders | grep nvenc
ffmpeg -decoders | grep cuvid

# Check Intel QSV
ffmpeg -encoders | grep qsv
ffmpeg -decoders | grep qsv

# Check AMD AMF
ffmpeg -encoders | grep amf

# Check VAAPI (Linux)
vainfo
ffmpeg -encoders | grep vaapi

# Check Vulkan (FFmpeg 8.0+)
ffmpeg -encoders | grep vulkan
ffmpeg -decoders | grep vulkan
```

---

## NVIDIA NVENC/NVDEC Deep Dive

### Architecture Overview

NVIDIA GPUs contain dedicated hardware blocks for video encoding (NVENC) and decoding (NVDEC) that operate independently from CUDA cores. This means video encoding/decoding can run simultaneously with graphics or compute workloads without performance impact.

### Requirements

- **GPU**: GTX 600 series / Quadro K series or newer
- **Drivers**: NVIDIA 450+ (Linux), 456+ (Windows)
- **FFmpeg Build**: `--enable-nvenc --enable-cuda --enable-cuvid --enable-libnpp`
- **SDK**: NVIDIA Video Codec SDK (nv-codec-headers)

### NVENC Presets (FFmpeg 7.0+)

| Preset | Speed | Quality | Description |
|--------|-------|---------|-------------|
| p1 | Fastest | Lowest | Real-time capture, screen recording |
| p2 | Faster | Low | Quick previews |
| p3 | Fast | Medium | General streaming |
| p4 | Medium | Good | **Recommended default** |
| p5 | Slow | Better | High-quality streaming |
| p6 | Slower | Best | Offline encoding |
| p7 | Slowest | Highest | Maximum quality |

### NVENC Tune Options

| Tune | Use Case |
|------|----------|
| `hq` | High quality encoding |
| `ll` | Low latency (streaming) |
| `ull` | Ultra low latency |
| `lossless` | Lossless encoding |

### Basic NVENC Commands

```bash
# Simple H.264 encoding
ffmpeg -i input.mp4 -c:v h264_nvenc -preset p4 -b:v 5M output.mp4

# H.265/HEVC encoding
ffmpeg -i input.mp4 -c:v hevc_nvenc -preset p4 -b:v 4M output.mp4

# AV1 encoding (RTX 40 series+)
ffmpeg -i input.mp4 -c:v av1_nvenc -preset p4 -b:v 3M output.mp4
```

### Full GPU Pipeline (Critical for Performance)

The key optimization is keeping frames in GPU memory throughout the pipeline:

```bash
# OPTIMAL: Full GPU decode-encode pipeline
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -c:v h264_nvenc \
  -preset p4 \
  -b:v 5M \
  output.mp4
```

**Why this matters**: Without `-hwaccel_output_format cuda`, decoded frames are:
1. Copied from GPU to system memory via PCIe
2. Processed in system memory
3. Copied back to GPU memory via PCIe for encoding

This creates significant latency and reduces throughput by up to 50%.

### GPU Scaling with NVENC

```bash
# Using scale_cuda filter
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -c:v h264_nvenc \
  output.mp4

# Using built-in decoder resize (cuvid)
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -resize 1280x720 \
  -i input.mp4 \
  -c:v h264_nvenc \
  output.mp4

# Using scale_npp (NPP library - more options)
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_npp=1280:720:interp_algo=super \
  -c:v h264_nvenc \
  output.mp4
```

### NVENC Quality Optimization

```bash
# High-quality VBR encoding with lookahead
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
  -bf 4 \
  -b_ref_mode middle \
  -c:a copy \
  output.mp4

# Constant quality mode (CQP)
ffmpeg -i input.mp4 \
  -c:v h264_nvenc \
  -preset p4 \
  -rc constqp \
  -qp 23 \
  output.mp4

# Two-pass encoding (best quality)
ffmpeg -i input.mp4 \
  -c:v h264_nvenc \
  -preset p5 \
  -2pass 1 \
  -b:v 5M \
  output.mp4
```

### NVENC Quality Parameters

| Parameter | Description | Recommended |
|-----------|-------------|-------------|
| `-rc-lookahead` | Frames to look ahead for rate control | 20-32 |
| `-spatial-aq` | Spatial adaptive quantization | 1 (enabled) |
| `-temporal-aq` | Temporal adaptive quantization | 1 (enabled) |
| `-aq-strength` | AQ strength (1-15) | 8 |
| `-bf` | Number of B-frames | 3-4 |
| `-b_ref_mode` | B-frame reference mode | middle |
| `-cq` | Constant quality value | 18-28 |

### Live Streaming with NVENC

```bash
# Low-latency streaming to RTMP
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input \
  -c:v h264_nvenc \
  -preset p3 \
  -tune ll \
  -zerolatency 1 \
  -b:v 6M \
  -maxrate 6M \
  -bufsize 12M \
  -g 120 \
  -keyint_min 120 \
  -c:a aac -b:a 160k \
  -f flv rtmp://server/live/stream

# WebRTC with WHIP (FFmpeg 8.0+)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input \
  -c:v h264_nvenc \
  -preset p4 \
  -tune ll \
  -f whip "https://whip-endpoint/publish"
```

---

## CUDA Filters Reference

### Available CUDA Filters (FFmpeg 8.0+)

| Filter | Description | Key Parameters |
|--------|-------------|----------------|
| `scale_cuda` | GPU video scaling | `w`, `h`, `format`, `interp_algo` |
| `scale_npp` | NPP-based scaling | `w`, `h`, `interp_algo` |
| `overlay_cuda` | GPU overlay/compositing | `x`, `y`, `eof_action` |
| `pad_cuda` | GPU padding (8.0+) | `w`, `h`, `x`, `y`, `color` |
| `chromakey_cuda` | GPU chroma keying | `color`, `similarity`, `blend` |
| `colorspace_cuda` | Color space conversion | `all`, `space`, `trc`, `primaries` |
| `bilateral_cuda` | Bilateral filter | `sigmaS`, `sigmaR`, `window_size` |
| `bwdif_cuda` | Deinterlacing | `mode`, `parity`, `deint` |
| `hwupload_cuda` | Upload to GPU | - |
| `hwdownload` | Download from GPU | - |

### scale_cuda Examples

```bash
# Basic scaling
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1280:720" \
  -c:v h264_nvenc output.mp4

# Scale with pixel format conversion
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1920:1080:format=yuv420p" \
  -c:v h264_nvenc output.mp4

# Maintain aspect ratio
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1280:-2" \
  -c:v h264_nvenc output.mp4
```

### scale_npp (NVIDIA Performance Primitives)

```bash
# High-quality downscaling with super-sampling
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_npp=1280:720:interp_algo=super" \
  -c:v h264_nvenc output.mp4

# Lanczos interpolation
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_npp=1920:1080:interp_algo=lanczos" \
  -c:v h264_nvenc output.mp4
```

**Interpolation Algorithms (scale_npp):**
| Algorithm | Quality | Speed | Best For |
|-----------|---------|-------|----------|
| `nn` | Low | Fastest | Pixel art, nearest neighbor |
| `linear` | Medium | Fast | General use |
| `cubic` | Good | Medium | Smooth scaling |
| `lanczos` | High | Slow | High quality |
| `super` | Best | Slowest | Downscaling |

### overlay_cuda

```bash
# Basic overlay
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i overlay.mp4 \
  -filter_complex "[0:v][1:v]overlay_cuda=10:10" \
  -c:v h264_nvenc output.mp4

# Overlay with scaling
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i logo.png \
  -filter_complex "[1:v]scale_cuda=200:-2[logo];[0:v][logo]overlay_cuda=W-w-10:H-h-10" \
  -c:v h264_nvenc output.mp4
```

**overlay_cuda Pixel Format Requirements:**
- Main input: NV12 or YUV420P
- Overlay input: NV12, YUV420P, or YUVA420P
- Main and overlay formats should match (no cross-format overlay)

### pad_cuda (FFmpeg 8.0+)

```bash
# Add black letterboxing
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "pad_cuda=1920:1080:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v h264_nvenc output.mp4

# Scale and letterbox pipeline
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1920:-2,pad_cuda=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v h264_nvenc output.mp4
```

### chromakey_cuda

```bash
# Green screen removal on GPU
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i greenscreen.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i background.mp4 \
  -filter_complex "[0:v]chromakey_cuda=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay_cuda" \
  -c:v h264_nvenc output.mp4
```

### hwupload_cuda and hwdownload

When mixing CPU and GPU filters, use these to transfer frames:

```bash
# CPU decode -> CPU filter -> GPU encode
ffmpeg -i input.mp4 \
  -vf "fade=in:0:30,hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# GPU decode -> CPU filter -> GPU encode (download and re-upload)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "hwdownload,format=nv12,drawtext=text='Hello':fontsize=48,hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# Complete hybrid pipeline
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -filter_complex "\
    [0:v]scale_cuda=1920:1080[scaled];\
    [scaled]hwdownload,format=nv12[cpu];\
    [cpu]drawtext=text='Watermark':fontsize=48:x=10:y=10[text];\
    [text]hwupload_cuda[gpu]" \
  -map "[gpu]" \
  -c:v h264_nvenc output.mp4
```

---

## Intel Quick Sync Video (QSV)

### Requirements

- Intel CPU with integrated graphics (Sandy Bridge+) or Intel Arc GPU
- Intel Media SDK or oneVPL (Video Processing Library)
- FFmpeg built with `--enable-libmfx` or `--enable-libvpl`

### Detection

```bash
# Check QSV support
ffmpeg -encoders | grep qsv
ffmpeg -decoders | grep qsv

# Verify GPU access (Linux)
ls /dev/dri/
vainfo

# Check oneVPL (FFmpeg 6.0+)
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw 2>&1 | head
```

### QSV Encoders

| Encoder | Codec | Notes |
|---------|-------|-------|
| `h264_qsv` | H.264/AVC | Most compatible |
| `hevc_qsv` | H.265/HEVC | Better compression |
| `av1_qsv` | AV1 | Intel Arc, 12th gen+ |
| `mjpeg_qsv` | MJPEG | Fast for thumbnails |
| `mpeg2_qsv` | MPEG-2 | Legacy support |
| `vp9_qsv` | VP9 | WebM support |

### Basic QSV Encoding

```bash
# Initialize QSV device
ffmpeg -init_hw_device qsv=hw \
  -filter_hw_device hw \
  -i input.mp4 \
  -c:v h264_qsv \
  -preset medium \
  -global_quality 22 \
  output.mp4

# Full QSV pipeline (decode + encode)
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -i input.mp4 \
  -c:v h264_qsv \
  -preset medium \
  -b:v 5M \
  output.mp4
```

### QSV Quality Settings

```bash
# Constant quality (recommended)
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 \
  -c:v hevc_qsv \
  -preset slow \
  -global_quality 22 \
  -look_ahead 1 \
  output.mp4

# VBR with lookahead
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 \
  -c:v h264_qsv \
  -preset medium \
  -b:v 5M \
  -maxrate 7M \
  -bufsize 10M \
  -look_ahead 1 \
  -look_ahead_depth 40 \
  output.mp4
```

**QSV Quality Parameters:**
| Parameter | Description | Range |
|-----------|-------------|-------|
| `-global_quality` | Quality level (like CRF) | 1-51 (lower = better) |
| `-preset` | Encoding speed/quality | `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow` |
| `-look_ahead` | Enable lookahead | 0 or 1 |
| `-look_ahead_depth` | Lookahead frames | 10-100 |

### QSV with VPP (Video Processing Pipeline)

```bash
# GPU scaling with vpp_qsv
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -i input.mp4 \
  -vf "vpp_qsv=w=1280:h=720" \
  -c:v h264_qsv \
  output.mp4

# Deinterlacing with VPP
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -i interlaced.mp4 \
  -vf "vpp_qsv=deinterlace=2" \
  -c:v h264_qsv \
  output.mp4

# Multiple VPP operations
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -i input.mp4 \
  -vf "vpp_qsv=w=1920:h=1080:deinterlace=2:denoise=50" \
  -c:v hevc_qsv \
  output.mp4
```

### VVC QSV Decoding (FFmpeg 7.1+)

```bash
# Hardware VVC decode
ffmpeg -hwaccel qsv \
  -hwaccel_output_format qsv \
  -c:v vvc_qsv \
  -i input.vvc \
  -c:v h264_qsv \
  output.mp4
```

### Multi-GPU QSV (Linux)

```bash
# Select specific GPU
ffmpeg -init_hw_device qsv=hw:/dev/dri/renderD129 \
  -filter_hw_device hw \
  -i input.mp4 \
  -c:v h264_qsv output.mp4
```

---

## AMD AMF and VAAPI

### AMD AMF (Windows/Linux)

AMD Advanced Media Framework is the primary method for AMD GPU encoding on Windows.

```bash
# Check AMF support
ffmpeg -encoders | grep amf

# H.264 AMF encoding
ffmpeg -i input.mp4 \
  -c:v h264_amf \
  -quality balanced \
  -b:v 5M \
  output.mp4

# H.265 AMF encoding
ffmpeg -i input.mp4 \
  -c:v hevc_amf \
  -quality balanced \
  -b:v 4M \
  output.mp4

# AV1 AMF (RDNA3+ GPUs)
ffmpeg -i input.mp4 \
  -c:v av1_amf \
  -quality balanced \
  -b:v 3M \
  output.mp4
```

**AMF Quality Presets:**
| Preset | Description |
|--------|-------------|
| `speed` | Fastest encoding |
| `balanced` | **Recommended** |
| `quality` | Best quality |

### AMF with Hardware Decode

```bash
# DX11 decode -> AMF encode
ffmpeg -hwaccel d3d11va \
  -hwaccel_output_format d3d11 \
  -i input.mp4 \
  -c:v hevc_amf \
  -quality balanced \
  output.mp4

# DX9 decode (older systems)
ffmpeg -hwaccel dxva2 \
  -hwaccel_output_format dxva2_vld \
  -i input.mp4 \
  -c:v h264_amf \
  output.mp4
```

### VAAPI (Linux - Intel and AMD)

VAAPI is the primary hardware acceleration method on Linux, supporting both Intel and AMD GPUs.

```bash
# Check VAAPI support
vainfo
ffmpeg -encoders | grep vaapi

# Basic VAAPI encoding
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 \
  -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi \
  -b:v 5M \
  output.mp4

# Full VAAPI pipeline
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
# GPU scaling with scale_vaapi
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 \
  -vf 'scale_vaapi=w=1280:h=720' \
  -c:v h264_vaapi \
  output.mp4

# Deinterlace with VAAPI
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i interlaced.mp4 \
  -vf 'deinterlace_vaapi' \
  -c:v h264_vaapi \
  output.mp4
```

### VAAPI Rate Control

```bash
# Constant quality (CQP)
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 \
  -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi \
  -rc_mode CQP \
  -qp 23 \
  output.mp4

# Variable bitrate (VBR)
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 \
  -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi \
  -rc_mode VBR \
  -b:v 5M \
  -maxrate 7M \
  output.mp4
```

### VVC VAAPI Decoding (FFmpeg 8.0+)

```bash
# Hardware VVC decode on Intel/AMD Linux
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.vvc \
  -c:v h264_vaapi \
  output.mp4
```

---

## Vulkan Video (FFmpeg 8.0+)

### Overview

Vulkan Video provides cross-platform GPU acceleration using Vulkan 1.3 compute shaders. Unlike proprietary accelerators (NVENC, QSV, AMF), Vulkan codecs work on any Vulkan 1.3 implementation.

### FFmpeg 8.0 Vulkan Features

| Codec | Encode | Decode | Notes |
|-------|--------|--------|-------|
| H.264 | Yes | - | Via compute shaders |
| H.265/HEVC | Yes | - | Via compute shaders |
| AV1 | Yes (8.0+) | - | Cross-platform GPU AV1 |
| VP9 | - | Yes (8.0+) | Hardware decode |
| FFv1 | Yes (8.0+) | Yes (8.0+) | Lossless codec |
| ProRes RAW | - | Yes (8.0+) | Apple format |

### Basic Vulkan Encoding

```bash
# H.264 Vulkan encoding
ffmpeg -init_hw_device vulkan \
  -i input.mp4 \
  -c:v h264_vulkan \
  -b:v 5M \
  output.mp4

# H.265 Vulkan encoding
ffmpeg -init_hw_device vulkan \
  -i input.mp4 \
  -c:v hevc_vulkan \
  -b:v 4M \
  output.mp4

# AV1 Vulkan encoding (8.0+)
ffmpeg -init_hw_device vulkan \
  -i input.mp4 \
  -c:v av1_vulkan \
  -b:v 3M \
  output.mp4

# FFv1 Vulkan lossless (8.0+)
ffmpeg -init_hw_device vulkan \
  -i input.mp4 \
  -c:v ffv1_vulkan \
  output.mkv
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

### VP9 Vulkan Decoding

```bash
# Hardware VP9 decode
ffmpeg -init_hw_device vulkan \
  -hwaccel vulkan \
  -hwaccel_output_format vulkan \
  -i input.webm \
  -c:v h264_vulkan \
  output.mp4
```

### Lossless Screen Capture with FFv1 Vulkan

```bash
# Linux X11 screen capture
ffmpeg -init_hw_device vulkan \
  -f x11grab -framerate 60 -i :0.0 \
  -c:v ffv1_vulkan \
  screen_capture.mkv

# Windows desktop capture
ffmpeg -init_hw_device vulkan \
  -f gdigrab -framerate 60 -i desktop \
  -c:v ffv1_vulkan \
  screen_capture.mkv
```

### Vulkan Requirements

- Vulkan 1.3 driver support
- Mesa 24.1+ for open-source drivers
- Latest GPU drivers for optimal performance
- FFmpeg 8.0+ for AV1, VP9, FFv1 support

---

## GPU Memory Management

### Critical Concepts

1. **PCIe Bandwidth**: Transfers between CPU and GPU memory are limited by PCIe bandwidth
2. **GPU Memory**: Frames kept in GPU memory avoid costly transfers
3. **Zero-Copy**: Optimal pipelines keep data entirely on GPU

### Memory Flow Patterns

**Pattern 1: Full GPU Pipeline (Optimal)**
```
Input File -> GPU Decode -> GPU Filter -> GPU Encode -> Output File
                    |          |           |
                    v          v           v
                  [GPU Memory - No PCIe Transfer]
```

**Pattern 2: CPU Filter Insertion (Suboptimal)**
```
Input -> GPU Decode -> hwdownload -> CPU Filter -> hwupload -> GPU Encode -> Output
                           |                           |
                           v                           v
                     [PCIe Transfer]             [PCIe Transfer]
```

**Pattern 3: Software Decode + GPU Encode**
```
Input -> CPU Decode -> hwupload -> GPU Encode -> Output
                          |
                          v
                    [PCIe Transfer]
```

### Optimal Command Patterns

```bash
# OPTIMAL: Full GPU pipeline
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -c:v h264_nvenc \
  output.mp4

# SUBOPTIMAL: GPU decode, CPU filter, GPU encode
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "hwdownload,format=nv12,drawtext=text='Hello',hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# AVOID: Multiple unnecessary transfers
ffmpeg -hwaccel cuda -i input.mp4 \  # Transfers to CPU after decode
  -vf scale=1280:720 \                # CPU scaling
  -c:v h264_nvenc output.mp4          # Transfers to GPU for encode
```

### Memory Monitoring

```bash
# NVIDIA GPU memory usage
nvidia-smi dmon -s m

# Watch GPU utilization
watch -n 1 nvidia-smi

# Intel GPU monitoring
intel_gpu_top
```

### Best Practices

1. **Use `-hwaccel_output_format`**: Keep decoded frames in GPU memory
2. **Use GPU filters when available**: scale_cuda, overlay_cuda, pad_cuda
3. **Batch similar operations**: Minimize filter graph complexity
4. **Monitor GPU memory**: High-resolution content can exhaust GPU memory
5. **Use `-vsync 0`**: Prevents frame duplication overhead

---

## Multi-GPU Encoding

### NVIDIA Multi-GPU

```bash
# Specify GPU by index
ffmpeg -hwaccel cuda \
  -hwaccel_device 0 \
  -hwaccel_output_format cuda \
  -i input1.mp4 \
  -c:v h264_nvenc output1.mp4 &

ffmpeg -hwaccel cuda \
  -hwaccel_device 1 \
  -hwaccel_output_format cuda \
  -i input2.mp4 \
  -c:v h264_nvenc output2.mp4 &

wait

# Initialize specific CUDA device for filters
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -init_hw_device cuda:1 \
  -filter_complex "[0:v]scale_cuda=1280:720[scaled]" \
  -map "[scaled]" \
  -c:v h264_nvenc output.mp4
```

### Intel Multi-GPU

```bash
# Select GPU by render device path
ffmpeg -init_hw_device qsv=hw:/dev/dri/renderD128 \
  -filter_hw_device hw \
  -i input1.mp4 \
  -c:v h264_qsv output1.mp4 &

ffmpeg -init_hw_device qsv=hw:/dev/dri/renderD129 \
  -filter_hw_device hw \
  -i input2.mp4 \
  -c:v h264_qsv output2.mp4 &

wait
```

### Parallel Encoding Strategy

For maximum throughput:
1. Run 4+ parallel FFmpeg sessions
2. Use inputs with 15+ seconds to amortize initialization
3. Measure aggregate FPS across all sessions

```bash
# Environment variables for faster initialization
export CUDA_VISIBLE_DEVICES=0
export CUDA_DEVICE_MAX_CONNECTIONS=2

# Parallel encoding script
for i in {1..4}; do
  ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
    -i input_$i.mp4 \
    -c:v h264_nvenc \
    output_$i.mp4 &
done
wait
```

### 1:N Encoding (Single Input, Multiple Outputs)

More efficient than separate processes - shares CUDA context:

```bash
# Single input to multiple resolutions
ffmpeg -y -vsync 0 \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -filter_complex "[0:v]split=3[v1][v2][v3];\
    [v1]scale_cuda=1920:1080[hd];\
    [v2]scale_cuda=1280:720[sd];\
    [v3]scale_cuda=640:360[mobile]" \
  -map "[hd]" -c:v h264_nvenc -b:v 5M output_1080p.mp4 \
  -map "[sd]" -c:v h264_nvenc -b:v 2M output_720p.mp4 \
  -map "[mobile]" -c:v h264_nvenc -b:v 500k output_360p.mp4
```

---

## filter_complex Syntax Reference

### Basic Syntax

```
filter_complex "filterchain1;filterchain2;..."
```

Each filterchain consists of:
- **Input labels**: `[input_label]`
- **Filter(s)**: `filter1,filter2,...` (comma-separated)
- **Output labels**: `[output_label]`

### Syntax Components

```
[input_label1][input_label2]filter=param1=value1:param2=value2[output_label]
```

| Component | Description | Example |
|-----------|-------------|---------|
| `[0:v]` | Video stream from input 0 | First input video |
| `[1:a]` | Audio stream from input 1 | Second input audio |
| `[v0]` | Custom label | User-defined |
| `,` | Chain filters | `scale,fps` |
| `;` | Separate chains | `chain1;chain2` |
| `=` | Parameter assignment | `scale=1280:720` |
| `:` | Parameter separator | `w=1280:h=720` |

### Stream References

| Reference | Meaning |
|-----------|---------|
| `[0]` | First input (all streams) |
| `[0:v]` | First input, video stream |
| `[0:a]` | First input, audio stream |
| `[0:s]` | First input, subtitle stream |
| `[0:v:0]` | First input, first video stream |
| `[1:a:1]` | Second input, second audio stream |

### Default Labels

- Unlabeled first filter input: uses `in`
- Unlabeled last filter output: uses `out`
- Unlabeled pads connect sequentially

### Escaping Rules

When specifying filtergraphs on command line:
1. Wrap entire filtergraph in double quotes
2. Escape special characters (`[],;,:`) if needed
3. Use single quotes inside double quotes for nested strings

```bash
# Correct escaping
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]drawtext=text='Hello World':fontsize=24[out]" \
  -map "[out]" output.mp4

# Using shell variables
text="Dynamic Text"
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]drawtext=text='$text':fontsize=24[out]" \
  -map "[out]" output.mp4
```

---

## Common filter_complex Patterns

### 1. Picture-in-Picture (PiP)

```bash
# Basic PiP - small video in corner
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240[pip];\
    [0:v][pip]overlay=W-w-10:H-h-10" \
  -c:v libx264 -c:a copy output.mp4

# PiP with border
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240,drawbox=x=0:y=0:w=iw:h=ih:c=white:t=3[pip];\
    [0:v][pip]overlay=W-w-10:H-h-10" \
  output.mp4

# Animated PiP (moving)
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240[pip];\
    [0:v][pip]overlay='W-w-10-sin(t)*20':'H-h-10-cos(t)*20'" \
  output.mp4
```

### 2. Video Grid Layouts

```bash
# 2x2 Grid using hstack/vstack (fast)
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 \
  -filter_complex "\
    [0:v]scale=640:360[v0];\
    [1:v]scale=640:360[v1];\
    [2:v]scale=640:360[v2];\
    [3:v]scale=640:360[v3];\
    [v0][v1]hstack=inputs=2[top];\
    [v2][v3]hstack=inputs=2[bottom];\
    [top][bottom]vstack=inputs=2[out]" \
  -map "[out]" output.mp4

# 3x2 Grid
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 -i 5.mp4 -i 6.mp4 \
  -filter_complex "\
    [0:v]scale=426:240[v0];\
    [1:v]scale=426:240[v1];\
    [2:v]scale=426:240[v2];\
    [3:v]scale=426:240[v3];\
    [4:v]scale=426:240[v4];\
    [5:v]scale=426:240[v5];\
    [v0][v1][v2]hstack=inputs=3[top];\
    [v3][v4][v5]hstack=inputs=3[bottom];\
    [top][bottom]vstack=inputs=2[out]" \
  -map "[out]" output.mp4

# Using xstack filter (more flexible)
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 \
  -filter_complex "\
    [0:v]scale=640:360[v0];\
    [1:v]scale=640:360[v1];\
    [2:v]scale=640:360[v2];\
    [3:v]scale=640:360[v3];\
    [v0][v1][v2][v3]xstack=inputs=4:layout=0_0|640_0|0_360|640_360[out]" \
  -map "[out]" output.mp4
```

### 3. Video Transitions (xfade)

```bash
# Simple fade transition
ffmpeg -i first.mp4 -i second.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[v];\
    [0:a][1:a]acrossfade=d=1[a]" \
  -map "[v]" -map "[a]" output.mp4

# Dissolve transition
ffmpeg -i first.mp4 -i second.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=dissolve:duration=2:offset=3[v]" \
  -map "[v]" output.mp4

# Available transitions: fade, wipeleft, wiperight, wipeup, wipedown,
# slideleft, slideright, circlecrop, rectcrop, distance, fadeblack,
# fadewhite, radial, smoothleft, dissolve, pixelize, diagtl, etc.

# Multiple transitions (3 clips)
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 \
  -filter_complex "\
    [0:v]settb=AVTB,fps=30[v0];\
    [1:v]settb=AVTB,fps=30[v1];\
    [2:v]settb=AVTB,fps=30[v2];\
    [v0][v1]xfade=transition=fade:duration=1:offset=4[xf1];\
    [xf1][v2]xfade=transition=dissolve:duration=1:offset=8[out]" \
  -map "[out]" output.mp4
```

### 4. Audio Mixing

```bash
# Mix two audio tracks
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex "\
    [0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[aout]" \
  -map 0:v -map "[aout]" output.mp4

# Mix with volume control
ffmpeg -i vocals.mp4 -i music.mp3 \
  -filter_complex "\
    [0:a]volume=1.0[v0];\
    [1:a]volume=0.3[v1];\
    [v0][v1]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" output.mp4

# Audio with delay (ducking)
ffmpeg -i main.mp4 -i effect.mp3 \
  -filter_complex "\
    [1:a]adelay=2000|2000[delayed];\
    [0:a][delayed]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" output.mp4

# Merge channels (stereo from two mono)
ffmpeg -i left.wav -i right.wav \
  -filter_complex "[0:a][1:a]amerge=inputs=2[aout]" \
  -map "[aout]" stereo.wav
```

### 5. Text Overlays with Animation

```bash
# Static text overlay
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=text='Watermark':\
    fontsize=48:fontcolor=white@0.8:\
    x=10:y=H-th-10[out]" \
  -map "[out]" output.mp4

# Fade-in text
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=text='Hello':\
    fontsize=64:fontcolor=white:\
    x=(w-text_w)/2:y=(h-text_h)/2:\
    alpha='if(lt(t,1),t,1)'[out]" \
  -map "[out]" output.mp4

# Scrolling credits
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=textfile=credits.txt:\
    fontsize=32:fontcolor=white:\
    x=(w-text_w)/2:y=h-t*50[out]" \
  -map "[out]" output.mp4

# Timed text (appear/disappear)
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=text='Show at 2s':\
    fontsize=48:fontcolor=yellow:\
    x=100:y=100:\
    enable='between(t,2,5)'[out]" \
  -map "[out]" output.mp4
```

### 6. Color Correction

```bash
# Basic EQ adjustment
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]eq=brightness=0.1:contrast=1.2:saturation=1.3[out]" \
  -map "[out]" output.mp4

# Apply LUT
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]lut3d=file=cinematic.cube[out]" \
  -map "[out]" output.mp4

# Color balance adjustment
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]colorbalance=\
    rs=0.1:gs=-0.05:bs=-0.1:\
    rm=0.05:gm=0:bm=-0.05:\
    rh=0.1:gh=0:bh=-0.1[out]" \
  -map "[out]" output.mp4

# Curves adjustment
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]curves=preset=vintage[out]" \
  -map "[out]" output.mp4
```

### 7. Split and Duplicate Streams

```bash
# Split for multiple processing
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=3[v1][v2][v3];\
    [v1]scale=1920:1080[hd];\
    [v2]scale=1280:720[sd];\
    [v3]scale=640:360[mobile]" \
  -map "[hd]" hd.mp4 \
  -map "[sd]" sd.mp4 \
  -map "[mobile]" mobile.mp4

# Split video and audio separately
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=2[v1][v2];\
    [0:a]asplit=2[a1][a2];\
    [v1]scale=1280:720[vout1];\
    [v2]scale=640:360[vout2]" \
  -map "[vout1]" -map "[a1]" output1.mp4 \
  -map "[vout2]" -map "[a2]" output2.mp4
```

### 8. Video Concatenation with Filters

```bash
# Concatenate with format normalization
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 \
  -filter_complex "\
    [0:v]scale=1920:1080,fps=30,setpts=PTS-STARTPTS[v0];\
    [1:v]scale=1920:1080,fps=30,setpts=PTS-STARTPTS[v1];\
    [2:v]scale=1920:1080,fps=30,setpts=PTS-STARTPTS[v2];\
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo[a0];\
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo[a1];\
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo[a2];\
    [v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[outv][outa]" \
  -map "[outv]" -map "[outa]" output.mp4

# Loop input
ffmpeg -stream_loop 3 -i input.mp4 \
  -filter_complex "[0:v]setpts=N/FRAME_RATE/TB[out]" \
  -map "[out]" -t 60 output.mp4
```

---

## Advanced Filtergraph Examples

### 1. Complete Green Screen Pipeline

```bash
# Green screen with despill, edge cleanup, and color grading
ffmpeg -i greenscreen.mp4 -i background.mp4 \
  -filter_complex "\
    [0:v]chromakey=0x00FF00:0.2:0.1,\
         colorbalance=gs=-0.15:gm=-0.1:gh=-0.05,\
         eq=saturation=1.1[fg];\
    [1:v]scale=1920:1080[bg];\
    [bg][fg]overlay=format=auto,\
         eq=contrast=1.1:saturation=1.1,\
         colorbalance=rs=0.1:bs=-0.1:rh=0.05:bh=-0.08,\
         curves=all='0/0.02 0.5/0.5 1/0.98'[out]" \
  -map "[out]" -map 0:a \
  -c:v libx264 -crf 18 output.mp4
```

### 2. Multi-Layer Composition

```bash
# Video with lower third, logo, and timecode
ffmpeg -i main.mp4 -i logo.png -i lower_third.png \
  -filter_complex "\
    [1:v]scale=150:-1[logo];\
    [2:v]scale=400:-1[third];\
    [0:v][logo]overlay=W-w-20:20[step1];\
    [step1][third]overlay=50:H-h-80:enable='between(t,5,55)'[step2];\
    [step2]drawtext=text='%{pts\\:hms}':\
      fontsize=32:fontcolor=white:\
      x=W-tw-20:y=H-th-20[out]" \
  -map "[out]" -map 0:a output.mp4
```

### 3. GPU-Accelerated Complex Pipeline

```bash
# CUDA accelerated composition
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
       -hwaccel cuda -hwaccel_output_format cuda -i overlay.mp4 \
  -filter_complex "\
    [0:v]scale_cuda=1920:1080[main];\
    [1:v]scale_cuda=320:180[pip];\
    [main][pip]overlay_cuda=W-w-10:H-h-10[gpu];\
    [gpu]hwdownload,format=nv12[cpu];\
    [cpu]drawtext=text='Watermark':fontsize=32:x=10:y=10[text];\
    [text]hwupload_cuda[out]" \
  -map "[out]" -map 0:a \
  -c:v h264_nvenc -preset p4 output.mp4
```

### 4. Audio Visualization Overlay

```bash
# Waveform overlay on video
ffmpeg -i video.mp4 -i audio.mp3 \
  -filter_complex "\
    [1:a]showwaves=s=1920x200:mode=cline:colors=white@0.8[wave];\
    [0:v][wave]overlay=0:H-h-50[out]" \
  -map "[out]" -map 1:a output.mp4

# Spectrum analyzer
ffmpeg -i video.mp4 \
  -filter_complex "\
    [0:a]showspectrum=s=1920x200:legend=0:color=rainbow[spec];\
    [0:v][spec]overlay=0:H-h[out]" \
  -map "[out]" -map 0:a output.mp4
```

### 5. Adaptive Bitrate Prep (ABR Ladder)

```bash
# Generate HLS-ready variants
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=4[v1][v2][v3][v4];\
    [v1]scale=1920:1080[1080p];\
    [v2]scale=1280:720[720p];\
    [v3]scale=854:480[480p];\
    [v4]scale=640:360[360p];\
    [0:a]asplit=4[a1][a2][a3][a4]" \
  -map "[1080p]" -c:v libx264 -b:v 5M -maxrate 5.5M -bufsize 10M \
  -map "[a1]" -c:a aac -b:a 192k out_1080p.mp4 \
  -map "[720p]" -c:v libx264 -b:v 2.5M -maxrate 2.8M -bufsize 5M \
  -map "[a2]" -c:a aac -b:a 128k out_720p.mp4 \
  -map "[480p]" -c:v libx264 -b:v 1M -maxrate 1.2M -bufsize 2M \
  -map "[a3]" -c:a aac -b:a 96k out_480p.mp4 \
  -map "[360p]" -c:v libx264 -b:v 500k -maxrate 600k -bufsize 1M \
  -map "[a4]" -c:a aac -b:a 64k out_360p.mp4
```

### 6. Time-Based Effects

```bash
# Effects that appear at specific times
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=3[v1][v2][v3];\
    [v1]trim=0:5,setpts=PTS-STARTPTS[part1];\
    [v2]trim=5:10,setpts=PTS-STARTPTS,eq=brightness=0.2:saturation=2.0[part2];\
    [v3]trim=10,setpts=PTS-STARTPTS[part3];\
    [part1][part2][part3]concat=n=3:v=1:a=0[out]" \
  -map "[out]" -map 0:a output.mp4

# Glitch effect timed to music
ffmpeg -i music_video.mp4 \
  -filter_complex "\
    [0:v]minterpolate='mi_mode=mci:mc_mode=aobmc':\
      enable='lt(mod(t,4),0.3)'[glitch];\
    [glitch]rgbashift=rh='3*sin(t*10)':bh='-3*sin(t*10)'[out]" \
  -map "[out]" -map 0:a output.mp4
```

---

## Performance Optimization

### General Tips

1. **Avoid unnecessary filter stages** - Each filter adds processing overhead
2. **Use hardware filters when available** - scale_cuda > scale
3. **Keep frames in GPU memory** - Use `-hwaccel_output_format`
4. **Match input/output formats** - Avoid format conversions
5. **Use `-threads 0`** - Auto-detect optimal thread count

### Benchmarking

```bash
# Benchmark encoding speed
ffmpeg -benchmark -i input.mp4 -c:v libx264 -f null -

# With hardware acceleration
ffmpeg -benchmark -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -c:v h264_nvenc -f null -

# Compare CPU vs GPU
time ffmpeg -i input.mp4 -c:v libx264 -preset fast -f null -
time ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -c:v h264_nvenc -preset p4 -f null -
```

### Parallel Processing

```bash
# Segment processing (large files)
ffmpeg -i input.mp4 -c copy -map 0 -segment_time 60 \
  -f segment segment_%03d.mp4

# Process segments in parallel
for seg in segment_*.mp4; do
  ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
    -i "$seg" -c:v h264_nvenc "processed_$seg" &
done
wait

# Concatenate results
ls processed_segment_*.mp4 | sed 's/^/file /' > concat.txt
ffmpeg -f concat -safe 0 -i concat.txt -c copy final.mp4
```

### Memory Optimization

```bash
# Limit memory usage for large files
ffmpeg -i input.mp4 \
  -max_muxing_queue_size 1024 \
  -c:v libx264 output.mp4

# Use thread_queue_size for multiple inputs
ffmpeg -thread_queue_size 512 -i input1.mp4 \
       -thread_queue_size 512 -i input2.mp4 \
  -filter_complex "[0:v][1:v]overlay" output.mp4
```

---

## Sources

- [FFmpeg Hardware Acceleration Wiki](https://trac.ffmpeg.org/wiki/HWAccelIntro)
- [NVIDIA FFmpeg Transcoding Guide](https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide/)
- [Using FFmpeg with NVIDIA GPU - SDK 13.0](https://docs.nvidia.com/video-technologies/video-codec-sdk/13.0/ffmpeg-with-nvidia-gpu/index.html)
- [FFmpeg Filters Documentation](https://ffmpeg.org/ffmpeg-filters.html)
- [FFmpeg FilteringGuide Wiki](https://trac.ffmpeg.org/wiki/FilteringGuide)
- [OTTVerse - FFmpeg xfade Filter](https://ottverse.com/crossfade-between-videos-ffmpeg-xfade-filter/)
- [OTTVerse - Stack Videos with FFmpeg](https://ottverse.com/stack-videos-horizontally-vertically-grid-with-ffmpeg/)
- [Intel Media SDK FFmpeg QSV Wiki](https://github.com/intel/media-delivery/blob/master/doc/features/ffmpeg-qsv/README.md)
- [AMD AMF FFmpeg Wiki](https://github.com/GPUOpen-LibrariesAndSDKs/AMF/wiki/FFmpeg-and-AMF-HW-Acceleration)
- [VAAPI Linux Hardware Acceleration Gist](https://gist.github.com/Brainiarc7/95c9338a737aa36d9bb2931bed379219)
- [FFmpeg 8.0 "Huffman" Release Notes](https://ffmpeg.org/download.html)
- [Phoronix - FFmpeg Vulkan AV1 Encoding](https://www.phoronix.com/news/FFmpeg-Vulkan-AV1-Encoding)

---

## Recommendations for Plugin Updates

### 1. Update `ffmpeg-hardware-acceleration` Skill

Add or enhance:
- Expanded CUDA filters section (overlay_cuda, pad_cuda details)
- scale_npp interpolation algorithms
- Multi-GPU encoding patterns
- GPU memory management best practices
- Vulkan video 8.0+ updates

### 2. Create New `ffmpeg-filter-complex-patterns` Skill

New skill covering:
- Complete filter_complex syntax reference
- Named stream patterns
- Common composition patterns (PiP, grids, transitions)
- Audio mixing patterns
- GPU + CPU hybrid filter chains
- Text animation patterns

### 3. Update `ffmpeg-fundamentals-2025` Skill

Add:
- filter_complex quick reference
- Common filter chain patterns
- Debugging filtergraphs

### 4. Performance Reference Document

New reference covering:
- GPU vs CPU encoding comparison
- Parallel processing strategies
- Memory optimization
- Benchmarking methods
