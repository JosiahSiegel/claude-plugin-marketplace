# Filter Essentials

Video filters (`-vf`), audio filters (`-af`), complex filtergraphs, and filter_complex quick reference.

## Video Filters (-vf)

```bash
# Chain multiple filters
ffmpeg -i input.mp4 -vf "scale=1280:720,fps=30,format=yuv420p" output.mp4

# Crop
ffmpeg -i input.mp4 -vf "crop=640:480:100:50" output.mp4

# Rotate
ffmpeg -i input.mp4 -vf "transpose=1" output.mp4  # 90 deg clockwise
ffmpeg -i input.mp4 -vf "transpose=2" output.mp4  # 90 deg counter-clockwise
ffmpeg -i input.mp4 -vf "hflip" output.mp4        # Horizontal flip
ffmpeg -i input.mp4 -vf "vflip" output.mp4        # Vertical flip

# Overlay/Watermark
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=10:10" output.mp4
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=W-w-10:H-h-10" output.mp4

# Text overlay
ffmpeg -i input.mp4 -vf "drawtext=text='Hello World':x=10:y=10:fontsize=24:fontcolor=white" output.mp4

# Fade in/out
ffmpeg -i input.mp4 -vf "fade=t=in:st=0:d=1,fade=t=out:st=9:d=1" output.mp4

# Speed up/slow down
ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" -af "atempo=2.0" output.mp4  # 2x speed
ffmpeg -i input.mp4 -vf "setpts=2.0*PTS" -af "atempo=0.5" output.mp4  # 0.5x speed

# Deinterlace
ffmpeg -i input.mp4 -vf "yadif" output.mp4

# Denoise
ffmpeg -i input.mp4 -vf "nlmeans" output.mp4
ffmpeg -i input.mp4 -vf "hqdn3d" output.mp4

# Sharpen
ffmpeg -i input.mp4 -vf "unsharp=5:5:1.0:5:5:0.0" output.mp4

# Color correction
ffmpeg -i input.mp4 -vf "eq=brightness=0.1:contrast=1.2:saturation=1.3" output.mp4
```

## Audio Filters (-af)

```bash
# Multiple audio filters
ffmpeg -i input.mp4 -af "volume=1.5,highpass=f=200,lowpass=f=3000" output.mp4

# Noise reduction
ffmpeg -i input.mp4 -af "afftdn=nf=-25" output.mp4

# Compressor/limiter
ffmpeg -i input.mp4 -af "acompressor=threshold=-20dB:ratio=4:attack=5:release=50" output.mp4

# Equalizer
ffmpeg -i input.mp4 -af "equalizer=f=1000:width_type=h:width=200:g=-10" output.mp4

# Fade audio
ffmpeg -i input.mp4 -af "afade=t=in:ss=0:d=3,afade=t=out:st=57:d=3" output.mp4

# Channel remix (stereo to mono)
ffmpeg -i input.mp4 -af "pan=mono|c0=0.5*c0+0.5*c1" output.mp4
```

## Complex Filtergraphs

```bash
# Picture-in-picture
ffmpeg -i main.mp4 -i pip.mp4 -filter_complex "[1:v]scale=320:240[pip];[0:v][pip]overlay=W-w-10:H-h-10" output.mp4

# Side by side
ffmpeg -i left.mp4 -i right.mp4 -filter_complex "[0:v]pad=iw*2:ih[bg];[bg][1:v]overlay=W/2:0" output.mp4

# Grid layout (2x2)
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 -filter_complex \
  "[0:v]scale=640:360[v0];[1:v]scale=640:360[v1];[2:v]scale=640:360[v2];[3:v]scale=640:360[v3];\
   [v0][v1]hstack[top];[v2][v3]hstack[bottom];[top][bottom]vstack" output.mp4
```

## filter_complex Quick Reference

### Syntax Components

| Component | Description | Example |
|-----------|-------------|---------|
| `[0:v]` | First input video | `[0:v]scale=1280:720` |
| `[1:a]` | Second input audio | `[0:a][1:a]amix` |
| `[label]` | Custom named label | `[scaled]`, `[mixed]` |
| `,` | Chain filters | `scale,fps,format` |
| `;` | Separate chains | `chain1;chain2` |
| `-map "[label]"` | Output specific label | `-map "[out]"` |

### Common Patterns

```bash
# Video transition (xfade)
ffmpeg -i a.mp4 -i b.mp4 -filter_complex \
  "[0:v][1:v]xfade=transition=fade:duration=1:offset=4[v]" \
  -map "[v]" output.mp4

# Audio mixing
ffmpeg -i video.mp4 -i music.mp3 -filter_complex \
  "[0:a]volume=1.0[v0];[1:a]volume=0.3[v1];[v0][v1]amix=inputs=2[a]" \
  -map 0:v -map "[a]" output.mp4

# Multi-output (ABR ladder)
ffmpeg -i input.mp4 -filter_complex \
  "[0:v]split=2[v1][v2];[v1]scale=1920:1080[hd];[v2]scale=1280:720[sd]" \
  -map "[hd]" hd.mp4 -map "[sd]" sd.mp4
```

For comprehensive filter_complex patterns, see the `ffmpeg-filter-complex-patterns` skill for PiP, grids, transitions, audio mixing, and GPU-accelerated filtergraphs.
