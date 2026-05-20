# Common FFmpeg Operations

Recipes for format conversion, scaling, trimming, concatenation, audio operations, subtitles, Whisper transcription, and image operations.

## Format Conversion

```bash
# MP4 to WebM
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm

# MKV to MP4 (no re-encoding)
ffmpeg -i input.mkv -c copy output.mp4

# AVI to MP4 with H.265
ffmpeg -i input.avi -c:v libx265 -crf 28 -c:a aac output.mp4

# GIF to MP4
ffmpeg -i input.gif -movflags +faststart -pix_fmt yuv420p output.mp4

# MP4 to GIF (optimized)
ffmpeg -i input.mp4 -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

## Resolution & Scaling

```bash
# Scale to 1080p (maintain aspect ratio)
ffmpeg -i input.mp4 -vf "scale=1920:-2" output.mp4

# Scale to 720p
ffmpeg -i input.mp4 -vf "scale=-2:720" output.mp4

# Scale to fit within bounds
ffmpeg -i input.mp4 -vf "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease" output.mp4

# Scale with padding (letterbox)
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" output.mp4
```

## Trimming & Splitting

```bash
# Extract segment (fast seek)
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 -c copy output.mp4

# Extract from timestamp to end
ffmpeg -ss 00:05:00 -i input.mp4 -c copy output.mp4

# Extract first 10 seconds
ffmpeg -i input.mp4 -t 10 -c copy output.mp4

# Split into segments
ffmpeg -i input.mp4 -c copy -map 0 -segment_time 60 -f segment output_%03d.mp4

# Accurate trim (re-encode)
ffmpeg -i input.mp4 -ss 00:01:00 -t 00:00:30 -c:v libx264 -c:a aac output.mp4
```

## Concatenation

```bash
# Create file list
echo "file 'part1.mp4'" > list.txt
echo "file 'part2.mp4'" >> list.txt
echo "file 'part3.mp4'" >> list.txt

# Concatenate (same codecs)
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4

# Concatenate with re-encoding
ffmpeg -f concat -safe 0 -i list.txt -c:v libx264 -c:a aac output.mp4
```

## Audio Operations

```bash
# Extract audio
ffmpeg -i input.mp4 -vn -c:a copy output.aac
ffmpeg -i input.mp4 -vn -c:a libmp3lame -b:a 320k output.mp3

# Replace audio
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 output.mp4

# Add audio to video
ffmpeg -i video.mp4 -i audio.mp3 -c:v copy -c:a aac -shortest output.mp4

# Remove audio
ffmpeg -i input.mp4 -an -c:v copy output.mp4

# Adjust volume
ffmpeg -i input.mp4 -af "volume=1.5" output.mp4
ffmpeg -i input.mp4 -af "volume=6dB" output.mp4

# Normalize audio (EBU R128)
ffmpeg -i input.mp4 -af loudnorm=I=-16:TP=-1.5:LRA=11 output.mp4
```

## Subtitles

```bash
# Burn subtitles (hardcode)
ffmpeg -i input.mp4 -vf "subtitles=subs.srt" output.mp4

# Add subtitle track
ffmpeg -i input.mp4 -i subs.srt -c copy -c:s mov_text output.mp4

# Extract subtitles
ffmpeg -i input.mkv -map 0:s:0 output.srt
```

## Whisper AI Transcription (FFmpeg 8.0+)

```bash
# Generate SRT subtitles from video using Whisper
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:queue=3:destination=output.srt:format=srt" \
  -f null -

# Live transcription from microphone
ffmpeg -loglevel warning -f pulse -i default \
  -af "highpass=f=200,lowpass=f=3000,whisper=model=ggml-medium-q5_0.bin:language=en:queue=10:destination=-:format=json:vad_model=for-tests-silero-v5.1.2-ggml.bin" \
  -f null -

# Display live subtitles on video (reads from frame metadata)
ffmpeg -i input.mp4 \
  -af "whisper=model=ggml-base.en.bin:language=en" \
  -vf "drawtext=text='%{metadata\:lavfi.whisper.text}':fontsize=24:fontcolor=white:x=10:y=h-th-10" \
  output_with_subtitles.mp4
```

### Whisper Model Sizes

| Model | Size | Speed | Quality | VRAM |
|-------|------|-------|---------|------|
| tiny | 39 MB | Fastest | Basic | ~1 GB |
| base | 74 MB | Fast | Good | ~1 GB |
| small | 244 MB | Medium | Better | ~2 GB |
| medium | 769 MB | Slow | High | ~5 GB |
| large | 1.55 GB | Slowest | Best | ~10 GB |

### Whisper Filter Parameters

- `model`: Path to GGML model file
- `language`: Language code or "auto" for detection
- `format`: Output format - "text", "srt", or "json"
- `destination`: Output file path (or "-" for stdout)
- `queue`: Buffer size (increase for VAD, e.g., 20)
- `vad_model`: Path to Silero VAD model for voice detection
- `use_gpu`: Set to "false" to disable GPU acceleration

## Image Operations

```bash
# Video to images
ffmpeg -i input.mp4 -vf "fps=1" frame_%04d.png

# Images to video
ffmpeg -framerate 30 -i frame_%04d.png -c:v libx264 -pix_fmt yuv420p output.mp4

# Extract single frame
ffmpeg -ss 00:00:10 -i input.mp4 -vframes 1 thumbnail.jpg

# Create video from single image
ffmpeg -loop 1 -i image.jpg -c:v libx264 -t 10 -pix_fmt yuv420p output.mp4
```

## Output Optimization

### Web Delivery

```bash
# MP4 for web (faststart)
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium -c:a aac -b:a 128k -movflags +faststart output.mp4

# WebM for web
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus -b:a 128k output.webm
```

### iOS/Apple Compatibility

```bash
# H.265 with hvc1 tag (required for Apple)
ffmpeg -i input.mp4 -c:v libx265 -vtag hvc1 -c:a aac output.mp4

# Baseline profile for older iOS
ffmpeg -i input.mp4 -c:v libx264 -profile:v baseline -level 3.0 -c:a aac output.mp4
```

### Android Compatibility

```bash
# Widely compatible H.264
ffmpeg -i input.mp4 -c:v libx264 -profile:v main -level 4.0 -c:a aac output.mp4
```
