# Complete FFmpeg 8.0+ Option Reference

Exhaustive option catalogs grouped by category. Use this for lookup; for the placement rules and common mistakes see the parent `SKILL.md`.

## Global Options (Complete List)

| Option | Description |
|--------|-------------|
| `-y` | Overwrite output files without asking |
| `-n` | Never overwrite output files |
| `-v level` / `-loglevel level` | Set logging verbosity (quiet, panic, fatal, error, warning, info, verbose, debug, trace) |
| `-stats` | Print encoding progress statistics |
| `-stats_period time` | Set statistics output period |
| `-progress url` | Send progress info to URL/file |
| `-stdin` | Enable stdin interaction |
| `-nostdin` | Disable stdin interaction |
| `-report` | Generate ffmpeg-*.log debug file |
| `-hide_banner` | Suppress program banner |
| `-max_alloc bytes` | Maximum allocation size limit |
| `-cpuflags flags` | Set CPU flags mask |
| `-cpucount count` | Override CPU count detection |
| `-max_error_rate ratio` | Maximum decoding error ratio |
| `-xerror` | Exit on error |
| `-abort_on flags` | Conditions to abort (empty_output, empty_output_stream) |
| `-filter_complex graph` | Global complex filtergraph |
| `-filter_complex_threads n` | Filtergraph thread count |
| `-filter_threads n` | Set filter processing threads |
| `-filter_buffered_frames n` | Max buffered frames in filtergraph |
| `-lavfi graph` | Alias for -filter_complex |
| `-filter_complex_script file` | Read filtergraph from file |
| `-sdp_file file` | Write SDP info to file |
| `-init_hw_device type=name` | Initialize hardware device |
| `-filter_hw_device name` | Hardware device for filters |
| `-hwaccels` | List available hardware accelerations |
| `-benchmark` | Show benchmarking info |
| `-benchmark_all` | Show per-step benchmarking |
| `-timelimit duration` | Exit after duration seconds |
| `-dump` | Dump each input packet |
| `-hex` | Dump packets in hex |
| `-debug_ts` | Print timestamp/latency debugging info |
| `-recast_media` | Force decoder of different media type |
| `-vsync mode` | Video sync method (deprecated, use -fps_mode) |
| `-fps_mode mode` | Frame rate mode (passthrough, cfr, vfr, auto) |
| `-frame_drop_threshold threshold` | Frame drop threshold |
| `-async samples_per_second` | Audio sync method |
| `-adrift_threshold threshold` | Audio drift threshold |
| `-copyts` | Copy timestamps from input |
| `-start_at_zero` | Shift input timestamps to start at 0 |
| `-copytb mode` | Copy input timebase (0=decoder, 1=demuxer, -1=auto) |
| `-dts_delta_threshold threshold` | DTS discontinuity threshold |
| `-dts_error_threshold threshold` | DTS error timestamp threshold |
| `-muxdelay seconds` | Maximum mux delay |
| `-muxpreload seconds` | Initial mux delay |
| `-streamid output_index:new_id` | Set stream ID in output |
| `-override_ffserver` | Override ffserver input specifications |
| `-bitexact` | Use only bit-exact algorithms |
| `-default_mode mode` | Default stream selection mode |
| `-vstats` | Dump video coding stats to vstats_HHMMSS.log |
| `-vstats_file file` | Dump video coding stats to specified file |
| `-vstats_version n` | Set vstats format version |
| `-print_graphs` | Print execution graph to stderr |
| `-print_graphs_file file` | Write execution graph to file |
| `-print_graphs_format fmt` | Set graph output format (default, compact, json, mermaid) |

## Input-Only Options (Complete List)

| Option | Description |
|--------|-------------|
| `-i url` | Input file URL |
| `-f fmt` | Force input format |
| `-c:v decoder` / `-vcodec decoder` | Video decoder |
| `-c:a decoder` / `-acodec decoder` | Audio decoder |
| `-c:s decoder` / `-scodec decoder` | Subtitle decoder |
| `-ss position` | Seek to position (fast, keyframe-based) |
| `-sseof position` | Seek relative to end of file (negative value) |
| `-t duration` | Limit input duration |
| `-to position` | Limit input to position |
| `-itsoffset offset` | Input timestamp offset |
| `-itsscale scale` | Input timestamp scale (per-stream) |
| `-isync input_index` | Assign input as sync source |
| `-re` | Read at native frame rate |
| `-readrate speed` | Read at specified rate |
| `-readrate_initial_burst duration` | Initial burst before rate limiting |
| `-readrate_catchup speed` | Catchup rate when behind |
| `-stream_loop count` | Loop input (-1 = infinite) |
| `-hwaccel method` | Hardware acceleration (none, auto, cuda, vaapi, qsv, d3d11va, dxva2, videotoolbox, vdpau, vulkan) |
| `-hwaccel_device device` | Hardware device path/name |
| `-hwaccel_output_format format` | Hardware output pixel format |
| `-autorotate` | Automatically rotate video (enabled by default) |
| `-noautorotate` | Disable automatic rotation |
| `-r fps` | Input frame rate (raw formats) |
| `-s size` | Input frame size (raw formats) |
| `-pix_fmt format` | Input pixel format (raw formats) |
| `-sample_fmt format` | Input sample format (raw audio) |
| `-ar rate` | Input audio sample rate |
| `-ac channels` | Input audio channel count |
| `-channel_layout layout` | Input audio channel layout |
| `-accurate_seek` | Enable accurate seeking (default) |
| `-noaccurate_seek` | Disable accurate seeking |
| `-seek_timestamp` | Enable seeking by timestamp |
| `-thread_queue_size count` | Input thread queue size |
| `-guess_layout_max channels` | Max channels for layout guessing |
| `-discard mode` | Discard frames (none, default, noref, bidir, nokey, all) |
| `-reinit_filter` | Reinitialize filters on input change (per-stream) |
| `-drop_changed` | Drop frames with changed parameters (per-stream) |
| `-display_rotation degrees` | Set display rotation metadata |
| `-display_hflip` | Set horizontal flip metadata |
| `-display_vflip` | Set vertical flip metadata |
| `-fix_sub_duration` | Fix subtitle durations |
| `-canvas_size size` | Subtitle canvas size |
| `-ignore_loop` | Ignore loop metadata (GIF) |
| `-dump_attachment:stream filename` | Extract attachment to file (per-stream) |

