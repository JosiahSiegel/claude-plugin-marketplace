# Drawtext Animation Recipes

Advanced FFmpeg `drawtext` formulas and complete commands for animated text, kinetic typography, timers, and dynamic overlays.

## Spring Physics Implementation

Create natural bounce effects with exponential decay:

```bash
# Vertical spring bounce (decaying oscillation)
# Formula: y_offset = amplitude * e^(-decay*t) * sin(frequency*t)
-vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=white:\
     x=(w-tw)/2:\
     y='(h-th)/2-30*exp(-t*2.5)*sin(t*15)'"

# Breakdown:
# -30*exp(-t*2.5) = amplitude decays from 30px to 0
# sin(t*15) = oscillates at 15 rad/s (≈2.4 Hz)
# Combines: bounces 2-3 times over ~1 second, settling at center
```

Parameter tuning:

- Decay rate (2.5): Higher = faster settling (3-4 for quick, 1-2 for slow)
- Frequency (15): Higher = more bounces (10-12 slow, 15-20 fast)
- Amplitude (30): Bounce height in pixels

## Elastic Overshoot Effect

```bash
# Elastic scale effect (rubber band)
# Overshoots target size multiple times before settling
-vf "drawtext=text='ELASTIC':fontsize='72*(1+0.4*exp(-t*3)*sin(t*20))':\
     fontcolor=yellow:x=(w-tw)/2:y=(h-th)/2"

# Scale oscillates: 72px → 101px → 65px → 80px → 70px → 72px (settled)
# Mathematical basis: e^(-3t) * sin(20t) creates damped oscillation
```

Elastic parameters:

- Base fontsize: 72 (target)
- Overshoot: 0.4 (40% maximum deviation) → 72 * 1.4 = 101px peak
- Decay: 3 (settles in ~1.5 seconds)
- Frequency: 20 (multiple small bounces)

## Bezier Curve Approximation (Ease-In-Out)

FFmpeg doesn't support bezier directly, but we can approximate with piecewise functions:

```bash
# Ease-out approximation (fast start, slow end)
# Cubic bezier (0, 0, 0.2, 1) approximation
-vf "drawtext=text='EASE OUT':\
     alpha='if(lt(t,0.5),1-exp(-t*6),1)':\
     fontsize=80:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     enable='lt(t,1)'"

# Ease-in approximation (slow start, fast end)
# Cubic bezier (0.8, 0, 1, 1) approximation
-vf "drawtext=text='EASE IN':\
     alpha='if(lt(t,0.5),exp(-(1-t)*6),0)':\
     fontsize=80:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     enable='between(t,1,2)'"

# Ease-in-out (S-curve) using sigmoid approximation
-vf "drawtext=text='SMOOTH':\
     alpha='1/(1+exp(-10*(t-0.5)))':\
     fontsize=80:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     enable='lt(t,1)'"
```

Mathematical reasoning:

- Exponential ease: `1 - e^(-kt)` creates natural deceleration
- Sigmoid curve: `1/(1+e^(-k(t-0.5)))` creates smooth S-curve (ease-in-out)
- k parameter: Controls transition sharpness (6-10 for subtle, 15-20 for pronounced)

## Wobble/Wiggle Effects

Create organic, unpredictable motion:

```bash
# Dual-frequency wobble (complex motion)
# Combines two sine waves at different frequencies for organic feel
-vf "drawtext=text='WOBBLE':fontsize=80:fontcolor=white:\
     x='(w-tw)/2+8*sin(t*7)+4*sin(t*17)':\
     y='(h-th)/2+6*cos(t*7)+3*cos(t*13)'"

# Breakdown:
# Primary wobble: 8*sin(t*7) = 8px amplitude, 7 rad/s (1.1 Hz)
# Secondary wobble: 4*sin(t*17) = 4px amplitude, 17 rad/s (2.7 Hz)
# Result: Complex, organic motion pattern

# Drunk/unstable effect (low frequency, large amplitude)
-vf "drawtext=text='UNSTABLE':fontsize=80:fontcolor=white:\
     x='(w-tw)/2+20*sin(t*2.5)+10*sin(t*6.3)':\
     y='(h-th)/2+15*cos(t*3.1)+8*cos(t*7.2)'"
```

