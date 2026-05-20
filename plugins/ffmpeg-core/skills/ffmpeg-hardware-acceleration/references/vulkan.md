# Vulkan Video and Vulkan Filters (FFmpeg 7.1+/8.0)

Cross-platform GPU acceleration via Vulkan compute shaders. Works on any Vulkan 1.3 driver (AMD, Intel, NVIDIA).

## Vulkan Codecs Overview

### FFmpeg 7.1 Vulkan Features
- H.264 Vulkan encoding
- H.265/HEVC Vulkan encoding

### FFmpeg 8.0 Vulkan Features (New)
- **AV1 Vulkan encoding** - GPU-accelerated AV1 via compute shaders
- **VP9 Vulkan decoding** - Hardware-accelerated VP9 decode
- **FFv1 Vulkan encode/decode** - Lossless codec for archival/capture
- **ProRes RAW Vulkan decode** - Apple ProRes RAW hardware decode

**Benefits:**
- Cross-platform: same code on AMD/Intel/NVIDIA
- No vendor lock-in
- Ideal for lossless screen capture, high-throughput archival, professional workflows

## Basic Vulkan Encoding

```bash
# H.264 Vulkan
ffmpeg -init_hw_device vulkan -i input.mp4 -c:v h264_vulkan -b:v 5M output.mp4

# H.265/HEVC Vulkan
ffmpeg -init_hw_device vulkan -i input.mp4 -c:v hevc_vulkan -b:v 4M output.mp4

# AV1 Vulkan (FFmpeg 8.0+)
ffmpeg -init_hw_device vulkan -i input.mp4 -c:v av1_vulkan -b:v 3M output.mp4

# FFv1 Vulkan Lossless (FFmpeg 8.0+)
ffmpeg -init_hw_device vulkan -i input.mp4 -c:v ffv1_vulkan output.mkv
```

## Full Vulkan Pipeline

```bash
ffmpeg -init_hw_device vulkan=vk \
  -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "scale_vulkan=1280:720" \
  -c:v h264_vulkan output.mp4
```

## VP9 / ProRes RAW Vulkan Decoding (FFmpeg 8.0+)

```bash
# VP9 decode
ffmpeg -init_hw_device vulkan \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm -c:v h264_vulkan output.mp4

# ProRes RAW decode
ffmpeg -init_hw_device vulkan \
  -hwaccel vulkan \
  -i input.mov -c:v libx264 output.mp4
```

## Lossless Screen Capture with FFv1 Vulkan

```bash
# Linux X11
ffmpeg -init_hw_device vulkan \
  -f x11grab -framerate 60 -i :0.0 \
  -c:v ffv1_vulkan screen_capture.mkv

# Windows
ffmpeg -init_hw_device vulkan \
  -f gdigrab -framerate 60 -i desktop \
  -c:v ffv1_vulkan screen_capture.mkv
```

Upcoming Vulkan codecs (next minor update): ProRes encode/decode, VC-2 encode/decode.

---

## Vulkan Filters Reference (FFmpeg 8.0+)

| Filter | Description | Key Parameters |
|--------|-------------|----------------|
| `scale_vulkan` | GPU scaling | `w`, `h`, `scaler` |
| `overlay_vulkan` | Compositing | `x`, `y` |
| `transpose_vulkan` | Rotate/transpose | `dir`, `passthrough` |
| `flip_vulkan` | Horizontal flip | - |
| `avgblur_vulkan` | Box blur | `sizeX`, `sizeY` |
| `gblur_vulkan` | Gaussian blur | `sigma`, `sigmaV`, `planes` |
| `chromaber_vulkan` | Chromatic aberration | `dist_x`, `dist_y` |
| `nlmeans_vulkan` | NLMeans denoising | `s`, `p`, `r` |
| `bwdif_vulkan` | Deinterlacing | `mode`, `parity`, `deint` |
| `xfade_vulkan` | Transitions | `transition`, `duration`, `offset` |
| `libplacebo` | Libplacebo processing | `w`, `h`, `colorspace` |

## Vulkan Scaling

