# Intel Quick Sync Video (QSV)

## Requirements
- Intel CPU with integrated graphics (Sandy Bridge+)
- Intel Media SDK or oneVPL
- FFmpeg built with `--enable-libmfx` or `--enable-libvpl`

## Detection

```bash
ffmpeg -encoders | grep qsv
ffmpeg -decoders | grep qsv
ls /dev/dri/
vainfo
```

## Basic QSV Encoding

```bash
# H.264 QSV
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 -c:v h264_qsv -preset medium -b:v 5M output.mp4

# H.265/HEVC QSV
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 -c:v hevc_qsv -preset medium -b:v 4M output.mp4

# AV1 QSV (Intel Arc, 12th gen+)
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 -c:v av1_qsv -preset medium -b:v 3M output.mp4
```

## Full QSV Pipeline

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -c:v h264_qsv -preset medium -b:v 5M output.mp4
```

## QSV Quality Settings

```bash
# Constant quality (recommended)
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -c:v hevc_qsv -preset slow \
  -global_quality 22 -look_ahead 1 output.mp4

# VBR with lookahead
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -c:v h264_qsv -preset medium \
  -b:v 5M -maxrate 7M -bufsize 10M \
  -look_ahead 1 -look_ahead_depth 40 output.mp4
```

| Parameter | Description | Range |
|-----------|-------------|-------|
| `-global_quality` | Quality level (like CRF) | 1-51 (lower = better) |
| `-preset` | Encoding speed/quality | `veryfast`...`veryslow` |
| `-look_ahead` | Enable lookahead | 0 or 1 |
| `-look_ahead_depth` | Lookahead frames | 10-100 |

## Multi-GPU QSV (Linux)

```bash
ffmpeg -init_hw_device qsv=hw:/dev/dri/renderD129 \
  -filter_hw_device hw \
  -i input.mp4 -c:v h264_qsv output.mp4
```

## QSV Scaling (vpp_qsv)

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -vf "vpp_qsv=w=1280:h=720" \
  -c:v h264_qsv -preset medium output.mp4
```

## VVC/H.266 QSV Decoding (FFmpeg 7.1+)

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -c:v vvc_qsv -i input.vvc \
  -c:v h264_qsv output.mp4
```
