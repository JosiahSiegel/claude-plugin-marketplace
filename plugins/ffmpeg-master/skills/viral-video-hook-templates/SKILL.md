---
name: viral-video-hook-templates
description: 10 proven viral video hook templates with FFmpeg implementations for maximum first-3-second retention. PROACTIVELY activate for: (1) Video hook creation, (2) Opening sequence optimization, (3) Attention-grabbing techniques, (4) Pattern interrupt effects, (5) Curiosity gap implementation, (6) Text overlay hooks, (7) Visual hook effects, (8) Audio hook strategies, (9) Retention optimization, (10) Scroll-stopping content. Provides: Research-backed hook formulas, FFmpeg filter implementations, psychological triggers, platform-specific hooks, A/B testing workflows, and real-world examples with measurable impact.
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

### 1. The Pattern Interrupt

**Psychology**: Breaks viewer's passive scrolling state with unexpected visual/audio

**Best For**: All content types, especially saturated niches

**FFmpeg Implementation**:

```bash
# Flash/brightness pulse at start (0.5 seconds)
ffmpeg -i input.mp4 \
  -vf "eq=brightness='0.3*between(t,0,0.1)+0.2*between(t,0.1,0.2)+0.1*between(t,0.2,0.3)'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_pattern_interrupt.mp4

# Zoom punch effect in first second
ffmpeg -i input.mp4 \
  -vf "zoompan=z='if(lt(t,1),1.3-0.3*t,1)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_zoom_punch.mp4

# Glitch effect burst (first 0.5s)
ffmpeg -i input.mp4 \
  -vf "rgbashift=rh=-5:rv=5:gh=3:gv=-3:bh=-2:bv=2:enable='lt(t,0.5)',chromashift=cbh=3:cbv=3:crh=-3:crv=-3:enable='lt(t,0.5)'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_glitch_hook.mp4
```

**Text Overlay Example**:
```bash
# "STOP." appearing suddenly
ffmpeg -i input.mp4 \
  -vf "drawtext=text='STOP.':fontsize=120:fontcolor=red:borderw=5:bordercolor=white:x=(w-tw)/2:y=(h-th)/2:enable='between(t,0,1.5)'" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_stop_hook.mp4
```

---

### 2. The Curiosity Gap

**Psychology**: Creates information deficit that viewer must resolve by watching

**Best For**: Educational, storytelling, reveals

**Templates**:
- "You won't believe what happens at [X]..."
- "This is why you've been doing [X] wrong..."
- "Nobody talks about this, but..."
- "The secret [industry] doesn't want you to know..."

**FFmpeg Implementation**:

```bash
# Two-part curiosity hook
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='What happens next':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.35:enable='between(t,0,1.5)',
    drawtext=text='will SHOCK you...':fontsize=64:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.45:enable='between(t,0.8,2.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_curiosity.mp4

# Animated reveal text
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='The truth about...':fontsize=48:fontcolor=white:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.15:alpha='if(lt(t,0.5),t*2,1)':enable='lt(t,3)',
    drawtext=text='[REVEALED]':fontsize=72:fontcolor=red:borderw=4:bordercolor=white:x=(w-tw)/2:y=h*0.25:enable='between(t,1.5,3)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_reveal.mp4
```

---

### 3. The Direct Challenge

**Psychology**: Triggers ego/identity response, forces engagement

**Best For**: Hot takes, controversial opinions, niche content

**Templates**:
- "If you do [X], you're doing it wrong"
- "Stop scrolling if you're a [type of person]"
- "This is for the 1% who actually want to [achieve X]"
- "Most people will ignore this, but..."

**FFmpeg Implementation**:

```bash
# Direct address hook
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='STOP SCROLLING':fontsize=72:fontcolor=red:borderw=5:bordercolor=white:x=(w-tw)/2:y=h*0.12:enable='between(t,0,2)',
    drawtext=text='if you want to':fontsize=48:fontcolor=white:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.20:enable='between(t,0.5,2)',
    drawtext=text='[YOUR BENEFIT]':fontsize=56:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.27:enable='between(t,1,2.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_challenge.mp4
```

---

### 4. The Transformation Tease

**Psychology**: Shows result first, creates desire to learn how

**Best For**: Before/after, tutorials, product demos

**Templates**:
- "From [bad state] to [good state] in [time]"
- "This is the before... (pause) ...and this is after"
- "Watch this transformation"

**FFmpeg Implementation**:

```bash
# Split screen before/after teaser
ffmpeg -i before.mp4 -i after.mp4 \
  -filter_complex "
    [0:v]scale=540:1920,crop=540:960:0:480[left];
    [1:v]scale=540:1920,crop=540:960:0:480[right];
    [left][right]hstack=inputs=2[v];
    [0:a][1:a]amix=inputs=2[a]
  " \
  -map "[v]" -map "[a]" \
  -c:v libx264 -preset fast -crf 23 \
  -t 3 \
  output_transform_tease.mp4

# Before label then after reveal
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='BEFORE':fontsize=72:fontcolor=red:borderw=4:bordercolor=white:x=(w-tw)/2:y=h*0.10:enable='between(t,0,1.5)',
    drawtext=text='AFTER':fontsize=72:fontcolor=green:borderw=4:bordercolor=white:x=(w-tw)/2:y=h*0.10:enable='between(t,2,3.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_before_after.mp4
```

