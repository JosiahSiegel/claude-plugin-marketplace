---
name: ffmpeg-fundamentals-2025
description: |
  Complete FFmpeg core knowledge system for FFmpeg 7.1 LTS and 8.0.1 (latest stable, released 2025-11-20).
  PROACTIVELY activate for: (1) Basic transcoding and format conversion, (2) Command syntax questions, (3) Codec selection (H.264, H.265, VVC, AV1, VP9, APV), (4) Quality settings (CRF, bitrate, presets), (5) Video/audio filter chains, (6) Trimming, splitting, concatenating, (7) Resolution scaling and aspect ratios, (8) FFmpeg 8.0 features (Whisper AI, Vulkan codecs, APV, WHIP), (9) Version checking and update guidance.
  Provides: Command syntax reference, codec comparison tables, filter examples, format conversion recipes, probing commands, Whisper transcription examples, version checking commands.
  Ensures: Correct FFmpeg usage with 2025 best practices and latest stable version.
---

# FFmpeg Fundamentals (2025)

Foundational FFmpeg knowledge for 7.1 LTS and 8.0.1. This SKILL is a lean orchestrator; detailed recipes and tables live under `references/`.

## When to Use This Skill

Use for foundational FFmpeg operations:

- First-time FFmpeg users needing syntax help
- Basic transcoding between formats (MP4, WebM, MKV, MOV)
- Understanding codec options and quality settings
- Simple filter operations (scale, crop, rotate)
- File analysis with ffprobe

For specialized topics see related skills: hardware encoding -> `ffmpeg-hardware-acceleration`, streaming -> `ffmpeg-streaming`, Docker -> `ffmpeg-docker-containers`, advanced filter graphs -> `ffmpeg-filter-complex-patterns`.

## Quick Reference

| Task | Command Pattern |
|------|-----------------|
| Convert format | `ffmpeg -i input.ext output.ext` |
| Set quality (CRF) | `-c:v libx264 -crf 23` |
| Scale video | `-vf "scale=1920:1080"` |
| Trim video | `-ss 00:00:10 -t 00:00:30` |
| Extract audio | `-vn -c:a aac output.m4a` |
| Probe file | `ffprobe -v error -show_format -show_streams file` |

## Core Workflow

1. Verify your FFmpeg version with `ffmpeg -version`. Prefer the latest stable (8.0.1) or the 7.1 LTS.
2. Probe the input with `ffprobe` to inspect codecs, container, resolution, and duration.
3. Decide whether to **remux** (`-c copy`) or **transcode** (specify encoders, quality).
4. Pick encoders and quality settings (see Codec Reference below).
5. Add filters as needed (see `references/filter-essentials.md` and `references/frame-manipulation.md`).
6. Verify the output: re-probe, check duration, A/V sync, and pixel format.

## Basic Command Syntax

```bash
ffmpeg [global_options] {[input_options] -i input} ... {[output_options] output} ...
```

Common examples:

```bash
# Basic transcode
ffmpeg -i input.mp4 output.mkv

# Specify codecs
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4

# Copy streams without re-encoding (remux)
ffmpeg -i input.mkv -c copy output.mp4

# CRF quality mode
ffmpeg -i input.mp4 -c:v libx264 -crf 23 output.mp4

# Bitrate mode
ffmpeg -i input.mp4 -c:v libx264 -b:v 5M output.mp4

# Overwrite without prompting
ffmpeg -y -i input.mp4 output.mp4

# Show progress as parseable stats
ffmpeg -progress - -i input.mp4 output.mp4
```

For exhaustive option ordering rules, stream specifiers, and per-format option tables, see the `ffmpeg-command-syntax` skill.

## Codec Reference (2025)

### Video Codecs (Software)

| Codec | Encoder | Use Case | Quality | Speed |
|-------|---------|----------|---------|-------|
| H.264/AVC | libx264 | Universal compatibility | Excellent | Medium |
| H.265/HEVC | libx265 | 4K, HDR, storage efficiency | Excellent | Slow |
| H.266/VVC | libvvenc | Next-gen, 8K | Best | Very Slow |
| AV1 | libsvtav1, libaom-av1 | Web streaming, royalty-free | Excellent | Slow-Medium |
| VP9 | libvpx-vp9 | WebM, YouTube | Very Good | Slow |
| ProRes | prores_ks | Professional editing | Lossless | Fast |

### Hardware Encoders

