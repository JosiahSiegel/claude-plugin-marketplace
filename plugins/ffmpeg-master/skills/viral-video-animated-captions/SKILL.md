---
name: viral-video-animated-captions
description: CapCut-style animated word-level captions for viral video with FFmpeg. PROACTIVELY activate for: (1) Word-by-word caption highlighting, (2) Animated subtitle effects, (3) CapCut-style captions, (4) Karaoke-style text, (5) Bounce/pop text animations, (6) Color-changing words, (7) Emoji integration in captions, (8) Multi-style caption presets, (9) Trending caption styles, (10) Social media caption optimization. Provides: ASS subtitle generation scripts, word-level timing workflows, animation presets, color schemes, font recommendations, and platform-specific caption styles for TikTok, YouTube Shorts, and Instagram Reels.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

---

# CapCut-Style Animated Captions (2025-2026)

## Why Animated Captions Matter

- **80% engagement boost** when captions are present
- **85% of social video** is watched without sound
- **Animated word highlighting** increases retention by 25-40%
- CapCut-style captions are now **expected** by viewers

---

## Quick Reference

| Style | Effect | Best For |
|-------|--------|----------|
| Word Pop | Words bounce in one at a time | High energy, Gen Z |
| Highlight Sweep | Color sweeps across words | Professional, educational |
| Karaoke | Words light up with audio timing | Music, voiceover |
| Typewriter | Characters appear sequentially | Storytelling, dramatic |
| Scale Pulse | Words pulse larger on appear | Emphasis, key points |

---

## Caption Workflow Overview

### Standard Workflow

1. **Generate transcript** with word-level timestamps (Whisper)
2. **Convert to ASS format** with animation styles
3. **Burn captions** into video with FFmpeg

---

## Step 1: Generate Word-Level Timestamps

### Using Whisper (FFmpeg 8.0+)

```bash
# Generate JSON with word-level timestamps
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:format=json" \
  transcript.json
```

### Using whisper.cpp Directly (More Control)

```bash
# Generate word-level JSON
whisper.cpp/main -m ggml-base.bin -f audio.wav -ojf -ml 1

# Output: audio.wav.json with word timings
```

### Using OpenAI Whisper API

```python
import whisper

model = whisper.load_model("base")
result = model.transcribe("audio.mp3", word_timestamps=True)

# Access word-level timing
for segment in result["segments"]:
    for word in segment["words"]:
        print(f"{word['word']}: {word['start']:.2f} - {word['end']:.2f}")
```

---

## Step 2: Create Animated ASS Subtitles

### ASS File Structure

```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial Black,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,200,1
Style: Highlight,Arial Black,72,&H0000FFFF,&H000000FF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,200,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
```

### Style 1: Word Pop (CapCut Default)

Each word pops in with a scale animation.

```ass
[V4+ Styles]
Style: WordPop,Montserrat,80,&H00FFFFFF,&H00FFFF00,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,250,1

[Events]
; Word "This" pops in at 0.0s
Dialogue: 0,0:00:00.00,0:00:00.50,WordPop,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}This
; Word "is" pops in at 0.3s
Dialogue: 0,0:00:00.30,0:00:00.80,WordPop,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}is
; Word "AMAZING" pops in with emphasis at 0.5s
Dialogue: 0,0:00:00.50,0:00:01.20,WordPop,,0,0,0,,{\c&H00FFFF&\fscx50\fscy50\t(0,100,\fscx120\fscy120)\t(100,250,\fscx100\fscy100)}AMAZING
```

### Style 2: Highlight Sweep

Words appear white, then highlight yellow as spoken.

```ass
[V4+ Styles]
Style: Sweep,Arial Black,72,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,250,1

[Events]
; Full sentence appears, words highlight in sequence
Dialogue: 0,0:00:00.00,0:00:02.00,Sweep,,0,0,0,,{\k20}This {\k15}is {\k25}how {\k20}you {\k30}do {\k20}it
```

### Style 3: Karaoke (Music/Voiceover)

Progressive color fill across each word.

```ass
[V4+ Styles]
Style: Karaoke,Impact,80,&H00FFFFFF,&H0000FFFF,&H00000000,&H00000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,250,1

[Events]
; Karaoke timing (values in centiseconds)
Dialogue: 0,0:00:00.00,0:00:03.00,Karaoke,,0,0,0,,{\kf50}This {\kf40}is {\kf60}the {\kf45}secret {\kf70}formula
```

