---
name: viral-video-animated-captions
description: |
  CapCut-style animated word-level captions for viral video with FFmpeg.
  PROACTIVELY activate for: (1) Word-by-word caption highlighting, (2) Animated subtitle effects, (3) CapCut-style captions, (4) Karaoke-style text, (5) Bounce/pop text animations, (6) Color-changing words, (7) Emoji integration in captions, (8) Multi-style caption presets, (9) Trending caption styles, (10) Social media caption optimization.
  Provides: ASS subtitle generation scripts, word-level timing workflows, animation presets, color schemes, font recommendations, and platform-specific caption styles for TikTok, YouTube Shorts, and Instagram Reels.
---

# CapCut-Style Animated Captions

Use this skill to create burned-in social captions with word-level timing, pop/bounce/scale animations, karaoke highlighting, and platform-appropriate caption styles. This SKILL is a lean orchestrator; detailed ASS styles, scripts, formulas, and presets are preserved in `references/caption-styles-and-generation.md`.

## When to Use

- Word-by-word or phrase-by-phrase social captions
- CapCut-style pop, bounce, sweep, karaoke, and typewriter captions
- Whisper transcript to animated ASS conversion
- TikTok, YouTube Shorts, Instagram Reels, and Facebook Reels caption styling
- Caption readability, safe zones, accessibility, and mobile typography

## Caption Workflow

1. Generate transcript with word-level timestamps using Whisper or another ASR tool.
2. Convert word timings into ASS events and styles.
3. Use ASS timing units correctly: karaoke tags use centiseconds; animation tags use milliseconds.
4. Burn ASS into the video with FFmpeg.
5. Verify readability, safe-zone placement, audio sync, and final platform specs.

## Minimal Burn-In Command

```bash
ffmpeg -i input.mp4 \
  -vf "ass=captions.ass" \
  -c:v libx264 -preset fast -crf 23 \
  -c:a copy \
  output_captioned.mp4
```

If audio copy fails because the output container cannot accept the source audio, re-encode audio with `-c:a aac -b:a 128k`.

## Quick Style Selection

| Style | Effect | Best for |
|---|---|---|
| Word Pop | Each word scales in with overshoot | High-energy hooks, gaming, comedy |
| Highlight Sweep | Full phrase visible, words highlight in sequence | Educational and professional explainers |
| Karaoke Fill | Progressive fill across words | Music, voiceover, lyric-style captions |
| Typewriter | Characters appear progressively | Dramatic storytelling |
| Bounce In | Words move/scale from below | Shorts/Reels emphasis beats |

## Timing and Readability Rules

- Word-level animations usually need 80-250ms appear time and 200-600ms dwell, depending on platform.
- Keep 3-6 words on screen for vertical social video.
- Use large sans-serif fonts, high contrast, and a thick outline.
- Avoid excessive shake/flash; keep accessibility and readability ahead of novelty.
- Keep captions inside mobile safe zones; avoid the lower UI-heavy region.

## Reference Map

- `references/caption-styles-and-generation.md` - Full preserved reference: Whisper timestamp commands, ASS structure, WordPop/Sweep/Karaoke/Typewriter/Bounce examples, Python JSON-to-ASS script, bash pipeline, burn commands, style presets, color schemes, emoji integration, platform guidelines, troubleshooting, spring/easing/shake/pulse formulas, accessibility guidance, sources.

## Related Skills

- `ffmpeg-captions-subtitles` - Subtitle fundamentals and burn-in
- `ffmpeg-karaoke-animated-text` - ASS karaoke and animated text patterns
- `ffmpeg-animation-timing-reference` - Timing units, easing, readability, sync
- `viral-video-platform-specs` - Export specs and safe zones
- `viral-video-hook-templates` - Hook and retention strategy