## Output-Only Options (Complete List)

| Option | Description |
|--------|-------------|
| `-f fmt` | Force output format |
| `-c:v encoder` / `-vcodec encoder` | Video encoder (or `copy`) |
| `-c:a encoder` / `-acodec encoder` | Audio encoder (or `copy`) |
| `-c:s encoder` / `-scodec encoder` | Subtitle encoder (or `copy`) |
| `-c:d codec` / `-dcodec codec` | Data stream codec |
| `-ss position` | Start time (accurate, slow) |
| `-t duration` | Output duration limit |
| `-to position` | Output end position |
| `-fs size` | File size limit (bytes) |
| `-frames:v count` / `-vframes count` | Video frame count limit |
| `-frames:a count` / `-aframes count` | Audio frame count limit |
| `-frames:d count` / `-dframes count` | Data frame count limit |
| `-r fps` | Output frame rate |
| `-fpsmax fps` | Maximum output frame rate |
| `-s size` | Output frame size |
| `-aspect ratio` | Display aspect ratio |
| `-pix_fmt format` | Output pixel format |
| `-sample_fmt format` | Output sample format |
| `-ar rate` | Output audio sample rate |
| `-ac channels` | Output audio channel count |
| `-channel_layout layout` | Output audio channel layout |
| `-vf filtergraph` / `-filter:v` | Video filter chain |
| `-af filtergraph` / `-filter:a` | Audio filter chain |
| `-map input:stream` | Stream mapping |
| `-map_metadata specifier` | Metadata mapping |
| `-map_chapters input_index` | Chapter mapping from input |
| `-b:v bitrate` | Video bitrate |
| `-b:a bitrate` | Audio bitrate |
| `-maxrate bitrate` | Maximum bitrate |
| `-minrate bitrate` | Minimum bitrate |
| `-bufsize size` | Rate control buffer size |
| `-crf value` | Constant Rate Factor (quality) |
| `-qp value` | Constant QP value |
| `-q:v value` / `-qscale:v value` | Video quality scale (VBR) |
| `-q:a value` / `-qscale:a value` | Audio quality scale (VBR) |
| `-preset name` | Encoder preset |
| `-tune name` | Encoder tuning |
| `-profile:v name` | Video profile |
| `-level value` | Codec level |
| `-g frames` | GOP size / keyframe interval |
| `-keyint_min frames` | Minimum keyframe interval |
| `-sc_threshold value` | Scene change threshold |
| `-bf frames` | B-frame count |
| `-refs frames` | Reference frames |
| `-pass n` | Multi-pass encoding (1 or 2) |
| `-passlogfile prefix` | Pass log file prefix |
| `-rc_lookahead frames` | Rate control lookahead |
| `-an` | Disable audio output |
| `-vn` | Disable video output |
| `-sn` | Disable subtitle output |
| `-dn` | Disable data stream output |
| `-metadata key=value` | Set global metadata |
| `-metadata:s:v key=value` | Set video stream metadata |
| `-metadata:s:a key=value` | Set audio stream metadata |
| `-metadata:c:0 key=value` | Set chapter metadata |
| `-disposition:s:0 flags` | Set stream disposition |
| `-program title=name:st=0:st=1` | Create program in output |
| `-stream_group type=value:...` | Create stream group |
| `-target type` | Target format (vcd, svcd, dvd, dv, dv50) |
| `-shortest` | Stop at shortest stream |
| `-shortest_buf_duration duration` | Buffer for shortest detection |
| `-apad` | Pad audio to match video (use with -shortest) |
| `-copypriorss n` | Copy frames before start time (0=no, 1=yes, -1=auto) |
| `-avoid_negative_ts mode` | Handle negative timestamps (make_non_negative, make_zero, auto, disabled) |
| `-timestamp date` | Set recording timestamp |
| `-movflags flags` | MOV/MP4 flags (+faststart, +frag_keyframe, etc.) |
| `-fflags flags` | Format flags (+genpts, +igndts, +discardcorrupt, etc.) |
| `-bsf:v filter` | Video bitstream filter |
| `-bsf:a filter` | Audio bitstream filter |
| `-tag:v fourcc` / `-vtag fourcc` | Video tag/fourcc |
| `-tag:a fourcc` / `-atag fourcc` | Audio tag/fourcc |
| `-timecode hh:mm:ss:ff` | Set initial timecode |
| `-force_key_frames expr` | Force keyframe positions |
| `-copyinkf` | Copy initial non-keyframes (stream copy) |
| `-init_hw_device type=name` | Initialize hw device for output |
| `-enc_time_base mode` | Encoder timebase (demux, filter, auto) |
| `-attach filename` | Add attachment (fonts, images) |
| `-pre preset_name` | Use preset file (per-stream) |
| `-fpre preset_file` | Use preset file (per-file) |
| `-max_muxing_queue_size packets` | Muxing queue size |
| `-muxing_queue_data_threshold bytes` | Queue data threshold |
| `-dcodec codec` | Data stream codec (alias for -c:d) |
| `-intra` | Use only intra frames (deprecated, use -g 1) |
| `-vol volume` | Audio volume (256=normal, deprecated, use -af volume) |
| `-autoscale` | Auto-scale video (enabled by default) |
| `-noautoscale` | Disable auto-scaling |
| `-autorotate` | Auto-rotate video on output (enabled by default) |
| `-noautorotate` | Disable auto-rotation on output |

