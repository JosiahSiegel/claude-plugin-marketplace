---
name: viral-video-platform-specs
description: |
  Complete platform upload specifications for viral video creation across TikTok, YouTube Shorts, Instagram Reels, Facebook Reels, Snapchat Spotlight, and Twitter/X.
  PROACTIVELY activate for: (1) Platform-specific video encoding, (2) Upload requirements lookup, (3) Multi-platform export, (4) File size optimization, (5) Aspect ratio conversion, (6) Duration limits, (7) Audio requirements, (8) Caption/subtitle specs, (9) Thumbnail requirements, (10) Quality vs compatibility trade-offs.
  Provides: Comprehensive spec tables, FFmpeg presets per platform, optimal encoding settings, file size calculators, batch export workflows, and 2025-2026 platform-specific algorithm insights.
---

# Viral Video Platform Specifications

Use this skill to choose export settings for TikTok, YouTube Shorts, Instagram Reels, Facebook Reels, Snapchat Spotlight, Twitter/X, Pinterest, LinkedIn, and mobile-browser playback. This SKILL is a lean orchestrator; detailed platform tables, commands, and recipes are preserved in `references/platform-details-and-recipes.md`.

## Quick Reference

| Platform | Aspect | Recommended resolution | Practical duration | Max size | Default codec |
|---|---:|---:|---:|---:|---|
| TikTok | 9:16 | 1080x1920 | 21-34s | 287 MB iOS | H.264 + AAC |
| YouTube Shorts | 9:16 | 1080x1920 | 50-59s | 256 GB | H.264 or VP9 |
| Instagram Reels | 9:16 | 1080x1920 | 7-30s | 4 GB | H.264 + AAC |
| Facebook Reels | 9:16 | 1080x1920 | 15-30s | 4 GB | H.264 + AAC |
| Snapchat Spotlight | 9:16 | 1080x1920 | <=60s | 300 MB | H.264 + AAC |
| Twitter/X | 9:16, 16:9, 1:1 | 1080x1920 | <=140s | 512 MB | H.264 + AAC |

## Universal Social Export Baseline

```bash
ffmpeg -i input.mp4 \
  -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:black,setsar=1,fps=30" \
  -c:v libx264 -preset medium -crf 22 -profile:v high -level 4.1 \
  -c:a aac -b:a 192k -ar 48000 -ac 2 \
  -pix_fmt yuv420p -movflags +faststart \
  output_social.mp4
```

Adjust loudness, duration, bitrate, and metadata per platform from the reference file.

## Core Workflow

1. Verify `ffmpeg -version`; prefer current stable builds for security and codec fixes.
2. Identify target platform(s) and whether the video is native-app upload or mobile-browser playback.
3. Normalize to vertical 9:16 unless the platform or campaign calls for square/horizontal.
4. Use H.264/AAC for the broadest acceptance. Use VP9 only when intentionally targeting YouTube/WebM.
5. Apply platform loudness targets: TikTok/Reels often around -10 to -12 LUFS; YouTube around -14 LUFS; Facebook around -13 LUFS.
6. Keep `-pix_fmt yuv420p` and `-movflags +faststart` for compatibility.
7. Verify output with `ffprobe` before upload.

## Key Gotchas

- All major social platforms re-encode uploads; high-quality H.264 is usually a better upload source than HEVC/AV1 for social delivery.
- For web/mobile-browser playback, profile/level, `yuv420p`, and faststart matter more than platform upload limits.
- Keep captions and UI out of unsafe top/bottom regions, especially lower 35% on Reels-style interfaces.
- Two-pass bitrate control is useful when a platform file-size ceiling is strict.

## Reference Map

- `references/platform-details-and-recipes.md` - Full preserved reference: per-platform spec tables, FFmpeg presets, two-pass examples, multi-platform export script, file-size calculation, codec comparison, mobile-safe playback, color grading, text/caption readability, verification commands, sources.

## Related Skills

- `viral-video-animated-captions` - CapCut-style caption generation
- `viral-video-hook-templates` - Hook patterns and retention tactics
- `ffmpeg-animation-timing-reference` - Timing, readability, sync, and platform pacing
- `ffmpeg-command-syntax` - Correct option placement
