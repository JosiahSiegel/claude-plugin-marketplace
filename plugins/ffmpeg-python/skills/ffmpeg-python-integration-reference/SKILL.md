---
name: ffmpeg-python-integration-reference
description: |
  Authoritative Python-FFmpeg parameter integration reference ensuring type safety, accurate parameter mappings, and proper unit conversions.
  PROACTIVELY activate for: (1) ffmpeg-python library usage, (2) Python subprocess FFmpeg calls, (3) Caption/subtitle parameter mapping (drawtext, ASS), (4) Color format conversions (BGR, RGB, ABGR, ASS &HAABBGGRR), (5) Time unit conversions (seconds, centiseconds, milliseconds), (6) Type safety validation (int, float, string), (7) Coordinate systems, (8) Parameter range enforcement, (9) Frame pipe handling, (10) Error detection for type mismatches.
  Provides: Complete parameter type reference, color format conversion tables, time unit conversion formulas, validation patterns, working Python examples with proper typing.
---

# Python-FFmpeg Integration Reference

Use this skill when Python code is constructing FFmpeg commands, filters, ASS subtitles, or raw-frame pipes and the risk is a type, unit, color, or stream-mapping bug. This SKILL is a lean orchestrator; detailed tables and full code examples live in `references/python-ffmpeg-reference.md`.

## When to Use

- `ffmpeg-python` stream graphs and filter arguments
- Python `subprocess` calls to FFmpeg
- `drawtext`, ASS/SSA, karaoke, and animated caption parameter mapping
- RGB/BGR/ASS color conversion bugs
- Seconds vs centiseconds vs milliseconds confusion
- Raw frame pipe I/O with NumPy/OpenCV
- Range/type validation before command execution

## Critical Rules

1. **Validate types before passing parameters.** `fontsize` and `crf` are integers; bitrates are strings with units such as `5M` or `192k`; FFmpeg expressions are strings.
2. **Quote FFmpeg expressions in Python.** Use `x="(w-tw)/2"`, not Python variables named `w` or `tw`.
3. **Handle audio explicitly.** In `ffmpeg-python`, a video filter chain usually drops audio unless you map `input_file.audio` into the output.
4. **Know the color context.** FFmpeg drawtext colors are RGB/named strings; OpenCV arrays are BGR; ASS colors are `&HAABBGGRR`.
5. **Know the time context.** FFmpeg filters use seconds; ASS karaoke tags use centiseconds; ASS animation tags use milliseconds.

## Quick Reference

| FFmpeg / ASS parameter | Python type | Format / range | Common failure |
|---|---:|---|---|
| `-crf` | `int` or `str` | H.264/H.265 `0-51` | passing `18.5` |
| `-b:v`, `-b:a` | `str` | `5M`, `1000k`, `192k` | raw integer without unit |
| `fontsize` | `int` | practical `12-200` | passing `'24'` |
| `fontcolor` | `str` | `white`, `#FFFFFF`, `0xFFFFFF` | RGB tuple/list |
| ASS colour | `str` | `&HAABBGGRR` | using RGB byte order |
| `x`, `y`, `alpha`, `enable` | `str` for expressions | `'(w-tw)/2`, `between(t,1,5)` | unquoted expression |

## Core Workflow

1. Probe the input or metadata source so you know width, height, fps, duration, and stream availability.
2. Choose the integration layer: `ffmpeg-python` for command graphs, `subprocess` for full CLI parity and pipes, PyAV for frame-level library access.
3. Normalize color and time units at the Python boundary.
4. Validate parameters and ranges before building a command.
5. Map audio/subtitle streams intentionally.
6. Run on a short sample first; capture stderr for actionable FFmpeg errors.

## Reference Map

- `references/python-ffmpeg-reference.md` - Full preserved reference: color conversion functions, ASS style structures, karaoke/animation helpers, drawtext parameter tables, `ffmpeg-python` examples, subprocess pipe patterns, pitfalls, validation helpers, full working examples.

## Related Skills

- `ffmpeg-opencv-integration` - OpenCV/NumPy frame pipelines and BGR/RGB handoff
- `ffmpeg-pyav-integration` - PyAV frame-level API patterns
- `ffmpeg-captions-subtitles` - Subtitle extraction, burn-in, and styling
- `ffmpeg-animation-timing-reference` - Timing units, readability, easing, and sync
