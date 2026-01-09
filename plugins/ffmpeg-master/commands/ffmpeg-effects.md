---
name: Apply Video Effects
description: Apply creative video effects - glitch, datamosh, VHS, chromatic aberration, distortion, and artistic filters
argument-hint: <effect: glitch|vhs|datamosh|chromatic|trails|distortion> [input-file]
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

# FFmpeg Creative Effects

## Purpose
Apply creative video effects including glitch art, VHS simulation, datamosh, chromatic aberration, motion trails, and distortion effects.

## Workflow

### 1. Analyze Input
```bash
ffprobe -v error -show_entries stream=width,height,r_frame_rate,duration -of default=noprint_wrappers=1 INPUT
```

### 2. Effect Presets

#### Glitch (Combined)
```bash
ffmpeg -i INPUT \
  -vf "\
    minterpolate='mi_mode=mci:mc_mode=aobmc':enable='lt(mod(t,3),0.2)',\
    rgbashift=rh='3*sin(t*10)':bh='-3*sin(t*10)',\
    noise=c0s=10:c0f=t:enable='lt(mod(t,2),0.1)'" \
  -c:v libx264 -crf 18 OUTPUT
```

#### VHS/Analog
```bash
ffmpeg -i INPUT \
  -vf "\
    noise=c0s=15:c0f=t:c1s=10:c1f=t,\
    eq=saturation=1.4:contrast=1.1:brightness=-0.02,\
    chromashift=cbh=3:crh=-3,\
    rgbashift=rh=2:bh=-2,\
    drawgrid=w=iw:h=2:t=1:c=black@0.3,\
    curves=preset=vintage" \
  -c:v libx264 -crf 20 OUTPUT
```

#### Datamosh (Pixel Bleeding)
```bash
ffmpeg -i INPUT \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1'" \
  -c:v libx264 -crf 18 OUTPUT
```

#### Chromatic Aberration
```bash
# Static
ffmpeg -i INPUT -vf "rgbashift=rh=-5:bh=5" OUTPUT

# Pulsing (animated)
ffmpeg -i INPUT -vf "rgbashift=rh='5*sin(t*10)':bh='-5*sin(t*10)'" OUTPUT
```

#### Motion Trails
```bash
ffmpeg -i INPUT -vf "lagfun=decay=0.95" OUTPUT
```

#### Wave Distortion
```bash
ffmpeg -i INPUT \
  -vf "geq=lum='lum(X+10*sin(Y/20+T*5),Y)':cb='cb(X+10*sin(Y/20+T*5),Y)':cr='cr(X+10*sin(Y/20+T*5),Y)'" \
  OUTPUT
```

#### Barrel/Fisheye Distortion
```bash
ffmpeg -i INPUT \
  -vf "lenscorrection=cx=0.5:cy=0.5:k1=0.5:k2=0.5" \
  OUTPUT
```

### 3. Timing Effects

Apply effects only during specific time ranges:
```bash
# Effect between 5-10 seconds
-vf "effect_filter:enable='between(t,5,10)'"

# Effect at regular intervals
-vf "effect_filter:enable='lt(mod(t,4),0.3)'"
```

### 4. Effect Parameters

| Effect | Key Parameters |
|--------|----------------|
| Datamosh | mi_mode, mc_mode, scd (scene change) |
| Chromatic | rh, bh, rv, bv (shift amounts) |
| VHS noise | c0s, c0f (strength, flags) |
| Trails | decay (0-1, higher = longer trails) |
| Distortion | k1, k2 (barrel/pincushion) |

### 5. Combining Effects

Chain multiple effects:
```bash
ffmpeg -i INPUT \
  -vf "effect1,effect2,effect3" \
  OUTPUT
```

### 6. Performance Tips

- **Datamosh is CPU-intensive**: Consider processing at lower resolution
- **Test on short clips**: Use `-t 5` to process only 5 seconds
- **Hardware encode final**: After effects, use NVENC/QSV for encoding

## Output

Provide:
1. Complete FFmpeg command for the requested effect
2. Explanation of effect parameters
3. Options for timing/triggering the effect
4. Combination suggestions for more complex looks
5. Performance optimization tips
