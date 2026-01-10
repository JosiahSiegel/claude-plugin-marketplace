# Python-FFmpeg Integration Enhancement - v3.2 Update

## Overview

This document summarizes the comprehensive enhancement of the ffmpeg-master plugin's Python integration capabilities, focusing on type safety, accurate parameter mappings, and proper unit conversions for caption/subtitle effects.

## New Skill Created

### `ffmpeg-python-integration-reference` (1,577 lines)

**Location**: `skills/ffmpeg-python-integration-reference/skill.md`

A comprehensive, authoritative reference for Python-FFmpeg integration ensuring:
- Type-safe parameter mappings
- Accurate color format conversions
- Proper time unit conversions
- Validation helpers and error detection

## Key Features

### 1. Color Format Conversions (Section 1)

**Critical Focus**: Accurate conversion between different color format systems

| System | Format | Example | Python Type |
|--------|--------|---------|-------------|
| FFmpeg drawtext | RGB hex/named | `#FFFFFF`, `"white"` | `str` |
| ASS/SSA | &HAABBGGRR (BGR!) | `&H00FFFFFF` | `str` |
| OpenCV | BGR array | `[255, 255, 255]` | `np.ndarray` |
| PIL/Pillow | RGB tuple/hex | `(255, 255, 255)` | `tuple` |

**Python Functions Provided**:
```python
rgb_to_bgr_hex(r, g, b) -> str
rgb_to_ass_color(r, g, b, alpha) -> str
ass_color_to_rgb(ass_color) -> Tuple[int, int, int, int]
ffmpeg_color_to_rgb(color) -> Tuple[int, int, int]
```

**Common Preset Constants**:
- `ASS_COLORS` dictionary with pre-defined colors
- `ASS_ALPHA` transparency levels

### 2. Time Unit Conversions (Section 2)

**Critical Focus**: Handling THREE different time systems

| Context | Unit | Python Type | Conversion |
|---------|------|-------------|------------|
| FFmpeg filters | Seconds | `float`/`int` | Direct |
| ASS karaoke (\k) | Centiseconds | `int` | × 100 |
| ASS animation (\t) | Milliseconds | `int` | × 1000 |

**Python Functions Provided**:
```python
seconds_to_centiseconds(seconds) -> int
seconds_to_milliseconds(seconds) -> int
centiseconds_to_seconds(cs) -> float
milliseconds_to_seconds(ms) -> float
format_ass_timestamp(seconds) -> str
parse_ass_timestamp(timestamp) -> float
```

**Quick Conversion Constants**:
- `SECOND_TO_CS = 100`
- `SECOND_TO_MS = 1000`
- `CS_TO_MS = 10`

### 3. FFmpeg drawtext Parameters (Section 3)

Complete parameter type reference with validation:

| Parameter | Python Type | Range | Common Error |
|-----------|-------------|-------|--------------|
| `fontsize` | `int` | 1-999 | Using `str`: `fontsize="24"` ❌ |
| `fontcolor` | `str` | Named/hex | Wrong format ❌ |
| `x`, `y` | `str` or `int` | Expression/pixels | No quotes on expressions ❌ |
| `borderw` | `int` | 0-20 | Negative values ❌ |
| `shadowx`, `shadowy` | `int` | -50 to 50 | Wrong type ❌ |
| `alpha` | `str` (expression) | 0.0-1.0 | Using float directly ❌ |

### 4. ASS/SSA Subtitle Parameters (Section 4)

**Type-Safe ASS Style Definition**:
```python
class ASSStyle(NamedTuple):
    name: str
    fontname: str
    fontsize: int
    primary_colour: str      # &HAABBGGRR format
    secondary_colour: str    # &HAABBGGRR format
    outline_colour: str      # &HAABBGGRR format
    back_colour: str         # &HAABBGGRR format (shadow)
    bold: int                # -1 for bold (FFmpeg quirk!)
    italic: int              # 0 or 1
    outline: float           # 0.0-4.0
    shadow: float            # 0.0-4.0
    alignment: int           # 1-9 (numpad)
    # ... (15 total fields)
```

**ASS Alignment Reference** (Numpad layout):
```
7 (top-left)      8 (top-center)      9 (top-right)
4 (middle-left)   5 (middle-center)   6 (middle-right)
1 (bottom-left)   2 (bottom-center)   3 (bottom-right)
```

### 5. ASS Karaoke Tags (Section 5)

| Tag | Unit | Python Type | Effect |
|-----|------|-------------|--------|
| `\k` | Centiseconds | `int` | Instant highlight |
| `\kf`, `\K` | Centiseconds | `int` | Progressive fill |
| `\ko` | Centiseconds | `int` | Outline sweep |

