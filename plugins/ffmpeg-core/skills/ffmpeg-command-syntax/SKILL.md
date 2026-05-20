---
name: ffmpeg-command-syntax
description: |
  Complete FFmpeg command syntax reference covering option ordering, input vs output options, stream specifiers, and position-sensitive options.
  PROACTIVELY activate for: (1) Command syntax questions, (2) Option placement issues, (3) Input vs output option confusion, (4) Stream specifier syntax, (5) -ss/-t/-to position questions, (6) Global vs per-file options, (7) Multiple input/output handling, (8) Option order errors.
  Provides: Correct option placement rules, input-only vs output-only options, position-sensitive option behavior, stream specifier syntax, common mistakes and fixes.
---

## CRITICAL: FFmpeg Option Ordering Rules

**The most common FFmpeg mistake is putting options in the wrong place.** Options in FFmpeg are position-sensitive and apply to the NEXT file specified after them.

### The Golden Rule

```bash
ffmpeg [global_options] {[input_options] -i input}... {[output_options] output}...
```

**Key principle**: Options are applied to the **next** file. They are **reset between files**.

---

## Option Categories at a Glance

| Category | Where it goes | Notable members |
|----------|--------------|-----------------|
| Global | First, before any `-i` | `-y`, `-n`, `-v`, `-hide_banner`, `-filter_complex`, `-init_hw_device` |
| Input | Between previous output (or start) and the next `-i` | `-ss`, `-t`, `-to`, `-re`, `-stream_loop`, `-hwaccel`, `-itsoffset` |
| Output | After all `-i`, before the matching output file | `-c:v`, `-c:a`, `-crf`, `-preset`, `-vf`, `-af`, `-map`, `-movflags` |

The full per-category catalog (every option, with descriptions) lives in [`references/complete-option-reference.md`](references/complete-option-reference.md).

### Global Options (Quick Subset)

```bash
ffmpeg -y -hide_banner -v warning -i input.mp4 output.mp4
```

Common global flags: `-y`, `-n`, `-v`/`-loglevel`, `-stats`, `-progress`, `-report`, `-hide_banner`, `-filter_complex`, `-filter_complex_threads`, `-init_hw_device`, `-filter_hw_device`.

### Input Options (Quick Subset)

Placed **immediately before** the `-i` they apply to. They affect how the file is **read/decoded**.

Most-used: `-ss`, `-t`, `-to`, `-itsoffset`, `-itsscale`, `-re`, `-readrate`, `-stream_loop`, `-hwaccel`, `-hwaccel_device`, `-hwaccel_output_format`, `-c:v`/`-c:a` (as **decoder**), `-r`/`-s`/`-pix_fmt` (raw inputs), `-accurate_seek`, `-thread_queue_size`.

```bash
# Correct: Input options before their -i
ffmpeg -ss 00:01:00 -t 30 -i input.mp4 output.mp4

# Wrong: -ss after -i becomes an OUTPUT (slow) seek
ffmpeg -i input.mp4 -ss 00:01:00 output.mp4
```

Hardware acceleration must always go before `-i`:

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -c:v h264_nvenc output.mp4
```

### Output Options (Quick Subset)

Placed **after all inputs** and **before the output file** they apply to. They affect how the file is **encoded/written**.

Most-used: `-c:v`/`-c:a`/`-c:s` (as **encoder**), `-b:v`/`-b:a`, `-crf`, `-qp`, `-preset`, `-tune`, `-profile:v`, `-level`, `-r`/`-s`/`-aspect`/`-pix_fmt`, `-vf`/`-af`, `-map`, `-ss`/`-t`/`-to` (output forms), `-fs`, `-frames:v`/`-frames:a`, `-movflags`, `-metadata`, `-disposition`, `-shortest`, `-an`/`-vn`/`-sn`.

```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium output.mp4
```

---

## Options That Switch Behavior by Position

Some options have completely different meanings depending on whether they appear **before** or **after** `-i`.

### `-ss` (Seek/Start Time) - Position Critical

```bash
# BEFORE -i (INPUT): Fast keyframe seek, then decode to exact position with -accurate_seek (default)
ffmpeg -ss 00:01:00 -i input.mp4 -t 30 -c copy output.mp4

# AFTER -i (OUTPUT): Frame-accurate but slow - decodes everything, discards until target
ffmpeg -i input.mp4 -ss 00:01:00 -t 30 -c:v libx264 output.mp4

