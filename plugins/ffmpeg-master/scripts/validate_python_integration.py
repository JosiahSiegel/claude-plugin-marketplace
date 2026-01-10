#!/usr/bin/env python3
"""
Validation script for Python-FFmpeg integration reference.
Tests color conversions, time conversions, and parameter validation.
"""

from typing import Tuple


# Color conversion functions (from skill.md)
def rgb_to_ass_color(r: int, g: int, b: int, alpha: int = 0) -> str:
    """Convert RGB to ASS color format (&HAABBGGRR)."""
    return f"&H{alpha:02X}{b:02X}{g:02X}{r:02X}"


def ass_color_to_rgb(ass_color: str) -> Tuple[int, int, int, int]:
    """Parse ASS color to RGBA."""
    hex_val = ass_color.replace("&H", "").replace("&h", "").zfill(8)
    alpha = int(hex_val[0:2], 16)
    blue = int(hex_val[2:4], 16)
    green = int(hex_val[4:6], 16)
    red = int(hex_val[6:8], 16)
    return (red, green, blue, alpha)


# Time conversion functions (from skill.md)
def seconds_to_centiseconds(seconds: float) -> int:
    """Convert seconds to centiseconds for ASS karaoke."""
    return int(seconds * 100)


def seconds_to_milliseconds(seconds: float) -> int:
    """Convert seconds to milliseconds for ASS animation."""
    return int(seconds * 1000)


def centiseconds_to_seconds(centiseconds: int) -> float:
    """Convert ASS karaoke centiseconds to seconds."""
    return centiseconds / 100.0


def milliseconds_to_seconds(milliseconds: int) -> float:
    """Convert ASS animation milliseconds to seconds."""
    return milliseconds / 1000.0