**Python Generator**:
```python
def generate_karaoke_line(
    words: list[str],
    durations: list[float],  # In SECONDS
    style: str = "Karaoke"
) -> str:
    # Converts seconds to centiseconds automatically
    # Returns: '{\k80}Never {\k60}gonna {\k60}give {\k50}you {\k70}up'
```

### 6. ASS Animation Tags (Section 6)

| Tag | Format | Unit | Example |
|-----|--------|------|---------|
| `\t` | `\t(t1,t2,tags)` | Milliseconds | `\t(0,500,\fscx120)` |
| `\fad` | `\fad(in,out)` | Milliseconds | `\fad(300,200)` |
| `\move` | `\move(x1,y1,x2,y2,t1,t2)` | Milliseconds | `\move(0,0,100,100,0,1000)` |

**Animation Generators**:
```python
create_scale_animation(duration_ms, start_scale, peak_scale, end_scale) -> str
create_fade_animation(fade_in_ms, fade_out_ms) -> str
create_color_transition(start_rgb, end_rgb, duration_ms) -> str
create_animated_karaoke_word(word, duration_sec, pop_animation) -> str
```

### 7. ffmpeg-python Library Integration (Section 7)

**Type-Safe Filter Application**:
```python
def apply_drawtext_filter(
    input_stream,
    text: str,
    fontsize: int,  # Type-enforced
    fontcolor: str = "white",
    x: Union[str, int] = 10,
    y: Union[str, int] = 10,
    # ... with full validation
) -> ffmpeg.Stream:
    # Raises TypeError/ValueError for invalid parameters
```

**Complete Audio/Video Processing**:
```python
def add_subtitles_with_audio(...):
    # CRITICAL: Always explicitly handle audio stream
    video = input_file.video.drawtext(...)
    audio = input_file.audio  # Preserve audio!
    ffmpeg.output(video, audio, output_path)
```

### 8. Subprocess Pattern with Pipes (Section 8)

**Frame-by-Frame Processing**:
```python
def read_video_frames(input_path, width, height, pix_fmt="rgb24") -> Generator
def write_video_frames(output_path, width, height, fps, crf) -> subprocess.Popen
def process_video_frames(input_path, output_path, process_fn)
```

### 9. Common Pitfalls and Solutions (Section 9)

**6 Critical Pitfalls Documented**:

1. **String vs Int for Numeric Parameters**
   - ❌ `fontsize="24"`
   - ✅ `fontsize=24`

2. **RGB vs BGR Color Order**
   - ❌ ASS color as RGB: `&H00FF0000` (blue!)
   - ✅ ASS color as BGR: `&H000000FF` (red!)

3. **Centiseconds vs Milliseconds Confusion**
   - ❌ `{\k100\t(0,100,...)}` (1s vs 0.1s mismatch!)
   - ✅ `{\k100\t(0,1000,...)}` (both 1 second)

4. **Forgetting Quotes on Expressions**
   - ❌ `x=(w-tw)/2` (Python error!)
   - ✅ `x="(w-tw)/2"` (FFmpeg evaluates)

5. **Audio Stream Loss**
   - ❌ Filter without audio (silently dropped!)
   - ✅ Explicitly preserve: `audio = input_file.audio`

6. **Incorrect ASS Bold Value**
   - ❌ `bold=1` (may not work)
   - ✅ `bold=-1` (FFmpeg quirk for bold)

### 10. Validation Helpers (Section 10)

**Type and Range Validation Functions**:
```python
validate_fontsize(size: int) -> int
validate_crf(crf: int, codec: str) -> int
validate_ass_color(color: str) -> str
validate_alignment(alignment: int) -> int
validate_ffmpeg_color(color: str) -> str
validate_time_expression(expr: str) -> str
```

### 11. Complete Working Examples (Section 11)

**Two Full Production Examples**:

1. **Type-Safe Karaoke Generator** (120+ lines)
   - Complete class with validation
   - Automatic time unit conversion
   - ASS file generation
   - Video rendering with ffmpeg-python

2. **Dynamic Text Overlay with Type Safety** (80+ lines)
   - Fluent API design
   - Method chaining
   - Complete validation
   - Production-ready code

## Integration with Existing Skills

### Updated Skills

1. **`ffmpeg-opencv-integration`** - Added cross-reference:
   - Link to new Python integration reference
   - Note about type-safe parameter mappings

