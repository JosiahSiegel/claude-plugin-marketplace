# FFmpeg Master Plugin

FFmpeg Master is a meta-bundle plugin. Installing it auto-installs the focused FFmpeg sub-plugins listed below. The router plugin intentionally owns no agents, commands, or domain skills; use the sub-plugins directly when you want narrower trigger surfaces, or install this bundle for the full suite.

## Included sub-plugins

| Sub-plugin | Covers |
|------------|--------|
| `ffmpeg-core` | Encoding, transcoding, command syntax, codecs, audio, subtitles, ffprobe diagnostics, restoration, hardware acceleration |
| `ffmpeg-effects` | Creative filtergraphs, transitions, color/chromakey, shapes, overlays, glitch effects, karaoke, kinetic captions, waveforms |
| `ffmpeg-platforms` | Streaming, Docker, Modal.com serverless, Cloudflare, WebAssembly, CI/CD, production media runtimes |
| `ffmpeg-python` | PyAV, ffmpeg-python mappings, subprocess patterns, OpenCV/cv2 frame pipelines, ML video integration |
| `ffmpeg-social-video` | TikTok, YouTube Shorts, Reels, vertical exports, platform specs, viral hooks, animated captions, batch social output |

## Installation

```bash
claude plugin add ffmpeg-master
```

Claude Code installs and enables the dependency sub-plugins automatically on supported versions.

## Prefer direct installation for focused work

```bash
claude plugin add ffmpeg-core
claude plugin add ffmpeg-effects
claude plugin add ffmpeg-platforms
claude plugin add ffmpeg-python
claude plugin add ffmpeg-social-video
```

## License

MIT
