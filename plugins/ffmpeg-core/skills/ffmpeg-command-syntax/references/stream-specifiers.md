# Stream Specifiers

Stream specifiers target specific streams for per-stream options. Appended with a colon after the option name.

## Syntax

```text
-option[:stream_specifier] value
```

## Stream Specifier Types

| Specifier | Meaning | Example |
|-----------|---------|---------|
| `:v` | All video streams | `-c:v libx264` |
| `:V` | Video streams (not thumbnails/covers) | `-c:V libx264` |
| `:a` | All audio streams | `-c:a aac` |
| `:s` | All subtitle streams | `-c:s mov_text` |
| `:d` | All data streams | `-c:d copy` |
| `:t` | All attachment streams | `... ` |
| `:v:0` | First video stream | `-b:v:0 5M` |
| `:a:1` | Second audio stream | `-c:a:1 ac3` |
| `:0` | First stream (any type) | `-c:0 copy` |
| `:1` | Second stream (any type) | `-c:1 libx264` |
| `:#0x1234` | Stream with specific PID | `-c:#0x1234 copy` |
| `:i:0x100` | Stream with specific ID | `-c:i:0x100 copy` |
| `:m:key:value` | Stream with matching metadata | `-c:m:language:eng aac` |
| `:p:0` | Streams in program 0 | `-c:p:0 copy` |
| `:u` | Usable configuration streams | `-c:u copy` |

## Input Index Prefix

For multi-input commands, prefix with input index:

```bash
# Stream 0 from input 1
ffmpeg -i a.mp4 -i b.mp4 -map 1:0 -c copy output.mp4

# Video from input 0, audio from input 1
ffmpeg -i video.mp4 -i audio.mp3 -map 0:v -map 1:a output.mp4

# Second audio stream from third input
ffmpeg -i a.mp4 -i b.mp4 -i c.mp4 -map 2:a:1 output.mp4
```

## Per-Stream Option Examples

```bash
# Different codecs per stream type
ffmpeg -i input.mkv -c:v libx264 -c:a aac -c:s mov_text output.mp4

# Different bitrates per stream index
ffmpeg -i input.mkv -map 0 \
  -c:v libx264 -b:v:0 5M \
  -c:a:0 aac -b:a:0 192k \
  -c:a:1 ac3 -b:a:1 384k \
  output.mkv

# Different settings for each audio stream
ffmpeg -i multichannel.mxf -map 0:v:0 -map 0:a:0 -map 0:a:0 \
  -c:a:0 ac3 -b:a:0 640k \
  -ac:a:1 2 -c:a:1 aac -b:a:1 128k \
  output.mp4
```
