---
name: ffmpeg-karaoke-animated-text
description: Complete karaoke subtitle system and advanced animated text effects. PROACTIVELY activate for: (1) Karaoke-style highlighted lyrics, (2) ASS/SSA advanced subtitle styling, (3) Scrolling credits (horizontal/vertical), (4) Typewriter text animation, (5) Bouncing/moving text, (6) Text fade in/out effects, (7) Word-by-word text reveal, (8) Kinetic typography, (9) Lower thirds animation, (10) Countdown timers and dynamic text. Provides: ASS karaoke timing format, drawtext with time expressions, scrolling text patterns, text animation formulas, kinetic typography techniques, subtitle styling reference, multi-line animated text.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

## Quick Reference

| Effect | Command |
|--------|---------|
| Scrolling credits | `-vf "drawtext=textfile=credits.txt:y=h-80*t"` |
| Typewriter | `-vf "drawtext=text='Hello':enable='gte(t,n*0.1)'"` |
| Fade in text | `-vf "drawtext=text='Title':alpha='min(1,t/2)'"` |
| Bouncing text | `-vf "drawtext=text='Bounce':y='h/2+50*sin(t*5)'"` |
| Karaoke ASS | Use ASS format with `\k` timing tags |
| Moving text | `-vf "drawtext=text='Move':x='w-mod(t*100,w+tw)'"` |

## When to Use This Skill

Use for **animated text and karaoke**:
- Music video lyrics with karaoke highlighting
- Movie-style scrolling credits
- Animated titles and lower thirds
- Typewriter text reveal
- Kinetic typography
- Countdown timers

---

# FFmpeg Karaoke & Animated Text (2025)

Complete guide to karaoke subtitles, kinetic typography, scrolling credits, and advanced text animation with FFmpeg.

## Karaoke Subtitles (ASS/SSA Format)

### ASS Karaoke Basics

ASS (Advanced SubStation Alpha) supports karaoke timing with `\k` tags.

```ass
[Script Info]
Title: Karaoke Example
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Karaoke,Arial,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,3,2,2,10,10,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50}Twinkle {\k50}twinkle {\k50}little {\k50}star
Dialogue: 0,0:00:05.00,0:00:09.00,Karaoke,,0,0,0,,{\k50}How {\k50}I {\k50}wonder {\k50}what {\k50}you {\k50}are
```

### Karaoke Timing Tags

| Tag | Effect | Example |
|-----|--------|---------|
| `\k` | Fill from left | `{\k100}Word` = 1 second fill |
| `\kf` or `\K` | Smooth fill (fade) | `{\kf100}Word` |
| `\ko` | Outline highlight | `{\ko100}Word` |

Duration is in centiseconds (100 = 1 second).

### Apply Karaoke ASS to Video

```bash
# Burn karaoke subtitles into video
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass" \
  -c:v libx264 -crf 18 -c:a copy \
  output_karaoke.mp4

# With specific fonts directory
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass:fontsdir=/path/to/fonts" \
  output.mp4
```

### Advanced ASS Karaoke Styles

```ass
[V4+ Styles]
; Gradient karaoke (yellow to red)
Style: KaraokeGradient,Impact,80,&H0000FFFF,&H000000FF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,60,1

; Glow effect karaoke
Style: KaraokeGlow,Arial Black,72,&H00FFFFFF,&H00FF00FF,&H00FF00FF,&H00000000,1,0,0,0,100,100,0,0,4,0,20,2,10,10,50,1

; Outline only (neon style)
Style: KaraokeNeon,Arial,80,&H00000000,&H0000FF00,&H0000FF00,&H00000000,1,0,0,0,100,100,0,0,3,4,0,2,10,10,50,1

[Events]
; Word-by-word with effects
Dialogue: 0,0:00:01.00,0:00:05.00,KaraokeGradient,,0,0,0,,{\k50\fad(200,0)}Never {\k50}gonna {\k50}give {\k50}you {\k50}up
; With positioning
Dialogue: 0,0:00:05.00,0:00:09.00,KaraokeGlow,,0,0,0,,{\pos(960,900)\k50}Never {\k50}gonna {\k50}let {\k50}you {\k50}down
```

### ASS Color Format

