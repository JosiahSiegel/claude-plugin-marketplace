---
name: viral-video-hook-templates
description: |
  10 proven viral video hook templates with FFmpeg implementations for maximum first-3-second retention.
  PROACTIVELY activate for: (1) Video hook creation, (2) Opening sequence optimization, (3) Attention-grabbing techniques, (4) Pattern interrupt effects, (5) Curiosity gap implementation, (6) Text overlay hooks, (7) Visual hook effects, (8) Audio hook strategies, (9) Retention optimization, (10) Scroll-stopping content.
  Provides: Research-backed hook formulas, FFmpeg filter implementations, psychological triggers, platform-specific hooks, A/B testing workflows, and real-world examples with measurable impact.
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

---

# Viral Video Hook Templates (2025-2026)

## The Science of Hooks

**The Critical Window**: You have **1.3-3 seconds** to stop the scroll. Research shows:
- 65% of viewers decide to watch or skip within 3 seconds
- Videos with strong hooks have 2-3x higher completion rates
- The hook accounts for up to 80% of a video's viral potential

---

## Hook Timing Reference

### Optimal Hook Durations by Type

| Hook Type | Duration | Reasoning |
|-----------|----------|-----------|
| Pattern Interrupt (visual) | 0.3-0.5s | Quick shock, then content |
| Pattern Interrupt (text) | 1.0-1.5s | Time to read "STOP" etc |
| Curiosity Gap | 2.0-3.0s | Two-part reveal timing |
| Direct Challenge | 1.5-2.5s | Read + process + react |
| Transformation Tease | 2.0-3.0s | Before/after comparison |
| Question Hook | 1.5-2.0s | Read + mental engagement |

### FFmpeg Time Units Quick Reference

**All FFmpeg filter expressions use SECONDS with decimals**:

| Expression | Meaning | Example Use |
|------------|---------|-------------|
| `t` | Current time | `enable='lt(t,2)'` = first 2 seconds |
| `between(t,0,2.5)` | Time range | Hook visible for 2.5s |
| `if(lt(t,1),expr1,expr2)` | Conditional | Different effect in first second |
| `sin(t*10)` | Oscillation | 10 cycles per second |
| `exp(-t*3)` | Decay | Quick fade (3 = fast decay) |

### Recommended Hook Timing

```bash
# Hook window timing breakdown:
# 0.0-0.3s: Visual impact (flash, zoom, color)
# 0.3-1.5s: Primary hook text appears
# 1.0-2.5s: Secondary text/elaboration
# 2.5-3.0s: Transition to main content

# Example: Complete hook with timed elements
ffmpeg -i input.mp4 \
  -vf "
    eq=brightness='0.2*between(t,0,0.2)',
    drawtext=text='STOP':fontsize=80:fontcolor=red:x=(w-tw)/2:y=h*0.12:enable='between(t,0.2,1.5)',
    drawtext=text='This changes everything':fontsize=48:fontcolor=white:x=(w-tw)/2:y=h*0.20:enable='between(t,1.0,2.8)'
  " \
  output_timed_hook.mp4
```

---

## The 10 Proven Hook Templates

A compact index of the ten canonical viral-video hooks. Each entry has its full FFmpeg filter graph and parameters in `references/ten-hook-templates.md`.

1. **Pattern Interrupt** — unexpected visual shift in the first 0.5 s.
2. **Question Hook** — provocative text overlay aligned with quick cut.
3. **Bold Statement Hook** — declarative on-screen text with emphasis.
4. **Curiosity Gap** — partial reveal that promises payoff later.
5. **Negative Hook** — counterintuitive opener.
6. **Number Hook** — "5 things..." text overlay.
7. **Story Hook** — open with a mid-action scene.
8. **Visual Spectacle** — striking transition or shot composition.
9. **Direct Address** — character looks into camera and speaks first frame.
10. **Cliffhanger** — hold a beat that resolves seconds later.

Load `references/ten-hook-templates.md` for the full filter graph of any template.

## Visual Hook Effects Library

### Shake/Tremor Effect

```bash
# Subtle shake for emphasis
ffmpeg -i input.mp4 \
  -vf "crop=1060:1900:(10+10*sin(t*30)):(10+10*cos(t*25)):enable='lt(t,1)',scale=1080:1920" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_shake.mp4
```

