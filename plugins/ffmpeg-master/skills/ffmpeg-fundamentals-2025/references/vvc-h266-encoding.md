# VVC/H.266 Encoding with FFmpeg

Versatile Video Coding (VVC/H.266) is the latest video coding standard, offering 25-50% better compression than HEVC at similar quality.

## FFmpeg VVC Support Timeline

- **FFmpeg 7.0**: Native VVC decoder added (experimental)
- **FFmpeg 7.1 LTS**: Production-ready VVC decoder, QSV hardware decoding
- **FFmpeg 8.0**: VA-API hardware decoding, stable native decoder

## Encoding with libvvenc

```bash
# Basic VVC encoding
ffmpeg -i input.mp4 \
  -c:v libvvenc -qp 32 \
  -c:a aac -b:a 128k \
  output.mp4

# High quality encoding
ffmpeg -i input.mp4 \
  -c:v libvvenc -qp 24 \
  -vvenc-params "preset=medium" \
  -c:a aac -b:a 192k \
  output_hq.mp4

# 4K encoding with tiling (parallel processing)
ffmpeg -i input_4k.mp4 \
  -c:v libvvenc -qp 28 \
  -vvenc-params "preset=fast:tiles=4x4:threads=16" \
  -c:a copy \
  output_4k_vvc.mp4

# Specify exact bitrate
ffmpeg -i input.mp4 \
  -c:v libvvenc -b:v 5M \
  -vvenc-params "preset=medium" \
  output_cbr.mp4
```

## Quality Parameters

| QP Value | Quality Level | Use Case |
|----------|--------------|----------|
| 18-22 | Excellent | Archival, mastering |
| 23-27 | High | High-quality streaming |
| 28-32 | Good | General streaming |
| 33-38 | Medium | Bandwidth-constrained |
| 38+ | Low | Preview, thumbnails |

## Presets Comparison

| Preset | Speed | Compression | Use Case |
|--------|-------|-------------|----------|
| faster | 3-4x | Low | Live encoding |
| fast | 2x | Medium-low | Quick batch jobs |
| medium | 1x | Balanced | Default |
| slow | 0.4x | High | Quality priority |
| slower | 0.2x | Higher | Final delivery |

## Hardware Decoding

### VA-API (FFmpeg 8.0+, Intel/AMD on Linux)

```bash
# VVC hardware decoding with VA-API
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -i input_vvc.mp4 \
  -c:v libx264 -crf 20 \
  output.mp4

# Hardware decode and scale
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input_vvc.mp4 \
  -vf "scale_vaapi=w=1920:h=1080" \
  -c:v h264_vaapi \
  output.mp4
```

### Intel QSV (FFmpeg 7.1+)

```bash
# VVC hardware decoding with QSV
ffmpeg -hwaccel qsv \
  -i input_vvc.mp4 \
  -c:v libx264 -crf 20 \
  output.mp4

# Full QSV pipeline
ffmpeg -hwaccel qsv \
  -i input_vvc.mp4 \
  -c:v h264_qsv -preset fast \
  output.mp4
```

## Container Support

- **MP4/MOV**: Full support
- **MKV**: Full support (FFmpeg 8.0+)
- **TS**: Experimental

```bash
# VVC in MKV container (FFmpeg 8.0+)
ffmpeg -i input.mp4 \
  -c:v libvvenc -qp 28 \
  -c:a copy \
  output.mkv
```

## Screen Content Coding (SCC)

FFmpeg 8.0 adds VVC Screen Content Coding support:

```bash
# Screen content (presentations, desktop capture)
ffmpeg -i screen_capture.mp4 \
  -c:v libvvenc -qp 26 \
  -vvenc-params "preset=medium:scc=1" \
  output_screen.mp4
```

SCC features:
- Intra Block Copy (IBC)
- Palette Mode
- Adaptive Color Transform (ACT)

## Comparison with HEVC

| Metric | HEVC (libx265) | VVC (libvvenc) |
|--------|----------------|----------------|
| Bitrate (same quality) | 100% | 50-75% |
| Encoding speed | 1x | 0.2-0.4x |
| Decoding complexity | 1x | 2x |
| Hardware support | Widespread | Growing |
| Browser support | Safari, Edge | Limited |

## Best Practices

1. **Use VVC for**:
   - Archival where storage matters
   - 4K/8K content where bandwidth is limited
   - Future-proofing content libraries

2. **Avoid VVC for**:
   - Live streaming (too slow)
   - Web delivery (limited browser support)
   - Quick turnaround projects

3. **Encode workflow**:
   ```bash
   # Test settings on sample first
   ffmpeg -i input.mp4 -t 30 \
     -c:v libvvenc -qp 28 -vvenc-params "preset=medium" \
     test_output.mp4

   # Verify quality before full encode
   ffplay test_output.mp4
   ```

## Decoding VVC Files

```bash
# Software decode (always available in FFmpeg 7.1+)
ffmpeg -i input.vvc -c:v libx264 -crf 18 output.mp4

# Play VVC file directly
ffplay input.vvc

# Get VVC file info
ffprobe -v error -show_streams input.vvc
```
