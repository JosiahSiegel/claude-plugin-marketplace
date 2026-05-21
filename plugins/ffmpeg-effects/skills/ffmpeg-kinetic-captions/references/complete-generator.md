# Complete Kinetic Caption Generator (Python + ASS)

A full Python script that takes word-level timestamps and emits Advanced SubStation Alpha (ASS) captions with kinetic animation. SKILL.md keeps the per-effect recipes; this reference holds the assembled generator.

## Complete Kinetic Caption Generator

```python
#!/usr/bin/env python3
"""
kinetic_captions.py - Generate kinetic ASS captions from word-level timestamps

Usage: python kinetic_captions.py transcript.json output.ass [style]
Styles: pop, grow, karaoke, bounce, elastic, shake

Input JSON format (Whisper output):
{
  "segments": [
    {
      "words": [
        {"word": "This", "start": 0.0, "end": 0.5},
        {"word": "is", "start": 0.5, "end": 0.8},
        ...
      ]
    }
  ]
}
"""

import json
import sys
from typing import List, Dict, Tuple

# Animation presets
PRESETS = {
    'pop': {
        'start_scale': 50,
        'peak_scale': 115,
        'end_scale': 100,
        'grow_ms': 100,
        'shrink_ms': 100,
        'word_overlap_ms': 50
    },
    'grow': {
        'start_scale': 80,
        'peak_scale': 115,
        'end_scale': 100,
        'grow_ms': 150,
        'shrink_ms': 200,
        'word_overlap_ms': 0
    },
    'karaoke': {
        'use_karaoke': True,
        'peak_scale': 112,
        'grow_ms': 150,
        'shrink_ms': 200
    },
    'bounce': {
        'start_scale': 80,
        'peak_scale': 120,
        'bounce_scale': 95,
        'end_scale': 100,
        'grow_ms': 100,
        'bounce_ms': 100,
        'settle_ms': 100,
        'word_overlap_ms': 50
    },
    'elastic': {
        'start_scale': 40,
        'peak1_scale': 130,
        'valley_scale': 90,
        'peak2_scale': 105,
        'end_scale': 100,
        'phase1_ms': 80,
        'phase2_ms': 80,
        'phase3_ms': 100,
        'phase4_ms': 120,
        'word_overlap_ms': 80
    },
    'shake': {
        'start_scale': 100,
        'peak_scale': 115,
        'shake_amplitude': 8,
        'shake_cycles': 3,
        'shake_duration_ms': 150,
        'grow_ms': 80
    }
}

# Platform presets
PLATFORMS = {
    'tiktok': {
        'font_name': 'Arial Black',
        'font_size': 88,
        'animation_speed': 0.8,
        'max_words': 5
    },
    'youtube': {
        'font_name': 'Montserrat',
        'font_size': 76,
        'animation_speed': 1.2,
        'max_words': 6
    },
    'instagram': {
        'font_name': 'Impact',
        'font_size': 82,
        'animation_speed': 1.0,
        'max_words': 5
    }
}


def format_time_ass(seconds: float) -> str:
    """Convert seconds to ASS timestamp (H:MM:SS.cc)"""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = seconds % 60
    return f"{h}:{m:02d}:{s:05.2f}"


def generate_pop_effect(word: str, preset: dict) -> str:
    """Generate pop animation tags"""
    s = preset['start_scale']
    p = preset['peak_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    sh = preset['shrink_ms']

    return f"{{\\fscx{s}\\fscy{s}\\t(0,{g},\\fscx{p}\\fscy{p})\\t({g},{g+sh},\\fscx{e}\\fscy{e})}}{word}"


def generate_grow_effect(word: str, preset: dict) -> str:
    """Generate grow animation tags (for karaoke highlight)"""
    s = preset.get('start_scale', 100)
    p = preset['peak_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    sh = preset['shrink_ms']

    if preset.get('use_karaoke'):
        # Karaoke duration calculated externally
        return f"{{\\t(0,{g},\\fscx{p}\\fscy{p})\\t({g},{g+sh},\\fscx{e}\\fscy{e})}}"
    else:
        return f"{{\\fscx{s}\\fscy{s}\\t(0,{g},\\fscx{p}\\fscy{p})\\t({g},{g+sh},\\fscx{e}\\fscy{e})}}{word}"


def generate_bounce_effect(word: str, preset: dict) -> str:
    """Generate spring bounce animation tags"""
    s = preset['start_scale']
    p = preset['peak_scale']
    b = preset['bounce_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    bm = preset['bounce_ms']
    st = preset['settle_ms']

    t1 = g
    t2 = t1 + bm
    t3 = t2 + st

    return f"{{\\fscx{s}\\fscy{s}\\t(0,{t1},\\fscx{p}\\fscy{p})\\t({t1},{t2},\\fscx{b}\\fscy{b})\\t({t2},{t3},\\fscx{e}\\fscy{e})}}{word}"


def generate_elastic_effect(word: str, preset: dict) -> str:
    """Generate elastic overshoot animation tags"""
    s = preset['start_scale']
    p1 = preset['peak1_scale']
    v = preset['valley_scale']
    p2 = preset['peak2_scale']
    e = preset['end_scale']
    t1 = preset['phase1_ms']
    t2 = t1 + preset['phase2_ms']
    t3 = t2 + preset['phase3_ms']
    t4 = t3 + preset['phase4_ms']

    return f"{{\\fscx{s}\\fscy{s}\\t(0,{t1},\\fscx{p1}\\fscy{p1})\\t({t1},{t2},\\fscx{v}\\fscy{v})\\t({t2},{t3},\\fscx{p2}\\fscy{p2})\\t({t3},{t4},\\fscx{e}\\fscy{e})}}{word}"


def generate_shake_effect(word: str, preset: dict) -> str:
    """Generate shake + scale animation"""
    p = preset['peak_scale']
    amp = preset['shake_amplitude']
    cycles = preset['shake_cycles']
    dur = preset['shake_duration_ms']
    g = preset['grow_ms']

    # Calculate shake timing
    cycle_dur = dur // cycles
    shake_tags = ""

    for i in range(cycles):
        t_start = g + (i * cycle_dur)
        t_mid = t_start + (cycle_dur // 2)
        t_end = t_start + cycle_dur
        offset = amp - (i * 2)  # Decay amplitude
        if offset > 0:
            # Note: position shake requires \pos, complex for per-word
            pass

    return f"{{\\fscx100\\fscy100\\t(0,{g},\\fscx{p}\\fscy{p})\\t({g},{g+dur},\\fscx100\\fscy100)}}{word}"


def generate_karaoke_line(words: List[Dict], preset: dict, style_name: str) -> str:
    """Generate karaoke line with grow effect"""
    if not words:
        return ""

    karaoke_text = ""
    for word_data in words:
        word = word_data['word'].strip()
        duration_sec = word_data['end'] - word_data['start']
        duration_cs = int(duration_sec * 100)  # Centiseconds for \k

        grow_tag = generate_grow_effect(word, preset)
        karaoke_text += f"{{\\k{duration_cs}}}{grow_tag}{word} "

    return karaoke_text.strip()


def create_ass_header(platform: str = 'tiktok') -> str:
    """Create ASS file header with styles"""
    plat = PLATFORMS.get(platform, PLATFORMS['tiktok'])

    return f"""[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0
Title: Kinetic Captions

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: KineticPop,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticGrow,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticKaraoke,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticBounce,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticElastic,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,280,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""


def generate_kinetic_captions(transcript_path: str, output_path: str,
                              style: str = 'pop', platform: str = 'tiktok'):
    """Generate kinetic ASS captions from Whisper JSON transcript"""

    with open(transcript_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    preset = PRESETS.get(style, PRESETS['pop'])
    style_name = f"Kinetic{style.title()}"

    header = create_ass_header(platform)
    events = []

    # Extract all words
    all_words = []
    segments = data.get('segments', [])
    for segment in segments:
        words = segment.get('words', [])
        all_words.extend(words)

    if style == 'karaoke':
        # Group words into lines and generate karaoke
        for segment in segments:
            words = segment.get('words', [])
            if not words:
                continue

            start = words[0]['start']
            end = words[-1]['end']
            karaoke_line = generate_karaoke_line(words, preset, style_name)

            events.append(
                f"Dialogue: 0,{format_time_ass(start)},{format_time_ass(end)},{style_name},,0,0,0,,{karaoke_line}"
            )
    else:
        # Word-by-word animation
        effect_func = {
            'pop': generate_pop_effect,
            'grow': generate_grow_effect,
            'bounce': generate_bounce_effect,
            'elastic': generate_elastic_effect,
            'shake': generate_shake_effect
        }.get(style, generate_pop_effect)

        overlap = preset.get('word_overlap_ms', 50) / 1000

        for word_data in all_words:
            word = word_data['word'].strip()
            start = word_data['start']
            end = word_data['end'] + overlap  # Small overlap for smooth display

            effect_text = effect_func(word, preset)
            events.append(
                f"Dialogue: 0,{format_time_ass(start)},{format_time_ass(end)},{style_name},,0,0,0,,{effect_text}"
            )

    # Write output
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(header)
        f.write('\n'.join(events))

    print(f"Created {output_path} with {len(events)} caption events ({style} style for {platform})")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python kinetic_captions.py transcript.json output.ass [style] [platform]")
        print("Styles: pop, grow, karaoke, bounce, elastic, shake")
        print("Platforms: tiktok, youtube, instagram")
        sys.exit(1)

    transcript = sys.argv[1]
    output = sys.argv[2]
    style = sys.argv[3] if len(sys.argv) > 3 else 'pop'
    platform = sys.argv[4] if len(sys.argv) > 4 else 'tiktok'

    generate_kinetic_captions(transcript, output, style, platform)
```

---

# Section 9: FFmpeg Drawtext Kinetic Effects

For simple text overlays without ASS files, use FFmpeg drawtext expressions.
