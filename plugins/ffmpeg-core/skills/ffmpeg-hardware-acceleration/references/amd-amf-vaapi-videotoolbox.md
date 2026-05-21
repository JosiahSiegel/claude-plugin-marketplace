# AMD AMF, VAAPI, and Apple VideoToolbox

## AMD AMF

### Requirements
- AMD GPU (GCN or newer)
- AMD drivers with AMF support
- FFmpeg built with `--enable-amf`

### Detection

```bash
ffmpeg -encoders | grep amf
```

### Basic AMF Encoding

```bash
# H.264 AMF
ffmpeg -i input.mp4 -c:v h264_amf -quality balanced -b:v 5M output.mp4

# H.265/HEVC AMF
ffmpeg -i input.mp4 -c:v hevc_amf -quality balanced -b:v 4M output.mp4

# AV1 AMF (RDNA3+)
ffmpeg -i input.mp4 -c:v av1_amf -quality balanced -b:v 3M output.mp4
```

### AMF Quality Presets

| Preset | Description |
|--------|-------------|
| speed | Fastest encoding |
| balanced | **Recommended** |
| quality | Best quality |

### AMD Hardware Upscaling (FFmpeg 8.0+)

```bash
# Super resolution
ffmpeg -i input.mp4 \
  -vf "sr_amf=4096:2160:algorithm=sr1-1" \
  -c:v hevc_amf output.mp4
```

## VAAPI (Linux)

### Requirements
- Intel, AMD, or NVIDIA GPU on Linux
- VAAPI drivers (intel-media-driver, mesa-va-drivers)
- FFmpeg built with `--enable-vaapi`

### Detection

```bash
vainfo
ffmpeg -encoders | grep vaapi
ffmpeg -decoders | grep vaapi
```

### Basic VAAPI Encoding

```bash
# H.264 VAAPI (upload from CPU)
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi -b:v 5M output.mp4

# H.265/HEVC VAAPI
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi -b:v 4M output.mp4
```

### Full VAAPI Pipeline

```bash
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 -c:v h264_vaapi -b:v 5M output.mp4
```

### VAAPI Scaling

```bash
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 -vf 'scale_vaapi=w=1280:h=720' \
  -c:v h264_vaapi output.mp4
```

### VVC VAAPI Decoding (FFmpeg 8.0+)

FFmpeg 8.0 adds VVC/H.266 hardware decoding on Intel and AMD GPUs via VAAPI.

```bash
# Hardware VVC decoding
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.vvc -c:v h264_vaapi output.mp4

# VVC decode + transcode to H.265
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mkv -c:v hevc_vaapi -b:v 4M output.mp4

# VVC with Screen Content Coding (SCC) support
# FFmpeg 8.0 adds full SCC: IBC, Palette Mode, ACT
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -i screen_recording.vvc output.mp4
```

**VVC VAAPI Requirements:**
- Intel Xe2 graphics (Lunar Lake) or newer for full VVC support
- FFmpeg 8.0 or later
- Intel media driver with VVC support

## Apple VideoToolbox

### Requirements
- macOS 10.8+ or iOS 8+
- FFmpeg built with `--enable-videotoolbox`

### Detection

```bash
ffmpeg -encoders | grep videotoolbox
ffmpeg -decoders | grep videotoolbox
```

### Basic VideoToolbox Encoding

```bash
# H.264 VideoToolbox
ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4

# H.265/HEVC VideoToolbox (Apple-compatible tag)
ffmpeg -i input.mp4 -c:v hevc_videotoolbox -b:v 4M -tag:v hvc1 output.mp4

# ProRes VideoToolbox
ffmpeg -i input.mp4 -c:v prores_videotoolbox -profile:v 3 output.mov
```

### VideoToolbox Quality Settings

```bash
# Quality-based
ffmpeg -i input.mp4 -c:v h264_videotoolbox -q:v 65 output.mp4

# Hardware decode + encode
ffmpeg -hwaccel videotoolbox \
  -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4
```