# BOTH (recommended): coarse seek + fine seek
ffmpeg -ss 00:00:55 -i input.mp4 -ss 00:00:05 -t 30 -c:v libx264 output.mp4
```

**Note**: `-ss` before `-i` resets timestamps to 0. Use `-copyts` to preserve originals.

### `-t` and `-to`

```bash
# -t BEFORE -i: limits how much of input to READ
ffmpeg -t 60 -i input.mp4 -c copy output.mp4

# -t AFTER -i: limits output DURATION
ffmpeg -i input.mp4 -t 60 -c copy output.mp4

# -ss + -to: with timestamp reset, -to is relative to new zero
ffmpeg -ss 00:01:00 -i input.mp4 -to 00:00:30 output.mp4  # 30s clip
ffmpeg -ss 00:01:00 -copyts -i input.mp4 -to 00:01:30 output.mp4  # also 30s clip
```

### `-r` (Frame Rate)

```bash
# BEFORE -i: input frame rate (raw/image sequences)
ffmpeg -r 30 -i frame_%04d.png output.mp4

# AFTER -i: output frame rate (adds/drops frames)
ffmpeg -i input.mp4 -r 24 output.mp4
```

### `-s` (Size)

```bash
# BEFORE -i: raw input size
ffmpeg -s 1920x1080 -pix_fmt yuv420p -i raw.yuv output.mp4

# AFTER -i: scales output (prefer -vf scale instead)
ffmpeg -i input.mp4 -s 1280x720 output.mp4
```

### `-c` / `-codec`

```bash
# BEFORE -i: DECODER selection
ffmpeg -c:v h264_cuvid -i input.mp4 -c:v h264_nvenc output.mp4

# AFTER -i: ENCODER selection (common case)
ffmpeg -i input.mp4 -c:v libx264 -c:a aac output.mp4
```

---

## Stream Specifiers (Quick Form)

Target specific streams with `-option[:specifier]`:

```bash
ffmpeg -i input.mkv -c:v libx264 -c:a aac -c:s mov_text output.mp4
ffmpeg -i a.mp4 -i b.mp4 -map 1:0 -c copy output.mp4
```

Common specifiers: `:v`, `:V`, `:a`, `:s`, `:d`, `:t`, `:v:0`, `:a:1`, `:0`, `:m:key:value`, `:p:0`. Full table and per-stream examples in [`references/stream-specifiers.md`](references/stream-specifiers.md).

---

## Multiple Inputs and Outputs

```bash
# Per-input options
ffmpeg \
  -ss 10 -i first.mp4 \
  -ss 5 -i second.mp4 \
  -filter_complex "[0:v][1:v]overlay" output.mp4

# Per-output options (they RESET between outputs)
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 23 output_h264.mp4 \
  -c:v libx265 -crf 28 output_h265.mp4
```

```bash
# WRONG: second output silently gets no encoding options
ffmpeg -i input.mp4 -c:v libx264 -crf 23 out1.mp4 out2.mp4
```

---

## Common Mistakes and Fixes

### 1. Input option after `-i`

```bash
# WRONG: -hwaccel after -i has no effect
ffmpeg -i input.mp4 -hwaccel cuda -c:v h264_nvenc output.mp4
# CORRECT
ffmpeg -hwaccel cuda -i input.mp4 -c:v h264_nvenc output.mp4
```

### 2. Output option before `-i`

```bash
# WRONG: -c:v before -i tries to choose a decoder
ffmpeg -c:v libx264 -i input.mp4 output.mp4
# CORRECT
ffmpeg -i input.mp4 -c:v libx264 output.mp4
```

### 3. Expecting options to persist across outputs

```bash
# WRONG
ffmpeg -i input.mp4 -c:v libx264 -crf 23 out1.mp4 out2.mp4
# CORRECT
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 23 out1.mp4 \
  -c:v libx264 -crf 23 out2.mp4
```

### 4. Wrong `-ss` position for accuracy

```bash
# Fast but may snap to keyframe
ffmpeg -ss 00:05:00 -i input.mp4 -t 30 -c copy output.mp4
# Accurate but slow
ffmpeg -i input.mp4 -ss 00:05:00 -t 30 -c:v libx264 output.mp4
# Fast AND accurate
ffmpeg -ss 00:04:55 -i input.mp4 -ss 5 -t 30 -c:v libx264 output.mp4
```

### 5. Mixing inputs and outputs

```bash
# WRONG
ffmpeg -i input1.mp4 -c:v libx264 output1.mp4 -i input2.mp4 output2.mp4
# CORRECT
ffmpeg -i input1.mp4 -i input2.mp4 \
  -map 0 -c:v libx264 output1.mp4 \
  -map 1 -c:v libx264 output2.mp4
