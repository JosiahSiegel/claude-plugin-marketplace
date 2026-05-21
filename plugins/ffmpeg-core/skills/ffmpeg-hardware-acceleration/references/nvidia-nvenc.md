# NVIDIA NVENC/NVDEC

Detailed encoding, GPU pipeline, CUDA filter, scale_npp, chromakey, quality tuning, two-pass, B-frames, and multi-GPU patterns for NVIDIA hardware.

## Requirements

- NVIDIA GPU (GTX 600+ / Quadro K series+)
- NVIDIA drivers 450+
- FFmpeg built with `--enable-nvenc --enable-cuda --enable-cuvid`

## Detection

```bash
ffmpeg -encoders | grep nvenc
ffmpeg -decoders | grep cuvid
nvidia-smi
ffmpeg -hwaccels
```

## Basic NVENC Encoding

```bash
# H.264 NVENC
ffmpeg -i input.mp4 -c:v h264_nvenc -preset p4 -b:v 5M output.mp4

# H.265/HEVC NVENC
ffmpeg -i input.mp4 -c:v hevc_nvenc -preset p4 -b:v 4M output.mp4

# AV1 NVENC (RTX 40 series+)
ffmpeg -i input.mp4 -c:v av1_nvenc -preset p4 -b:v 3M output.mp4
```

## NVENC Presets (FFmpeg 7+)

| Preset | Speed | Quality | Use Case |
|--------|-------|---------|----------|
| p1 | Fastest | Lowest | Real-time capture |
| p2 | Faster | Low | Screen recording |
| p3 | Fast | Medium | General streaming |
| p4 | Medium | Good | **Recommended** |
| p5 | Slow | Better | High-quality streaming |
| p6 | Slower | Best | Offline encoding |
| p7 | Slowest | Highest | Maximum quality |

## Full GPU Pipeline (Decode + Encode)

```bash
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

## GPU Scaling and Filtering

```bash
# scale_cuda
ffmpeg -y -vsync 0 \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -c:v h264_nvenc -preset p4 output.mp4

# overlay_cuda
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i overlay.mp4 \
  -filter_complex "[0:v][1:v]overlay_cuda=10:10" \
  -c:v h264_nvenc output.mp4

# pad_cuda (FFmpeg 8.0+)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -vf "pad_cuda=1920:1080:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v h264_nvenc output.mp4

# Letterbox via pad_cuda
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -vf "scale_cuda=1920:-2,pad_cuda=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v h264_nvenc output.mp4
```

## CUDA Filters Reference (FFmpeg 8.0+)

| Filter | Description | Key Parameters |
|--------|-------------|----------------|
| `scale_cuda` | GPU video scaling | `w`, `h`, `format`, `interp_algo` |
| `scale_npp` | NPP-based scaling (higher quality) | `w`, `h`, `interp_algo` |
| `overlay_cuda` | GPU overlay/compositing | `x`, `y`, `eof_action` |
| `pad_cuda` | GPU padding (8.0+) | `w`, `h`, `x`, `y`, `color` |
| `chromakey_cuda` | GPU chroma keying | `color`, `similarity`, `blend` |
| `colorspace_cuda` | Color space conversion | `all`, `space`, `trc`, `primaries` |
| `bilateral_cuda` | Bilateral filter | `sigmaS`, `sigmaR`, `window_size` |
| `bwdif_cuda` | Deinterlacing | `mode`, `parity`, `deint` |
| `hwupload_cuda` | Upload to GPU | - |
| `hwdownload` | Download from GPU | - |

## scale_npp (NVIDIA Performance Primitives)

```bash
# Super-sampling downscale
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -vf "scale_npp=1280:720:interp_algo=super" \
  -c:v h264_nvenc output.mp4

# Lanczos upscale
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -vf "scale_npp=1920:1080:interp_algo=lanczos" \
  -c:v h264_nvenc output.mp4
```

| Algorithm | Quality | Speed | Best For |
|-----------|---------|-------|----------|
| `nn` | Low | Fastest | Pixel art, nearest neighbor |
| `linear` | Medium | Fast | General use |
| `cubic` | Good | Medium | Smooth scaling |
| `lanczos` | High | Slow | High quality upscaling |
| `super` | Best | Slowest | Downscaling |

## GPU Chromakey (Green Screen)

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i greenscreen.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i background.mp4 \
  -filter_complex "[0:v]chromakey_cuda=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay_cuda" \
  -c:v h264_nvenc output.mp4
```

## Hybrid GPU + CPU Pipelines

```bash
# CPU decode -> CPU filter -> GPU encode
ffmpeg -i input.mp4 \
  -vf "fade=in:0:30,hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# GPU decode -> CPU drawtext -> GPU encode
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "hwdownload,format=nv12,drawtext=text='Hello':fontsize=48,hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# Full hybrid: GPU scale -> CPU text -> GPU encode
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -filter_complex "\
    [0:v]scale_cuda=1920:1080[scaled];\
    [scaled]hwdownload,format=nv12[cpu];\
    [cpu]drawtext=text='Watermark':fontsize=48:x=10:y=10[text];\
    [text]hwupload_cuda[gpu]" \
  -map "[gpu]" \
  -c:v h264_nvenc output.mp4
```

## NVENC Quality Optimization

```bash
# HQ with lookahead and AQ
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p5 -tune hq \
  -rc vbr -cq 23 -b:v 0 \
  -rc-lookahead 32 -spatial-aq 1 -temporal-aq 1 \
  -c:a copy output.mp4

# Constant quality (CQP)
ffmpeg -i input.mp4 \
  -c:v h264_nvenc -preset p4 -rc constqp -qp 23 \
  -c:a copy output.mp4
```

## NVENC Two-Pass Encoding

```bash
ffmpeg -i input.mp4 \
  -c:v h264_nvenc -preset p5 -2pass 1 -b:v 5M \
  -c:a copy output.mp4
```

## NVENC B-Frames and GOP

```bash
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p4 -bf 4 -b_ref_mode 2 -g 250 \
  -c:a copy output.mp4
```

## NVIDIA Multi-GPU

```bash
# Parallel jobs on different GPUs
ffmpeg -hwaccel cuda -hwaccel_device 0 -hwaccel_output_format cuda \
  -i input1.mp4 -c:v h264_nvenc output1.mp4 &

ffmpeg -hwaccel cuda -hwaccel_device 1 -hwaccel_output_format cuda \
  -i input2.mp4 -c:v h264_nvenc output2.mp4 &

wait

# Named device for filters
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -init_hw_device cuda=gpu1:1 \
  -filter_complex "[0:v]scale_cuda=1280:720[scaled]" \
  -map "[scaled]" -c:v h264_nvenc output.mp4
```

## 1:N ABR Ladder (Single Input, Multiple Outputs)

```bash
ffmpeg -y -vsync 0 \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -filter_complex "[0:v]split=3[v1][v2][v3];\
    [v1]scale_cuda=1920:1080[hd];\
    [v2]scale_cuda=1280:720[sd];\
    [v3]scale_cuda=640:360[mobile]" \
  -map "[hd]" -c:v h264_nvenc -b:v 5M output_1080p.mp4 \
  -map "[sd]" -c:v h264_nvenc -b:v 2M output_720p.mp4 \
  -map "[mobile]" -c:v h264_nvenc -b:v 500k output_360p.mp4
```

## Parallel Throughput

```bash
export CUDA_VISIBLE_DEVICES=0
export CUDA_DEVICE_MAX_CONNECTIONS=2

for i in {1..4}; do
  ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
    -i input_$i.mp4 -c:v h264_nvenc output_$i.mp4 &
done
wait
```
