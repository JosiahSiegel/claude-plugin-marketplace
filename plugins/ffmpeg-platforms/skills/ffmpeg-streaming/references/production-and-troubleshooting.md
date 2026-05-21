# FFmpeg Streaming: Multicast, Re-streaming, Production Patterns & Troubleshooting

Multicast streaming setup, protocol re-streaming (RTMP/HLS/DASH/SRT conversion), production patterns (encoder profiles, ABR ladders, monitoring), and a streaming troubleshooting catalogue. SKILL.md keeps protocol overviews and per-protocol setup (RTMP, HLS, DASH, SRT, WebRTC/WHIP); this reference holds the broader networking and production material.

## Multicast Streaming

### UDP Multicast

```bash
# Send multicast
ffmpeg -re -i input.mp4 \
  -c:v libx264 -c:a aac \
  -f mpegts "udp://239.0.0.1:1234?pkt_size=1316"

# Receive multicast
ffmpeg -i "udp://239.0.0.1:1234" -c copy output.mp4
```

## Re-streaming (Protocol Conversion)

### RTMP to HLS

```bash
# Receive RTMP, output HLS
ffmpeg -i rtmp://source/live/stream \
  -c:v libx264 -preset veryfast \
  -c:a aac \
  -hls_time 4 \
  -hls_list_size 10 \
  -hls_flags delete_segments \
  /var/www/html/hls/stream.m3u8
```

### SRT to RTMP

```bash
ffmpeg -i "srt://0.0.0.0:9000?mode=listener" \
  -c copy \
  -f flv rtmp://destination/live/stream
```

### RTMP to Multiple Destinations

```bash
ffmpeg -i rtmp://source/live/stream \
  -c copy -f flv rtmp://youtube/live/key1 \
  -c copy -f flv rtmp://twitch/app/key2 \
  -c copy -f flv rtmp://facebook/rtmp/key3
```

## Production Patterns

### nginx-rtmp Integration

```nginx
# nginx.conf
rtmp {
    server {
        listen 1935;
        application live {
            live on;
            exec_push ffmpeg -i rtmp://localhost/live/$name
                -c:v libx264 -preset veryfast -b:v 3000k
                -c:a aac -b:a 128k
                -hls_time 4
                -hls_list_size 10
                -hls_flags delete_segments
                /var/www/html/hls/$name.m3u8;
        }
    }
}
```

### Docker Streaming Setup

```yaml
# docker-compose.yml
version: '3.8'

services:
  rtmp:
    image: tiangolo/nginx-rtmp
    ports:
      - "1935:1935"
      - "8080:8080"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf

  transcoder:
    image: jrottenberg/ffmpeg:7.1-ubuntu2404
    depends_on:
      - rtmp
    command: >
      -i rtmp://rtmp:1935/live/stream
      -c:v libx264 -preset veryfast
      -c:a aac
      -hls_time 4
      -f hls /output/stream.m3u8
    volumes:
      - ./output:/output
```

### Monitoring & Logging

```bash
# Enable detailed logging
ffmpeg -report -i input.mp4 -f flv rtmp://server/live/stream

# Real-time stats
ffmpeg -re -i input.mp4 \
  -progress pipe:1 \
  -c:v libx264 -c:a aac \
  -f flv rtmp://server/live/stream

# Write stats to file
ffmpeg -re -i input.mp4 \
  -progress stats.txt \
  -c:v libx264 -c:a aac \
  -f flv rtmp://server/live/stream
```

## Troubleshooting

### Common Issues

**"Connection refused"**
```bash
# Check server is reachable
nc -zv server 1935

# Test with simple stream
ffmpeg -re -f lavfi -i testsrc=size=1280x720:rate=30 \
  -f flv rtmp://server/live/test
```

**Buffer underrun/overrun**
```bash
# Increase buffer size
ffmpeg -re -i input.mp4 \
  -b:v 3000k -maxrate 3000k -bufsize 6000k \
  -f flv rtmp://server/live/stream
```

**High latency**
```bash
# Reduce latency settings
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset ultrafast -tune zerolatency \
  -g 30 -keyint_min 30 \
  -f flv rtmp://server/live/stream
```

**Packet drops**
```bash
# Increase receive buffer (SRT)
ffmpeg -i "srt://server:9000?rcvbuf=8192000" -c copy output.mp4

# Increase buffer for UDP
ffmpeg -buffer_size 8192000 -i udp://239.0.0.1:1234 -c copy output.mp4
```

