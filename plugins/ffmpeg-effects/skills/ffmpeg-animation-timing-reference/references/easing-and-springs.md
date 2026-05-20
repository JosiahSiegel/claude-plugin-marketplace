# Easing Functions, Spring Physics, and Natural Motion

Mathematical reference for animation easing, spring systems, oscillation, and natural motion in FFmpeg.

## Material Design Timing Standards

| Animation Type | Duration | Easing | Use Case |
|----------------|----------|--------|----------|
| Small (icon, button) | 100ms | ease-out | Micro-interactions |
| Medium (card, dialog) | 200-300ms | ease-in-out | Standard UI |
| Large (page, panel) | 300-500ms | ease-out | Major transitions |
| Complex (multi-element) | 400-700ms | ease-in-out | Choreographed |

## FFmpeg Easing Expressions

### Ease Out (Deceleration) - Elements Entering

```bash
# Ease out: fast start, slow finish
# Good for: Elements appearing, sliding in
-vf "drawtext=text='Hello':alpha='1-exp(-t*5)':fontsize=48:fontcolor=white:x=(w-tw)/2:y=(h-th)/2"
```

### Ease In (Acceleration) - Elements Leaving

```bash
# Ease in: slow start, fast finish
# Good for: Elements disappearing, sliding out
-vf "drawtext=text='Goodbye':alpha='exp(-(5-t)*5)':fontsize=48:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:enable='lt(t,5)'"
```

### Bounce Effect

```bash
# Bounce: overshoot then settle
# Duration: 400-600ms recommended
-vf "drawtext=text='Bounce':y='h/2-50+50*exp(-t*3)*sin(t*15)':fontsize=48:fontcolor=white:x=(w-tw)/2"
```

### Elastic Effect

```bash
# Elastic: spring-like oscillation
# Duration: 600-1000ms recommended
-vf "drawtext=text='Elastic':fontsize='48*(1+0.3*exp(-t*2)*sin(t*10))':fontcolor=white:x=(w-tw)/2:y=(h-th)/2"
```

### Smooth Oscillation (Continuous)

```bash
# Pulse/float effect
# Period: 2-4 seconds per cycle
-vf "drawtext=text='Float':y='h/2+20*sin(t*2)':fontsize=48:fontcolor=white:x=(w-tw)/2"
```

## Recommended Easing by Context

| Context | Function | Duration |
|---------|----------|----------|
| Element appearing | `1-exp(-t*5)` | 200-400ms |
| Element disappearing | `exp(-t*5)` | 150-300ms |
| Emphasis/attention | `1+0.2*sin(t*6)` | Continuous |
| Bounce entrance | `exp(-t*3)*sin(t*15)` | 400-600ms |
| Smooth transition | Linear (no easing) | Any |

## Complete Easing Function Formulas

Based on standard animation libraries (CSS, anime.js, React Spring) and adapted for FFmpeg.

### Linear (No Easing)

```text
f(t) = t
```

**FFmpeg:** `alpha='t'` or `x='t*100'`

Use for: Constant speed motion, mechanical effects.

### Quadratic Easing

Ease In (Acceleration):

```text
f(t) = t^2
```

**FFmpeg:** `alpha='t*t'`

Ease Out (Deceleration):

```text
f(t) = 1 - (1-t)^2
```

**FFmpeg:** `alpha='1-(1-t)*(1-t)'`

Ease In-Out:

```text
f(t) = if(t < 0.5, 2*t^2, 1 - 2*(1-t)^2)
```

**FFmpeg:** `alpha='if(lt(t,0.5),2*t*t,1-2*(1-t)*(1-t))'`

### Cubic Easing

Ease In:

```text
f(t) = t^3
```

**FFmpeg:** `alpha='t*t*t'`

Ease Out:

```text
f(t) = 1 - (1-t)^3
```

**FFmpeg:** `alpha='1-(1-t)*(1-t)*(1-t)'`

Ease In-Out (Material Design Default):

```text
f(t) = if(t < 0.5, 4*t^3, 1 - 4*(1-t)^3)
```

**FFmpeg:** `alpha='if(lt(t,0.5),4*t*t*t,1-4*(1-t)*(1-t)*(1-t))'`

### Exponential Easing

Ease In:

```text
f(t) = 2^(10*(t-1))
```

**FFmpeg:** `alpha='exp(10*(t-1)*0.693)'` (note: `2^x = e^(x*ln(2))`, `ln(2) ~= 0.693`)

