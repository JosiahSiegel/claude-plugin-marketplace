---
name: ffmpeg-karaoke-animated-text
description: |
  Complete karaoke subtitle system and advanced animated text effects.
  PROACTIVELY activate for: (1) Karaoke-style highlighted lyrics, (2) ASS/SSA advanced subtitle styling, (3) Scrolling credits (horizontal/vertical), (4) Typewriter text animation, (5) Bouncing/moving text, (6) Text fade in/out effects, (7) Word-by-word text reveal, (8) Kinetic typography, (9) Lower thirds animation, (10) Countdown timers and dynamic text.
  Provides: ASS karaoke timing format, drawtext with time expressions, scrolling text patterns, text animation formulas, kinetic typography techniques, subtitle styling reference, multi-line animated text.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# FFmpeg Karaoke & Animated Text

Use this skill for karaoke subtitles, kinetic typography, scrolling credits, animated lower thirds, typewriter text, timers, and dynamic text overlays. Keep answers practical: identify whether ASS or `drawtext` is the right tool, provide a copy-paste-ready command or ASS snippet, and call out timing units.

## Quick Reference

| Effect | Pattern |
|--------|---------|
| Karaoke ASS | Use ASS format with `\k`, `\kf`, or `\ko` timing tags |
| Burn karaoke | `ffmpeg -i input.mp4 -vf "ass=karaoke.ass" -c:v libx264 -crf 18 -c:a copy output.mp4` |
| Scrolling credits | `-vf "drawtext=textfile=credits.txt:y=h-80*t"` |
| Typewriter | Stagger `drawtext` layers with `enable='gte(t,...)'` |
| Fade in text | `-vf "drawtext=text='Title':alpha='min(1,t/2)'"` |
| Bouncing text | `-vf "drawtext=text='Bounce':y='h/2+50*sin(t*5)'"` |
| Moving text | `-vf "drawtext=text='Move':x='w-mod(t*100,w+tw)'"` |
| Rotation | Use ASS (`\frz`, `\frx`, `\fry`); `drawtext` does not rotate text natively |

## When to Use This Skill

Use for animated text and karaoke:

- Music video lyrics with karaoke highlighting
- Movie-style scrolling credits
- Animated titles and lower thirds
- Typewriter text reveal
- Kinetic typography and word pops
- Countdown timers, stopwatches, frame counters, timecode overlays
- Multi-line text and textfile-driven overlays

## Tool Choice: ASS vs drawtext

| Need | Best Tool | Why |
|------|-----------|-----|
| Word/syllable karaoke highlighting | ASS | Native `\k`, `\kf`, `\ko` support |
| Styled subtitles with outline/glow/rotation | ASS | Rich subtitle styling and transform tags |
| Simple overlay text | `drawtext` | Fast, direct FFmpeg filter |
| Timecode, frame numbers, metadata text | `drawtext` | Built-in variable expansion |
| Scrolling credits/news tickers | `drawtext` | Straightforward position expressions |
| Per-word kinetic captions | ASS or multiple `drawtext` layers | ASS is easier for rotation/scale; drawtext is direct for formula motion |

---

## CRITICAL: ASS Time Unit Reference

**ASS uses TWO DIFFERENT time unit systems. This is a common source of bugs.** Karaoke tags use centiseconds; ASS animation tags use milliseconds; FFmpeg `drawtext` expressions use seconds.

### Karaoke Tags = CENTISECONDS (1/100 second)

| Tag | Unit | Example | Duration |
|-----|------|---------|----------|
| `\k` | centiseconds | `{\k50}` | 0.5 seconds |
| `\kf` | centiseconds | `{\kf100}` | 1.0 second |
| `\ko` | centiseconds | `{\ko25}` | 0.25 seconds |

Conversion: `seconds * 100 = centiseconds`.

### Animation Tags = MILLISECONDS (1/1000 second)

