---
name: terminal-standards
description: |
  This skill should be used when the user asks about ANSI, VT100, VT220, ECMA-48, ISO 6429, xterm control sequences, terminal capability detection, terminfo, environment variables, alternate screen protocols, SGR colors, OSC, CSI, DCS, terminal graphics, Windows virtual terminal processing, ConPTY, tmux/screen, SSH, or escape-sequence compatibility. PROACTIVELY activate for: escape sequences, terminal standards, capability negotiation, raw ANSI output, xterm protocols, alternate screen, color support, OSC 8 links, OSC 52 clipboard, Kitty/iTerm2 protocols, sixel, and cross-terminal fallback design. Provides: safe protocol rules, negotiation checklists, compatibility warnings, and reference tables.
---

# Terminal Standards, Escape Sequences, and Capability Negotiation

Use this skill when code emits or parses terminal control sequences, depends on terminal features, or must behave across emulators, multiplexers, and Windows console hosts.

## Standards hierarchy

Think in layers:

1. **Baseline:** printable text, carriage return, newline, backspace, tab.
2. **ECMA-48 / ANSI / ISO 6429:** CSI controls and SGR attributes.
3. **DEC VT lineage:** cursor movement, alternate keypad modes, device status patterns, private modes.
4. **xterm conventions:** alternate screen, mouse modes, focus events, bracketed paste, OSC extensions.
5. **Modern emulator extensions:** Kitty keyboard/graphics, iTerm2 images, sixel, OSC 8 hyperlinks, OSC 52 clipboard, theme queries.
6. **Platform host behavior:** Windows virtual terminal processing, ConPTY, tmux/screen filtering, SSH latency.

The further down this stack you go, the more you need detection, fallbacks, and cleanup.

## Safer defaults

- Prefer framework abstractions and terminfo/capability libraries over hard-coded control sequences.
- Reset styles deliberately; do not rely on terminal defaults after complex SGR output.
- Treat unknown responses, missing responses, and blocked queries as normal.
- Never require clipboard, images, focus events, or extended keyboard protocols for core functionality.
- When enabling a mode, register a cleanup path before continuing.

## Common sequences and caveats

| Feature | Typical sequence | Caveat |
|--|--|--|
| Alternate screen | `CSI ? 1049 h` / `CSI ? 1049 l` | May be disabled or mediated by multiplexers. Cleanup is mandatory. |
| SGR reset | `CSI 0 m` | Reset before exit and after errors. |
| Truecolor | `CSI 38;2;R;G;B m` / `CSI 48;2;R;G;B m` | Downsample to 256/16/no-color when needed. |
| Bracketed paste | `CSI ? 2004 h` / `CSI ? 2004 l` | Parse paste boundaries; disable on exit. |
| SGR mouse | `CSI ? 1006 h` plus tracking modes | Requires parser and coordinate validation. |
| Focus events | `CSI ? 1004 h` | Treat as advisory; may not arrive. |
| OSC 8 links | `OSC 8 ; ; URI ST` | Provide visible URL fallback. |
| OSC 52 clipboard | OSC 52 | Often blocked by terminals, multiplexers, SSH policies, or security settings. |
| DCS passthrough | `DCS ... ST` | Used by multiplexers and some protocols; highly environment-dependent. |
| Terminal title | `OSC 0/2` | Restore or avoid changing titles unexpectedly. |
| Palette queries/changes | OSC 4/10/11 variants | Useful but fragmented; restore changes and time out queries. |

See `references/escape-sequence-field-guide.md` for detailed tables.

## Capability negotiation checklist

- Is stdout a TTY? If not, avoid cursor controls and interactive modes by default.
- Is `TERM` meaningful? Handle `dumb`, empty, and unknown values.
- Is the app inside tmux/screen? Assume some protocols are filtered or need passthrough.
- Is Windows VT processing enabled for classic console APIs?
- Does the library expose color level detection? Prefer it over ad hoc environment parsing.
- Are user overrides available: `--color`, `--no-color`, `--plain`, `--ascii`, `--no-mouse`?
- Are query timeouts bounded so the app does not hang waiting for terminal replies?

## Cleanup contract

If enabling raw mode, alternate screen, mouse tracking, bracketed paste, focus events, cursor hiding, or keyboard protocols, verify cleanup on normal quit, Ctrl-C, panic, exception, fatal error, failed partial initialization, and test assertion failures.

## Reference files

- `references/escape-sequence-field-guide.md` - ANSI/VT/xterm controls and cautions.
- `references/capability-negotiation.md` - Detection and fallback patterns across terminals.
