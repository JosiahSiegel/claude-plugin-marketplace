# Quick Copy-Paste Timing Patterns

Battle-tested FFmpeg and ASS timing snippets ready to drop into commands.

## FFmpeg Common Timing Patterns

```bash
# 2-second fade in:
-vf "fade=t=in:d=2"

# Text visible from 1s to 5s:
-vf "drawtext=text='Hello':enable='between(t,1,5)':..."

# 1.5s xfade starting at 4s:
-filter_complex "[0:v][1:v]xfade=duration=1.5:offset=4"

# 2-second zoom at 30fps (60 frames):
-vf "zoompan=z='1.5':d=60:s=1080x1920"

# Fade text in over 0.5s, hold, fade out over 0.3s (5s total):
-vf "drawtext=text='Hello':alpha='if(lt(t,0.5),t/0.5,if(lt(t,4.7),1,(5-t)/0.3))':enable='lt(t,5)':..."
```

## ASS Common Timing Patterns

```ass
; Word karaoke (centiseconds): 0.5s + 0.4s + 0.6s + 0.5s
{\k50}This {\k40}is {\k60}the {\k50}test

; 200ms pop animation (milliseconds):
{\fscx80\fscy80\t(0,200,\fscx100\fscy100)}Pop

; 500ms slide + 300ms fade:
{\move(0,1920,540,960,0,500)\fad(300,0)}Slide in

; Bounce: 150ms up, 100ms overshoot, 150ms settle (total 400ms)
{\fscx90\fscy90\t(0,150,\fscx110\fscy110)\t(150,250,\fscx95\fscy95)\t(250,400,\fscx100\fscy100)}Bounce
```

## Frame Rate Conversion Reference

| Frame Rate | 1 Frame Duration | 30 Frames | 60 Frames |
|------------|------------------|-----------|-----------|
| 24 fps | 41.67 ms | 1.25 s | 2.5 s |
| 25 fps | 40 ms | 1.2 s | 2.4 s |
| 30 fps | 33.33 ms | 1 s | 2 s |
| 50 fps | 20 ms | 0.6 s | 1.2 s |
| 60 fps | 16.67 ms | 0.5 s | 1 s |

### Zoompan Duration Calculation

```bash
# zoompan d= parameter is in FRAMES, not seconds!

# For 2-second zoom at 30fps:
ffmpeg -i input.mp4 -vf "zoompan=z='1.2':d=60:s=1080x1920" output.mp4
# d=60 frames / 30fps = 2 seconds

# For 2-second zoom at 60fps:
ffmpeg -i input.mp4 -vf "zoompan=z='1.2':d=120:s=1080x1920" output.mp4
# d=120 frames / 60fps = 2 seconds

# Formula: frames = seconds * fps
```