## Video Color/HDR Options (Output)

| Option | Description |
|--------|-------------|
| `-color_range range` | Color range (tv/pc, limited/full, mpeg/jpeg) |
| `-color_primaries primaries` | Color primaries (bt709, bt2020, smpte170m, etc.) |
| `-color_trc trc` | Transfer characteristics (bt709, smpte2084/pq, arib-std-b67/hlg, etc.) |
| `-colorspace space` | Colorspace (bt709, bt2020nc, smpte170m, etc.) |
| `-chroma_sample_location loc` | Chroma sample location |
| `-top n` | Top field first (1) or bottom field first (0) |
| `-bits_per_raw_sample n` | Bits per raw sample |
| `-dc precision` | Intra DC precision |
| `-qphist` | Show QP histogram |

## Subtitle Options

| Option | Description | Type |
|--------|-------------|------|
| `-sn` | Disable subtitles | Input/Output |
| `-scodec codec` | Subtitle codec | Input/Output |
| `-stag fourcc` | Subtitle tag/fourcc | Output |
| `-fix_sub_duration` | Fix subtitle durations | Input |
| `-canvas_size size` | Subtitle canvas size | Input |

## FFmpeg 8.0+ Specific Options

| Option | Description | Type |
|--------|-------------|------|
| `-vaapi_device path` | VAAPI device path | Input/Global |
| `-qsv_device path` | Intel QSV device | Input/Global |
| `-vulkan_device device` | Vulkan device selection | Input/Global |
| `-fps_mode mode` | Frame rate mode (replaces -vsync) | Output |
| `-enc_stats_pre file` | Pre-encoding stats output | Output |
| `-enc_stats_post file` | Post-encoding stats output | Output |
| `-enc_stats_pre_fmt fmt` | Pre-encoding stats format | Output |
| `-enc_stats_post_fmt fmt` | Post-encoding stats format | Output |
| `-autoscale` | Auto-scale to encoder (default) | Output |
| `-noautoscale` | Disable auto-scaling | Output |
| `-bits_per_raw_sample n` | Set bits per raw sample | Output |

## Threading Options

| Option | Description | Type |
|--------|-------------|------|
| `-threads n` | Encoding/decoding threads (0=auto) | Per-stream/Output |
| `-thread_type type` | Thread type (frame, slice) | Per-stream |
| `-filter_threads n` | Filter processing threads | Global |
| `-filter_complex_threads n` | Complex filtergraph threads | Global |

```bash
# Auto-detect threads for encoding
ffmpeg -i input.mp4 -c:v libx264 -threads 0 output.mp4

# Specific thread count
ffmpeg -i input.mp4 -c:v libx264 -threads 8 output.mp4

# Per-stream threading
ffmpeg -i input.mp4 -threads:v 8 -threads:a 2 -c:v libx264 -c:a aac output.mp4

# Filter threads
ffmpeg -filter_threads 4 -i input.mp4 -vf "scale=1920:1080" output.mp4
```

## Format Flags (-fflags)

| Flag | Description |
|------|-------------|
| `+genpts` | Generate PTS if missing |
| `+igndts` | Ignore DTS (use PTS only) |
| `+ignidx` | Ignore index |
| `+discardcorrupt` | Discard corrupted frames |
| `+sortdts` | Sort packets by DTS |
| `+fastseek` | Enable fast seeking |
| `+nobuffer` | Disable buffering |
| `+flush_packets` | Flush packets immediately |
| `+bitexact` | Bit-exact output |
| `+shortest` | Stop at shortest stream |
| `+autobsf` | Auto-insert bitstream filters |