Ease Out (Recommended for text appearing):

```text
f(t) = 1 - 2^(-10*t)
```

**FFmpeg:** `alpha='1-exp(-10*t*0.693)'`

### Sine Easing (Smooth, Gentle)

Ease In:

```text
f(t) = 1 - cos(t*pi/2)
```

**FFmpeg:** `alpha='1-cos(t*1.571)'` (`pi/2 ~= 1.571`)

Ease Out:

```text
f(t) = sin(t*pi/2)
```

**FFmpeg:** `alpha='sin(t*1.571)'`

Ease In-Out:

```text
f(t) = -(cos(pi*t) - 1)/2
```

**FFmpeg:** `alpha='-(cos(3.1416*t)-1)/2'`

### Circular Easing (Sharp Curve)

Ease In:

```text
f(t) = 1 - sqrt(1 - t^2)
```

**FFmpeg:** `alpha='1-sqrt(1-t*t)'`

Ease Out:

```text
f(t) = sqrt(1 - (1-t)^2)
```

**FFmpeg:** `alpha='sqrt(1-(1-t)*(1-t))'`

### Elastic Easing (Overshoot with Oscillation)

Ease Out (most common):

```text
f(t) = 2^(-10*t) * sin((t*10 - 0.75)*2pi/3) + 1
```

**FFmpeg approximation:**

```bash
alpha='exp(-10*t*0.693)*sin((t*10-0.75)*2.094)+1'
```

(`2pi/3 ~= 2.094`)

Ease In:

```text
f(t) = -2^(10*(t-1)) * sin((t*10 - 10.75)*2pi/3)
```

**FFmpeg:**

```bash
alpha='-exp(10*(t-1)*0.693)*sin((t*10-10.75)*2.094)'
```

### Bounce Easing

Single bounce approximation:

```bash
alpha='if(lt(t,0.4),
         7.5625*t*t,
         if(lt(t,0.8),
            7.5625*(t-0.6)*(t-0.6)+0.75,
            7.5625*(t-0.9)*(t-0.9)+0.9375))'
```

Simplified damped oscillation bounce:

```bash
alpha='1-abs(cos(t*4.5*3.1416))*exp(-t*6)'
```

### Back Easing (Overshoot)

Ease Out (slight overshoot then settle):

```text
f(t) = 1 + c3 * (t-1)^3 + c1 * (t-1)^2
where c1 = 1.70158, c3 = c1 + 1
```

Simplified FFmpeg overshoot (10% beyond target):

```bash
alpha='if(lt(t,0.7),t*1.3,1+(1-t)*0.3)'
```

## Spring Physics

### Standard Mass-Spring-Damper

Differential equation:

```text
m * x''(t) + c * x'(t) + k * x(t) = 0

m = mass
c = damping coefficient
k = spring stiffness
x(t) = position at time t
```

Natural frequency: `omega_n = sqrt(k/m)`.
Damping ratio: `zeta = c / (2 * sqrt(k * m))`.

### Damping Cases

Under-damped (0 < zeta < 1) - bouncy, overshoots:

```text
x(t) = e^(-zeta*omega_n*t) * [A*cos(omega_d*t) + B*sin(omega_d*t)]
omega_d = omega_n * sqrt(1 - zeta^2)
```

Critically damped (zeta = 1) - no overshoot, fastest settle:

```text
x(t) = (A + B*t) * e^(-omega_n*t)
```

Over-damped (zeta > 1) - slow, sluggish:

```text
x(t) = A*e^(r1*t) + B*e^(r2*t)
```

### Simplified Spring for UI

```python
# Two-parameter approach (bounce + duration)
mass = 1
stiffness = (2*pi / duration)**2

if bounce >= 0:
    damping = (1 - bounce) * 4*pi / duration
else:
    damping = 4*pi / (duration * (1 + bounce))
```

Bounce mapping:

- `bounce = 0`: critically damped (no overshoot)
- `0 < bounce < 1`: under-damped (1 = undamped oscillation)
- `bounce < 0`: over-damped (negative = slower settling)

### FFmpeg Spring Implementation

Basic under-damped spring (stiffness=100, damping=10, mass=1):

