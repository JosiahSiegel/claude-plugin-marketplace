---
name: Apply Color Effects
description: Apply color grading, LUTs, chromakey (green screen), and cinematic color effects
argument-hint: <effect: lut|chromakey|grade|cinematic> [input-file]
allowed-tools:
  - Bash
  - Read
  - Write
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# FFmpeg Color Effects

## Purpose
Apply professional color grading, LUTs (Look-Up Tables), chromakey (green screen removal), and cinematic color effects to video.

## Workflow

### 1. Analyze Input
```bash
ffprobe -v error -show_entries stream=width,height,pix_fmt -of default=noprint_wrappers=1 INPUT
```

### 2. Color Effect Presets

#### LUT Application (3D Look-Up Tables)
```bash
# Apply .cube LUT file
ffmpeg -i INPUT -vf "lut3d=file='cinematic.cube'" OUTPUT

# Apply with intensity control (0-1)
ffmpeg -i INPUT -vf "lut3d=file='vintage.cube':interp=tetrahedral" OUTPUT
```

#### Chromakey (Green Screen Removal)
```bash
# Standard green screen
ffmpeg -i INPUT -vf "chromakey=0x00FF00:0.3:0.1" -c:v libx264 OUTPUT

# Blue screen
ffmpeg -i INPUT -vf "chromakey=0x0000FF:0.3:0.1" OUTPUT

# Fine-tuned green (studio green)
ffmpeg -i INPUT -vf "chromakey=0x00B140:0.25:0.05" OUTPUT
```

#### Colorkey (Non-chroma keying)
```bash
# Remove specific color
ffmpeg -i INPUT -vf "colorkey=0xFFFFFF:0.3:0.2" OUTPUT
```

#### Green Screen Composite
```bash
# Composite foreground over background
ffmpeg -i foreground.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay=format=auto" \
  -c:v libx264 -crf 18 OUTPUT
```

### 3. Cinematic Color Presets

#### Teal and Orange (Blockbuster Look)
```bash
ffmpeg -i INPUT \
  -vf "curves=b='0/0.1 0.5/0.4 1/0.8':r='0/0 0.5/0.6 1/1',eq=saturation=1.2:contrast=1.1" \
  OUTPUT
```

#### Film Emulation (Vintage)
```bash
ffmpeg -i INPUT \
  -vf "curves=preset=vintage,eq=saturation=0.9:brightness=0.02" \
  OUTPUT
```

#### High Contrast Noir
```bash
ffmpeg -i INPUT \
  -vf "eq=contrast=1.5:brightness=-0.1:saturation=0.1" \
  OUTPUT
```

#### Warm/Golden Hour
```bash
ffmpeg -i INPUT \
  -vf "colorbalance=rs=0.15:gs=0.05:bs=-0.1:rm=0.1:gm=0.05:bm=-0.05" \
  OUTPUT
```

#### Cool/Moonlight
```bash
ffmpeg -i INPUT \
  -vf "colorbalance=rs=-0.1:bs=0.2:rm=-0.1:bm=0.15,eq=brightness=-0.1" \
  OUTPUT
```

### 4. Color Adjustment Filters

#### Color Balance
```bash
# Shadows (s), Midtones (m), Highlights (h)
ffmpeg -i INPUT -vf "colorbalance=rs=0.1:gs=0:bs=-0.1:rm=0.05:gm=0:bm=-0.05" OUTPUT
```

#### Curves Adjustment
```bash
# Boost contrast with S-curve
ffmpeg -i INPUT -vf "curves=all='0/0 0.25/0.15 0.5/0.5 0.75/0.85 1/1'" OUTPUT

# RGB channel manipulation
ffmpeg -i INPUT -vf "curves=r='0/0 0.5/0.6 1/1':g='0/0 0.5/0.5 1/1':b='0/0.1 0.5/0.4 1/0.9'" OUTPUT
```

#### Saturation and Vibrance
```bash
# Increase saturation
ffmpeg -i INPUT -vf "eq=saturation=1.5" OUTPUT

# Selective color boost (vibrance-like)
ffmpeg -i INPUT -vf "hue=s=1.3" OUTPUT
```

#### White Balance / Color Temperature
```bash
# Warm (increase color temperature)
ffmpeg -i INPUT -vf "colortemperature=temperature=6500" OUTPUT

# Cool (decrease color temperature)
ffmpeg -i INPUT -vf "colortemperature=temperature=4500" OUTPUT
```

### 5. Professional Workflows

#### Spill Suppression (After Chromakey)
```bash
ffmpeg -i INPUT \
  -filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1,despill=type=green:mix=0.5[fg]" \
  OUTPUT
```

#### Color Match Between Clips
```bash
ffmpeg -i source.mp4 -i reference.mp4 \
  -filter_complex "[0:v][1:v]colorcorrect=rl=0.1:bl=-0.1:rh=0.05:bh=-0.05[out]" \
  -map "[out]" OUTPUT
```

### 6. Parameter Reference

| Filter | Key Parameters |
|--------|----------------|
| chromakey | color, similarity (0-1), blend (0-1) |
| lut3d | file, interp (nearest, trilinear, tetrahedral) |
| curves | preset, r/g/b/all channel curves |
| colorbalance | rs/gs/bs (shadows), rm/gm/bm (mids), rh/gh/bh (highs) |
| eq | contrast, brightness, saturation, gamma |
| colortemperature | temperature (Kelvin value) |

### 7. Testing Tips

- **Preview first**: Use `-t 5` to test on 5 seconds
- **Check histogram**: Add `split[a][b];[b]histogram,format=yuva444p[h];[a][h]overlay` to see color distribution
- **A/B comparison**: Use `hstack` to compare original vs processed

## Output

Provide:
1. Complete FFmpeg command for the requested color effect
2. Explanation of color parameters and their visual impact
3. Suggestions for fine-tuning the effect
4. Alternative presets or looks to try
5. Tips for matching footage or maintaining consistency
