# Format/Protocol/Muxer Options

These options belong to **specific muxers/demuxers/protocols**, not the main FFmpeg options. They are passed using `-option value` syntax but only work with their specific format. Unlike main options, they are not position-sensitive in the same way and only apply when the matching format is selected.

## HLS Muxer (Output)

```bash
ffmpeg -i input.mp4 -c copy \
  -hls_time 10 \
  -hls_list_size 6 \
  -hls_segment_filename "seg_%03d.ts" \
  -hls_flags delete_segments \
  playlist.m3u8
```

## Segment Muxer (Output)

```bash
ffmpeg -i input.mp4 -c copy \
  -f segment \
  -segment_time 60 \
  -segment_list playlist.txt \
  -segment_format mp4 \
  output_%03d.mp4
```

## DASH Muxer (Output)

```bash
ffmpeg -i input.mp4 -c copy \
  -f dash \
  -seg_duration 4 \
  -init_seg_name "init_$RepresentationID$.m4s" \
  manifest.mpd
```

## RTSP/RTMP Protocol (Input)

```bash
ffmpeg -rtsp_transport tcp -i "rtsp://server/stream" output.mp4
ffmpeg -rtmp_buffer 1000 -i "rtmp://server/live/stream" output.mp4
```

## Raw Video Input

```bash
ffmpeg -f rawvideo -video_size 1920x1080 -pix_fmt yuv420p -framerate 30 \
  -i input.yuv output.mp4
```

## MP4/MOV Muxer Flags (-movflags)

```bash
# Fast start (move moov atom to beginning for web)
ffmpeg -i input.mp4 -c copy -movflags +faststart output.mp4

# Fragmented MP4 (for DASH/streaming)
ffmpeg -i input.mp4 -c copy -movflags +frag_keyframe+empty_moov output.mp4

# Separate moov atom
ffmpeg -i input.mp4 -c copy -movflags +frag_keyframe+separate_moof output.mp4

# All common streaming flags
ffmpeg -i input.mp4 -c copy \
  -movflags +faststart+frag_keyframe+empty_moov+default_base_moof \
  output.mp4
```

| Flag | Description |
|------|-------------|
| `faststart` | Move moov before mdat (web streaming) |
| `frag_keyframe` | Fragment at each keyframe |
| `empty_moov` | Empty initial moov (DASH) |
| `separate_moof` | Separate moof for each track |
| `default_base_moof` | Base offset at moof (DASH) |
| `negative_cts_offsets` | Allow negative CTS offsets |
| `isml` | IIS Smooth Streaming |
| `omit_tfhd_offset` | Omit offset in tfhd |
| `disable_chpl` | Disable chapter track |
| `write_colr` | Write colr atom |
| `write_gama` | Write gama atom |

## MPEG-TS Muxer

```bash
# MPEG-TS with PCR
ffmpeg -i input.mp4 -c copy -mpegts_copyts 1 output.ts

# Set service info
ffmpeg -i input.mp4 -c copy \
  -mpegts_service_id 1 \
  -mpegts_service_type digital_tv \
  output.ts
```

## Matroska/WebM Muxer

```bash
# Cue points at clusters
ffmpeg -i input.mp4 -c:v libvpx-vp9 -cues_to_front 1 output.webm

# Set cluster size
ffmpeg -i input.mp4 -c copy -cluster_size_limit 2M output.mkv
```
