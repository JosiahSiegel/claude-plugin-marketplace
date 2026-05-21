---
name: python-video-pipeline
description: |
  Expert guide to end-to-end Python video pipelines combining FFmpeg, OpenCV, PyAV, ffmpegcv, Decord, VidGear, and Modal.com for scalable GPU-accelerated workflows.
  PROACTIVELY activate for: (1) FFmpeg+OpenCV in same pipeline (decode, process, re-encode); (2) color-format mismatches (BGR vs RGB across OpenCV, PIL, PyAV, FFmpeg); (3) frame dim ordering (HWC vs CHW) between OpenCV and ML frameworks; (4) audio stream loss in filter chains; (5) memory mgmt for long/large videos (streaming vs in-memory); (6) choosing ffmpegcv/Decord/VidGear/PyAV for performance; (7) GPU decode/encode on Modal.com; (8) parallel + chunk-based processing on Modal; (9) transcoding pipelines on serverless; (10) HLS generation on Modal; (11) upload -> process -> transcode -> HLS workflows; (12) batch sizing for GPU memory, pixel formats, large-video streaming.
  Provides: library selection matrix, integration recipes, Modal.com deployment examples, GPU pipeline tuning, production-ready workflow examples.
---

# Python Video Pipeline Skill

Use this skill for end-to-end Python video pipelines that combine decoding, OpenCV/PyAV/frame processing, FFmpeg encoding, serverless execution, GPU acceleration, HLS output, and large-file orchestration.

## When to Use This Skill

Use when the user asks for tasks covered by the frontmatter triggers, especially implementation guidance, debugging, architecture choices, production hardening, or performance-sensitive decisions in this domain. Start from this orchestrator, then load the focused reference file that matches the requested detail level.

## Core Workflow

1. Start by selecting the pipeline architecture: simple OpenCV, FFmpeg plus OpenCV pipes, PyAV frame processing, ffmpegcv/Decord/VidGear, or Modal for scalable execution.
2. Normalize color and shape conventions at every library boundary: OpenCV BGR/HWC, PIL RGB, PyAV RGB, FFmpeg pixel formats, and ML CHW tensors.
3. Probe media metadata before processing so FPS, resolution, frame count, audio presence, and codec assumptions are explicit.
4. Process long videos as streams, batches, or chunks; avoid accumulating all frames unless inputs are small and bounded.
5. Re-mux or preserve audio after frame-level processing, since OpenCV-only workflows usually produce video-only outputs.
6. On Modal or GPU infrastructure, tune batch size, pixel format, decode/encode acceleration, volume usage, and timeout boundaries.

## Key Gotchas

- BGR/RGB mismatches silently produce wrong colors across OpenCV, FFmpeg, PyAV, PIL, and ML frameworks.
- Frame dimensions are usually HWC in NumPy/OpenCV but may need CHW for deep learning frameworks.
- OpenCV `VideoWriter` output may not preserve the source audio; plan an explicit FFmpeg audio re-mux step.
- Parallel frame processing must restore original frame order before reconstruction.
- Chunked processing needs timestamp and concat handling; audio is usually handled after chunk recombination.

## Reference Map

- [references/video-pipeline-complete-patterns.md](references/video-pipeline-complete-patterns.md) - Full original pipeline guide covering library selection, integration gotchas, FFmpeg/OpenCV pipes, ffmpegcv, VidGear, Decord, Modal GPU workflows, chunking, transcoding, HLS, end-to-end workflows, and optimization tips.
- [references/modal-video-patterns.md](references/modal-video-patterns.md) - Additional Modal-specific video patterns already maintained for this skill.

## Response Guidance

- Preserve the user's existing framework, library, and tooling choices unless there is a clear compatibility or performance reason to suggest an alternative.
- Give copy-pasteable code only for the exact task at hand; otherwise point to the relevant reference section.
- Call out tradeoffs, failure modes, and verification steps for production workflows.
- Prefer accessible, maintainable, measurable solutions over clever micro-optimizations.
