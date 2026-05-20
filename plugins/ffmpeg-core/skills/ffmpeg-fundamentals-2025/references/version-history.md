# FFmpeg Version History

## Checking Your Version

```bash
# Check installed version
ffmpeg -version

# Check build configuration
ffmpeg -buildconf
```

## Official Sources for Latest Version

- Official Download Page: https://ffmpeg.org/download.html
- Official Git Repository: https://git.ffmpeg.org/gitweb/ffmpeg.git
- GitHub Releases: https://github.com/FFmpeg/FFmpeg/releases

## FFmpeg 8.0.1 (Released 2025-11-20) - Current Latest Stable

The latest stable release from the 8.0 "Huffman" branch (originally cut from master on 2025-08-09). This patch release contains important bug fixes and security updates.

FFmpeg 8.0 is one of the largest releases to date, named after the Huffman code algorithm invented in 1952.

### AI and Transcription

- **Whisper AI Filter**: Built-in speech recognition via whisper.cpp for live subtitle generation and transcription
- Supports 99 languages with automatic language detection
- Outputs to SRT, JSON, or plain text formats
- Voice Activity Detection (VAD) support with Silero VAD

### Vulkan Compute Codecs (Cross-Platform GPU)

- **FFv1 Vulkan**: Encode and decode via Vulkan 1.3 compute shaders
- **ProRes RAW Vulkan**: Hardware-accelerated decode
- **AV1 Vulkan Encoder**: GPU-accelerated AV1 encoding
- **VP9 Vulkan Decoder**: Hardware-accelerated VP9 decode
- Works on any Vulkan 1.3 implementation (AMD, Intel, NVIDIA)

### New Codecs

- **APV Codec**: Samsung Advanced Professional Video encoder (via libopenapv) and native decoder
- **ProRes RAW Decoder**: Native Apple ProRes RAW decode
- **RealVideo 6.0 Decoder**: Native RV6 decode support
- **G.728 Decoder**: Low-delay CELP audio codec
- **Sanyo LD-ADPCM Decoder**: Sanyo audio format
- **ADPCM IMA Xbox Decoder**: Xbox audio format
- **libx265 Alpha Layer Encoding**: HEVC with alpha channel

### Hardware Acceleration

- **VVC VA-API Decoding**: H.266/VVC hardware decode on Intel/AMD Linux
- **VVC QSV Decoding**: Intel Quick Sync VVC hardware decode
- **OpenHarmony Support**: H.264/H.265 encode/decode for HarmonyOS platform

### New Features

- **WHIP Muxer**: Sub-second latency WebRTC ingestion
- **Animated JPEG XL Encoding**: Via libjxl library
- **FLV v2 Support**: Multitrack audio/video and modern codecs
- **VVC in Matroska**: H.266/VVC support in MKV container
- **VVC SCC Support**: Screen Content Coding with IBC, Palette Mode, ACT
- **TLS Verification**: Enabled by default for HTTPS connections

### New Filters

- **whisper**: AI speech recognition filter
- **colordetect**: Detect JPEG/MPEG range and alpha channel properties
- **pad_cuda**: GPU-accelerated padding filter
- **scale_d3d11**: Direct3D 11 hardware scaling filter

### Breaking Changes

- **Dropped**: OpenSSL 1.1.0 support (requires 1.1.1+)
- **Dropped**: yasm assembler support (use nasm instead)
- **Deprecated**: OpenMAX encoders
- **Changed**: Default PNG prediction method set to PAETH
- **Changed**: GCC autovectorization no longer disabled on x86/ARM/AArch64

### Infrastructure

- New Forgejo-based code hosting at code.ffmpeg.org
- Modernized mailing list infrastructure

## FFmpeg 7.1 "Péter" LTS (September 2024)

- **VVC Decoder Stable**: Full native H.266/VVC decoder (production-ready)
- **MV-HEVC Decoder**: 3D HEVC for Apple Vision Pro / iPhone spatial video
- **LC-EVC Decoder**: MPEG-5 Part 2 enhancement layer
- **xHE-AAC Decoder**: Extended High Efficiency AAC
- **Vulkan H.264/H.265 Encoders**: GPU encoding via Vulkan Video
- **Native Intel QSV VVC Decoder**: Hardware-accelerated VVC
- **AVX2 VVC Optimizations**: Faster software VVC decoding
- **Full-Range Color Fixes**: Correct color range handling throughout pipeline

## Staying Up-to-Date

### Why Version Matters

- Security fixes: Patch releases address vulnerabilities
- Bug fixes: Issues with specific codecs or filters get resolved
- New features: Major versions add codec support and filters
- Performance: Optimizations improve encoding speed

### Recommended Update Strategy

1. **Production**: Use LTS releases (7.1) for stability, apply patch updates
2. **Development**: Use latest stable (8.0.1) for new features
3. **Always**: Check release notes before upgrading

### Official Resources

- Release Notes: https://ffmpeg.org/download.html
- Security Advisories: https://ffmpeg.org/security.html
- Mailing Lists: https://ffmpeg.org/contact.html
