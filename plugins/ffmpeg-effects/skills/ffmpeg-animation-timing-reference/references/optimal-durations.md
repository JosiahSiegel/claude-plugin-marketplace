# Optimal Animation Durations

Human-perception-grounded duration guidelines for FFmpeg animations and ASS subtitle effects.

## Human Perception Thresholds

| Timing | Brain Response | Application |
|--------|----------------|-------------|
| <16ms | Sub-perceptual | Cannot perceive (below 60fps frame) |
| 16-50ms | Preattentive | Flash effects, subliminal |
| 50-100ms | Motion detection | Pattern interrupts, glitches |
| 100-200ms | Conscious recognition | Quick animations, snappy UI |
| 200-400ms | Attention capture | Standard animations |
| 400-800ms | Processing time | Complex transitions |
| 800ms-2s | Contemplation | Dramatic, emotional effects |
| >2s | Extended focus | Deliberate, artistic pacing |

## Recommended Durations by Effect Type

### Text Animations

| Effect | Fast | Standard | Slow | Notes |
|--------|------|----------|------|-------|
| Word pop (scale) | 100-150ms | 150-250ms | 250-400ms | Material Design: 200ms |
| Fade in | 200-300ms | 300-500ms | 500-800ms | Smooth appearance |
| Fade out | 150-250ms | 200-400ms | 400-600ms | Slightly faster than fade in |
| Slide in | 200-300ms | 300-500ms | 500-800ms | Distance affects perception |
| Bounce | 300-400ms | 400-600ms | 600-800ms | Needs overshoot time |
| Typewriter | 30-50ms/char | 50-80ms/char | 80-120ms/char | Per character |

### Video Transitions (xfade)

| Transition | Fast | Standard | Slow | Best For |
|------------|------|----------|------|----------|
| Fade/Dissolve | 0.3-0.5s | 0.8-1.2s | 1.5-2.5s | Universal |
| Wipe | 0.2-0.4s | 0.5-0.8s | 1.0-1.5s | Directional energy |
| Slide | 0.3-0.5s | 0.6-1.0s | 1.2-2.0s | Dynamic movement |
| Circle/Iris | 0.5-0.8s | 1.0-1.5s | 2.0-3.0s | Dramatic reveal |
| Zoom | 0.4-0.6s | 0.8-1.2s | 1.5-2.5s | Impact, intensity |
| Pixelize | 0.3-0.5s | 0.5-0.8s | 1.0-1.5s | Glitch aesthetic |

### Hook Effects (First 1-3 Seconds)

| Hook Type | Effect Duration | Total Hook | Timing Pattern |
|-----------|----------------|------------|----------------|
| Pattern Interrupt | 50-150ms | 0.5-1.5s | Instant grab |
| Flash/Brightness | 80-200ms | 0.3-0.8s | Quick pulse |
| Zoom Punch | 200-400ms | 1-2s | Fast zoom-in, hold |
| Glitch | 100-300ms | 0.5-1.5s | Multiple bursts |
| Text Slam | 150-250ms | 1-2s | Quick appear, hold |

### Karaoke/Caption Animations

| Content | Duration Formula | Example |
|---------|------------------|---------|
| Single word | Word length * 50-100ms | "Hello" = 250-500ms |
| Short phrase | 1-2 seconds | "Check this out" |
| Sentence | Words / 3 per second | 9 words = 3 seconds |
| Reading captions | See `caption-readability.md` | Based on WPM |

## Duration Cheat Sheet

| Duration | Use For |
|----------|---------|
| 50-100ms | Glitch, flash |
| 100-200ms | Quick UI feedback |
| 200-300ms | Standard animation |
| 300-500ms | Smooth transition |
| 500-800ms | Noticeable movement |
| 800-1500ms | Dramatic effect |
| 1.5-3s | Caption display |
| 3-5s | Long text reading |

## Viral Video Timing (1.3-second Attention Threshold)

Hook animations must complete within ~0.5s to fit within the 1.3-second attention window with room for text/content.

| Effect Type | FPS | Effect Duration | Frame Count | `d=` Parameter |
|-------------|-----|-----------------|-------------|----------------|
| Hook zoom punch | 60 | 0.4-0.5s | 24-30 frames | `d=1` (use time conditional) |
| Hook flash | 60 | 0.2-0.3s | 12-18 frames | `d=1` (use time conditional) |
| Continuous zoom | 30 | Entire video | N/A | `d=1` (recalc per frame) |
| Text animations | 60 | 0.3-0.5s | 18-30 frames | `d=1` (use time conditional) |

Always use `d=1` for continuous per-frame processing in `zoompan`. Limit effect duration using time conditionals like `if(lt(t,0.5),effect,1)` rather than setting `d=` to a frame count (which would freeze the video after that many frames).

### Optimal Zoom Parameters by Platform

| Platform | Hook Zoom | Hook Duration | Continuous Zoom | Recommended FPS |
|----------|-----------|---------------|-----------------|-----------------|
| TikTok | 1.5x (50%) | 0.4-0.5s | +0.2%/sec | 60fps for hooks |
| YouTube Shorts | 1.5x (50%) | 0.5-0.6s | +0.15%/sec | 60fps throughout |
| Instagram Reels | 1.4x (40%) | 0.5-0.6s | +0.18%/sec | 60fps for hooks |

### Optimized Hook Formulas

```bash
# 1.5x zoom punch over 0.5s at 60fps (RECOMMENDED):
fps=60,zoompan=z='if(lt(t,0.5),1.5-t,1)':d=1:s=1080x1920

# 8% zoom pulse at ~2Hz for 1.5s (sin(t*12) = 12 rad/s = 1.91 Hz):
fps=60,zoompan=z='if(lt(t,1.5),1+0.08*sin(t*12),1)':d=1:s=1080x1920

# Subtle continuous zoom for TikTok (0.2%/sec):
zoompan=z='1+0.002*t':d=1:s=1080x1920

# Subtle continuous zoom for YouTube Shorts (0.15%/sec):
zoompan=z='1+0.0015*t':d=1:s=1080x1920
```
