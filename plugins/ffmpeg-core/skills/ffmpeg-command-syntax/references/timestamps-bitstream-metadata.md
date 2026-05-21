# Timestamps, Bitstream Filters, Metadata, Attachments, Disposition

Reference for advanced packet-level and container-level options.

## Advanced Timestamp Handling

```bash
# Copy timestamps exactly from input
ffmpeg -copyts -i input.mp4 -c copy output.mp4

# Shift timestamps to start at zero
ffmpeg -start_at_zero -i input.mp4 -c copy output.mp4

# Both: copy but start at zero
ffmpeg -copyts -start_at_zero -i input.mp4 -c copy output.mp4

# Offset input timestamps
ffmpeg -itsoffset 5 -i input.mp4 -c copy output.mp4  # Delay by 5 seconds

# Scale input timestamps (2x speed)
ffmpeg -itsscale 0.5 -i input.mp4 -c copy output.mp4

# Handle negative timestamps
ffmpeg -i input.mp4 -avoid_negative_ts make_zero output.mp4
```

### Timestamp Modes

| Mode | Description |
|------|-------------|
| `make_non_negative` | Shift timestamps to be non-negative |
| `make_zero` | Shift to start at exactly zero |
| `auto` | Auto-select based on format |
| `disabled` | Don't adjust timestamps |

## Bitstream Filters (-bsf)

```bash
# Extract AnnexB NAL units for H.264
ffmpeg -i input.mp4 -c:v copy -bsf:v h264_mp4toannexb output.h264

# Add SEI recovery point for broadcast
ffmpeg -i input.mp4 -c:v copy -bsf:v h264_redundant_pps output.mp4

# HEVC HVC1 to HEV1
ffmpeg -i input.mp4 -c:v copy -bsf:v hevc_mp4toannexb output.hevc

# Insert ADTS headers for AAC
ffmpeg -i input.mp4 -c:a copy -bsf:a aac_adtstoasc output.aac

# Remove filler data
ffmpeg -i input.mp4 -c:v copy -bsf:v filter_units=remove_types=6 output.mp4

# Metadata injection
ffmpeg -i input.mp4 -c:v copy -bsf:v h264_metadata=level=4.1 output.mp4
```

### Common Bitstream Filters

| Filter | Description |
|--------|-------------|
| `h264_mp4toannexb` | Convert H.264 to AnnexB format |
| `hevc_mp4toannexb` | Convert HEVC to AnnexB format |
| `aac_adtstoasc` | Convert AAC ADTS to ASC |
| `extract_extradata` | Extract codec extradata |
| `h264_redundant_pps` | Add redundant PPS |
| `h264_metadata` | Modify H.264 metadata |
| `hevc_metadata` | Modify HEVC metadata |
| `filter_units` | Filter NAL units |
| `dump_extra` | Dump extradata to packets |
| `prores_metadata` | Modify ProRes metadata |
| `vp9_superframe` | VP9 superframe handling |
| `av1_metadata` | Modify AV1 metadata |

## Metadata Mapping (-map_metadata)

### Syntax

```bash
-map_metadata[:metadata_spec_out] infile[:metadata_spec_in]
```

### Metadata Specifiers

| Specifier | Target |
|-----------|--------|
| `g` | Global file metadata |
| `s:stream_index` | Stream metadata |
| `s:v` / `s:a` / `s:s` | All video/audio/subtitle streams |
| `c:chapter_index` | Chapter metadata |
| `p:program_index` | Program metadata |

### Examples

```bash
# Copy all metadata from input to output
ffmpeg -i input.mp4 -map_metadata 0 -c copy output.mp4

# Copy global metadata only
ffmpeg -i input.mp4 -map_metadata:g 0:g -c copy output.mp4

# Strip all metadata
ffmpeg -i input.mp4 -map_metadata -1 -c copy output.mp4

# Copy metadata from second input file
ffmpeg -i video.mp4 -i metadata_source.mp4 -map 0 -map_metadata 1 -c copy output.mp4

# Copy stream metadata from input stream 0 to output stream 0
ffmpeg -i input.mp4 -map_metadata:s:0 0:s:0 -c copy output.mp4

# Copy chapter metadata
ffmpeg -i input.mp4 -map_metadata:c 0:c -map_chapters 0 -c copy output.mp4

# Copy all metadata, but set specific values
ffmpeg -i input.mp4 -map_metadata 0 -metadata title="New Title" -c copy output.mp4
```

### Metadata Manipulation

```bash
# Add/modify metadata
ffmpeg -i input.mp4 -metadata title="Video Title" -metadata artist="Creator" output.mp4

# Set stream-specific metadata
ffmpeg -i input.mp4 -metadata:s:v:0 title="Main Video" -metadata:s:a:0 language=eng output.mp4

# Set chapter metadata
ffmpeg -i input.mp4 -metadata:c:0 title="Chapter 1" output.mp4

# Remove specific metadata (set to empty)
ffmpeg -i input.mp4 -metadata comment= -c copy output.mp4
```

## Attachments

### Adding (-attach)

```bash
# Attach font file (for subtitles)
ffmpeg -i input.mkv -attach DejaVuSans.ttf \
  -metadata:s:t:0 mimetype=application/x-truetype-font \
  -c copy output.mkv

# Attach cover art
ffmpeg -i input.mp4 -attach cover.jpg \
  -metadata:s:t:0 mimetype=image/jpeg \
  -c copy output.mkv

# Multiple attachments
ffmpeg -i input.mkv \
  -attach font1.ttf -metadata:s:t:0 mimetype=application/x-truetype-font \
  -attach font2.ttf -metadata:s:t:1 mimetype=application/x-truetype-font \
  -c copy output.mkv
```

### Extracting (-dump_attachment)

```bash
# Extract first attachment to specific file
ffmpeg -dump_attachment:t:0 extracted_font.ttf -i input.mkv

# Extract all attachments (uses filename metadata)
ffmpeg -dump_attachment:t "" -i input.mkv

# Extract specific stream by index
ffmpeg -dump_attachment:3 attachment.bin -i input.mkv
```

## Disposition Flags

```bash
# Set stream as default
ffmpeg -i input.mkv -c copy -disposition:a:0 default output.mkv

# Set as default and forced subtitle
ffmpeg -i input.mkv -c copy -disposition:s:0 default+forced output.mkv

# Clear all dispositions
ffmpeg -i input.mkv -c copy -disposition:a:1 0 output.mkv

# Multiple dispositions
ffmpeg -i input.mkv -c copy \
  -disposition:v:0 default \
  -disposition:a:0 default \
  -disposition:a:1 0 \
  output.mkv
```

### Disposition Values

| Value | Description |
|-------|-------------|
| `default` | Default stream for playback |
| `dub` | Dubbed audio track |
| `original` | Original language |
| `comment` | Commentary track |
| `lyrics` | Lyrics track |
| `karaoke` | Karaoke version |
| `forced` | Forced subtitles |
| `hearing_impaired` | Subtitles for hearing impaired |
| `visual_impaired` | Audio for visually impaired |
| `clean_effects` | Clean audio effects |
| `attached_pic` | Attached picture (cover art) |
| `captions` | Closed captions |
| `descriptions` | Audio descriptions |
| `metadata` | Metadata stream |
| `dependent` | Dependent stream |
| `still_image` | Still image stream |