### Style 4: Typewriter Effect

Characters appear one at a time.

```ass
[V4+ Styles]
Style: Typewriter,Courier New,64,&H00FFFFFF,&H00FFFFFF,&H00000000,&H80000000,0,0,0,0,100,100,0,0,1,3,0,2,10,10,250,1

[Events]
; Each character has its own timing
Dialogue: 0,0:00:00.00,0:00:00.10,Typewriter,,0,0,0,,T
Dialogue: 0,0:00:00.10,0:00:00.20,Typewriter,,0,0,0,,Th
Dialogue: 0,0:00:00.20,0:00:00.30,Typewriter,,0,0,0,,Thi
Dialogue: 0,0:00:00.30,0:00:00.40,Typewriter,,0,0,0,,This
; ... continue for each character
```

### Style 5: Bounce In

Words bounce from below with overshoot.

```ass
[V4+ Styles]
Style: Bounce,Arial Black,76,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,250,1

[Events]
; Word bounces up from bottom
Dialogue: 0,0:00:00.00,0:00:00.80,Bounce,,0,0,0,,{\move(540,1200,540,960)\t(0,150,\fscx110\fscy110)\t(150,300,\fscx95\fscy95)\t(300,400,\fscx100\fscy100)}Word
```

---

## Caption Generation Scripts

### Python Script: JSON to Animated ASS

```python
#!/usr/bin/env python3
"""
Convert Whisper JSON transcript to animated ASS subtitles.
Usage: python json_to_ass.py transcript.json output.ass [style]
Styles: pop, sweep, karaoke, bounce
"""

import json
import sys

def format_time(seconds):
    """Convert seconds to ASS timestamp format (H:MM:SS.cc)"""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h}:{m:02d}:{s:05.2f}"

def generate_pop_style(words):
    """Generate word-pop animation (CapCut default style)"""
    events = []
    for word_data in words:
        word = word_data['word'].strip()
        start = word_data['start']
        end = word_data['end']

        # Pop animation: scale from 50% to 110% to 100%
        # NOTE: ASS \t() animation tags use MILLISECONDS (not centiseconds!)
        # \t(0,80,...) = 0-80ms scale up, \t(80,180,...) = 80-180ms scale down
        effect = r"{\fscx50\fscy50\t(0,80,\fscx115\fscy115)\t(80,180,\fscx100\fscy100)}"

        events.append(
            f"Dialogue: 0,{format_time(start)},{format_time(end)},WordPop,,0,0,0,,{effect}{word}"
        )
    return events

def generate_sweep_style(segments):
    """Generate highlight sweep animation"""
    events = []
    for segment in segments:
        words = segment.get('words', [])
        if not words:
            continue

        start_time = words[0]['start']
        end_time = words[-1]['end']

        # Build karaoke timing string
        # NOTE: ASS karaoke \k tags use CENTISECONDS (multiply seconds by 100)
        karaoke_text = ""
        for i, word_data in enumerate(words):
            word = word_data['word'].strip()
            # Convert seconds to centiseconds: 0.5s * 100 = 50 centiseconds = {\k50}
            duration = int((word_data['end'] - word_data['start']) * 100)
            karaoke_text += f"{{\\k{duration}}}{word} "

        events.append(
            f"Dialogue: 0,{format_time(start_time)},{format_time(end_time)},Sweep,,0,0,0,,{karaoke_text.strip()}"
        )
    return events

def generate_karaoke_style(segments):
    """Generate karaoke-fill animation"""
    events = []
    for segment in segments:
        words = segment.get('words', [])
        if not words:
            continue

        start_time = words[0]['start']
        end_time = words[-1]['end']

        # Build karaoke fill timing
        karaoke_text = ""
        for word_data in words:
            word = word_data['word'].strip()
            duration = int((word_data['end'] - word_data['start']) * 100)
            karaoke_text += f"{{\\kf{duration}}}{word} "

        events.append(
            f"Dialogue: 0,{format_time(start_time)},{format_time(end_time)},Karaoke,,0,0,0,,{karaoke_text.strip()}"
        )
    return events

def generate_bounce_style(words):
    """Generate bounce-in animation"""
    events = []
    for word_data in words:
        word = word_data['word'].strip()
        start = word_data['start']
        end = word_data['end']

        # Bounce from below with overshoot
        # NOTE: ASS \t() and \move() use MILLISECONDS
        # 0-120ms: scale up, 120-200ms: overshoot, 200-280ms: settle (total 280ms bounce)
        effect = r"{\move(540,1100,540,960)\t(0,120,\fscx115\fscy115)\t(120,200,\fscx95\fscy95)\t(200,280,\fscx100\fscy100)}"

        events.append(
            f"Dialogue: 0,{format_time(start)},{format_time(end)},Bounce,,0,0,0,,{effect}{word}"
        )
    return events

def create_ass_file(transcript_path, output_path, style='pop'):
    """Create ASS file from Whisper JSON transcript"""

    with open(transcript_path, 'r') as f:
        data = json.load(f)

    # ASS header
    header = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0
Title: Animated Captions

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: WordPop,Arial Black,80,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,250,1
Style: Sweep,Arial Black,72,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,250,1
Style: Karaoke,Impact,80,&H00FFFFFF,&H0000FFFF,&H00000000,&H00000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,250,1
Style: Bounce,Arial Black,76,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,250,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

    # Extract all words from segments
    all_words = []
    segments = data.get('segments', [])
    for segment in segments:
        words = segment.get('words', [])
        all_words.extend(words)

    # Generate events based on style
    if style == 'pop':
        events = generate_pop_style(all_words)
    elif style == 'sweep':
        events = generate_sweep_style(segments)
    elif style == 'karaoke':
        events = generate_karaoke_style(segments)
    elif style == 'bounce':
        events = generate_bounce_style(all_words)
    else:
        events = generate_pop_style(all_words)

    # Write ASS file
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(header)
        f.write('\n'.join(events))

    print(f"Created {output_path} with {len(events)} caption events ({style} style)")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python json_to_ass.py transcript.json output.ass [style]")
        print("Styles: pop, sweep, karaoke, bounce")
        sys.exit(1)

    transcript = sys.argv[1]
    output = sys.argv[2]
    style = sys.argv[3] if len(sys.argv) > 3 else 'pop'

    create_ass_file(transcript, output, style)
```