### Zoom Pulse

```bash
# Rhythmic zoom pulse - 8% amplitude at ~2Hz for 1.5s (60% more visible than 5%)
# sin(t*12) = 12 rad/s = 1.91 Hz oscillation. Completes before 1.3-second decision point
# Note: 60fps ensures smooth motion; d=1 for continuous per-frame processing
ffmpeg -i input.mp4 \
  -vf "fps=60,zoompan=z='if(lt(t,1.5),1+0.08*sin(t*12),1)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_zoom_pulse.mp4
```

### Color Flash

```bash
# Red flash then normal
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=0.5:gs=-0.2:bs=-0.2:enable='lt(t,0.3)',colorbalance=rs=0.3:enable='between(t,0.3,0.5)'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_color_flash.mp4
```

### Vignette Reveal

```bash
# Dark vignette that opens up
ffmpeg -i input.mp4 \
  -vf "vignette=PI*min(t,2)/2" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_vignette_reveal.mp4
```

---

## A/B Testing Workflow

### Generate Multiple Hook Variants

```bash
#!/bin/bash
# generate_hook_variants.sh - Create multiple hook versions for testing

INPUT="$1"
BASE=$(basename "$INPUT" .mp4)

# Variant A: Curiosity Gap
ffmpeg -i "$INPUT" \
  -vf "drawtext=text='Wait for it...':fontsize=64:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.15:enable='between(t,0,2)'" \
  -c:v libx264 -preset fast -crf 23 -c:a copy \
  "${BASE}_hook_A.mp4" &

# Variant B: Direct Challenge
ffmpeg -i "$INPUT" \
  -vf "drawtext=text='STOP SCROLLING':fontsize=72:fontcolor=red:borderw=5:bordercolor=white:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2)'" \
  -c:v libx264 -preset fast -crf 23 -c:a copy \
  "${BASE}_hook_B.mp4" &

# Variant C: Question Hook
ffmpeg -i "$INPUT" \
  -vf "drawtext=text='Did you know?':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.15:enable='between(t,0,2)'" \
  -c:v libx264 -preset fast -crf 23 -c:a copy \
  "${BASE}_hook_C.mp4" &

wait
echo "Generated 3 hook variants for A/B testing"
ls -la "${BASE}_hook_*.mp4"
```

---

## Hook Performance Metrics

| Hook Type | Avg Stop Rate | Best Content Type | Risk Level |
|-----------|---------------|-------------------|------------|
| Pattern Interrupt | 85% | All | Low |
| Curiosity Gap | 78% | Educational | Low |
| Direct Challenge | 75% | Opinion/Niche | Medium |
| Transformation | 80% | Tutorial/Demo | Low |
| Bold Claim | 72% | How-to | Medium |
| Counter-Intuitive | 70% | Educational | Medium |
| Social Proof | 68% | Reviews | Low |
| Urgency | 65% | Trending/News | High |
| Storytelling | 82% | Personal/Brand | Low |
| Question | 74% | Educational | Low |

---

## Platform-Specific Hook Recommendations

| Platform | Best Hooks | Avoid |
|----------|-----------|-------|
| **TikTok** | Pattern Interrupt, Curiosity Gap, Direct Challenge | Long text hooks |
| **YouTube Shorts** | Transformation, Question, Storytelling | Clickbait-y urgency |
| **Instagram Reels** | Social Proof, Transformation, Bold Claim | Too promotional |
| **Facebook Reels** | Storytelling, Social Proof, Question | Youth slang |

---

## Animation, Color & Audio Parameters (2025-2026)

Concrete parameter values for animation timing, color grading LUTs, and audio hook design live in `references/animation-color-audio-parameters.md`. Highlights:

- **Animation timing:** kinetic-text holds at 0.4-0.6 s; pattern-interrupt cuts at 0.3 s.
- **Color grading:** boost saturation 1.15-1.3x for thumbnail pop; teal/orange split-tone for cinematic feel.
- **Audio:** trending sound layer at -8 dB under primary; voice-over at -3 dB.

## Related Skills

- `viral-video-platform-specs` - Platform requirements
- `viral-video-animated-captions` - Caption styling
- `ffmpeg-viral-tiktok` - TikTok optimization
- `ffmpeg-viral-shorts` - YouTube Shorts optimization