| Tag | Unit | Example | Duration |
|-----|------|---------|----------|
| `\t(t1,t2,...)` | milliseconds | `\t(0,500,...)` | 0-500ms animation |
| `\fad(in,out)` | milliseconds | `\fad(200,300)` | 200ms in, 300ms out |
| `\move(x1,y1,x2,y2,t1,t2)` | milliseconds | `\move(0,0,100,100,0,1000)` | 1 second move |

Conversion: `seconds * 1000 = milliseconds`.

### FFmpeg drawtext = SECONDS

| Expression | Unit | Example |
|------------|------|---------|
| `t` | seconds | `t=2.5` means 2.5 seconds |
| `enable='between(t,0,3)'` | seconds | visible from 0-3 seconds |
| `alpha='min(1,t/2)'` | seconds | fade over 2 seconds |

### Common Mistake

```ass
; WRONG - mixing units:
Dialogue: 0,0:00:00.00,0:00:02.00,Style,,0,0,0,,{\k100\t(0,100,...)}Word
; {\k100} = 1 second, but \t(0,100,...) = 0.1 seconds

; CORRECT - matched duration:
Dialogue: 0,0:00:00.00,0:00:02.00,Style,,0,0,0,,{\k100\t(0,1000,...)}Word
```

For the full timing-unit reference, use `ffmpeg-animation-timing-reference`.

---

## Karaoke Core Pattern

```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Karaoke,Arial,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,3,2,2,10,10,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50}Twinkle {\k50}twinkle {\k50}little {\k50}star
```

Burn into video:

```bash
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass" \
  -c:v libx264 -crf 18 -c:a copy \
  output_karaoke.mp4
```

For advanced styles, neon/gradient karaoke, per-character timing, and animated karaoke transforms, see `references/karaoke-ass-patterns.md`.

## drawtext Core Patterns

```bash
# Fade in title over 2 seconds
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Title':fontsize=100:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:alpha='min(1,t/2)'" \
  output.mp4

# Vertical bounce
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=yellow:x=(w-tw)/2:y='(h-th)/2+50*sin(t*5)'" \
  bounce.mp4

# Scroll credits upward at 80px/sec
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=credits.txt:fontsize=48:fontcolor=white:x=(w-tw)/2:y=h-80*t" \
  -c:v libx264 -crf 18 output.mp4
```

For spring/elastic/wobble formulas, typewriter effects, lower thirds, countdowns, stopwatches, metadata overlays, and multi-line text, see `references/drawtext-animation-recipes.md`.

## Workflow

1. **Choose ASS or drawtext** using the tool-choice table.
2. **Verify timing units** before writing tags or expressions.
3. **Probe input when needed** (`ffprobe`) to confirm duration, frame rate, and resolution.
4. **Set output encoding explicitly** when burning text (`-c:v libx264 -crf 18`, audio copy only when compatible).
5. **Use short test renders** (`-ss`, `-t`) before rendering a full music video or credit roll.
6. **Check readability**: karaoke should track words within ~30ms; captions need enough display time; scrolling credits should move slowly enough to read.

## Reference Map

- `references/karaoke-ass-patterns.md` - ASS karaoke basics, `\k` / `\kf` / `\ko`, BPM timing, tag selection, neon/gradient styles, per-character karaoke, ASS color format, animated karaoke effects.
- `references/drawtext-animation-recipes.md` - Spring bounce, elastic overshoot, easing approximations, wobble/wiggle, pulse, wipes, typewriter, fades, moving text, kinetic typography, lower thirds, countdowns, stopwatches, dynamic variables, multi-line text.
- `references/scrolling-credits-and-expressions.md` - Music/education/credits timing, vertical credits, horizontal tickers, ASS rotation workaround, `drawtext` variables and expression cookbook.

## Related Skills

- `ffmpeg-animation-timing-reference` - Timing units, caption durations, easing, sync tolerances
- `ffmpeg-captions-subtitles` - Subtitle fundamentals, extraction, burn-in, styling
- `ffmpeg-kinetic-captions` - Word-level pop/bounce/grow caption effects
- `viral-video-animated-captions` - Social-video caption templates
- `ffmpeg-shapes-graphics` - Boxes, backgrounds, graphic overlays
- `ffmpeg-transitions-effects` - xfade and video transitions
