# Professional Workflows & Troubleshooting

Self-contained processing chains for common production scenarios, plus quick fixes for typical post-processing issues.

## Professional Workflows

### Podcast Processing

```bash
# Complete podcast processing chain
ffmpeg -i raw_podcast.wav \
  -af "highpass=f=80,\
       acompressor=threshold=-20dB:ratio=4:attack=5:release=50,\
       loudnorm=I=-16:TP=-1.5:LRA=11,\
       silenceremove=start_periods=1:start_silence=1:start_threshold=-50dB" \
  -c:a aac -b:a 96k \
  podcast.m4a
```

### Music Mastering Chain

```bash
# Mastering chain
ffmpeg -i mix.wav \
  -af "equalizer=f=60:width_type=o:width=1:g=1,\
       equalizer=f=12000:width_type=o:width=1:g=0.5,\
       acompressor=threshold=-12dB:ratio=2:attack=20:release=200,\
       alimiter=limit=0.95,\
       loudnorm=I=-14:TP=-1:LRA=9" \
  -c:a flac \
  master.flac
```

### Broadcast Normalization

```bash
# EBU R128 broadcast compliance
ffmpeg -i input.wav \
  -af "loudnorm=I=-23:TP=-1:LRA=11:dual_mono=true" \
  -ar 48000 \
  -c:a pcm_s24le \
  broadcast.wav
```

## Troubleshooting

### Common Issues

**"loudnorm resamples to 192kHz"**
```bash
# Force output sample rate
ffmpeg -i input.mp3 \
  -af loudnorm=I=-16:TP=-1.5:LRA=11 \
  -ar 48000 \
  output.mp3
```

**Audio/video sync after processing**
```bash
# Maintain sync with video
ffmpeg -i video.mp4 \
  -af "loudnorm=I=-16:TP=-1.5:LRA=11,aresample=async=1" \
  -c:v copy \
  output.mp4
```

**Quality loss from re-encoding**
- Use lossless intermediate format (FLAC, WAV)
- Avoid multiple lossy conversions
- Use high bitrates for final lossy encode
