# Hardware Acceleration Device Initialization

Per-backend syntax for `-hwaccel`, `-init_hw_device`, and `-filter_hw_device`. For an in-depth comparison of GPU pipelines, see the `ffmpeg-hardware-acceleration` skill.

## CUDA (NVIDIA)

```bash
# Basic CUDA
ffmpeg -hwaccel cuda -i input.mp4 -c:v h264_nvenc output.mp4

# Specify device
ffmpeg -hwaccel cuda -hwaccel_device 0 -i input.mp4 -c:v h264_nvenc output.mp4

# Full GPU pipeline (decode + filter + encode on GPU)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -vf "scale_cuda=1920:1080" -c:v h264_nvenc output.mp4

# Initialize named device for filters
ffmpeg -init_hw_device cuda=gpu0:0 -filter_hw_device gpu0 \
  -i input.mp4 -vf "hwupload_cuda,scale_cuda=1920:1080,hwdownload" \
  -c:v libx264 output.mp4
```

## VAAPI (AMD/Intel Linux)

```bash
# Basic VAAPI
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 -i input.mp4 \
  -c:v h264_vaapi output.mp4

# VAAPI with output format
ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi \
  -hwaccel_device /dev/dri/renderD128 -i input.mp4 \
  -vf "scale_vaapi=1920:1080" -c:v h264_vaapi output.mp4

# Using -vaapi_device shortcut
ffmpeg -vaapi_device /dev/dri/renderD128 -i input.mp4 \
  -vf "hwupload,scale_vaapi=1920:1080" -c:v h264_vaapi output.mp4
```

## QSV (Intel)

```bash
# Basic QSV
ffmpeg -hwaccel qsv -i input.mp4 -c:v h264_qsv output.mp4

# QSV with device specification
ffmpeg -qsv_device /dev/dri/renderD128 -hwaccel qsv \
  -i input.mp4 -c:v h264_qsv output.mp4

# Full QSV pipeline
ffmpeg -hwaccel qsv -hwaccel_output_format qsv -i input.mp4 \
  -vf "scale_qsv=1920:1080" -c:v h264_qsv output.mp4
```

## Vulkan (Cross-platform FFmpeg 7.1+/8.0+)

```bash
# Vulkan hardware acceleration
ffmpeg -init_hw_device vulkan=vk:0 -filter_hw_device vk \
  -i input.mp4 -vf "hwupload,scale_vulkan=1920:1080,hwdownload" \
  -c:v libx264 output.mp4

# Vulkan encoder (FFmpeg 8.0+)
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan -i input.mp4 \
  -c:v h264_vulkan output.mp4
```

## D3D11VA (Windows)

```bash
# D3D11 hardware acceleration
ffmpeg -hwaccel d3d11va -i input.mp4 -c:v h264_nvenc output.mp4

# With specific adapter
ffmpeg -hwaccel d3d11va -hwaccel_device 0 -i input.mp4 \
  -c:v hevc_amf output.mp4
```

## VideoToolbox (macOS)

```bash
# VideoToolbox decode + encode
ffmpeg -hwaccel videotoolbox -i input.mp4 \
  -c:v h264_videotoolbox output.mp4

# With ProRes
ffmpeg -i input.mov -c:v prores_videotoolbox output.mov
```