### Bash Script: Full Caption Pipeline

```bash
#!/bin/bash
# animated_captions.sh - Full pipeline for animated captions
# Usage: ./animated_captions.sh input.mp4 [style]

INPUT="$1"
STYLE="${2:-pop}"  # Default to 'pop' style
OUTPUT="${INPUT%.mp4}_captioned.mp4"

echo "=== Animated Caption Pipeline ==="
echo "Input: $INPUT"
echo "Style: $STYLE"

# Step 1: Extract audio
echo "[1/4] Extracting audio..."
ffmpeg -y -i "$INPUT" -vn -acodec pcm_s16le -ar 16000 -ac 1 audio_temp.wav

# Step 2: Generate transcript with Whisper
echo "[2/4] Generating transcript with Whisper..."
# Using FFmpeg's built-in Whisper (FFmpeg 8.0+)
ffmpeg -y -i audio_temp.wav \
  -af "whisper=model=ggml-base.bin:language=auto:destination=transcript.json:format=json" \
  -f null -

# Step 3: Convert to animated ASS
echo "[3/4] Creating animated ASS subtitles ($STYLE style)..."
python3 json_to_ass.py transcript.json captions.ass "$STYLE"

# Step 4: Burn subtitles into video
echo "[4/4] Burning captions into video..."
ffmpeg -y -i "$INPUT" \
  -vf "ass=captions.ass" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  "$OUTPUT"

# Cleanup
rm -f audio_temp.wav transcript.json

echo "=== Complete! ==="
echo "Output: $OUTPUT"
```

---

## FFmpeg Caption Presets

### Burn ASS Captions

```bash
# Standard ASS burn
ffmpeg -i input.mp4 \
  -vf "ass=captions.ass" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_captioned.mp4

# With custom fonts directory
ffmpeg -i input.mp4 \
  -vf "ass=captions.ass:fontsdir=/path/to/fonts" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_captioned.mp4
```

### Real-Time Caption Overlay (Whisper + Drawtext)

```bash
# Live captions from Whisper directly overlaid
ffmpeg -i input.mp4 \
  -af "whisper=model=ggml-base.bin:language=en" \
  -vf "drawtext=text='%{metadata\:lavfi.whisper.text}':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h-th-200:box=1:boxcolor=black@0.4:boxborderw=10" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a aac -b:a 128k \
  output_live_captions.mp4
```