```bash
# omega_n = sqrt(100/1) = 10
# zeta = 10 / (2*sqrt(100*1)) = 0.5 (under-damped)
# omega_d = 10 * sqrt(1 - 0.25) ~= 8.66

-vf "drawtext=text='SPRING':\
     y='(h-th)/2-50*exp(-5*t)*cos(8.66*t)':\
     fontsize=80:fontcolor=white:x=(w-tw)/2"
```

Tunable spring parameters:

```bash
# Low bounce (zeta=0.8, quick settle):
y='(h-th)/2+amplitude*exp(-8*t)*sin(10*t)'

# Medium bounce (zeta=0.5, balanced):
y='(h-th)/2+amplitude*exp(-5*t)*sin(12*t)'

# High bounce (zeta=0.3, very bouncy):
y='(h-th)/2+amplitude*exp(-3*t)*sin(14*t)'

# Critical damping (zeta=1, no overshoot):
y='(h-th)/2+amplitude*exp(-10*t)*(1+10*t)'
```

## Oscillation and Wave Formulas

### Basic Trig

Sine wave (smooth oscillation):

```text
y = A * sin(omega*t + phi)

A = amplitude
omega = angular frequency (rad/s)
t = time (s)
phi = phase offset (rad)
```

Frequency conversion: `omega = 2*pi*f`.

```text
1 Hz = 6.28 rad/s
2 Hz = 12.56 rad/s
3 Hz = 18.85 rad/s
```

FFmpeg examples:

```bash
# 2 Hz oscillation:
y='50*sin(12.56*t)'

# 1 Hz with phase offset (starts at peak):
y='50*sin(6.28*t+1.571)'

# Cosine (equivalent to sin(t + pi/2)):
y='50*cos(6.28*t)'
```

### Amplitude Modulation

```bash
# Exponential decay envelope:
y='50*exp(-2*t)*sin(10*t)'

# Linear decay:
y='50*max(0,1-t)*sin(10*t)'

# Low-frequency modulates high-frequency:
y='(30+20*sin(2*t))*sin(20*t)'
```

### Frequency Modulation

```bash
# Accelerating oscillation (siren):
y='50*sin(5*t*t)'

# Decelerating:
y='50*sin(20*t-5*t*t)'

# Vibrato:
y='50*sin(10*t+2*sin(3*t))'
```

### Lissajous (Parametric Motion)

```bash
# Circular orbit:
-vf "drawtext=text='o':\
     x='(w/2)+200*cos(2*t)':\
     y='(h/2)+200*sin(2*t)':\
     fontsize=40:fontcolor=white"

# Elliptical:
x='(w/2)+200*cos(2*t)'
y='(h/2)+100*sin(2*t)'

# Figure-8 (Lissajous 1:2):
x='(w/2)+150*sin(1*t)'
y='(h/2)+150*sin(2*t)'
```

## Pseudo-Random and Noise

```bash
# Pseudo-random using irrational sine frequency:
'10*sin(t*137.5)'

# Multi-layered:
'5*sin(t*137.5)+3*sin(t*241.3)+2*sin(t*89.7)'

# Smooth (Perlin-like):
noise = 'sin(t*2.3)+0.5*sin(t*5.1)+0.25*sin(t*11.7)'

# Normalized 0-1:
normalized = '(sin(t*2.3)+0.5*sin(t*5.1)+0.25*sin(t*11.7)+1.75)/3.5'
```

### Jitter / Shake

```bash
# Continuous shake:
x='(w-tw)/2+5*sin(t*50)'
y='(h-th)/2+5*cos(t*47)'

# Decaying shake (impact):
x='(w-tw)/2+10*exp(-t*3)*sin(t*50)'
y='(h-th)/2+10*exp(-t*3)*cos(t*47)'

# Triggered shake (between t=2 and 2.5):
x='(w-tw)/2+if(between(t,2,2.5),15*sin(t*60),0)'
```

## Practical Animation Cookbook

### Fade Transitions

```bash
# Linear fade in 0-0.5s:
alpha='min(1,t/0.5)'

# Ease-out fade in:
alpha='1-exp(-5*t)'

# Cubic fade in:
alpha='min(1,(t/0.5)*(t/0.5)*(t/0.5))'

# Fade out (last 2s of a 10s video):
alpha='if(gt(t,8),1-(t-8)/2,1)'

# Exponential fade out:
alpha='if(gt(t,8),exp(-(t-8)*3),1)'

# Fade in 0-1s, hold, fade out 9-10s:
alpha='if(lt(t,1),t,if(gt(t,9),10-t,1))'
```