ASS uses `&HAABBGGRR` format (Alpha, Blue, Green, Red):
- `&H00FFFFFF` = White (fully opaque)
- `&H000000FF` = Red
- `&H0000FF00` = Green
- `&H00FF0000` = Blue
- `&H80000000` = 50% transparent black

### Karaoke with Animation Effects

```ass
[Events]
; Bounce effect per word
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50\t(0,500,\fry360)}Word1 {\k50\t(0,500,\fry360)}Word2

; Scale pop on highlight
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50\t(0,100,\fscx120\fscy120)\t(100,200,\fscx100\fscy100)}Pop

; Color transition
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k100\t(0,1000,\c&H0000FF&)}Red {\k100\t(0,1000,\c&H00FF00&)}Green
```

### ASS Animation Tags Reference

| Tag | Effect |
|-----|--------|
| `\t(t1,t2,tags)` | Animate tags from t1 to t2 |
| `\move(x1,y1,x2,y2)` | Move text from point to point |
| `\fad(fadein,fadeout)` | Fade in/out (milliseconds) |
| `\fscx`, `\fscy` | Scale X/Y percentage |
| `\frx`, `\fry`, `\frz` | Rotate on axis |
| `\pos(x,y)` | Position text |
| `\an1-9` | Alignment (numpad positions) |

## Scrolling Credits

### Vertical Scroll (Bottom to Top)

```bash
# Basic scrolling credits
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=credits.txt:\
       fontfile=/path/to/font.ttf:\
       fontsize=48:\
       fontcolor=white:\
       x=(w-tw)/2:\
       y=h-80*t" \
  -c:v libx264 -crf 18 output.mp4

# y=h-80*t: Start at bottom (h), move up at 80 pixels/second
```

### credits.txt Format

```
DIRECTED BY
John Smith

PRODUCED BY
Jane Doe

STARRING
Actor One
Actor Two
Actor Three

MUSIC BY
Composer Name

SPECIAL THANKS
Everyone
```

### Scrolling Credits with Sections

```bash
# Multi-speed credits (slower for names)
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=credits.txt:\
       fontsize=48:\
       fontcolor=white:\
       x=(w-tw)/2:\
       y='h-60*t':\
       line_spacing=20" \
  output.mp4
```

### Horizontal Scrolling (News Ticker)

```bash
# Right to left scroll
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BREAKING NEWS... This is a scrolling ticker message':\
       fontsize=36:\
       fontcolor=white:\
       y=h-50:\
       x='w-mod(t*150,w+tw)'" \
  ticker.mp4

# x='w-mod(t*150,w+tw)': Continuous scroll at 150 pixels/second
```

### Looping Horizontal Scroll

```bash
# Seamless looping ticker
ffmpeg -i input.mp4 \
  -vf "drawtext=text='   LIVE NEWS     BREAKING STORY     UPDATES   ':\
       fontsize=40:\
       fontcolor=yellow:\
       y=h-60:\
       x='w-mod(t*200\\,w+tw)':\
       box=1:boxcolor=red@0.8:boxborderw=10" \
  news_ticker.mp4
```

## Typewriter Effect

### Character-by-Character Reveal

```bash
# Typewriter effect using enable
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" \
  -vf "\
    drawtext=text='H':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.0)',\
    drawtext=text='e':x=150:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.1)',\
    drawtext=text='l':x=200:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.2)',\
    drawtext=text='l':x=250:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.3)',\
    drawtext=text='o':x=300:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.4)'" \
  typewriter.mp4
```

### Typewriter with Cursor

```bash
# Blinking cursor during typing
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=5" \
  -vf "\
    drawtext=text='Hello':fontsize=72:fontcolor=white:x=100:y=500:\
             enable='gte(t,0)':alpha='min(1,(t-0)/0.5)',\
    drawtext=text='|':fontsize=72:fontcolor=white:\
             x='100+72*min(5,floor(t/0.1))':y=500:\
             alpha='lt(mod(t,0.5),0.25)'" \
  typewriter_cursor.mp4
```

## Text Fade Effects

### Fade In

```bash
# Simple fade in
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Title':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(lt(t,2),t/2,1)'" \
  fade_in.mp4

# Explanation: alpha goes from 0 to 1 over 2 seconds
```

### Fade Out

