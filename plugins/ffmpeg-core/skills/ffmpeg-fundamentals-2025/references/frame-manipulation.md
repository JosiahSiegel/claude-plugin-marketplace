# Frame Manipulation

Frame rate conversion, timestamp manipulation, frame selection, thumbnails, tiles, freezing, looping, and reversing.

## Frame Rate Conversion

```bash
# Change frame rate (drop/duplicate frames)
ffmpeg -i input.mp4 -vf "fps=30" output.mp4
ffmpeg -i input.mp4 -vf "fps=24000/1001" output.mp4  # 23.976 fps

# Motion-interpolated frame rate conversion (smoother)
ffmpeg -i input.mp4 -vf "framerate=fps=60" output.mp4

# High-quality motion interpolation (minterpolate)
ffmpeg -i input.mp4 -vf "minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1" output.mp4

# Simple motion interpolation (faster)
ffmpeg -i input.mp4 -vf "minterpolate=fps=60:mi_mode=blend" output.mp4
```

### minterpolate Modes

| mi_mode | Description | Speed | Quality |
|---------|-------------|-------|---------|
| `dup` | Duplicate frames | Fastest | Lowest |
| `blend` | Blend adjacent frames | Fast | Medium |
| `mci` | Motion-compensated interpolation | Slow | Best |

## Timestamp Manipulation (setpts)

```bash
# Speed up 2x (halve timestamps)
ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" output.mp4

# Slow down 2x (double timestamps)
ffmpeg -i input.mp4 -vf "setpts=2.0*PTS" output.mp4

# Start from timestamp 0 (reset PTS)
ffmpeg -i input.mp4 -vf "setpts=PTS-STARTPTS" output.mp4

# Time-lapse: keep every 10th frame, at 30fps output
ffmpeg -i input.mp4 -vf "select='not(mod(n,10))',setpts=N/30/TB" output.mp4

# Variable speed (accelerate over time)
ffmpeg -i input.mp4 -vf "setpts='PTS/(1+0.001*N)'" output.mp4
```

### setpts Variables

| Variable | Description |
|----------|-------------|
| `PTS` | Input presentation timestamp |
| `N` | Frame count (starting at 0) |
| `PREV_PTS` | Previous frame timestamp |
| `TB` | Timebase |
| `STARTPTS` | First frame timestamp |
| `RTCSTART` | Real-time clock start |

## Frame Selection (select)

```bash
# Select every 5th frame
ffmpeg -i input.mp4 -vf "select='not(mod(n,5))',setpts=N/FRAME_RATE/TB" output.mp4

# Select I-frames only (keyframes)
ffmpeg -i input.mp4 -vf "select='eq(pict_type,I)',setpts=N/FRAME_RATE/TB" keyframes.mp4

# Select frames with scene change
ffmpeg -i input.mp4 -vf "select='gt(scene,0.4)',setpts=N/FRAME_RATE/TB" scenes.mp4

# Select frames based on time range
ffmpeg -i input.mp4 -vf "select='between(t,5,10)',setpts=N/FRAME_RATE/TB" output.mp4

# Select frames by expression (dark frames)
ffmpeg -i input.mp4 -vf "select='lt(avg(scene),0.1)'" output.mp4
```

### select Expressions

| Expression | Description |
|------------|-------------|
| `n` | Frame number |
| `t` | Timestamp (seconds) |
| `pict_type` | Picture type (I, P, B) |
| `scene` | Scene change score |
| `key` | 1 for keyframes |
| `interlace_type` | Interlace type |

## Thumbnail Generation

```bash
# Generate thumbnail from best frame
ffmpeg -i input.mp4 -vf "thumbnail" -frames:v 1 thumbnail.jpg

# Thumbnail with custom frames to analyze
ffmpeg -i input.mp4 -vf "thumbnail=n=100" -frames:v 1 thumbnail.jpg

# Generate multiple thumbnails (every 10 seconds)
ffmpeg -i input.mp4 -vf "fps=1/10,thumbnail=n=1" thumb_%04d.jpg

# Thumbnail at specific time
ffmpeg -ss 00:00:30 -i input.mp4 -vframes 1 thumbnail.jpg
```

## Tile / Contact Sheet

```bash
# Create 4x4 tile mosaic
ffmpeg -i input.mp4 -vf "fps=1/5,scale=320:180,tile=4x4" -frames:v 1 contact_sheet.jpg

# Create tile with padding
ffmpeg -i input.mp4 -vf "fps=1/10,scale=256:144,tile=5x4:margin=5:padding=5" contact.png

# Video tile mosaic (animated)
ffmpeg -i input.mp4 -vf "scale=320:180,tile=2x2" tiled.mp4
```

### tile Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `layout` | Grid dimensions | `4x4` |
| `margin` | Outer margin | `10` |
| `padding` | Inter-tile padding | `5` |
| `color` | Background color | `black` |

## Frame Freezing

```bash
# Freeze first frame for 3 seconds, then play
ffmpeg -i input.mp4 -vf "tpad=start_mode=clone:start_duration=3" output.mp4

# Freeze last frame for 3 seconds
ffmpeg -i input.mp4 -vf "tpad=stop_mode=clone:stop_duration=3" output.mp4

# Add black frames at start
ffmpeg -i input.mp4 -vf "tpad=start=90:color=black" output.mp4

# Freeze specific frame range (frames 100-150)
ffmpeg -i input.mp4 -vf "freezeframes=first=100:last=150:replace=100" output.mp4
```

## Loop and Reverse

```bash
# Loop video 3 times
ffmpeg -stream_loop 3 -i input.mp4 -c copy output.mp4

# Loop filter (within filter graph)
ffmpeg -i input.mp4 -vf "loop=loop=3:size=30:start=0" output.mp4

# Reverse video
ffmpeg -i input.mp4 -vf "reverse" reversed.mp4

# Reverse audio too
ffmpeg -i input.mp4 -vf "reverse" -af "areverse" reversed.mp4

# Boomerang effect (forward then reverse)
ffmpeg -i input.mp4 -filter_complex "[0:v]split[v1][v2];[v2]reverse[r];[v1][r]concat=n=2:v=1:a=0" boomerang.mp4
```

## Frame Extraction Patterns

```bash
# Extract all frames
ffmpeg -i input.mp4 frames/frame_%05d.png

# Extract at specific FPS
ffmpeg -i input.mp4 -vf "fps=1" frames/frame_%04d.jpg

# Extract keyframes only
ffmpeg -i input.mp4 -vf "select='eq(pict_type,I)'" -vsync vfr keyframe_%04d.png

# Extract frames with timestamp filename
ffmpeg -i input.mp4 -vf "fps=1" -frame_pts 1 "frame_%d.jpg"
```