### Scale Animations (ASS)

```ass
; Pop in:
{\fscx0\fscy0\t(0,300,\fscx100\fscy100)}Text

; Pulse with hold:
{\t(0,300,\fscx110\fscy110)\t(300,600,\fscx100\fscy100)}

; Overshoot bounce:
{\fscx50\fscy50\t(0,150,\fscx115\fscy115)\t(150,300,\fscx95\fscy95)\t(300,450,\fscx100\fscy100)}
```

### Position Animations

```bash
# Slide in from right (linear):
x='if(lt(t,1),w-((w-(w-tw)/2)*t),(w-tw)/2)'

# Slide in with ease-out:
x='if(lt(t,1),w-((w-(w-tw)/2)*(1-exp(-5*t))),(w-tw)/2)'

# Bounce in from bottom (ASS):
# {\move(540,1920,540,960,0,400)\t(0,150,\fscy115)\t(150,300,\fscy95)\t(300,400,\fscy100)}

# Circular path:
x='(w/2)+radius*cos(speed*t)'
y='(h/2)+radius*sin(speed*t)'
```

### Rotation (ASS only)

```ass
; Continuous spin (360 deg over 2s):
{\t(0,2000,\frz360)}Text

; Wobble:
{\t(0,200,\frz15)\t(200,400,\frz-10)\t(400,600,\frz5)\t(600,800,\frz0)}
```

## Timing Psychology and Perception

### Human Perception Thresholds

| Threshold | Duration | Perception | Use Case |
|-----------|----------|------------|----------|
| Flicker fusion | 16-20ms | Below: perceived as continuous | 60fps = 16.67ms/frame |
| Preattentive | 20-50ms | Detected but not consciously processed | Subliminal cues |
| Attention capture | 50-100ms | Minimum for conscious recognition | Flash effects |
| Pattern interrupt | 100-200ms | Breaks expectation, grabs attention | Hook effects |
| Comfortable transition | 200-400ms | Natural UI timing | Standard animations |
| Deliberate motion | 400-800ms | Noticeable, purposeful | Dramatic emphasis |
| Sustained attention | 800ms-2s | Holds focus | Title cards, captions |
| Cognitive processing | 2-5s | Complex information | Infographic reveals |

### Distance vs Duration (Constant Perceived Speed)

```text
duration = sqrt(distance) * k

distance = pixels traveled
k = speed constant (typically 5-15)

100px -> sqrt(100)*10 = 100ms
400px -> sqrt(400)*10 = 200ms
```

FFmpeg implementation (move 500px in 224ms):

```bash
-vf "drawtext=text='MOVE':\
     x='if(lt(t,0.224),(w-500)+500*t/0.224,w)':\
     y=(h-th)/2:fontsize=80:fontcolor=white"
```

### Biological Rhythms

| Rhythm | Rate | Use Case |
|--------|------|----------|
| Resting heartbeat | 60-80 BPM (1-1.3 Hz) | Calm, meditative pulse |
| Walking pace | 100-120 BPM (1.7-2 Hz) | Comfortable, steady rhythm |
| Excited/anxious | 120-160 BPM (2-2.7 Hz) | Energetic, urgent feeling |
| Breathing | 12-20/min (0.2-0.33 Hz) | Slow, natural oscillation |

```bash
# Heartbeat pulse (70 BPM = 1.17 Hz):
fontsize='72+6*max(0,sin(t*7.33))'

# Walking pace (110 BPM = 1.83 Hz):
fontsize='72+4*abs(sin(t*11.5))'

# Breathing (15/min = 0.25 Hz):
fontsize='72+10*sin(t*1.57)'
```

## Sources

- FFmpeg Expression Evaluation Documentation: https://ffmpeg.org/ffmpeg-utils.html#Expression-Evaluation
- Spring Physics for UI Animations: https://www.kvin.me/posts/effortless-ui-spring-animations
- Easing Functions Mathematical Reference: https://easings.net/
- Material Design Motion Guidelines: https://m3.material.io/styles/motion/overview
- React Spring Physics Documentation: https://www.react-spring.dev/docs/advanced/spring-configs
- ASS Subtitle Format Specification: https://aegisub.org/docs/latest/ass_tags/
- WCAG 2.2 Animation Accessibility: https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions
- Accessible Animations: https://www.a11y-collective.com/blog/wcag-animation/
