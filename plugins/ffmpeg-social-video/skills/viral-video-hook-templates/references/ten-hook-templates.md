# The Ten Proven Hook Templates (Detailed Reference)

Full FFmpeg filter graphs and parameter values for each of the ten canonical viral-video hook templates. SKILL.md keeps the short index; this reference has each complete recipe.

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

# Zoom punch effect - 1.5x to 1.0x zoom over 0.5s at 60fps for maximum impact
# 50% initial zoom (1.5x) is highly visible on mobile, completes within 0.5s attention window
# Note: d=1 ensures continuous per-frame processing; the time conditional limits zoom to first 0.5s
ffmpeg -i input.mp4 \
  -vf "fps=60,zoompan=z='if(lt(t,0.5),1.5-t,1)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1080x1920" \
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

