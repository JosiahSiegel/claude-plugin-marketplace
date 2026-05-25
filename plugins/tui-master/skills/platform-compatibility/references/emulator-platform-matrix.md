# Emulator and Platform Compatibility Matrix

## Feature classes

| Feature | Reliability | Notes |
|--|--|--|
| Printable UTF-8 text | High with UTF-8 locale/code page | Validate Windows code page and Unix locale. |
| CSI cursor movement and SGR | High | Baseline for full-screen apps, but still avoid on `TERM=dumb` and non-TTY output. |
| 16-color palette | High | Actual colors are theme-defined; do not assume contrast. |
| 256-color | Common | Use terminfo/library detection; remote `TERM` may lie. |
| Truecolor | Common in modern emulators | Multiplexers need correct configuration; downsample gracefully. |
| Alternate screen | Common | May be disabled by user settings or mediated by multiplexer. |
| SGR mouse | Common in modern TUIs | Touchpads create high-frequency wheel/drag streams. |
| Bracketed paste | Common | Still optional; parse boundaries safely. |
| Focus events | Mixed | Advisory only. |
| OSC 8 hyperlinks | Mixed to common | Show visible URL fallback. |
| OSC 52 clipboard | Often restricted | May be blocked by terminal, multiplexer, SSH policy, or security settings. |
| Kitty keyboard protocol / xterm modifyOtherKeys | Mixed | Push/pop safely and provide legacy fallback. |
| Images: Kitty graphics, iTerm2 images, sixel | Fragmented | Never core UI. Provide text or Unicode fallback. |

## Per-environment quirks

| Environment | Strengths | Quirks to test | Recommended posture |
|--|--|--|--|
| Windows Terminal + ConPTY | Modern VT, UTF-8 capable, tabs/panes, GPU rendering, good color support | ConPTY buffering, resize delivery, Ctrl-C/process lifetime, code page, emoji/font fallback | Support through Crossterm/tcell/Terminal.Gui/Spectre; include Windows CI smoke tests. |
| Classic conhost | Available on older Windows and server contexts | VT output may need explicit enable; older builds lack features; input differs from Unix PTY | Degrade to plain/16-color; avoid claiming advanced features without testing. |
| macOS Terminal.app | Stable default terminal, good baseline CSI/SGR | Conservative extensions, Option/Alt behavior, theme contrast, locale defaults | Use standard VT features; make iTerm2-only features optional. |
| iTerm2 | Rich extensions: images, inline files, notifications, OSC features | Proprietary protocols; settings can alter keys, paste, clipboard, and reporting | Treat extensions as enhancements with visible text fallback. |
| VTE/GNOME Terminal | Common Linux baseline, solid xterm-like behavior | Distro/version differences, OSC support varies, theme palette user-controlled | Good target for standard CSI/SGR, bracketed paste, SGR mouse. |
| Kitty | Strong protocol innovation, keyboard and graphics support, performance | Kitty keyboard/graphics are not universal; remote/multiplexer negotiation matters | Optional enhanced keyboard/images; fallback to xterm-style input. |
| Alacritty | Fast, focused emulator with standard terminal behavior | Historically limited proprietary extensions; config-driven key behavior | Good conservative baseline; do not expect images or rich OSC extensions. |
| WezTerm | Broad protocol support, multiplexing features, configurable | User configuration can change key handling; SSH/mux layers affect capabilities | Good advanced target, but still detect and fallback. |
| foot | Lightweight Wayland terminal, good standards support | Linux/Wayland-specific; server-side configuration matters | Treat as modern xterm-like; test Wayland desktop paths if target users use it. |
| tmux | Ubiquitous multiplexer, sessions survive disconnects | `TERM` describes tmux not outer terminal; truecolor/OSC 52/passthrough need config; alt screen can be affected | Use `tmux-256color` when configured; support DCS passthrough only as optional. |
| GNU screen | Older but common on servers | More limited color/extension behavior; terminfo often `screen`; OSC 52 support varies | Conservative CSI/SGR/16 or 256-color; avoid advanced protocols. |
| Zellij | Modern multiplexer with panes/layouts | Compatibility differs from tmux; input and paste handling need real tests | Treat as a distinct target, not a tmux clone. |

## Windows

- Windows Terminal plus ConPTY is the primary modern target: broad VT support, Unicode rendering, tabs/panes, GPU text rendering, themes, and copy/paste integration.
- Classic console hosts can require `ENABLE_VIRTUAL_TERMINAL_PROCESSING` for output and appropriate input modes for VT input. Older hosts may not behave like Unix PTYs.
- ConPTY is a pseudo-console API, not a byte-for-byte Unix PTY clone. It can affect buffering, dimensions, process lifetime, signal behavior, and test harness design.
- Prefer framework support such as Crossterm, tcell, Terminal.Gui, or Spectre.Console rather than hand-rolled Win32 console mode code unless necessary.

## Unix-like PTYs

- PTYs preserve the historical terminal model: termios modes, process groups, signals, `SIGWINCH`, and byte streams.
- Raw mode disables canonical line editing and may suppress signal generation depending on flags; restore termios on every exit path.
- Locale matters. A non-UTF-8 locale can break Unicode rendering even if the emulator can display it.

## macOS Terminal.app and iTerm2

- Terminal.app is conservative and integrates with macOS defaults. Test Option/Alt behavior, theme contrast, and clipboard expectations.
- iTerm2 offers proprietary image, inline file, notification, and escape-code extensions. Use them only as enhancements with clear fallback.
- Both can run remote shells or multiplexers; do not infer local capabilities from remote environment variables alone.

## Linux desktop emulators

- GNOME Terminal and many others use VTE; expect solid CSI/SGR support and common xterm extensions.
- Konsole, foot, Kitty, Alacritty, and WezTerm have different priorities: performance, protocol extensions, GPU rendering, Wayland/X11 integration, keyboard handling, and configuration depth.
- GPU-accelerated terminals can render quickly, but the application still pays for bytes sent, parser work, and SSH latency. Diff and batch writes remain important.

## Multiplexer and remote rules

- Inside tmux/screen/Zellij, the inner `TERM` often hides outer-terminal capability. Prefer conservative behavior plus explicit user overrides.
- OSC 52, OSC 8, truecolor, focus events, and image protocols may be blocked or require passthrough settings.
- SSH adds latency and can strip environment variables. Do not assume `TERM_PROGRAM` reflects the local emulator on a remote host.
- Container shells often lack locale, terminfo, and real TTY allocation unless launched with `-it`.

## Capability strategy

1. Ask for user intent through flags first: `--plain`, `--ascii`, `--no-mouse`, `--color`, `--no-tui`.
2. Use libraries and terminfo where available.
3. Treat environment variables as hints, not proof.
4. Bound terminal queries with timeouts and handle absent or malformed replies.
5. Keep a conservative path that requires only text, newline, and ordinary input.
