# FFmpeg Captions: drawtext Overlays and Whisper AI Integration

Detailed examples for `drawtext` overlays (fonts, positioning, escaping, time expressions, boxes, outlines, animated text) and Whisper AI transcription / subtitle generation workflows in FFmpeg 8.0+ style pipelines. SKILL.md keeps subtitle formats, hardcoded subtitles, soft subtitle tracks, extraction, CEA-608/708, positioning, batch processing, troubleshooting, and best practices.

## Text Overlays (drawtext)

### Basic Text Overlay

```bash
# Simple text overlay
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Hello World':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4

# Centered text
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Centered Text':x=(w-tw)/2:y=(h-th)/2:fontsize=48:fontcolor=white" \
  output.mp4

# Text at bottom center
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Bottom Text':x=(w-tw)/2:y=h-th-20:fontsize=32:fontcolor=white" \
  output.mp4
```

### Styled Text Overlays

```bash
# Text with background box
ffmpeg -i video.mp4 \
  -vf "drawtext=text='With Background':x=10:y=10:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5" \
  output.mp4

# Text with outline (border)
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Outlined Text':x=10:y=10:fontsize=48:fontcolor=white:borderw=3:bordercolor=black" \
  output.mp4

# Shadow effect
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Shadow Text':x=10:y=10:fontsize=36:fontcolor=white:shadowcolor=black:shadowx=3:shadowy=3" \
  output.mp4

# Custom font
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Custom Font':fontfile=/path/to/font.ttf:fontsize=24:fontcolor=white" \
  output.mp4
```

### Dynamic Text

```bash
# Display timestamp
ffmpeg -i video.mp4 \
  -vf "drawtext=text='%{pts\:hms}':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4

# Display frame number
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Frame\: %{n}':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4

# Display current date/time
ffmpeg -i video.mp4 \
  -vf "drawtext=text='%{localtime\:%Y-%m-%d %H\\\:%M\\\:%S}':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4

# Text from file
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=message.txt:x=10:y=10:fontsize=24:fontcolor=white:reload=1" \
  output.mp4
```

### Animated Text

```bash
# Scrolling text (credits)
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=credits.txt:x=(w-tw)/2:y=h-t*50:fontsize=24:fontcolor=white" \
  output.mp4

# Fade in text
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Fade In':x=(w-tw)/2:y=(h-th)/2:fontsize=48:fontcolor=white:alpha='if(lt(t,1),t,1)'" \
  output.mp4

# Text appears at specific time (3 seconds)
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Appears at 3s':x=10:y=10:fontsize=24:fontcolor=white:enable='gte(t,3)'" \
  output.mp4

# Text visible between 2-5 seconds
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Visible 2-5s':x=10:y=10:fontsize=24:fontcolor=white:enable='between(t,2,5)'" \
  output.mp4

# Blinking text
ffmpeg -i video.mp4 \
  -vf "drawtext=text='BLINK':x=10:y=10:fontsize=36:fontcolor=red:alpha='if(mod(floor(t*2),2),1,0)'" \
  output.mp4
```

## Whisper AI Integration (FFmpeg 8.0+)

FFmpeg 8.0 integrates OpenAI's Whisper speech recognition model via whisper.cpp, enabling fully local and offline automatic transcription and subtitle generation.

### Features
- **Speech to Text**: High accuracy transcription
- **Multi-language**: 99 languages supported
- **Flexible Output**: SRT subtitles, JSON, or plain text
- **GPU Acceleration**: Uses system GPU by default
- **Voice Activity Detection**: Silero VAD support for better segmentation
- **Real-time**: Works with live audio streams

### Generate SRT Subtitles

```bash
# Generate subtitles from video using Whisper
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:queue=3:destination=output.srt:format=srt" \
  -f null -

# Specify language for better accuracy
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:destination=english.srt:format=srt" \
  -f null -

# Use larger model for higher quality
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-medium.bin:language=auto:destination=output.srt:format=srt" \
  -f null -
```

### Live Transcription