```bash
# Fade out (assuming 10 second video)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Goodbye':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(gt(t,8),1-(t-8)/2,1)'" \
  fade_out.mp4
```

### Fade In and Out

```bash
# Title card with fade in/out
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=6" \
  -vf "drawtext=text='Chapter One':fontsize=120:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(lt(t,1),t,if(gt(t,5),1-(t-5),1))'" \
  title_card.mp4
```

## Moving Text

### Bouncing Text

```bash
# Vertical bounce
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=yellow:\
       x=(w-tw)/2:\
       y='(h-th)/2+50*sin(t*5)'" \
  bounce.mp4

# Horizontal bounce
ffmpeg -i input.mp4 \
  -vf "drawtext=text='PING PONG':fontsize=60:fontcolor=cyan:\
       x='(w-tw)/2+200*sin(t*3)':\
       y=(h-th)/2" \
  horizontal_bounce.mp4
```

### Circular Motion

```bash
# Text moving in circle
ffmpeg -i input.mp4 \
  -vf "drawtext=text='ORBIT':fontsize=60:fontcolor=white:\
       x='(w/2)+200*cos(t*2)-tw/2':\
       y='(h/2)+200*sin(t*2)-th/2'" \
  orbit.mp4
```

### Enter from Side

```bash
# Slide in from right
ffmpeg -i input.mp4 \
  -vf "drawtext=text='SLIDE IN':fontsize=80:fontcolor=white:\
       x='if(lt(t,1),w-tw*(t),w-tw)':\
       y=(h-th)/2" \
  slide_in.mp4

# Slide in from left
ffmpeg -i input.mp4 \
  -vf "drawtext=text='FROM LEFT':fontsize=80:fontcolor=white:\
       x='if(lt(t,1),-tw+tw*t,0)':\
       y=(h-th)/2" \
  slide_left.mp4
```

## Kinetic Typography

### Word Pop Effect

```bash
# Words appearing with scale
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=8" \
  -vf "\
    drawtext=text='THIS':fontsize='72*(1+0.3*exp(-3*(t-1)))':fontcolor=white:\
             x=(w-tw)/2:y=h/2-100:enable='gte(t,1)',\
    drawtext=text='IS':fontsize='72*(1+0.3*exp(-3*(t-2)))':fontcolor=white:\
             x=(w-tw)/2:y=h/2:enable='gte(t,2)',\
    drawtext=text='KINETIC':fontsize='72*(1+0.3*exp(-3*(t-3)))':fontcolor=red:\
             x=(w-tw)/2:y=h/2+100:enable='gte(t,3)'" \
  kinetic_pop.mp4
```

### Shake Effect

```bash
# Shaking text (impact effect)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='IMPACT':fontsize=120:fontcolor=white:\
       x='(w-tw)/2+10*sin(t*50)*exp(-t*2)':\
       y='(h-th)/2+10*cos(t*50)*exp(-t*2)'" \
  shake.mp4
```

### Rotation Animation

```bash
# Spinning text (requires recent FFmpeg)
# Note: drawtext doesn't support rotation natively
# Use ASS subtitles for rotation:

# Create spinning.ass
cat << 'EOF' > spinning.ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Style: Spin,Arial,72,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,0,5,0,0,0,1

[Events]
Dialogue: 0,0:00:00.00,0:00:05.00,Spin,,0,0,0,,{\an5\pos(960,540)\t(0,5000,\frz1080)}SPINNING
EOF

ffmpeg -i input.mp4 -vf "ass=spinning.ass" output.mp4
```

## Lower Thirds

### Basic Lower Third

```bash
# Name and title lower third
ffmpeg -i input.mp4 \
  -vf "\
    drawbox=x=50:y=h-150:w=500:h=100:c=blue@0.7:t=fill,\
    drawtext=text='John Smith':fontsize=36:fontcolor=white:\
             x=70:y=h-140,\
    drawtext=text='CEO, Company Inc.':fontsize=24:fontcolor=white@0.8:\
             x=70:y=h-100" \
  lower_third.mp4
```

### Animated Lower Third

