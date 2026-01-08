# Vulkan Compute Codecs in FFmpeg 8.0

FFmpeg 8.0 introduced Vulkan compute-based video codecs, enabling cross-platform GPU acceleration without vendor-specific APIs.

## What's New in FFmpeg 8.0

- **FFv1 Vulkan**: Encode and decode via Vulkan 1.3 compute shaders
- **ProRes RAW Vulkan**: Hardware-accelerated decode
- **AV1 Vulkan Encoder**: GPU-accelerated AV1 encoding
- **VP9 Vulkan Decoder**: Hardware-accelerated VP9 decode

## Requirements

- Vulkan 1.3 compatible GPU and drivers
- FFmpeg 8.0+ built with Vulkan support

## Check Vulkan Support

```bash
# Check for Vulkan hardware acceleration
ffmpeg -hwaccels | grep vulkan

# List Vulkan devices
ffmpeg -init_hw_device vulkan -v verbose 2>&1 | grep -i vulkan

# Check Vulkan encoders
ffmpeg -encoders | grep vulkan

# Check Vulkan decoders
ffmpeg -decoders | grep vulkan
```

## FFv1 Vulkan Codec

FFv1 is a lossless video codec, now with Vulkan acceleration.

### Encoding

```bash
# FFv1 Vulkan encoding
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -c:v ffv1_vulkan \
  output.mkv

# With specific GPU selection
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk:0 -filter_hw_device vk \
  -c:v ffv1_vulkan \
  output.mkv
```

### Decoding

```bash
# FFv1 Vulkan decoding
ffmpeg -hwaccel vulkan \
  -i input_ffv1.mkv \
  -c:v libx264 -crf 18 \
  output.mp4
```

## AV1 Vulkan Encoder

```bash
# AV1 Vulkan encoding
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -c:v av1_vulkan \
  output.webm

# With quality settings
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -c:v av1_vulkan -b:v 5M \
  output.webm
```

## VP9 Vulkan Decoder

```bash
# VP9 Vulkan decoding to H.264
ffmpeg -hwaccel vulkan \
  -i input.webm \
  -c:v libx264 -crf 20 \
  output.mp4

# Keep in GPU for further processing
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm \
  -vf "scale_vulkan=w=1920:h=1080" \
  -c:v av1_vulkan \
  output.mp4
```

## ProRes RAW Vulkan Decoder

```bash
# ProRes RAW Vulkan decoding
ffmpeg -hwaccel vulkan \
  -i input.braw \
  -c:v libx264 -crf 18 \
  output.mp4
```

## Hardware Device Initialization

### Auto-select GPU

```bash
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i input.mp4 ...
```

### Select Specific GPU

```bash
# First GPU (index 0)
ffmpeg -init_hw_device vulkan=vk:0 -filter_hw_device vk \
  -i input.mp4 ...

# Second GPU (index 1)
ffmpeg -init_hw_device vulkan=vk:1 -filter_hw_device vk \
  -i input.mp4 ...
```

### List Available GPUs

```bash
# Show Vulkan device info
ffmpeg -init_hw_device vulkan=vk -v verbose 2>&1 | grep -E "device|GPU"
```

## Vulkan Filters

FFmpeg includes Vulkan-based video filters:

```bash
# Vulkan scale filter
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "scale_vulkan=w=1920:h=1080" \
  -c:v av1_vulkan \
  output.mp4

# Vulkan color conversion
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "format_vulkan=pix_fmts=p010" \
  -c:v av1_vulkan \
  output.mp4
```

## Cross-Platform Compatibility

Vulkan works on:

| Platform | AMD | NVIDIA | Intel |
|----------|-----|--------|-------|
| Linux | Yes | Yes | Yes |
| Windows | Yes | Yes | Yes |
| macOS | Via MoltenVK | N/A | N/A |

## Performance Comparison

| Codec | API | Relative Speed |
|-------|-----|----------------|
| H.264 | NVENC | 1x |
| H.264 | Vulkan | 0.8-0.9x |
| FFv1 | CPU | 1x |
| FFv1 | Vulkan | 3-5x |
| AV1 | libaom (CPU) | 1x |
| AV1 | Vulkan | 10-15x |

## Best Practices

1. **Use Vulkan when**:
   - You need cross-platform GPU acceleration
   - Vendor-specific APIs (NVENC, QSV) aren't available
   - Working with FFv1 lossless compression

2. **Prefer vendor APIs when**:
   - Maximum performance is critical
   - You're on a single platform
   - Using established codecs (H.264, H.265)

3. **Memory considerations**:
   ```bash
   # Keep processing on GPU to avoid transfers
   ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
     -i input.mp4 \
     -vf "scale_vulkan=1920:1080" \
     -c:v av1_vulkan \
     output.mp4
   ```

## Troubleshooting

### "Vulkan not available"
- Install/update GPU drivers
- Ensure Vulkan 1.3 support
- Check FFmpeg was built with `--enable-vulkan`

### Poor performance
- Ensure `hwaccel_output_format vulkan` to keep data on GPU
- Use Vulkan filters instead of CPU filters
- Try different GPU if multiple available

### Encoding errors
- Check input pixel format compatibility
- Try adding explicit format conversion
- Verify GPU memory availability

## Example Pipelines

### Lossless Archival with FFv1

```bash
# Fast lossless encoding for archival
ffmpeg -i source.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -c:v ffv1_vulkan \
  -c:a flac \
  archive.mkv
```

### Web Delivery with AV1

```bash
# AV1 encoding for web
ffmpeg -i source.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -c:v av1_vulkan -b:v 3M \
  -c:a libopus -b:a 128k \
  output.webm
```

### Transcode VP9 to AV1

```bash
# VP9 decode + AV1 encode (all on GPU)
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm \
  -c:v av1_vulkan -b:v 3M \
  -c:a copy \
  output.mp4
```