---

## Caption Style Presets

### TikTok Viral Style

```ass
Style: TikTokViral,Arial Black,84,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,300,1
```

- **Font**: Arial Black (bold, readable)
- **Size**: 84 (large for mobile)
- **Colors**: White text, yellow highlight
- **Position**: Lower third (MarginV=300)

### YouTube Shorts Professional

```ass
Style: ShortsPro,Montserrat,72,&H00FFFFFF,&H00FFFFFF,&H00333333,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,280,1
```

- **Font**: Montserrat (modern, clean)
- **Size**: 72
- **Colors**: White with gray outline
- **Shadow**: Yes (professional look)

### Instagram Reels Trendy

```ass
Style: ReelsTrend,Impact,80,&H00FFFFFF,&H00FF00FF,&H00000000,&H00000000,1,0,0,0,100,100,2,0,1,5,0,2,10,10,260,1
```

- **Font**: Impact
- **Size**: 80
- **Colors**: White text, magenta highlight
- **Letter spacing**: 2 (spread out)

### Mr. Beast Style (High Energy)

```ass
Style: MrBeast,Impact,96,&H0000FFFF,&H000000FF,&H00000000,&H00000000,1,0,0,0,110,110,0,0,1,8,0,2,10,10,200,1
```

- **Font**: Impact
- **Size**: 96 (HUGE)
- **Colors**: Yellow text, red highlight
- **Scale**: 110% (extra impact)

---

## Color Schemes for Different Content

### High Energy / Gaming

```
Primary: &H0000FFFF (Yellow)
Highlight: &H000000FF (Red)
Outline: &H00000000 (Black)
```

### Professional / Educational

```
Primary: &H00FFFFFF (White)
Highlight: &H00FFD700 (Gold)
Outline: &H00333333 (Dark Gray)
```

### Lifestyle / Aesthetic

```
Primary: &H00FFFFFF (White)
Highlight: &H00FFC0CB (Pink)
Outline: &H00000000 (Black)
```

### Comedy / Casual

```
Primary: &H00FFFFFF (White)
Highlight: &H0000FF00 (Green)
Outline: &H00000000 (Black)
```

---

## Emoji Integration

### Adding Emojis to Captions

```ass
; Emoji in ASS subtitles (requires emoji font)
Dialogue: 0,0:00:01.00,0:00:02.00,Default,,0,0,0,,This is FIRE 🔥

; Using emoji font explicitly
Dialogue: 0,0:00:01.00,0:00:02.00,Default,,0,0,0,,{\fnSegoe UI Emoji}🔥{\fnArial Black} AMAZING
```

### Common Viral Emojis

```
🔥 - Fire (excitement, trending)
💀 - Skull (dying laughing)
😱 - Shocked (reactions)
✅ - Checkmark (lists, confirmations)
❌ - X mark (wrong/avoid)
💯 - 100 (emphasis, agreement)
👀 - Eyes (attention, looking)
🚨 - Alert (important, breaking)
```

---

## Platform-Specific Caption Guidelines

| Platform | Font Size | Position | Max Words/Screen | Animation |
|----------|-----------|----------|------------------|-----------|
| **TikTok** | 80-96 | Center/Lower | 3-5 words | Fast, punchy |
| **YouTube Shorts** | 72-84 | Lower third | 4-6 words | Smooth, readable |
| **Instagram Reels** | 76-88 | Center | 3-5 words | Trendy, stylish |
| **Facebook Reels** | 72-80 | Lower third | 5-7 words | Clear, accessible |

---

## Troubleshooting

### Captions Not Showing

```bash
# Verify ASS file is valid
ffmpeg -i captions.ass -f null -

# Check font availability
fc-list | grep -i "arial"
```

### Timing Issues

```bash
# Shift all captions by 0.5 seconds
ffmpeg -itsoffset 0.5 -i captions.ass shifted.ass
```

### Wrong Position on 9:16

```bash
# Adjust MarginV in ASS style for vertical video
# MarginV=250-350 is typical for 1920px height
```

---

## Related Skills

- `ffmpeg-captions-subtitles` - Full caption system
- `ffmpeg-karaoke-animated-text` - Advanced karaoke effects
- `viral-video-platform-specs` - Platform requirements
- `viral-video-hook-templates` - Hook patterns