```bash
# Live transcription from microphone (Linux PulseAudio)
ffmpeg -loglevel warning -f pulse -i default \
  -af "highpass=f=200,lowpass=f=3000,whisper=model=ggml-medium-q5_0.bin:language=en:queue=10:destination=-:format=json:vad_model=for-tests-silero-v5.1.2-ggml.bin" \
  -f null -

# Live transcription from microphone (Windows)
ffmpeg -loglevel warning -f dshow -i audio="Microphone" \
  -af "whisper=model=ggml-base.bin:language=en:queue=10:destination=-:format=text" \
  -f null -

# Live transcription from microphone (macOS)
ffmpeg -loglevel warning -f avfoundation -i ":0" \
  -af "whisper=model=ggml-base.bin:language=en:queue=10:destination=-:format=text" \
  -f null -
```

### Display Live Subtitles on Video

```bash
# Whisper writes to frame metadata, drawtext reads it
ffmpeg -i input.mp4 \
  -af "whisper=model=ggml-base.en.bin:language=en" \
  -vf "drawtext=text='%{metadata\:lavfi.whisper.text}':fontsize=24:fontcolor=white:x=10:y=h-th-10:box=1:boxcolor=black@0.5:boxborderw=5" \
  output_with_subtitles.mp4

# Centered subtitles with styling
ffmpeg -i input.mp4 \
  -af "whisper=model=ggml-base.bin:language=auto" \
  -vf "drawtext=text='%{metadata\:lavfi.whisper.text}':fontsize=32:fontcolor=white:x=(w-tw)/2:y=h-th-50:borderw=2:bordercolor=black" \
  output.mp4
```

### JSON Output for Post-Processing

```bash
# Generate JSON for custom processing
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:destination=output.json:format=json" \
  -f null -
```

### With Voice Activity Detection (VAD)

```bash
# Use Silero VAD for better speech detection
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:queue=20:destination=output.srt:format=srt:vad_model=for-tests-silero-v5.1.2-ggml.bin:vad_threshold=0.5" \
  -f null -

# VAD parameters for noisy audio
ffmpeg -i noisy_video.mp4 -vn \
  -af "whisper=model=ggml-medium.bin:language=en:queue=20:destination=output.srt:format=srt:vad_model=silero.bin:vad_threshold=0.6:vad_min_speech_duration=0.2:vad_min_silence_duration=0.3" \
  -f null -
```

### Disable GPU (CPU-only processing)

```bash
# Force CPU processing (slower but works without GPU)
ffmpeg -i video.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:use_gpu=false:destination=output.srt:format=srt" \
  -f null -
```

### Whisper Models

| Model | Size | Speed | Quality | VRAM | Recommended For |
|-------|------|-------|---------|------|-----------------|
| tiny | 39 MB | Fastest | Basic | ~1 GB | Quick previews, low-resource |
| base | 74 MB | Fast | Good | ~1 GB | General use, balanced |
| small | 244 MB | Medium | Better | ~2 GB | Higher accuracy |
| medium | 769 MB | Slow | High | ~5 GB | Quality-critical |
| large | 1.55 GB | Slowest | Best | ~10 GB | Maximum accuracy |

### Whisper Filter Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `model` | Path to GGML model file | Required |
| `language` | Language code or "auto" | "auto" |
| `format` | Output format: "text", "srt", "json" | "text" |
| `destination` | Output file path or "-" for stdout | Required |
| `queue` | Buffer size in seconds | 3 |
| `vad_model` | Path to Silero VAD model | None |
| `vad_threshold` | VAD sensitivity (0-1) | 0.5 |
| `vad_min_speech_duration` | Min speech duration (seconds) | 0.1 |
| `vad_min_silence_duration` | Min silence duration (seconds) | 0.5 |
| `use_gpu` | Enable GPU acceleration | true |

### Model Download

Download GGML models from the whisper.cpp project:
```bash
# Download base model
curl -L -o ggml-base.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin

# Download medium model for better quality
curl -L -o ggml-medium.bin https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin
```

