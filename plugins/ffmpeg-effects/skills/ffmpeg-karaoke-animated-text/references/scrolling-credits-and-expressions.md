# Scrolling Credits and Drawtext Expressions

Recipes for vertical credits, horizontal tickers, genre/content timing, and `drawtext` expression reference.

## Optimal Animation Timing by Content Type

### Music Video Karaoke

| Genre | Syllable Timing | Animation Style | Color Scheme |
|-------|----------------|-----------------|--------------|
| **Ballad** | 100-200 centiseconds | `\kf` smooth fill | White → Soft Blue |
| **Pop** | 40-80 centiseconds | `\kf` with bounce | White → Bright Pink |
| **Rap** | 15-40 centiseconds | `\k` instant | White → Red |
| **Rock** | 50-100 centiseconds | `\k` with shake | White → Orange |
| **EDM** | 30-60 centiseconds | `\ko` outline | Neon colors |

### Educational Content

```bash
# Slow, clear typewriter for learning
# 80ms per character = comfortable reading pace
-vf "drawtext=textfile=lesson.txt:\
     fontsize=48:fontcolor=white:\
     x=50:y=100:\
     enable='gte(n,eif(n/24,80))'"
# Each character appears every 80/24 ≈ 3.3 frames at 24fps
```

### Scrolling Credits Optimization

```bash
# Professional credits scroll
# Speed: 60-80 pixels/second for comfortable reading
-vf "drawtext=textfile=credits.txt:\
     fontsize=42:fontcolor=white:\
     x=(w-tw)/2:\
     y='h-60*t':\
     line_spacing=25"

# Calculation:
# 60 px/s at 42px font = ~1.4 lines/second
# For 50 lines: 50/1.4 = ~36 seconds total duration
```

Credits readability formula:

```text
scroll_speed = font_size * 1.2 to 1.5  (pixels/second)
total_duration = (line_count * line_height) / scroll_speed

Example:
font_size = 42px
line_height = 42 + 25 (spacing) = 67px
scroll_speed = 42 * 1.4 = 59 px/s
50 lines = 50 * 67 = 3350 pixels
duration = 3350 / 59 = 56.8 seconds
```

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

```text
DIRECTED BY
Name

PRODUCED BY
Name

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

## Horizontal Scrolling (News Ticker)

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
       x='w-mod(t*200\,w+tw)':\
       box=1:boxcolor=red@0.8:boxborderw=10" \
  news_ticker.mp4
```

## Rotation Animation via ASS

`drawtext` doesn't support rotation natively. Use ASS subtitles for rotation:

```bash
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

## Sources

Enhanced with research from:

- [FFmpeg Drawtext Animation Exploration](https://www.braydenblackwell.com/blog/ffmpeg-text-rendering)
- [ASS Karaoke Tags Documentation](https://docs.karaokes.moe/contrib-guide/create-karaoke/karaoke/)
- [Advanced Aegisub Karaoke](https://docs.karaokes.moe/contrib-guide/create-karaoke/karaoke-advanced/)
- [Spring Physics for Animations](https://www.kvin.me/posts/effortless-ui-spring-animations)
- [Easing Functions Mathematical Reference](https://easings.net/)
- [FFmpeg Expression Evaluation](https://ffmpeg.org/ffmpeg-utils.html#Expression-Evaluation)
