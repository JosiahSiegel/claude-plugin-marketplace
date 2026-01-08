---
name: Setup Streaming
description: Set up live streaming with FFmpeg - RTMP, HLS, DASH with optimal encoding settings
argument-hint: <platform: twitch|youtube|hls|rtmp> [source]
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# FFmpeg Streaming Setup

## Purpose
Configure FFmpeg for live streaming to platforms (Twitch, YouTube, Facebook) or custom RTMP/HLS/DASH endpoints.

## Workflow

### 1. Determine Streaming Requirements

Ask user about:
- **Platform**: Twitch, YouTube, Facebook, custom server
- **Input source**: Webcam, screen capture, file, RTMP input
- **Resolution**: 1080p60, 1080p30, 720p60, 720p30
- **Bitrate limits**: Platform restrictions or bandwidth constraints
- **Hardware acceleration**: Available GPU

### 2. Platform-Specific Settings

#### Twitch (Recommended)
```bash
ffmpeg -re -i INPUT \
  -c:v libx264 -preset veryfast -b:v 6000k -maxrate 6000k -bufsize 12000k \
  -g 60 -keyint_min 60 \
  -c:a aac -b:a 160k -ar 44100 \
  -f flv rtmp://live.twitch.tv/app/STREAM_KEY
```

#### YouTube
```bash
ffmpeg -re -i INPUT \
  -c:v libx264 -preset veryfast -b:v 4500k -maxrate 4500k -bufsize 9000k \
  -g 60 -keyint_min 60 \
  -c:a aac -b:a 128k -ar 44100 \
  -f flv rtmp://a.rtmp.youtube.com/live2/STREAM_KEY
```

#### Facebook
```bash
ffmpeg -re -i INPUT \
  -c:v libx264 -preset veryfast -b:v 4000k -maxrate 4000k -bufsize 8000k \
  -g 60 \
  -c:a aac -b:a 128k -ar 44100 \
  -f flv rtmps://live-api-s.facebook.com:443/rtmp/STREAM_KEY
```

### 3. Input Sources

#### Webcam + Microphone (Linux)
```bash
ffmpeg -f v4l2 -framerate 30 -video_size 1920x1080 -i /dev/video0 \
  -f alsa -i default \
  -c:v libx264 -preset ultrafast -tune zerolatency -b:v 4000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

#### Webcam + Microphone (macOS)
```bash
ffmpeg -f avfoundation -framerate 30 -video_size 1920x1080 -i "0:0" \
  -c:v libx264 -preset ultrafast -tune zerolatency -b:v 4000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

#### Screen Capture (Linux)
```bash
ffmpeg -f x11grab -framerate 30 -video_size 1920x1080 -i :0.0 \
  -f pulse -i default \
  -c:v libx264 -preset ultrafast -tune zerolatency -b:v 4000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

#### Screen Capture (Windows)
```bash
ffmpeg -f gdigrab -framerate 30 -i desktop \
  -c:v libx264 -preset ultrafast -tune zerolatency -b:v 4000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

### 4. GPU-Accelerated Streaming

#### NVIDIA NVENC
```bash
ffmpeg -re -i INPUT \
  -c:v h264_nvenc -preset p3 -tune ll -b:v 6000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

#### Intel QSV
```bash
ffmpeg -re -init_hw_device qsv=hw -filter_hw_device hw \
  -i INPUT \
  -c:v h264_qsv -preset fast -b:v 6000k \
  -c:a aac -b:a 128k \
  -f flv rtmp://server/live/stream
```

### 5. HLS Output

```bash
ffmpeg -re -i INPUT \
  -c:v libx264 -preset veryfast -b:v 3000k \
  -c:a aac -b:a 128k \
  -hls_time 4 \
  -hls_list_size 10 \
  -hls_flags delete_segments \
  -hls_segment_filename "segment_%03d.ts" \
  stream.m3u8
```

### 6. Multi-Bitrate ABR

```bash
ffmpeg -re -i INPUT \
  -filter_complex "[0:v]split=3[v1][v2][v3]; \
    [v1]scale=1920:1080[v1out]; \
    [v2]scale=1280:720[v2out]; \
    [v3]scale=854:480[v3out]" \
  -map "[v1out]" -c:v:0 libx264 -b:v:0 5000k \
  -map "[v2out]" -c:v:1 libx264 -b:v:1 2500k \
  -map "[v3out]" -c:v:2 libx264 -b:v:2 1000k \
  -map a:0 -c:a aac -b:a 128k \
  -f hls -hls_time 4 \
  -var_stream_map "v:0,a:0 v:1,a:0 v:2,a:0" \
  -master_pl_name master.m3u8 \
  stream_%v.m3u8
```

### 7. Bitrate Recommendations

| Resolution | Framerate | Min Bitrate | Recommended | Max Bitrate |
|------------|-----------|-------------|-------------|-------------|
| 1080p | 60 | 4500 kbps | 6000 kbps | 9000 kbps |
| 1080p | 30 | 3000 kbps | 4500 kbps | 6000 kbps |
| 720p | 60 | 2500 kbps | 4000 kbps | 6000 kbps |
| 720p | 30 | 1500 kbps | 2500 kbps | 4000 kbps |
| 480p | 30 | 500 kbps | 1000 kbps | 2000 kbps |

## Output

Provide:
1. Complete FFmpeg streaming command for the platform
2. Explanation of key parameters (bitrate, keyframe, etc.)
3. Hardware acceleration options if available
4. Troubleshooting tips for common issues
5. Test command to verify stream before going live