```

### 6. `-t` vs `-to` with `-ss` timestamp reset

```bash
ffmpeg -ss 00:01:00 -i input.mp4 -to 00:00:30 output.mp4         # 30s clip
ffmpeg -ss 00:01:00 -copyts -i input.mp4 -to 00:01:30 output.mp4 # 30s clip
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 output.mp4          # 30s clip
```

### 7. `-vf` vs `-filter_complex`

```bash
# Single-input filter (per-output)
ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4

# Multi-input filter (global)
ffmpeg -i video.mp4 -i overlay.png \
  -filter_complex "[0:v][1:v]overlay=10:10" output.mp4

# WRONG: -vf cannot reference multiple inputs
ffmpeg -i video.mp4 -i overlay.png -vf "overlay=10:10" output.mp4
```

---

## Command Structure Examples

```bash
# Basic transcode
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -c:a aac output.mp4

# With input seeking
ffmpeg -ss 60 -i input.mp4 -t 30 -c:v libx264 output.mp4

# Hardware acceleration
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -c:v h264_nvenc -preset p4 output.mp4

# Multiple inputs with filters
ffmpeg -i main.mp4 -i overlay.png \
  -filter_complex "[0:v][1:v]overlay=10:10[v]" \
  -map "[v]" -map 0:a -c:v libx264 -c:a copy output.mp4

# Real-time streaming
ffmpeg -re -i input.mp4 -c:v libx264 -f flv rtmp://server/live/stream

# Full structure
ffmpeg \
  -y -hide_banner \
  -hwaccel cuda -ss 10 -i input1.mp4 \
  -stream_loop -1 -i input2.mp4 \
  -filter_complex "[0:v][1:v]overlay[v]" \
  -map "[v]" -map 0:a \
  -c:v h264_nvenc -b:v 5M \
  -c:a aac -b:a 192k \
  -movflags +faststart \
  output.mp4
```

---

## Quick Placement Cheatsheet

| Option | Before `-i` | After `-i` | Notes |
|--------|-------------|------------|-------|
| `-ss` | Fast seek | Accurate seek | Before = keyframe, After = decode |
| `-t` | Input limit | Output limit | Read vs write |
| `-to` | Input end | Output end | Affected by timestamp reset |
| `-r` | Input FPS | Output FPS | Raw / output conversion |
| `-s` | Input size | Output size | Raw / scaling |
| `-c:v`/`-c:a` | Decoder | Encoder | Before = decode |
| `-hwaccel`, `-re`, `-itsoffset`, `-stream_loop` | **Required** | N/A | Input only |
| `-vf`, `-af`, `-map`, `-crf`, `-preset`, `-movflags` | N/A | **Required** | Output only |
| `-y`, `-v`, `-filter_complex` | Global | Global | Place first |

---

## Extended Reference Map

For exhaustive lookups, see the companion reference files:

- **Complete option catalog** (all global / input / output / color / threading / format flag tables): [`references/complete-option-reference.md`](references/complete-option-reference.md)
- **Stream specifier syntax and examples**: [`references/stream-specifiers.md`](references/stream-specifiers.md)
- **Per-backend hardware device initialization** (CUDA, VAAPI, QSV, Vulkan, D3D11VA, VideoToolbox): [`references/hardware-device-init.md`](references/hardware-device-init.md)
- **Format/protocol/muxer options** (HLS, DASH, segment, RTSP, RTMP, raw video, movflags, MPEG-TS, Matroska): [`references/format-specific-options.md`](references/format-specific-options.md)
- **Timestamps, bitstream filters, metadata, attachments, disposition**: [`references/timestamps-bitstream-metadata.md`](references/timestamps-bitstream-metadata.md)

---

## External References

- [FFmpeg Documentation](https://ffmpeg.org/ffmpeg.html)
- [FFmpeg Wiki - Seeking](https://fftrac-bg.ffmpeg.org/wiki/Seeking)
- [Stream Specifiers](https://ffmpeg.org/ffmpeg.html#Stream-specifiers)
- [FFmpeg Formats Documentation](https://ffmpeg.org/ffmpeg-formats.html)
- [FFmpeg Bitstream Filters](https://ffmpeg.org/ffmpeg-bitstream-filters.html)