```bash
# CPU-to-GPU-to-CPU scaling
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i input.mp4 \
  -vf "hwupload,scale_vulkan=1920:1080,hwdownload,format=yuv420p" \
  output.mp4

# Full GPU pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 -vf "scale_vulkan=1280:720" \
  -c:v h264_vulkan output.mp4

# Specific scaler
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,scale_vulkan=w=1920:h=1080:scaler=lanczos,hwdownload,format=yuv420p" \
  output.mp4
```

## Vulkan Compositing

```bash
# Picture-in-picture
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i main.mp4 -i overlay.mp4 \
  -filter_complex "\
    [0:v]hwupload[main];\
    [1:v]hwupload,scale_vulkan=320:180[pip];\
    [main][pip]overlay_vulkan=x=10:y=10[out];\
    [out]hwdownload,format=yuv420p" \
  -map "[out]" output.mp4

# Full Vulkan overlay pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan -i main.mp4 \
  -hwaccel vulkan -hwaccel_output_format vulkan -i overlay.mp4 \
  -filter_complex "[0:v][1:v]overlay_vulkan=x=W-w-10:y=10" \
  -c:v h264_vulkan output.mp4
```

## Rotation and Flip

```bash
# 90° clockwise
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,transpose_vulkan=dir=clock,hwdownload,format=yuv420p" \
  output.mp4

# Horizontal flip
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,flip_vulkan,hwdownload,format=yuv420p" output.mp4
```

| dir | Rotation |
|-----|----------|
| `cclock_flip` | 90° counter-clockwise + vertical flip |
| `clock` | 90° clockwise |
| `cclock` | 90° counter-clockwise |
| `clock_flip` | 90° clockwise + vertical flip |

## Blur Effects

```bash
# Gaussian
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,gblur_vulkan=sigma=5,hwdownload,format=yuv420p" output.mp4

# Box
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,avgblur_vulkan=sizeX=5:sizeY=5,hwdownload,format=yuv420p" output.mp4
```

## Chromatic Aberration

```bash
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,chromaber_vulkan=dist_x=-0.002:dist_y=0.002,hwdownload,format=yuv420p" \
  output.mp4
```

## Vulkan Denoising (nlmeans_vulkan)

```bash
# Basic
ffmpeg -init_hw_device vulkan -i noisy.mp4 \
  -vf "hwupload,nlmeans_vulkan=s=3:p=7:r=15,hwdownload,format=yuv420p" output.mp4

# Full pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i noisy.mp4 -vf "nlmeans_vulkan=s=4" \
  -c:v h264_vulkan output.mp4
```

## Vulkan Deinterlacing (bwdif_vulkan)

```bash
# Bob-Weaver
ffmpeg -init_hw_device vulkan -i interlaced.mp4 \
  -vf "hwupload,bwdif_vulkan=mode=send_frame,hwdownload,format=yuv420p" output.mp4

# Full pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i interlaced.mp4 -vf "bwdif_vulkan=1" \
  -c:v h264_vulkan output.mp4
```

## Vulkan Transitions (xfade_vulkan)

```bash
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]hwupload[v1];\
    [1:v]hwupload[v2];\
    [v1][v2]xfade_vulkan=transition=fade:duration=1:offset=4[out];\
    [out]hwdownload,format=yuv420p" \
  -map "[out]" output.mp4
```

Transitions include: `fade`, `dissolve`, `wipeleft`, `wiperight`, `wipeup`, `wipedown`, `slideleft`, `slideright`, `slideup`, `slidedown`, etc.

## Libplacebo Processing (Advanced)

```bash
# HDR tonemapping
ffmpeg -init_hw_device vulkan -i hdr_input.mp4 \
  -vf "hwupload,libplacebo=tonemapping=hable:colorspace=bt709:color_primaries=bt709:color_trc=bt709,hwdownload,format=yuv420p" \
  sdr_output.mp4

# High-quality upscale
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,libplacebo=w=3840:h=2160:upscaler=ewa_lanczos,hwdownload,format=yuv420p10le" \
  output.mp4
```