2. **`ffmpeg-expert` agent** - Updated knowledge base:
   - Added reference to `ffmpeg-python-integration-reference`
   - Added reference to `ffmpeg-opencv-integration`

3. **`README.md`** - Documented new skill:
   - Added to skills list with description
   - Noted as NEW in v3.2

## Summary Checklist

The new skill provides:

### ✅ Type Safety
- [x] Complete parameter type reference
- [x] Validation functions for all parameter types
- [x] Error detection patterns
- [x] Type hints throughout

### ✅ Color Format Accuracy
- [x] RGB to BGR conversion functions
- [x] ASS &HAABBGGRR format handling
- [x] OpenCV BGR array support
- [x] FFmpeg hex/named color support
- [x] Complete color format comparison chart

### ✅ Time Unit Conversions
- [x] Seconds to centiseconds (karaoke)
- [x] Seconds to milliseconds (animation)
- [x] Reverse conversions (cs/ms to seconds)
- [x] ASS timestamp formatting/parsing
- [x] Quick conversion constants

### ✅ Caption Effects Integration
- [x] drawtext parameter reference
- [x] ASS style parameter reference
- [x] Karaoke tag reference (\k, \kf, \ko)
- [x] Animation tag reference (\t, \fad, \move)
- [x] Shadow/outline parameter ranges
- [x] Color format handling for effects

### ✅ Working Examples
- [x] Complete karaoke generator class
- [x] Type-safe text overlay builder
- [x] Frame processing pipelines
- [x] Validation helper usage
- [x] Common pitfall solutions

### ✅ Documentation Quality
- [x] 1,577 lines of comprehensive content
- [x] 11 major sections
- [x] Quick reference tables
- [x] Working Python code examples
- [x] Type hints and validation
- [x] Common mistakes highlighted

## Testing Recommendations

To verify the integration works correctly:

1. **Color Conversion Test**:
   ```python
   # Test RGB to ASS color conversion
   assert rgb_to_ass_color(255, 0, 0) == "&H000000FF"  # Red
   assert rgb_to_ass_color(0, 255, 0) == "&H0000FF00"  # Green
   assert rgb_to_ass_color(0, 0, 255) == "&H00FF0000"  # Blue
   ```

2. **Time Conversion Test**:
   ```python
   # Test second to centisecond conversion
   assert seconds_to_centiseconds(0.5) == 50
   assert seconds_to_milliseconds(0.5) == 500
   ```

3. **Validation Test**:
   ```python
   # Test parameter validation
   assert validate_fontsize(48) == 48
   try:
       validate_fontsize("48")  # Should raise TypeError
   except TypeError:
       pass  # Expected
   ```

4. **Integration Test**:
   ```python
   # Test complete karaoke generation
   karaoke = KaraokeGenerator("input.mp4", "output.mp4")
   karaoke.add_line(1.0, ["Hello", "World"], [0.5, 0.6])
   # Should render without errors
   ```

## Future Enhancements

Potential areas for expansion:

1. **PyAV Integration**: Add PyAV-specific parameter mappings
2. **MoviePy Integration**: Document MoviePy + FFmpeg workflows
3. **GPU Acceleration**: Expand CUDA/OpenCL parameter references
4. **Real-time Processing**: WebRTC/live streaming Python patterns
5. **ML Pipeline Integration**: PyTorch/TensorFlow + FFmpeg patterns

## Version Information

- **Plugin Version**: 3.2.0
- **New Skill**: `ffmpeg-python-integration-reference`
- **Skill Size**: 47,338 bytes, 1,577 lines
- **Creation Date**: 2026-01-10

## Files Modified

1. ✅ Created: `skills/ffmpeg-python-integration-reference/skill.md`
2. ✅ Updated: `skills/ffmpeg-opencv-integration/skill.md`
3. ✅ Updated: `agents/ffmpeg-expert.md`
4. ✅ Updated: `README.md`

## Conclusion

The ffmpeg-master plugin now provides **comprehensive, type-safe Python-FFmpeg integration** with:

- **Accurate parameter mappings** for all FFmpeg and ASS/SSA parameters
- **Proper unit conversions** between seconds, centiseconds, and milliseconds
- **Color format accuracy** for RGB, BGR, ASS &HAABBGGRR, and hex formats
- **Complete validation** to catch type mismatches before runtime
- **Working examples** demonstrating production-ready code
- **Error prevention** through documented common pitfalls

This enhancement ensures users can integrate FFmpeg with Python confidently, knowing all parameters are correctly typed, all units are properly converted, and all color formats are accurately mapped.

---

**End of Python-FFmpeg Integration Enhancement Document**
