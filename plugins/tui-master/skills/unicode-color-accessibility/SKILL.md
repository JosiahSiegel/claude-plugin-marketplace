---
name: unicode-color-accessibility
description: |
  This skill should be used when the user asks about Unicode rendering, wcwidth, grapheme clusters, emoji, combining marks, East Asian width, BiDi text, box drawing, Nerd Fonts, color themes, truecolor, 256-color fallback, NO_COLOR, contrast, accessibility, screen-reader behavior, keyboard access, reduced motion, or non-TUI fallbacks. PROACTIVELY activate for: Unicode width bugs, misaligned tables, emoji layout, ANSI-aware string measurement, color accessibility, screen-reader friendly CLI design, plain output mode, ASCII fallback, and terminal theme support. Provides: text measurement rules, color/fallback policy, accessibility checklist, and failure-mode fixes.
---

# Unicode, Color, Accessibility, and Non-TUI Fallbacks

Use this skill when terminal output must be visually correct, readable, inclusive, and robust across fonts, locales, themes, and assistive technologies.

## Text correctness rules

- Display width is not byte length, code point count, or user-perceived character count.
- Cursor movement and deletion should operate on grapheme clusters.
- Layout should measure printable text after stripping ANSI control sequences.
- Double-width characters, combining marks, emoji sequences, variation selectors, and zero-width joiners must be tested.
- Treat ambiguous East Asian width as narrow by default unless the target environment explicitly differs.

## Visual design rules

- Use semantic roles: error, warning, success, info, muted, selected, focused, disabled.
- Do not encode meaning by color alone; pair color with text, shape, icon, or position.
- Provide ASCII fallback for box drawing, braille charts, block elements, emoji, and private-use icons.
- Avoid assuming Nerd Fonts or patched fonts.
- Support light and dark backgrounds, 16-color, 256-color, truecolor, and no-color modes.

## Color preferences

Respect user and environment preferences:

- `NO_COLOR` disables non-essential color.
- `CLICOLOR`, `CLICOLOR_FORCE`, and `FORCE_COLOR` may force color depending on ecosystem conventions.
- `TERM=dumb`, non-TTY output, and CI usually imply plain output unless overridden.
- Provide explicit flags such as `--color=auto|always|never`, `--plain`, and `--ascii`.

## Accessibility requirements

- All functionality must be keyboard-operable.
- Focus indicators must be visible without relying on color alone.
- Avoid flashing more than three times per second.
- Allow spinner, animation, and live-region suppression for reduced motion, logs, and CI.
- Provide screen-reader friendly alternatives: plain prompts, line-oriented commands, `--json`, `--plain`, or documented stdin/stdout workflows.
- Use meaningful labels, stable ordering, and visible status messages.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Misaligned tables | byte length or ANSI counted as visible width | use ANSI-aware wcwidth/grapheme measurement |
| Cursor splits emoji | movement by code point | move by grapheme cluster |
| Borders look broken | font or width mismatch | provide ASCII mode and test common fonts |
| Error only shown in red | color-only meaning | add text/icon/label and contrast check |
| Screen reader unusable | full-screen repaint grid | provide non-TUI mode and line-oriented flows |

## Reference files

- `references/text-measurement.md` - Unicode width, graphemes, emoji, BiDi, and ANSI measurement.
- `references/accessibility-fallbacks.md` - Color policy, screen-reader alternatives, and inclusive UX checklist.