def format_ass_timestamp(seconds: float) -> str:
    """Format seconds as ASS timestamp (H:MM:SS.CC)."""
    hours = int(seconds // 3600)
    minutes = int((seconds % 3600) // 60)
    secs = int(seconds % 60)
    centis = int((seconds % 1) * 100)
    return f"{hours}:{minutes:02d}:{secs:02d}.{centis:02d}"


# Validation functions (from skill.md)
def validate_fontsize(size: int) -> int:
    """Validate fontsize parameter."""
    if not isinstance(size, int):
        raise TypeError(f"fontsize must be int, got {type(size).__name__}")
    if not (1 <= size <= 999):
        raise ValueError(f"fontsize must be 1-999, got {size}")
    return size


def validate_alignment(alignment: int) -> int:
    """Validate ASS alignment (1-9 numpad)."""
    if not isinstance(alignment, int):
        raise TypeError(f"alignment must be int, got {type(alignment).__name__}")
    if not (1 <= alignment <= 9):
        raise ValueError(f"alignment must be 1-9, got {alignment}")
    return alignment


# Test suite
def test_color_conversions():
    """Test RGB to ASS color conversions."""
    print("Testing color conversions...")

    # Test basic colors
    assert rgb_to_ass_color(255, 255, 255) == "&H00FFFFFF", "White conversion failed"
    assert rgb_to_ass_color(0, 0, 0) == "&H00000000", "Black conversion failed"
    assert rgb_to_ass_color(255, 0, 0) == "&H000000FF", "Red conversion failed"
    assert rgb_to_ass_color(0, 255, 0) == "&H0000FF00", "Green conversion failed"
    assert rgb_to_ass_color(0, 0, 255) == "&H00FF0000", "Blue conversion failed"
    assert rgb_to_ass_color(255, 255, 0) == "&H0000FFFF", "Yellow conversion failed"

    # Test with alpha
    assert rgb_to_ass_color(255, 255, 255, 128) == "&H80FFFFFF", "White with alpha failed"

    # Test reverse conversion
    assert ass_color_to_rgb("&H00FFFFFF") == (255, 255, 255, 0), "White parsing failed"
    assert ass_color_to_rgb("&H000000FF") == (255, 0, 0, 0), "Red parsing failed"
    assert ass_color_to_rgb("&H0000FF00") == (0, 255, 0, 0), "Green parsing failed"
    assert ass_color_to_rgb("&H00FF0000") == (0, 0, 255, 0), "Blue parsing failed"

    print("[PASS] All color conversion tests passed!")


def test_time_conversions():
    """Test time unit conversions."""
    print("\nTesting time conversions...")

    # Seconds to centiseconds (karaoke)
    assert seconds_to_centiseconds(0.5) == 50, "0.5s to cs failed"
    assert seconds_to_centiseconds(1.0) == 100, "1.0s to cs failed"
    assert seconds_to_centiseconds(2.5) == 250, "2.5s to cs failed"

    # Seconds to milliseconds (animation)
    assert seconds_to_milliseconds(0.5) == 500, "0.5s to ms failed"
    assert seconds_to_milliseconds(1.0) == 1000, "1.0s to ms failed"
    assert seconds_to_milliseconds(0.2) == 200, "0.2s to ms failed"

    # Reverse conversions
    assert centiseconds_to_seconds(50) == 0.5, "50cs to s failed"
    assert centiseconds_to_seconds(100) == 1.0, "100cs to s failed"
    assert milliseconds_to_seconds(500) == 0.5, "500ms to s failed"
    assert milliseconds_to_seconds(1000) == 1.0, "1000ms to s failed"

    # Timestamp formatting
    assert format_ass_timestamp(1.5) == "0:00:01.50", "1.5s timestamp failed"
    assert format_ass_timestamp(65.25) == "0:01:05.25", "65.25s timestamp failed"
    assert format_ass_timestamp(3661.0) == "1:01:01.00", "3661s timestamp failed"

    print("[PASS] All time conversion tests passed!")


def test_validation():
    """Test parameter validation functions."""
    print("\nTesting parameter validation...")

    # Valid fontsize
    assert validate_fontsize(48) == 48, "Valid fontsize validation failed"
    assert validate_fontsize(1) == 1, "Min fontsize validation failed"
    assert validate_fontsize(999) == 999, "Max fontsize validation failed"

    # Invalid fontsize - wrong type
    try:
        validate_fontsize("48")
        assert False, "Should have raised TypeError for string fontsize"
    except TypeError:
        pass  # Expected

    # Invalid fontsize - out of range
    try:
        validate_fontsize(0)
        assert False, "Should have raised ValueError for fontsize=0"
    except ValueError:
        pass  # Expected

    try:
        validate_fontsize(1000)
        assert False, "Should have raised ValueError for fontsize=1000"
    except ValueError:
        pass  # Expected

    # Valid alignment
    for i in range(1, 10):
        assert validate_alignment(i) == i, f"Alignment {i} validation failed"

    # Invalid alignment
    try:
        validate_alignment(0)
        assert False, "Should have raised ValueError for alignment=0"
    except ValueError:
        pass  # Expected

    try:
        validate_alignment(10)
        assert False, "Should have raised ValueError for alignment=10"
    except ValueError:
        pass  # Expected

    print("[PASS] All validation tests passed!")


def test_common_mistakes():
    """Test common mistake scenarios."""
    print("\nTesting common mistake scenarios...")

    # Mistake: RGB vs BGR color order
    red_rgb = (255, 0, 0)
    red_ass = rgb_to_ass_color(*red_rgb)
    assert red_ass == "&H000000FF", "Red in ASS should be &H000000FF (BGR order)"
    assert red_ass != "&H00FF0000", "Red in ASS is NOT &H00FF0000 (that's blue!)"

    # Mistake: Centiseconds vs milliseconds
    duration_sec = 1.0
    karaoke_cs = seconds_to_centiseconds(duration_sec)
    animation_ms = seconds_to_milliseconds(duration_sec)
    assert karaoke_cs == 100, "1 second = 100 centiseconds for karaoke"
    assert animation_ms == 1000, "1 second = 1000 milliseconds for animation"
    assert karaoke_cs != animation_ms, "Karaoke and animation use different units!"

    print("[PASS] All common mistake tests passed!")


def test_karaoke_generation():
    """Test karaoke tag generation example."""
    print("\nTesting karaoke generation...")

    words = ["Never", "gonna", "give", "you", "up"]
    durations = [0.8, 0.6, 0.6, 0.5, 0.7]  # seconds

    # Generate karaoke tags
    karaoke_tags = []
    for word, duration_sec in zip(words, durations):
        cs = seconds_to_centiseconds(duration_sec)
        karaoke_tags.append(f"{{\\k{cs}}}{word}")

    karaoke_line = " ".join(karaoke_tags)
    expected = r"{\k80}Never {\k60}gonna {\k60}give {\k50}you {\k70}up"

    assert karaoke_line == expected, f"Karaoke line mismatch: {karaoke_line}"

    print(f"[PASS] Karaoke generation test passed!")
    print(f"       Generated: {karaoke_line}")


def main():
    """Run all validation tests."""
    print("=" * 60)
    print("Python-FFmpeg Integration Reference Validation")
    print("=" * 60)

    test_color_conversions()
    test_time_conversions()
    test_validation()
    test_common_mistakes()
    test_karaoke_generation()

    print("\n" + "=" * 60)
    print("[SUCCESS] ALL TESTS PASSED!")
    print("=" * 60)
    print("\nThe Python-FFmpeg integration reference is accurate.")
    print("All color conversions, time conversions, and validations work correctly.")


if __name__ == "__main__":
    main()
