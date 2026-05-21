# Audio Analysis & Measurement

Detailed reference for FFmpeg audio measurement filters: astats, ebur128, speechnorm, dialoguenhance, sofalizer, volumedetect, A-weighting, chromaprint, and a complete analysis workflow.

## Audio Statistics (astats)

Measure comprehensive audio statistics including RMS, peak levels, crest factor, bit depth, and DC offset.

```bash
# Full audio statistics
ffmpeg -i input.mp3 -af "astats=metadata=1:reset=1" -f null -

# Output includes:
# - RMS level and peak level
# - Crest factor
# - Dynamic range
# - DC offset
# - Min/Max sample values
# - Number of samples

# Per-channel statistics
ffmpeg -i input.mp3 -af "astats=metadata=1:reset=1:measure_perchannel=all" -f null -

# Measure specific metrics
ffmpeg -i input.mp3 -af "astats=measure_overall=RMS_level+Peak_level:reset=1" -f null -
```

**astats Metrics:**
| Metric | Description |
|--------|-------------|
| `DC_offset` | DC bias in signal |
| `Min_level` | Minimum sample value |
| `Max_level` | Maximum sample value |
| `Min_difference` | Minimum sample-to-sample difference |
| `Max_difference` | Maximum sample-to-sample difference |
| `Mean_difference` | Average sample-to-sample difference |
| `RMS_level` | Root Mean Square level (dB) |
| `Peak_level` | Peak level (dB) |
| `RMS_peak` | RMS peak level |
| `RMS_trough` | RMS trough level |
| `Crest_factor` | Peak to RMS ratio |
| `Flat_factor` | Flatness measure |
| `Peak_count` | Number of samples at peak |
| `Bit_depth` | Actual bit depth used |
| `Dynamic_range` | Dynamic range in dB |

## EBU R128 Loudness Measurement (ebur128)

Comprehensive loudness measurement per EBU R128 / ITU-R BS.1770 standards.

```bash
# Basic loudness measurement
ffmpeg -i input.mp3 -af "ebur128=peak=true" -f null -

# Output includes:
# - Momentary loudness (M)
# - Short-term loudness (S)
# - Integrated loudness (I)
# - Loudness Range (LRA)
# - True Peak (dBTP)

# Frame-by-frame measurement
ffmpeg -i input.mp3 -af "ebur128=framelog=verbose:peak=true" -f null - 2>&1 | grep Summary

# Generate loudness graph (PNG)
ffmpeg -i input.mp3 \
  -filter_complex "ebur128=video=1:meter=18:gauge=1[v];[v]scale=1280:720[out]" \
  -map "[out]" \
  -frames:v 1 \
  loudness_graph.png

# Create loudness monitoring video
ffmpeg -i input.mp3 \
  -filter_complex "ebur128=video=1:meter=18:gauge=1:scale=absolute[v]" \
  -map "[v]" -map 0:a \
  -c:a copy \
  loudness_monitor.mp4

# Measure with dual mono (speech)
ffmpeg -i input.mp3 -af "ebur128=dualmono=1:peak=true" -f null -
```

**ebur128 Parameters:**
| Parameter | Description | Values |
|-----------|-------------|--------|
| `video` | Generate video output | 0 or 1 |
| `meter` | Loudness meter level | 9, 12, 18 |
| `gauge` | Show gauge overlay | 0 or 1 |
| `scale` | Scale type | `absolute`, `relative` |
| `peak` | Measure true peak | `true`, `sample`, `none` |
| `dualmono` | Dual mono mode | 0 or 1 |
| `framelog` | Logging level | `quiet`, `info`, `verbose` |

## Speech Normalization (speechnorm)

Specialized normalizer for speech content that adapts to dynamic speech patterns.

```bash
# Basic speech normalization
ffmpeg -i speech.mp3 -af "speechnorm" output.mp3

# Speech normalization with custom parameters
ffmpeg -i speech.mp3 \
  -af "speechnorm=p=0.95:m=10:r=0.0005:l=1" \
  output.mp3

# Aggressive speech normalization
ffmpeg -i speech.mp3 \
  -af "speechnorm=p=0.9:e=15:r=0.001:l=1" \
  output.mp3

# Podcast processing with speech normalization
ffmpeg -i podcast.wav \
  -af "highpass=f=80,speechnorm=p=0.95:e=12.5:r=0.0005,loudnorm=I=-16:TP=-1.5" \
  -c:a aac -b:a 96k \
  podcast.m4a
```

