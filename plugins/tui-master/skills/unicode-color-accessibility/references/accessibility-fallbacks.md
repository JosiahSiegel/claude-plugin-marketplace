# Accessibility and Fallback Reference

## Accessible mode patterns

- `--no-tui`: line-oriented interactive mode or direct CLI subcommands.
- `--plain`: no cursor control, minimal formatting, stable text order.
- `--json`: machine-readable state for scripts and assistive workflows.
- `--color=never`: no color dependency.
- `--ascii`: no box drawing, emoji, braille, or private-use icons.

## Alternate flow contracts

Every full-screen workflow should have an equivalent plain or scriptable contract:

```text
TUI action: select failed job, open detail, retry
Plain flow:
  app jobs list --status failed --plain
  app jobs show JOB_ID --plain
  app jobs retry JOB_ID --confirm
JSON flow:
  app jobs list --status failed --json
  app jobs retry JOB_ID --json --confirm
```

Output contract examples:

```text
# --plain
STATUS failed
JOB api-17
ERROR timeout waiting for db
NEXT_ACTION app jobs retry api-17 --confirm

# --json
{"status":"failed","job_id":"api-17","error":"timeout waiting for db","actions":[{"name":"retry","command":["app","jobs","retry","api-17","--confirm"]}]}
```

Plain output should be stable, line-oriented, and free of cursor controls. JSON output should write machine-readable data to stdout and diagnostics to stderr.

## Color and contrast

Semantic roles should map to theme-aware palettes. Check contrast for foreground/background pairs and meaningful borders or chart lines. Do not use dim text for required information. In no-color mode, preserve meaning with words, punctuation, alignment, or labels.

When designing custom palettes, perceptual color spaces such as OKLCH can help choose evenly spaced colors, but terminal output ultimately becomes user-theme RGB, 256-color indexes, or 16-color roles. Always test the final mapped colors. High-DPI displays can make glyphs sharper, but terminals still lay out in cells; do not design pixel-dependent UI.

No-color equivalence examples:

| Color UI | Accessible fallback |
|--|--|
| Red row for failed job | Prefix `ERROR` or `FAILED`; include failure count. |
| Green success check | Text `OK` or `PASS`; do not require icon. |
| Yellow warning border | Heading `WARNING:` and explanatory text. |
| Blue focused field | Text cursor, label `Focused: Host`, or visible brackets. |
| Dim disabled command | Append `(disabled: requires selection)`. |

## Cognitive and motion accessibility

Keep navigation stable, avoid surprise focus jumps, use clear labels, group related actions, and explain destructive consequences in plain language. Avoid flashing more than three times per second and allow spinners, progress animation, and live dashboard updates to be reduced or disabled.

Reduced-motion contract:

```text
if --reduced-motion or CI or non-TTY:
  spinner -> static "Loading..."
  animated progress -> periodic line updates or final summary
  live dashboard -> slower refresh or manual refresh
```

## Screen-reader reality

Many full-screen TUIs repaint a visual grid that screen readers cannot interpret well. The accessible solution is usually not more escape sequences; it is a parallel plain interface with the same core functionality.

Document discoverability in `--help`:

```text
Accessibility:
  --no-tui          Use line-oriented prompts instead of full-screen UI.
  --plain          Print stable plain text with no cursor control.
  --json           Print machine-readable output for scripts.
  --color=never    Disable color.
  --ascii          Avoid Unicode drawing characters and emoji.
```

## Inclusive interaction checklist

- All actions reachable from keyboard.
- Help lists keybindings and non-TUI alternatives.
- Focus state is visible and textual where possible.
- Status and errors are announced in stable text regions or plain output.
- Animation can be disabled.
- Timeouts are avoidable or configurable.
- Destructive actions require confirmation that does not depend on color.
- Copy/export actions exist for content that may be hard to select from an alternate screen.
