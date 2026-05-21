---
name: ffmpeg-opencv-integration
description: |
  Complete FFmpeg + OpenCV + Python integration guide for video processing pipelines.
  PROACTIVELY activate for: (1) FFmpeg to OpenCV frame handoff, (2) cv2.VideoCapture vs ffmpeg subprocess, (3) BGR/RGB color format conversion gotchas, (4) Frame dimension order img[y,x] vs img[x,y], (5) ffmpegcv GPU-accelerated video I/O, (6) VidGear multi-threaded streaming, (7) Decord batch video loading for ML, (8) PyAV frame-level processing, (9) Audio stream preservation with video filters, (10) Memory-efficient frame generators, (11) OpenCV + FFmpeg + Modal parallel processing, (12) Pipe frames between FFmpeg and OpenCV.
  Provides: Color format conversion patterns, coordinate system gotchas, library selection guide, memory management, subprocess pipe patterns, GPU-accelerated alternatives to cv2.VideoCapture.
  Ensures: Correct integration between FFmpeg and OpenCV without color/coordinate bugs.
  See also: ffmpeg-python-integration-reference for type-safe parameter mappings.
---

# FFmpeg + OpenCV Integration Guide

Use this skill when FFmpeg handles video I/O and OpenCV handles image processing. This SKILL is a lean orchestrator; full pipe patterns, library examples, and Modal recipes are preserved in `references/opencv-pipelines-and-libraries.md`.

## When to Use

- Decode with FFmpeg and process frames with OpenCV
- Encode OpenCV-generated/processed frames with FFmpeg
- Compare `cv2.VideoCapture`, subprocess pipes, PyAV, ffmpegcv, VidGear, and Decord
- Fix RGB/BGR color bugs or `(height, width)` dimension-order bugs
- Preserve audio while replacing processed video frames
- Build GPU-assisted video I/O around CPU OpenCV processing

## Library Selection

| Need | Best option | Why |
|---|---|---|
| Simple local file | `cv2.VideoCapture` | Built-in and simple |
| Full FFmpeg format/protocol support | subprocess pipe | Exact CLI behavior |
| GPU video I/O | ffmpegcv | NVDEC/NVENC with OpenCV-like API |
| Network/RTSP streaming | VidGear | Threaded capture and stream helpers |
| ML batch loading | Decord | Fast random/batch frame access |
| Frame-level libav control | PyAV | Direct FFmpeg library access |

## Critical Gotchas

1. **OpenCV is BGR.** FFmpeg/PyAV/PIL/Decord often produce RGB. Convert explicitly.
2. **NumPy dimensions are `(height, width, channels)`.** Pixel access is `img[y, x]`, not `img[x, y]`.
3. **Video filters can drop audio.** Preserve or remux original audio intentionally.
4. **Release resources.** Always close `VideoCapture`, pipes, writers, and PyAV containers.
5. **Rawvideo pipes require exact frame size.** `width * height * channels` must match `-pix_fmt`.

## Minimal Pipe Patterns

FFmpeg to OpenCV using BGR frames:

```python
cmd = [
    "ffmpeg", "-i", input_path,
    "-f", "rawvideo", "-pix_fmt", "bgr24", "-"
]
```

OpenCV to FFmpeg using BGR frames:

```python
cmd = [
    "ffmpeg", "-y",
    "-f", "rawvideo", "-vcodec", "rawvideo",
    "-s", f"{width}x{height}", "-pix_fmt", "bgr24",
    "-r", str(fps), "-i", "-",
    "-c:v", "libx264", "-preset", "fast", "-crf", "23",
    "-pix_fmt", "yuv420p", output_path
]
```

## Core Workflow

1. Probe input dimensions, fps, duration, and audio streams.
2. Pick the I/O library based on the selection table.
3. Lock pixel format at boundaries (`bgr24` for OpenCV pipes; `yuv420p` for final H.264 output).
4. Process frames in generators/batches; avoid loading full videos unless they are small.
5. Preserve or re-encode audio explicitly.
6. Verify output duration, fps, resolution, codec, and A/V sync.

## Reference Map

- `references/opencv-pipelines-and-libraries.md` - Full preserved reference: color/dimension gotchas, cleanup patterns, FFmpeg-to-OpenCV and OpenCV-to-FFmpeg pipes, bidirectional pipeline, ffmpegcv, VidGear, Decord, PyAV, Modal.com examples, GPU pipeline, cheat sheets, sources.

## Related Skills

- `ffmpeg-python-integration-reference` - Type-safe parameters, colors, time units
- `ffmpeg-pyav-integration` - PyAV API details
- `ffmpeg-hardware-acceleration` - GPU decode/encode and filter pipelines