**speechnorm Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `p` | Peak value target | 0.95 | 0-1 |
| `e` | Expansion factor | 12.5 | 1-50 |
| `r` | Rise time (speed of increase) | 0.0005 | 0-1 |
| `f` | Fall time (speed of decrease) | 0.001 | 0-1 |
| `c` | Compression factor | 0 | 0-1 |
| `l` | Link channels | 0 | 0 or 1 |

## Dialogue Enhancement (dialoguenhance) - FFmpeg 8.0+

Enhance dialogue clarity by separating and boosting voice frequencies.

```bash
# Basic dialogue enhancement
ffmpeg -i input.mp4 -af "dialoguenhance" -c:v copy output.mp4

# Custom dialogue enhancement
ffmpeg -i input.mp4 \
  -af "dialoguenhance=original=0.3:enhance=0.7:voice=0.8" \
  -c:v copy output.mp4

# Heavy enhancement for poor recordings
ffmpeg -i input.mp4 \
  -af "dialoguenhance=original=0.2:enhance=0.9" \
  -c:v copy output.mp4
```

**dialoguenhance Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `original` | Original signal mix | 1 | 0-1 |
| `enhance` | Enhanced signal mix | 1 | 0-1 |
| `voice` | Voice clarity boost | 2 | 2-32 |

## 3D Audio / Binaural (sofalizer)

Apply HRTF (Head-Related Transfer Function) for 3D audio and binaural processing using SOFA files.

```bash
# Basic binaural conversion (requires SOFA file)
ffmpeg -i surround.ac3 \
  -af "sofalizer=sofa=/path/to/hrtf.sofa" \
  binaural.mp3

# With custom gain and rotation
ffmpeg -i surround.ac3 \
  -af "sofalizer=sofa=/path/to/hrtf.sofa:gain=0:rotation=0" \
  binaural.mp3

# Binaural conversion with elevation
ffmpeg -i surround.ac3 \
  -af "sofalizer=sofa=/path/to/hrtf.sofa:elevation=0:radius=1" \
  binaural.mp3
```

**SOFA Files:**
- Download HRTF databases from: https://sofacoustics.org/data/database/
- Common formats: CIPIC, MIT KEMAR, LISTEN databases

**sofalizer Parameters:**
| Parameter | Description | Range |
|-----------|-------------|-------|
| `sofa` | Path to SOFA file | - |
| `gain` | Additional gain (dB) | -20 to 40 |
| `rotation` | Head rotation (degrees) | -360 to 360 |
| `elevation` | Head elevation (degrees) | -90 to 90 |
| `radius` | Distance scaling | 0 to 3 |
| `type` | Interpolation type | `time`, `freq` |

## Volume Detection

```bash
# Detect volume levels
ffmpeg -i input.mp3 -af "volumedetect" -f null -

# Output includes:
# - mean_volume (average)
# - max_volume (peak)
# - histogram data
```

## A-Weighting (aweighting)

Apply A-weighting curve for perceived loudness measurement.

```bash
# Apply A-weighting filter
ffmpeg -i input.mp3 -af "aweighting" output_aweighted.wav

# Measure A-weighted levels
ffmpeg -i input.mp3 -af "aweighting,astats=measure_overall=RMS_level" -f null -
```

## Audio Fingerprinting (chromaprint)

Generate audio fingerprints for identification.

```bash
# Generate chromaprint fingerprint
ffmpeg -i input.mp3 -f chromaprint -fp_format raw fingerprint.txt

# Generate Base64 fingerprint
ffmpeg -i input.mp3 -f chromaprint -fp_format base64 - 2>&1 | grep FINGERPRINT
```

## Complete Analysis Workflow

```bash
#!/bin/bash
# audio-analysis.sh - Complete audio analysis

INPUT="$1"

echo "=== Audio Analysis Report ==="
echo "File: $INPUT"
echo ""

echo "--- Basic Statistics ---"
ffmpeg -i "$INPUT" -af "astats=measure_overall=all" -f null - 2>&1 | grep -A 50 "Parsed_astats"

echo ""
echo "--- Loudness (EBU R128) ---"
ffmpeg -i "$INPUT" -af "ebur128=peak=true" -f null - 2>&1 | grep -E "(Summary|I:|LRA:|Peak:)"

echo ""
echo "--- Volume Detection ---"
ffmpeg -i "$INPUT" -af "volumedetect" -f null - 2>&1 | grep -E "(mean_volume|max_volume)"

echo ""
echo "--- Silence Detection ---"
ffmpeg -i "$INPUT" -af "silencedetect=noise=-50dB:d=0.5" -f null - 2>&1 | grep silence
```
