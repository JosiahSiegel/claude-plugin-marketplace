# Caption Readability Formula

Optimal caption display duration calculation based on reading speed research and WCAG 2.2 accessibility requirements.

## Reading Speed Standards

| Audience | Words Per Minute (WPM) | Use Case |
|----------|------------------------|----------|
| Slow readers | 120-140 WPM | Accessibility, elderly |
| **Average** | **160-180 WPM** | **Recommended default** |
| Fast readers | 200-220 WPM | Experienced viewers |
| Skim reading | 250-300 WPM | Not recommended for video |

## Caption Duration Calculation

### Formula

```python
# Basic formula:
caption_duration = (word_count / words_per_minute) * 60

# With minimum duration (accessibility):
minimum_duration = 1.5  # seconds - WCAG recommendation
duration = max(minimum_duration, caption_duration)

# Conservative formula (recommended):
duration = max(1.5, (word_count / 160) * 60)
```

### Quick Reference Table

| Word Count | @ 160 WPM | @ 180 WPM | Recommended |
|------------|-----------|-----------|-------------|
| 1-2 words | 0.75s | 0.67s | **1.5s** (minimum) |
| 3 words | 1.13s | 1.0s | **1.5s** (minimum) |
| 4 words | 1.5s | 1.33s | **1.5s** |
| 5 words | 1.88s | 1.67s | **1.9s** |
| 6 words | 2.25s | 2.0s | **2.3s** |
| 8 words | 3.0s | 2.67s | **3.0s** |
| 10 words | 3.75s | 3.33s | **3.8s** |
| 15 words | 5.63s | 5.0s | **5.6s** |

### Python Implementation

```python
def calculate_caption_duration(text: str, wpm: int = 160) -> float:
    """
    Calculate optimal caption display duration.

    Args:
        text: Caption text
        wpm: Words per minute (default 160 for comfortable reading)

    Returns:
        Duration in seconds
    """
    word_count = len(text.split())
    calculated = (word_count / wpm) * 60

    # WCAG minimum: 1.5 seconds for any caption
    minimum = 1.5

    # Add 0.5s buffer for cognitive processing
    buffer = 0.5

    return max(minimum, calculated + buffer)

# Examples:
print(calculate_caption_duration("Hello"))           # 1.5s (minimum)
print(calculate_caption_duration("This is a test")) # 2.0s
print(calculate_caption_duration("Check out this incredible transformation")) # 2.88s
```

## Accessibility Guidelines (WCAG 2.2)

| Guideline | Requirement |
|-----------|-------------|
| Minimum duration | 1.5 seconds for any caption |
| Maximum reading speed | 200 WPM (3.3 words/second) |
| Character limit | 42 characters per line (readability) |
| Lines per caption | Maximum 2 lines |
| Persistence | Caption visible for full duration |
