---
name: ffmpeg-pyav-integration
description: |
  Complete PyAV (Python FFmpeg bindings) integration guide.
  PROACTIVELY activate for: (1) PyAV installation on Ubuntu/Windows/macOS, (2) Building PyAV against custom FFmpeg, (3) FFmpeg 7.0/8.0+ compatibility, (4) av.open() video/audio decoding, (5) VideoFrame/AudioFrame NumPy conversion, (6) Filter graph processing, (7) Video encoding with H.264/H.265/AV1, (8) Seeking and keyframe extraction, (9) RTSP/network streaming with PyAV, (10) Memory management and thread safety, (11) Error handling with FFmpegError, (12) Subtitle extraction, (13) Container manipulation and remuxing, (14) Performance optimization and threading.
  Provides: Complete PyAV API patterns, installation guides for all Ubuntu versions, FFmpeg 8.0+ compatibility matrix, type-safe examples, memory management best practices, filter graph examples, encoding/decoding patterns.
---

# PyAV Integration Guide

Use PyAV when Python needs direct access to FFmpeg libraries: containers, streams, packets, frames, codecs, filters, seeking, subtitles, and NumPy conversion. This SKILL is a lean orchestrator; the full API examples are preserved in `references/pyav-recipes-and-api.md`.

## When to Use PyAV

Use PyAV for:

- Frame-level video/audio decoding and encoding
- Precise seeking and keyframe extraction
- NumPy/Pillow/OpenCV frame access without shelling out per frame
- Container inspection, packet-level remuxing, subtitle reads
- RTSP/network stream handling with library-level control

Use FFmpeg CLI/subprocess instead for simple transcodes, production command parity, or heavy hardware-accelerated pipelines.

## Quick Reference

| Task | PyAV pattern | Notes |
|---|---|---|
| Open media | `av.open(path)` | Prefer context manager |
| Decode video | `container.decode(video=0)` | Yields `VideoFrame` |
| To NumPy | `frame.to_ndarray(format='rgb24')` | Convert to BGR for OpenCV |
| From NumPy | `av.VideoFrame.from_ndarray(arr, format='rgb24')` | Encode generated frames |
| Seek | `container.seek(offset)` | Usually keyframe-based |
| Encode | `stream.encode(frame)` then `container.mux(packet)` | Flush encoder at end |
| Close | `container.close()` | Critical in loops |

## Minimal Patterns

```python
import av

with av.open("input.mp4") as container:
    stream = container.streams.video[0]
    stream.thread_type = "AUTO"
    for frame in container.decode(stream):
        rgb = frame.to_ndarray(format="rgb24")
        break
```

```python
import av

with av.open("input.mp4") as container:
    stream = container.streams.video[0]
    container.seek(int(10.0 * av.time_base), backward=True)
    for frame in container.decode(stream):
        if frame.time >= 10.0:
            image = frame.to_ndarray(format="rgb24")
            break
```

## Core Workflow

1. Install `av` from wheels unless you explicitly need a custom FFmpeg build.
2. Check PyAV and FFmpeg library compatibility before relying on new FFmpeg 8.x features.
3. Open containers with a context manager or `try/finally` close.
4. Select streams explicitly; decode only what you need.
5. Convert frame pixel/sample formats intentionally.
6. For encoding, set codec, dimensions, pixel format, rate, and options explicitly; flush encoders.
7. Disable verbose logging in threaded applications and prefer file paths over Python file objects.

## Key Gotchas

- PyAV frames can reference underlying buffers; call `.copy()` on NumPy arrays you keep after container close.
- `thread_type='AUTO'` can greatly improve decode speed but may add frame delay.
- PyAV hardware acceleration is limited compared with CLI FFmpeg.
- Subtitle transcoding support is limited; use FFmpeg CLI for complex subtitle workflows.

## Reference Map

- `references/pyav-recipes-and-api.md` - Full preserved reference: installation, custom FFmpeg builds, FFmpeg 8 compatibility, decoding, NumPy conversion, encoding, audio, filters, seeking, remuxing, subtitles, RTSP, errors, memory, threading, performance, hardware caveats, common patterns.

## Related Skills

- `ffmpeg-python-integration-reference` - Type-safe FFmpeg parameter mapping
- `ffmpeg-opencv-integration` - OpenCV pipelines and color conversion
- `ffmpeg-fundamentals-2025` - Core FFmpeg operations and codec choices
