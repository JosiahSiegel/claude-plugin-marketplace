# Terminal Color Design

## Semantic palette roles

Define roles before choosing RGB values:

- `text`, `muted`, `disabled`
- `background`, `surface`, `surface-muted`, `border`
- `primary`, `accent`, `selected`, `focused`
- `success`, `warning`, `error`, `info`
- `chart-1` through `chart-n`

Map widgets to roles, not raw colors. This allows dark/light themes, 16-color fallback, and user customization without rewriting components.

## Color hierarchy

- Main content should remain readable in default terminal foreground/background.
- Accent color should be rare enough to guide the eye.
- Error and warning colors should be reserved for actual problems.
- Disabled and muted content must still meet readability needs when the text is required.
- Avoid mixing multiple saturated colors in the same small panel.

## Backgrounds

Use background colors carefully because many users tune terminal backgrounds for comfort.

- **No background fill:** safest for CLI output and mixed scrollback.
- **Subtle surface fill:** useful for selected rows, focused inputs, and cards when contrast is verified.
- **Full-screen fill:** acceptable for immersive TUIs that own the alternate screen and have theme control.
- **Danger fill:** reserve for destructive confirmation or critical alerts, with text labels and fallback.

## Dark and light themes

Design palettes as paired themes rather than assuming a dark terminal. Verify yellow, blue, purple, and dim gray on both light and dark backgrounds. When terminal background detection is unavailable or blocked, choose conservative colors and expose a theme override.

## 16-color, 256-color, and truecolor

- In truecolor, choose colors with enough luminance separation, not just hue separation.
- In 256-color, test the downsampled palette; some hues collapse together.
- In 16-color, prefer semantic terminal colors and high-intensity variants cautiously.
- In no-color, preserve all meaning through labels, prefixes, icons, borders, or ordering.

Example fallback palette:

| Role | Truecolor | 256-color | 16-color | No-color equivalent |
|--|--|--|--|--|
| `text` | `#d6deeb` | 188 | default fg | plain text |
| `muted` | `#8a93a5` | 245 | bright black | optional hints only |
| `primary` | `#82aaff` | 111 | bright blue | `>` marker or heading |
| `success` | `#7fdbca` | 116 | green | `OK`, `PASS`, `SUCCESS` |
| `warning` | `#ffcb6b` | 221 | yellow | `WARNING:` prefix |
| `error` | `#ff5370` | 203 | red | `ERROR:` prefix |
| `selected` | fg `#ffffff`, bg `#31415f` | fg 15, bg 60 | inverse | `>` marker plus focus label |
| `border` | `#4b5263` | 240 | blue/bright black | ASCII border or spacing |

Mapping function shape:

```text
resolve(role, color_level, theme):
  if color_level == none: return no_color_style(role)
  if color_level == 16: return theme.roles[role].ansi16
  if color_level == 256: return nearest_ansi256(theme.roles[role].rgb)
  return theme.roles[role].rgb
```

Never use fallback color alone as the semantic signal. The no-color column is part of the design contract, not an afterthought.

## Contrast and accessibility

Aim for WCAG-style contrast: 4.5:1 for text and 3:1 for meaningful borders, focus outlines, and chart marks. Terminal color names are user-controlled, so test common themes and provide no-color modes. Do not rely on red/green alone; color vision deficiencies can make them indistinguishable.

## Gradients and fades

Gradients can make banners, progress bars, and charts feel polished in truecolor terminals. Keep them decorative or redundant:

- Provide a single-color fallback.
- Avoid gradients behind text unless contrast is controlled.
- Use short gradients; long truecolor ramps generate many escape sequences.
- Over SSH or slow terminals, prefer static solid colors.

## Theme adaptation

Support explicit theme selection before clever automatic detection. If using OSC palette or background queries, time out quickly and treat failure as normal. Respect `NO_COLOR`, `CLICOLOR`, `CLICOLOR_FORCE`, `FORCE_COLOR`, `TERM=dumb`, non-TTY output, and app-level `--color=auto|always|never`.