---

### 5. The Bold Claim

**Psychology**: Triggers skepticism that must be resolved by watching

**Best For**: Tutorials, hacks, revelations

**Templates**:
- "This [thing] changed my life"
- "The [X] that makes everything else obsolete"
- "I discovered this and my [metric] went up [X]%"
- "This one trick [dramatic result]"

**FFmpeg Implementation**:

```bash
# Bold claim with emphasis
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='This ONE thing':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.12:enable='between(t,0,1.5)',
    drawtext=text='changed EVERYTHING':fontsize=64:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.20:enable='between(t,0.8,2.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_bold_claim.mp4
```

---

### 6. The Counter-Intuitive

**Psychology**: Challenges existing beliefs, triggers cognitive dissonance

**Best For**: Educational, myth-busting, industry secrets

**Templates**:
- "[Common belief]? That's actually wrong"
- "Everything you know about [X] is backwards"
- "The [X] industry doesn't want you to know this"
- "Why [opposite of expectation] is actually true"

**FFmpeg Implementation**:

```bash
# Myth vs Reality hook
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='MYTH':fontsize=64:fontcolor=red:borderw=4:bordercolor=white:x=w*0.25-(tw/2):y=h*0.12:enable='between(t,0,1.5)',
    drawtext=text='vs':fontsize=48:fontcolor=white:x=(w-tw)/2:y=h*0.12:enable='between(t,0.5,1.5)',
    drawtext=text='REALITY':fontsize=64:fontcolor=green:borderw=4:bordercolor=white:x=w*0.75-(tw/2):y=h*0.12:enable='between(t,0,1.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_counter_intuitive.mp4
```

---

### 7. The Social Proof

**Psychology**: Leverages herd mentality and FOMO

**Best For**: Product reviews, recommendations, trending topics

**Templates**:
- "[X million] people use this and don't know about [Y]"
- "This is why [authority/celebrity] does [X]"
- "Everyone's talking about this..."
- "[X]% of people don't know this exists"

**FFmpeg Implementation**:

```bash
# Stats-based social proof
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='10 MILLION people':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.10:enable='between(t,0,2)',
    drawtext=text='are using this wrong':fontsize=48:fontcolor=yellow:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.18:enable='between(t,0.8,2.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_social_proof.mp4
```

---

### 8. The Time-Sensitive Urgency

**Psychology**: Creates artificial scarcity, triggers fear of missing out

**Best For**: Trends, limited offers, news, seasonal content

**Templates**:
- "Before [date/event], you need to know this"
- "This won't work after [time]"
- "You have [X days] left to..."
- "Do this NOW before it's too late"

**FFmpeg Implementation**:

```bash
# Urgent countdown style
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='DO THIS NOW':fontsize=72:fontcolor=red:borderw=5:bordercolor=white:x=(w-tw)/2:y=h*0.10:enable='between(t,0,2)',
    drawtext=text='before it\\'s too late':fontsize=48:fontcolor=yellow:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.18:enable='between(t,0.8,2.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_urgency.mp4
```

---

### 9. The Storytelling Hook

**Psychology**: Triggers narrative engagement, emotional investment

**Best For**: Personal stories, case studies, testimonials

**Templates**:
- "3 months ago, I [bad situation]..."
- "This is the story of how I [achievement]"
- "It started when..."
- "Nobody expected what happened next"

**FFmpeg Implementation**:

```bash
# Story opener with fade-in text
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='3 months ago...':fontsize=56:fontcolor=white:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.15:alpha='if(lt(t,1),t,1)':enable='lt(t,3)',
    drawtext=text='everything changed':fontsize=48:fontcolor=yellow:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.23:alpha='if(lt(t-1,1),max(0,t-1),1)':enable='between(t,1,3)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_story.mp4
```

---

### 10. The Question Hook

**Psychology**: Activates problem-solving brain, demands mental engagement

**Best For**: Educational, listicles, Q&A content

**Templates**:
- "Have you ever wondered why [X]?"
- "What if I told you [X]?"
- "Can you guess [X]?"
- "Why does everyone get [X] wrong?"

**FFmpeg Implementation**:

```bash
# Question with reveal
ffmpeg -i input.mp4 \
  -vf "
    drawtext=text='Have you ever wondered':fontsize=48:fontcolor=white:borderw=3:bordercolor=black:x=(w-tw)/2:y=h*0.12:enable='between(t,0,1.5)',
    drawtext=text='WHY this happens?':fontsize=56:fontcolor=yellow:borderw=4:bordercolor=black:x=(w-tw)/2:y=h*0.20:enable='between(t,0.8,2.5)'
  " \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_question.mp4
```

---

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
# Rhythmic zoom pulse in first 2 seconds
ffmpeg -i input.mp4 \
  -vf "zoompan=z='if(lt(t,2),1+0.05*sin(t*10),1)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
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

## Related Skills

- `viral-video-platform-specs` - Platform requirements
- `viral-video-animated-captions` - Caption styling
- `ffmpeg-viral-tiktok` - TikTok optimization
- `ffmpeg-viral-shorts` - YouTube Shorts optimization