Wobble design principles:

- Use two frequencies (primary + secondary) for natural randomness
- Prime number ratios (e.g., 7 and 17) prevent pattern repetition
- Amplitude ratio 2:1 (primary twice the secondary) for balanced motion

## Pulse with Variable Intensity

Create heartbeat or alarm-style pulsing:

```bash
# Heartbeat pulse (two quick beats, pause)
# Pattern: THUMP-thump ... pause ... THUMP-thump
-vf "drawtext=text='♥ HEARTBEAT ♥':\
     fontsize='80+25*max(0,sin(t*15)*exp(-mod(t,1.2)*10))':\
     fontcolor=red:x=(w-tw)/2:y=(h-th)/2"

# Breakdown:
# sin(t*15) = rapid oscillation
# exp(-mod(t,1.2)*10) = decay envelope every 1.2 seconds
# max(0, ...) = only positive pulses
# Result: Pulse decays quickly, resets every 1.2s

# Alarm pulse (constant urgent rhythm)
-vf "drawtext=text='ALERT':\
     fontsize='80+20*abs(sin(t*8))':\
     fontcolor=yellow:x=(w-tw)/2:y=(h-th)/2"

# abs(sin(t*8)) creates continuous pulsing at 8 rad/s (1.3 Hz)
```

## Text Reveal Animations (Wipe Effects)

### Horizontal Wipe (Left to Right)

```bash
# Clip text progressively from left
# Uses drawbox mask to reveal text over time
-filter_complex "\
  [0:v]drawtext=text='REVEALED':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2[txt];\
  [txt]drawbox=x=0:y=0:w='min(w,t*500)':h=h:c=black@0:t=fill:replace=1[v]" \
  -map "[v]"

# Breakdown:
# w='min(w,t*500)' = width grows at 500 pixels/second
# Creates left-to-right reveal effect
```

### Vertical Wipe (Bottom to Top)

```bash
# Text rises from bottom
-vf "drawtext=text='RISING':fontsize=100:fontcolor=white:\
     x=(w-tw)/2:\
     y='if(lt(t,1),h-t*h,0)'"

# y position: starts at h (bottom), moves to 0 (top) over 1 second
```

## Countdown Timer Variations

### Animated Countdown with Anticipation

```bash
# Countdown that pulses on each second change
-vf "drawtext=text='%{eif\:10-floor(t)\:d}':\
     fontsize='200+50*abs(sin(floor(t)*50))*exp(-(t-floor(t))*8)':\
     fontcolor=white:x=(w-tw)/2:y=(h-th)/2"

# Breakdown:
# %{eif\:10-floor(t)\:d} = countdown number (10, 9, 8, ...)
# abs(sin(floor(t)*50)) = trigger pulse on integer seconds
# exp(-(t-floor(t))*8) = decay within each second
# Result: Number "pops" at each second change
```

### Split-Flap Display (Mechanical)

```bash
# Simulates old-school flip counter with vertical offset
-vf "drawtext=text='%{eif\:10-floor(t)\:d}':\
     fontsize=200:fontcolor=white:\
     x=(w-tw)/2:\
     y='(h-th)/2-(t-floor(t))*100*step(t-floor(t))'"

# y offset creates "flipping" motion at second boundaries
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

```bash
# Simple fade in
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Title':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(lt(t,2),t/2,1)'" \
  fade_in.mp4

# Fade out (assuming 10 second video)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Goodbye':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(gt(t,8),1-(t-8)/2,1)'" \
  fade_out.mp4

# Title card with fade in/out
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=6" \
  -vf "drawtext=text='Chapter One':fontsize=120:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(lt(t,1),t,if(gt(t,5),1-(t-5),1))'" \
  title_card.mp4
