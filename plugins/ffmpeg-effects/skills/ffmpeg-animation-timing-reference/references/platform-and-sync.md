# Platform-Specific Timing and Audio-Video Sync

## Platform-Specific Timing Profiles

### TikTok (Fast, Energetic)

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 0.5-1.5s between clips | Fast pacing |
| Text animation | 100-200ms | Snappy, punchy |
| Hook window | 1-1.5s | Immediate grab |
| Caption duration | 0.8-1.5s per phrase | Short, readable |
| Zoom effects | 200-400ms | Quick, impactful |
| Optimal video length | 15-30s (sweet spot) | Completion rate focus |

### YouTube Shorts (Medium-Fast)

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 1-2s between clips | Slightly slower than TikTok |
| Text animation | 150-300ms | Smooth but quick |
| Hook window | 2-3s | Slightly more time |
| Caption duration | 1.2-2s per phrase | More readable |
| Zoom effects | 300-600ms | Noticeable but smooth |
| Optimal video length | 50-60s | Algorithm favored |

### Instagram Reels (Aesthetic, Polished)

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 1.5-2.5s between clips | More polished |
| Text animation | 150-250ms | Stylish timing |
| Hook window | 2-3s | Visual-first platform |
| Caption duration | 1-1.8s per phrase | Instagram style |
| Zoom effects | 400-800ms | Cinematic feel |
| Optimal video length | 15-30s (trending) | Engagement focused |

### Professional/Broadcast

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 2-4s between clips | Deliberate pacing |
| Text animation | 300-500ms | Smooth, professional |
| Lower third entrance | 400-600ms | Broadcast standard |
| Caption duration | 2-4s per phrase | Full readability |
| Zoom effects | 800-1500ms | Subtle, cinematic |
| Typical segment | 30-90s | Standard TV timing |

## Audio-Video Sync Tolerances

### Synchronization Thresholds

| Sync Type | Maximum Tolerance | Recommended | Notes |
|-----------|-------------------|-------------|-------|
| Lip sync | +/-80ms | +/-40ms | Human perception limit |
| Music beat sync | +/-50ms | +/-20ms | Musical precision |
| Karaoke lyrics | +/-100ms | +/-30ms | Comfortable singing |
| Sound effects | +/-30ms | +/-10ms | Impact synchronization |
| Transition + audio | +/-100ms | +/-50ms | Cross-fade sync |

### Lip Sync Guidelines

```yaml
Tolerance: +/-80ms (audio can lead or lag video by 80ms)
Recommendation: Keep within +/-40ms for professional quality

Audio Leading (negative offset): Less noticeable, up to -80ms acceptable
Audio Lagging (positive offset): More noticeable, keep under +40ms
```

### Music Sync

```bash
# Calculate beat timing:
# 120 BPM = 2 beats/second = 500ms per beat
# 140 BPM = 2.33 beats/second = 429ms per beat

# Align transitions to beat:
# At 120 BPM, beats fall at: 0ms, 500ms, 1000ms, 1500ms, 2000ms...
```

### Karaoke Timing

```text
Word highlight should START when word begins (not before)
Early highlight: Confusing, breaks immersion
Late highlight: Frustrating for singers

Recommendation: Highlight 0-50ms AFTER word starts (slight lag preferred)
```

## Frame Rate Considerations

### Timing Precision Limits

| Frame Rate | Frame Duration | Precision Limit |
|------------|----------------|-----------------|
| 24 fps | 41.67ms | ~40ms increments |
| 25 fps | 40ms | 40ms increments |
| 30 fps | 33.33ms | ~33ms increments |
| 60 fps | 16.67ms | ~17ms increments |

### Animation Smoothness

```text
For smooth animation, use durations that are multiples of frame duration:

30fps:
- 100ms = 3 frames (smooth)
- 200ms = 6 frames (smooth)
- 333ms = 10 frames (smooth)
- 150ms = 4.5 frames (may stutter)

60fps:
- 100ms = 6 frames (smooth)
- 200ms = 12 frames (smooth)
- 167ms = 10 frames (smooth)
```

### Minimum Visible Duration

```text
Animation duration must be at least 2-3 frames to be perceived:
- 30fps minimum: ~67-100ms
- 60fps minimum: ~33-50ms

Very short effects (<50ms) may not render consistently
```

### Frame-Safe Duration Table

| Desired Duration | 30fps Safe | 60fps Safe |
|------------------|------------|------------|
| ~100ms | 100ms (3f) | 100ms (6f) |
| ~150ms | 167ms (5f) | 150ms (9f) |
| ~200ms | 200ms (6f) | 200ms (12f) |
| ~250ms | 233ms (7f) | 250ms (15f) |
| ~300ms | 300ms (9f) | 300ms (18f) |
| ~500ms | 500ms (15f) | 500ms (30f) |