| Platform | H.264 | H.265 | AV1 | VVC | FFv1 |
|----------|-------|-------|-----|-----|------|
| NVIDIA | h264_nvenc | hevc_nvenc | av1_nvenc | - | - |
| Intel | h264_qsv | hevc_qsv | av1_qsv | - | - |
| AMD | h264_amf | hevc_amf | av1_amf | - | - |
| Apple | h264_videotoolbox | hevc_videotoolbox | - | - | - |
| Vulkan | h264_vulkan | hevc_vulkan | av1_vulkan (8.0+) | - | ffv1_vulkan (8.0+) |

### Hardware Decoders (FFmpeg 8.0+)

| Platform | VVC/H.266 | VP9 | ProRes RAW |
|----------|-----------|-----|------------|
| VAAPI | vvc (8.0+) | Yes | - |
| QSV | vvc_qsv (7.1+) | Yes | - |
| Vulkan | - | vp9 (8.0+) | Yes (8.0+) |

### Audio Codecs

| Codec | Encoder | Use Case | Bitrate Range |
|-------|---------|----------|---------------|
| AAC | aac, libfdk_aac | Universal, streaming | 96-320 kbps |
| MP3 | libmp3lame | Legacy compatibility | 128-320 kbps |
| Opus | libopus | VoIP, streaming, WebM | 32-256 kbps |
| FLAC | flac | Lossless archival | ~900 kbps |
| AC3 | ac3 | DVD, Blu-ray | 384-640 kbps |
| EAC3 | eac3 | Streaming, Dolby Digital+ | 192-768 kbps |

## Probing & Analysis

```bash
# Get media info as JSON
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# Get duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4

# Get resolution
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 input.mp4

# Get codec
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 input.mp4

# Validate file
ffprobe -v error input.mp4 && echo "Valid" || echo "Invalid"
```

## Best Practices

### Performance

1. Use `-threads 0` to auto-detect optimal thread count.
2. Place `-ss` before `-i` for fast seeking (may be less accurate); after `-i` for frame-accurate seek.
3. Use `-c copy` when possible to avoid re-encoding.
4. Use hardware acceleration when available.

### Quality

1. Prefer CRF over bitrate for single-pass encoding.
2. Use `-preset slow` or slower for better compression.
3. Use `-tune` options (`film`, `animation`, `grain`) when appropriate.
4. Keep `-pix_fmt yuv420p` for broad compatibility.

### Compatibility

1. Use `-movflags +faststart` for web MP4 files.
2. Use `-vtag hvc1` for HEVC on Apple devices.
3. Test on target devices before mass conversion.
4. Provide fallback formats for older browsers.

### Error Prevention

1. Test commands on a sample file first.
2. Use `-report` for detailed logging.
3. Check output file size and duration.
4. Verify A/V sync after conversion.

## Capability Discovery

```bash
ffmpeg -encoders          # List encoders
ffmpeg -decoders          # List decoders
ffmpeg -formats           # List formats
ffmpeg -filters           # List filters
ffmpeg -hwaccels          # List hardware acceleration methods
ffmpeg -h encoder=libx264 # Encoder-specific options
```

Exit codes:

- 0: success
- 1: error (check stderr)
- 255: interrupted (Ctrl+C)

## Reference Map

Detailed recipes, option tables, and FFmpeg 8.0-specific guides:

- `references/version-history.md` - Full FFmpeg 8.0 / 7.1 LTS feature lists, update strategy, official resources
- `references/common-operations.md` - Format conversion, scaling, trimming, concat, audio, subtitles, Whisper recipe, image ops, output optimization (web/iOS/Android)
- `references/filter-essentials.md` - Video filters (`-vf`), audio filters (`-af`), complex filtergraphs, filter_complex syntax reference
- `references/frame-manipulation.md` - Frame rate, setpts, select, thumbnails, tiles, freezing, looping, reversing
- `references/whisper-transcription.md` - Whisper AI filter for speech recognition and subtitle generation
- `references/vvc-h266-encoding.md` - VVC/H.266 encoding with libvvenc plus hardware decode
- `references/vulkan-compute-codecs.md` - Vulkan compute-based codecs (FFv1, AV1, VP9, ProRes RAW)

For deeper dives: `ffmpeg-filter-complex-patterns`, `ffmpeg-hardware-acceleration`, `ffmpeg-streaming`, `ffmpeg-captions-subtitles`, `ffmpeg-audio-processing`.
