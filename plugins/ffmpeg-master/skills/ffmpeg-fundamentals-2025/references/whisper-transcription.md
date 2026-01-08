# Whisper AI Transcription with FFmpeg 8.0

FFmpeg 8.0 introduced the `whisper` audio filter for automatic speech recognition, powered by whisper.cpp.

## Requirements

- FFmpeg 8.0 or later built with whisper.cpp support
- GGML model file (download from Hugging Face)

## Verify Support

```bash
# Check FFmpeg version
ffmpeg -version  # Should show 8.0+

# Check for whisper filter
ffmpeg -filters | grep whisper
```

## Download Models

Models are in GGML format from whisper.cpp:

```bash
# Base model (~150MB, good balance)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin

# Medium model (~500MB, better accuracy)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium.bin

# Large model (~1.5GB, best accuracy)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large.bin

# Quantized models (smaller, faster)
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base-q5_0.bin
wget https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-medium-q5_0.bin
```

## Model Comparison

| Model | Size | VRAM | Speed | Quality |
|-------|------|------|-------|---------|
| tiny | 39 MB | ~1 GB | 32x | Basic |
| tiny.en | 39 MB | ~1 GB | 32x | Better (English) |
| base | 74 MB | ~1 GB | 16x | Good |
| base.en | 74 MB | ~1 GB | 16x | Better (English) |
| small | 244 MB | ~2 GB | 6x | Better |
| small.en | 244 MB | ~2 GB | 6x | Better (English) |
| medium | 769 MB | ~5 GB | 2x | High |
| medium.en | 769 MB | ~5 GB | 2x | Best (English) |
| large | 1.55 GB | ~10 GB | 1x | Best |

## Basic Usage

### Generate SRT Subtitles

```bash
# From video file
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:format=srt" \
  -f srt output.srt

# Specify language for better accuracy
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:format=srt" \
  -f srt output.srt
```

### Generate VTT Subtitles

```bash
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:format=vtt" \
  -f webvtt output.vtt
```

### Generate JSON Output

```bash
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:format=json" \
  -f null - 2>&1 | grep -o '{.*}'
```

## Filter Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| model | Path to GGML model file | (required) |
| language | ISO language code or "auto" | auto |
| format | Output format: text, srt, json | text |
| destination | Output file path (or "-" for stdout) | - |
| translate | Translate to English (0/1) | 0 |
| queue | Buffer size (frames) | 3 |
| use_gpu | Enable GPU acceleration (0/1) | 1 |
| vad_model | Path to Silero VAD model | (none) |

## Advanced Examples

### Translate to English

```bash
# Translate any language to English
ffmpeg -i foreign_video.mp4 -vn \
  -af "whisper=model=ggml-medium.bin:language=auto:translate=1:format=srt" \
  -f srt english_subs.srt
```

### With Voice Activity Detection (VAD)

```bash
# Download Silero VAD model
wget https://github.com/snakers4/silero-vad/raw/master/files/for-tests-silero-v5.1.2-ggml.bin

# Use VAD for better segmentation
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-medium.bin:language=en:queue=20:vad_model=for-tests-silero-v5.1.2-ggml.bin:format=srt" \
  -f srt output.srt
```

### Live Transcription from Microphone

```bash
# Linux (PulseAudio)
ffmpeg -loglevel warning -f pulse -i default \
  -af "highpass=f=200,lowpass=f=3000,whisper=model=ggml-base.bin:language=en:format=text" \
  -f null -

# macOS (AVFoundation)
ffmpeg -loglevel warning -f avfoundation -i ":0" \
  -af "whisper=model=ggml-base.bin:language=en:format=text" \
  -f null -
```

### Burn Subtitles into Video

```bash
# Two-pass approach (recommended)
# 1. Generate SRT
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:format=srt" \
  -f srt subs.srt

# 2. Burn into video
ffmpeg -i input.mp4 -vf "subtitles=subs.srt" \
  -c:v libx264 -crf 20 -c:a copy \
  output_with_subs.mp4
```

### Display Live Subtitles (Frame Metadata)

```bash
# Whisper writes text to frame metadata
ffmpeg -i input.mp4 \
  -af "whisper=model=ggml-base.en.bin:language=en" \
  -vf "drawtext=text='%{metadata\\:lavfi.whisper.text}':fontsize=24:fontcolor=white:x=10:y=h-th-10:box=1:boxcolor=black@0.5" \
  -c:v libx264 -crf 20 -c:a aac \
  output_with_live_subs.mp4
```

## Performance Optimization

### For Long Videos

```bash
# Extract audio first (faster processing)
ffmpeg -i input.mp4 -vn -c:a pcm_s16le -ar 16000 -ac 1 audio.wav

# Process audio separately
ffmpeg -i audio.wav \
  -af "whisper=model=ggml-base.bin:language=en:format=srt" \
  -f srt output.srt

# Clean up
rm audio.wav
```

### GPU Acceleration

```bash
# Enable GPU (if supported)
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:use_gpu=1:format=srt" \
  -f srt output.srt

# Disable GPU (force CPU)
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:use_gpu=0:format=srt" \
  -f srt output.srt
```

### Use Quantized Models

```bash
# Quantized models are smaller and faster
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-medium-q5_0.bin:language=en:format=srt" \
  -f srt output.srt
```

## Audio Preprocessing

For better accuracy, clean up audio before transcription:

```bash
# Noise reduction and normalization
ffmpeg -i input.mp4 -vn \
  -af "afftdn=nf=-25,loudnorm=I=-16:TP=-1.5:LRA=11,whisper=model=ggml-base.bin:language=en:format=srt" \
  -f srt output.srt

# High-pass and low-pass for speech
ffmpeg -i input.mp4 -vn \
  -af "highpass=f=200,lowpass=f=3000,whisper=model=ggml-base.bin:language=en:format=srt" \
  -f srt output.srt
```

## Supported Languages

Whisper supports 99 languages. Common codes:
- en: English
- es: Spanish
- fr: French
- de: German
- zh: Chinese
- ja: Japanese
- ko: Korean
- pt: Portuguese
- ru: Russian
- ar: Arabic
- auto: Automatic detection

## Troubleshooting

### "Filter whisper not found"
FFmpeg not built with whisper.cpp support. Use a build that includes it or compile from source.

### Poor accuracy
- Try a larger model (medium or large)
- Specify the language explicitly
- Apply audio preprocessing
- Use VAD for better segmentation

### Slow processing
- Use a smaller or quantized model
- Enable GPU acceleration
- Extract audio first for long videos

### Memory errors
- Use a smaller model
- Process in segments
- Disable GPU if VRAM is limited