```bash
# Slide-in lower third
ffmpeg -i input.mp4 \
  -vf "\
    drawbox=x='if(lt(t,0.5),-500+1000*t,50)':\
            y=h-150:w=500:h=100:c=blue@0.7:t=fill:\
            enable='between(t,0,8)',\
    drawtext=text='John Smith':fontsize=36:fontcolor=white:\
             x='if(lt(t,0.5),-430+1000*t,70)':y=h-140:\
             alpha='min(1,(t-0.3)/0.3)':\
             enable='between(t,0.3,8)',\
    drawtext=text='CEO, Company Inc.':fontsize=24:fontcolor=white:\
             x='if(lt(t,0.5),-430+1000*t,70)':y=h-100:\
             alpha='min(1,(t-0.5)/0.3)':\
             enable='between(t,0.5,8)'" \
  animated_lower_third.mp4
```

## Countdown Timer

### Simple Countdown

```bash
# 10 second countdown
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" \
  -vf "drawtext=text='%{eif\\:10-t\\:d}':fontsize=200:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2" \
  countdown.mp4
```

### Countdown with Animation

```bash
# Pulsing countdown
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" \
  -vf "drawtext=text='%{eif\\:10-t\\:d}':\
       fontsize='200+30*sin(t*10)*exp(-mod(t,1)*3)':\
       fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2" \
  pulsing_countdown.mp4
```

### Stopwatch/Timer

```bash
# Count up timer (MM:SS)
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=120" \
  -vf "drawtext=text='%{eif\\:floor(t/60)\\:d\\:2}\\:%{eif\\:mod(t,60)\\:d\\:2}':\
       fontsize=100:fontcolor=green:\
       x=(w-tw)/2:y=(h-th)/2" \
  stopwatch.mp4
```

## Dynamic Text from Variables

### Frame Number Display

```bash
# Show frame number
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Frame\\: %{frame_num}':\
       fontsize=24:fontcolor=white:\
       x=10:y=10" \
  frame_numbers.mp4
```

### Timecode Display

```bash
# Show timecode
ffmpeg -i input.mp4 \
  -vf "drawtext=text='%{pts\\:hms}':\
       fontsize=24:fontcolor=white:\
       x=10:y=10" \
  timecode.mp4

# With milliseconds
ffmpeg -i input.mp4 \
  -vf "drawtext=text='%{pts}':\
       fontsize=24:fontcolor=white:\
       x=10:y=10" \
  timecode_ms.mp4
```

### File Metadata Display

```bash
# Show filename
ffmpeg -i input.mp4 \
  -vf "drawtext=text='%{metadata\\:title}':\
       fontsize=24:fontcolor=white:\
       x=10:y=h-40" \
  metadata.mp4
```

## Multi-Line Text

### Centered Multi-Line

```bash
# Multi-line centered text
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Line One\nLine Two\nLine Three':\
       fontsize=48:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       line_spacing=20" \
  multiline.mp4
```

### Text File Input

```bash
# Use text file for long text
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=message.txt:\
       fontsize=36:fontcolor=white:\
       x=50:y=50:\
       line_spacing=10" \
  from_file.mp4
```

## Expression Reference

### Useful Time Expressions

| Expression | Result |
|------------|--------|
| `t` | Current time in seconds |
| `t*100` | Speed factor |
| `mod(t,5)` | Loop every 5 seconds |
| `sin(t*3)` | Oscillate 3 times/second |
| `exp(-t)` | Exponential decay |
| `if(lt(t,2),expr1,expr2)` | Conditional |
| `min(a,b)` / `max(a,b)` | Min/max |
| `floor(t)` / `ceil(t)` | Round down/up |

### Useful Variables

| Variable | Meaning |
|----------|---------|
| `w` | Video width |
| `h` | Video height |
| `tw` | Text width |
| `th` | Text height |
| `n` | Frame number |
| `frame_num` | Same as n |

### Common Patterns

```bash
# Appear after 2 seconds
enable='gte(t,2)'

# Visible between 2-5 seconds
enable='between(t,2,5)'

# Fade in over 1 second
alpha='min(1,t)'

# Center horizontally
x='(w-tw)/2'

# Center vertically
y='(h-th)/2'

# Loop position
x='mod(t*100,w)'

# Smooth oscillation
y='h/2+50*sin(t*3)'

# Decay animation
fontsize='100+50*exp(-t*2)'
```

This guide covers FFmpeg karaoke and animated text. For basic subtitles see `ffmpeg-captions-subtitles`, for shapes see `ffmpeg-shapes-graphics`.
