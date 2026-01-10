---
name: Create Kinetic Captions
description: Create animated kinetic captions with word-grow, bounce, pop, and karaoke effects for viral videos
argument-hint: <effect: pop|grow|bounce|elastic|karaoke-grow> [input-file] [--platform tiktok|youtube|instagram]
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# FFmpeg Kinetic Captions

## Purpose
Create animated kinetic captions with professional effects like word-grow karaoke, bouncy text, elastic effects, and CapCut-style word pop animations for viral social media videos.

## Workflow

### 1. Quick Effect Reference

| Effect | Description | Best For |
|--------|-------------|----------|
| `pop` | Words pop in from small to normal with overshoot | TikTok, fast-paced content |
| `grow` | Words smoothly scale up when highlighted | Karaoke, music videos |
| `bounce` | Elastic bounce with multiple oscillations | YouTube Shorts, emphasis |
| `elastic` | Spring physics with natural damping | Professional, premium feel |
| `karaoke-grow` | Combined karaoke fill + grow animation | Lyric videos, singalongs |

### 2. Generate Kinetic ASS Subtitles

#### Using the Script
```bash
# Basic kinetic captions
./generate-karaoke.sh kinetic lyrics.txt output.ass pop

# Platform-optimized
./generate-karaoke.sh kinetic lyrics.txt output.ass bounce tiktok
./generate-karaoke.sh kinetic lyrics.txt output.ass elastic youtube
./generate-karaoke.sh kinetic lyrics.txt output.ass karaoke-grow instagram
```

#### Manual ASS Creation

**Pop Effect (CapCut-Style):**
```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Style: Kinetic,Montserrat,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,50,50,30,1

[Events]
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Hello
Dialogue: 0,0:00:02.00,0:00:03.00,Kinetic,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}World
```

**Word-Grow Karaoke Effect:**
```ass
Dialogue: 0,0:00:01.00,0:00:05.00,Kinetic,,0,0,0,,{\k80\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}First {\k60\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}word {\k100\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}grows
```

**Bounce Effect:**
```ass
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}Bounce
```

**Elastic Effect:**
```ass
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx60\fscy60\t(0,80,\fscx125\fscy125)\t(80,160,\fscx92\fscy92)\t(160,240,\fscx105\fscy105)\t(240,320,\fscx98\fscy98)\t(320,400,\fscx100\fscy100)}Elastic
```

### 3. Apply to Video

```bash
# Burn subtitles into video
ffmpeg -i input.mp4 -vf "ass=kinetic.ass" -c:v libx264 -crf 18 -c:a copy output.mp4

# With hardware acceleration (NVENC)
ffmpeg -i input.mp4 -vf "ass=kinetic.ass" -c:v h264_nvenc -preset p4 -cq 20 -c:a copy output.mp4

# 9:16 vertical with kinetic captions
ffmpeg -i input.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,ass=kinetic.ass" -c:v libx264 -crf 18 output.mp4
```

### 4. Platform-Specific Timing

| Platform | Animation Speed | Recommended Effect |
|----------|----------------|-------------------|
| TikTok | Fast (100-200ms) | pop, bounce |
| YouTube Shorts | Medium (150-300ms) | grow, elastic |
| Instagram Reels | Stylish (200-400ms) | elastic, karaoke-grow |

### 5. Critical ASS Timing Notes

**IMPORTANT: ASS uses TWO different time units:**
- **Karaoke tags (`\k`, `\kf`, `\ko`)**: Centiseconds (100 = 1 second)
- **Animation tags (`\t`)**: Milliseconds (1000 = 1 second)

Example combining both:
```ass
{\k80\t(0,200,\fscx115\fscy115)}Word
```
- `\k80` = word highlighted for 0.8 seconds (80 centiseconds)
- `\t(0,200,...)` = animation over 200 milliseconds

### 6. Color Variations

```ass
# Yellow highlight on grow
{\k80\t(0,200,\fscx115\fscy115\c&H00FFFF&)\t(200,400,\fscx100\fscy100)}Word

# Gradient glow effect
{\k80\t(0,200,\fscx115\fscy115\3c&H0000FF&)\t(200,400,\fscx100\fscy100\3c&H000000&)}Word
```

### 7. Advanced: Python Generator

For complex projects, use the Python generator:

```python
import json

def generate_kinetic_ass(words, effect="pop", platform="tiktok"):
    """Generate kinetic ASS subtitle file"""

    effects = {
        "pop": r"{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}",
        "grow": r"{\fscx90\fscy90\t(0,150,\fscx110\fscy110)\t(150,300,\fscx100\fscy100)}",
        "bounce": r"{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}",
        "elastic": r"{\fscx60\fscy60\t(0,80,\fscx125\fscy125)\t(80,160,\fscx92\fscy92)\t(160,240,\fscx105\fscy105)\t(240,320,\fscx98\fscy98)\t(320,400,\fscx100\fscy100)}"
    }

    header = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Style: Kinetic,Montserrat,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,50,50,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

    effect_code = effects.get(effect, effects["pop"])
    lines = []

    for word_data in words:
        word = word_data["word"]
        start = word_data["start"]
        end = word_data["end"]
        lines.append(f"Dialogue: 0,{start},{end},Kinetic,,0,0,0,,{effect_code}{word}")

    return header + "\n".join(lines)

# Usage
words = [
    {"word": "Hello", "start": "0:00:01.00", "end": "0:00:02.00"},
    {"word": "World", "start": "0:00:02.00", "end": "0:00:03.00"}
]
ass_content = generate_kinetic_ass(words, effect="bounce", platform="tiktok")
```

## Output

Provide:
1. Complete ASS subtitle file with kinetic effects
2. FFmpeg command to apply to video
3. Platform-specific optimization recommendations
4. Timing adjustments for audio sync
5. Color and style customization options