```

## Moving Text

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

# Text moving in circle
ffmpeg -i input.mp4 \
  -vf "drawtext=text='ORBIT':fontsize=60:fontcolor=white:\
       x='(w/2)+200*cos(t*2)-tw/2':\
       y='(h/2)+200*sin(t*2)-th/2'" \
  orbit.mp4

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

# Shaking text (impact effect)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='IMPACT':fontsize=120:fontcolor=white:\
       x='(w-tw)/2+10*sin(t*50)*exp(-t*2)':\
       y='(h-th)/2+10*cos(t*50)*exp(-t*2)'" \
  shake.mp4
```

## Lower Thirds

```bash
# Name and title lower third
ffmpeg -i input.mp4 \
  -vf "\
    drawbox=x=50:y=h-150:w=500:h=100:c=blue@0.7:t=fill,\
    drawtext=text='Name':fontsize=36:fontcolor=white:\
             x=70:y=h-140,\
    drawtext=text='Title':fontsize=24:fontcolor=white@0.8:\
             x=70:y=h-100" \
  lower_third.mp4

# Slide-in lower third
ffmpeg -i input.mp4 \
  -vf "\
    drawbox=x='if(lt(t,0.5),-500+1000*t,50)':\
            y=h-150:w=500:h=100:c=blue@0.7:t=fill:\
            enable='between(t,0,8)',\
    drawtext=text='Name':fontsize=36:fontcolor=white:\
             x='if(lt(t,0.5),-430+1000*t,70)':y=h-140:\
             alpha='min(1,(t-0.3)/0.3)':\
             enable='between(t,0.3,8)',\
    drawtext=text='Title':fontsize=24:fontcolor=white:\
             x='if(lt(t,0.5),-430+1000*t,70)':y=h-100:\
             alpha='min(1,(t-0.5)/0.3)':\
             enable='between(t,0.5,8)'" \
  animated_lower_third.mp4
```

## Countdown, Stopwatch, and Dynamic Text

```bash
# 10 second countdown
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" \
  -vf "drawtext=text='%{eif\:10-t\:d}':fontsize=200:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2" \
  countdown.mp4

# Pulsing countdown
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" \
  -vf "drawtext=text='%{eif\:10-t\:d}':\
       fontsize='200+30*sin(t*10)*exp(-mod(t,1)*3)':\
       fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2" \
  pulsing_countdown.mp4

# Count up timer (MM:SS)
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=120" \
  -vf "drawtext=text='%{eif\:floor(t/60)\:d\:2}\:%{eif\:mod(t,60)\:d\:2}':\
       fontsize=100:fontcolor=green:\
       x=(w-tw)/2:y=(h-th)/2" \
  stopwatch.mp4

# Show frame number
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Frame\: %{frame_num}':\
       fontsize=24:fontcolor=white:\
       x=10:y=10" \
  frame_numbers.mp4

# Show timecode
ffmpeg -i input.mp4 \
  -vf "drawtext=text='%{pts\:hms}':\
       fontsize=24:fontcolor=white:\
       x=10:y=10" \
  timecode.mp4

# With milliseconds
ffmpeg -i input.mp4 \
  -vf "drawtext=text='%{pts}':\
       fontsize=24:fontcolor=white:\
       x=10:y=10" \
  timecode_ms.mp4

# Show title metadata
ffmpeg -i input.mp4 \
  -vf "drawtext=text='%{metadata\:title}':\
       fontsize=24:fontcolor=white:\
       x=10:y=h-40" \
  metadata.mp4
```

## Multi-Line Text

```bash
# Multi-line centered text
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Line One
Line Two
Line Three':\
       fontsize=48:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       line_spacing=20" \
  multiline.mp4

# Use text file for long text
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=message.txt:\
       fontsize=36:fontcolor=white:\
       x=50:y=50:\
       line_spacing=10" \
  from_file.mp4
```
