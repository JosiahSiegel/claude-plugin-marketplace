---
name: viral-audit
description: Audit a video strategy for viral potential with platform-specific recommendations
argument-hint: "<platform> <content-type> [video-url-or-description]"
allowed-tools:
  - Read
  - WebFetch
  - WebSearch
---

# Viral Video Audit

## Purpose

Perform a comprehensive audit of a video or video strategy to identify opportunities for improved viral potential and engagement.

## Arguments

- `$ARGUMENTS`: Platform target, content type, and optionally a video URL or description
  - Example: `tiktok fitness-tips`
  - Example: `youtube-shorts cooking demo at https://youtu.be/example`
  - Example: `instagram-reels lifestyle my current video gets 200 views`

## Workflow

### 1. Gather Information

If not provided in arguments, ask about:
- Platform target (TikTok, YouTube, Instagram, Facebook)
- Content type (short-form or long-form)
- Video topic/niche
- Current video URL or description
- Current metrics (views, engagement, retention if available)

### 2. Audit Framework

Evaluate across these dimensions:

#### Hook Analysis (Weight: 25%)

| Element | Check |
|---------|-------|
| First 1.3 seconds | Does it grab attention immediately? |
| First 3 seconds | Is there a clear hook? |
| Psychological trigger | Curiosity gap, pattern interrupt, or open loop? |
| Value proposition | Is the payoff clear? |

**Benchmark**: 65% who watch first 3 seconds will watch 10+ seconds

#### Retention Strategy (Weight: 25%)

| Element | Check |
|---------|-------|
| Pacing | Is it appropriate for platform? |
| Pattern interrupts | Are there visual/audio changes every 30-60 seconds? |
| Story structure | Beginning, middle, end? |
| Filler content | Any unnecessary segments? |

**Benchmark**: 80-90% completion rate for top performers

#### Visual Optimization (Weight: 20%)

| Element | Check |
|---------|-------|
| Thumbnail (YouTube) | Emotional face, <5 words, high contrast? |
| Captions | Present, styled, synchronized? (12-40% watch time boost) |
| Aspect ratio | Correct for platform (9:16 for short-form)? |
| Color grading | Consistent, on-trend? |

#### Audio Strategy (Weight: 15%)

| Element | Check |
|---------|-------|
| Trending sound | Using current trends? (88% say sound essential) |
| Voice quality | Clear, engaging, human? (35% drop with AI narration) |
| Music sync | Beats aligned with cuts? |
| Sound design | Enhance or distract? |

#### SEO & Discovery (Weight: 15%)

| Element | Check |
|---------|-------|
| Title | Keywords, compelling, optimal length? |
| Description | First 25 words optimized, CTAs? |
| Hashtags | 3-5 relevant, niche + broad mix? |
| Tags | Platform-appropriate? |

### 3. Scoring System

Rate each dimension 1-10 and calculate weighted score:

```
Hook Score: __/10 x 0.25 = __
Retention Score: __/10 x 0.25 = __
Visual Score: __/10 x 0.20 = __
Audio Score: __/10 x 0.15 = __
SEO Score: __/10 x 0.15 = __
---
VIRAL POTENTIAL SCORE: __/10
```

### 4. Platform-Specific Benchmarks

**TikTok:**
- Target retention: 60%+ completion rate (80%+ for viral)
- Hook window: 1.3 seconds
- Optimal length: 15-30 seconds
- Trending sounds: Essential (88% say sound matters)
- Cold start test: First 200-500 viewers determine reach

**YouTube Shorts:**
- Target retention: 70%+ in first 30 seconds
- Optimal length: 50-60 seconds (3x more views than 15-second)
- Freshness factor: Content older than 30 days rarely pushed
- CTA impact: 22% more engagement with strong CTA

**YouTube Long-form:**
- Target retention: 50%+ average (23.7% is average)
- Optimal length: 8-15 minutes
- Watch time: Primary metric
- Thumbnail: 60-70% CTR impact

**Instagram Reels:**
- Target retention: 80%+ for viral
- Optimal length: 7-30 seconds (viral), 30-90 seconds (engagement)
- 3/8/12 rule: 3s hook, 8s deepen, 12s+ deliver
- Sends Per Reach: Most powerful signal for new audience reach

### 5. Generate Recommendations

**Priority 1 (Immediate Impact):**
- List 2-3 changes with biggest effect
- Focus on hook and retention first

**Priority 2 (Short-term Improvements):**
- Visual and audio optimization
- SEO improvements

**Priority 3 (Long-term Strategy):**
- Content strategy refinements
- Audience building tactics

## Output Format

Provide:
1. **Overall Viral Potential Score** with breakdown
2. **Top 3 Strengths** of current approach
3. **Top 3 Weaknesses** limiting viral potential
4. **Prioritized Recommendations** with specific actions
5. **Platform-Specific Tips** tailored to target platform
6. **Benchmark Comparison** showing where content falls vs top performers
7. **Quick Win Actions** that can be implemented immediately
