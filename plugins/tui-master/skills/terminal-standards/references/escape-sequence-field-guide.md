# Escape Sequence Field Guide

## Naming and byte forms

| Name | 7-bit form | 8-bit C1 form | Typical use | Notes |
|--|--|--|--|--|
| `ESC` | `0x1b` | n/a | Introduces many control sequences | Show as `^[` in debug views. |
| `CSI` | `ESC [` | `0x9b` | Cursor, erase, SGR, mode set/reset, reports | Emit 7-bit form for broad UTF-8 compatibility. |
| `OSC` | `ESC ]` | `0x9d` | Title, hyperlinks, clipboard, palette queries | Terminate with BEL or ST. Treat payload as sensitive. |
| `DCS` | `ESC P` | `0x90` | Device control, sixel, tmux passthrough | Must be terminated by ST; never leave open. |
| `ST` | `ESC \\` | `0x9c` | String terminator for OSC/DCS/APC/PM | Prefer ST for OSC 8 and nested/passthrough cases. |
| `SGR` | `CSI ... m` | `0x9b ... m` | Rendition attributes and colors | Reset deliberately at style boundaries. |

Prefer 7-bit escape forms in application output. Many terminals accept 8-bit C1 controls, but UTF-8 byte streams, log processors, PTYs, and security filters commonly assume the `ESC`-prefixed form.

## Practical CSI table

| Intent | Sequence | Example | Caution |
|--|--|--|--|
| Move cursor | `CSI {row};{col} H` or `f` | `ESC[10;1H` | 1-based coordinates; only in controlled regions. |
| Relative moves | `CSI n A/B/C/D` | `ESC[3A` | Do not move outside the app-owned area. |
| Clear screen | `CSI 2 J` | `ESC[2J` | Does not necessarily clear scrollback. |
| Clear scrollback + screen | `CSI 3 J` plus `CSI 2 J` | `ESC[3JESC[2J` | User-hostile outside full-screen apps. |
| Clear line | `CSI 2 K` | `ESC[2K` | Useful for inline progress; pair with carriage return. |
| Hide/show cursor | `CSI ? 25 l` / `CSI ? 25 h` | `ESC[?25l` | Restore on every exit path. |
| Save/restore cursor | `ESC 7`/`ESC 8` or `CSI s`/`CSI u` | `ESC7...ESC8` | Semantics vary; alt-screen 1049 includes cursor save/restore. |
| Set title | `OSC 0 ; title ST` | `ESC]0;appESC\\` | Sanitize title; restore if you change it. |
| Device status report | `CSI 6 n` | terminal replies `CSI row;col R` | Bound with timeout; handle no or malformed reply. |
| Primary DA query | `CSI c` | terminal replies e.g. `CSI ? 1;2 c` | Fingerprinting is unreliable; do not block startup. |

## SGR rules and reset edge cases

| Intent | SGR | Notes |
|--|--|--|
| Reset all | `0` | Clears colors and most attributes; safest style boundary. |
| Bold / faint off | `22` | Turns off both bold and faint; there is no universal separate bold-only off. |
| Italic off | `23` | Italic support is mixed. |
| Underline off | `24` | Clears single/double underline in most terminals. |
| Blink off | `25` | Avoid blink for accessibility. |
| Inverse off | `27` | Needed if using selected rows with inverse video. |
| Foreground default | `39` | Prefer over `0` when only ending foreground color. |
| Background default | `49` | Prefer over `0` when only ending background color. |
| 16 colors | `30-37`, `90-97`, `40-47`, `100-107` | Theme-defined RGB; contrast is not guaranteed. |
| 256 colors | `38;5;n`, `48;5;n` | Indexes 16-231 are color cube; 232-255 grayscale. |
| Truecolor | `38;2;R;G;B`, `48;2;R;G;B` | Semicolon form is most widely emitted. |

Implementation pattern:

```text
render(style, text): SGR(style) + sanitize(text) + SGR(reset_to_parent_or_0)
```

Do not concatenate independently styled fragments without knowing the active parent style. If a bold red label is followed by red normal text, use `22` instead of `0` when preserving the foreground matters. If style nesting is hard, emit `0` then reapply the parent style at every boundary.

## DEC private modes and alternate screen variants

DEC private modes use `CSI ? number h` to set and `CSI ? number l` to reset.

| Mode | Set | Reset | Use |
|--|--|--|--|
| Cursor visible | `?25h` | `?25l` | Usually hide during draw, show on exit. |
| Application cursor keys | `?1h` | `?1l` | Changes arrow-key encoding; framework should manage. |
| Bracketed paste | `?2004h` | `?2004l` | Required for editors/shells that distinguish paste. |
| SGR mouse | `?1006h` | `?1006l` | Prefer over legacy mouse encodings. |
| Button event mouse | `?1002h` | `?1002l` | Press/release/drag; can be noisy. |
| Any event mouse | `?1003h` | `?1003l` | Very noisy; avoid unless needed. |
| Focus events | `?1004h` | `?1004l` | Advisory focus in/out events. |
| Alternate screen old | `?47h` | `?47l` | Historical xterm alt buffer; avoid new code. |
| Alternate screen no cursor save | `?1047h` | `?1047l` | Switch buffers; no cursor save/restore. |
| Save/restore cursor only | `?1048h` | `?1048l` | Not an alt buffer by itself. |
| Alternate screen with cursor save | `?1049h` | `?1049l` | Preferred full-screen TUI sequence. |

For full-screen apps, use a guard that enters `?1049h`, enables raw/input modes as needed, hides cursor only around rendering if desired, and reverses modes in opposite order. Multiplexers or user settings may inhibit alternate screen; your app should still quit cleanly.

## OSC and DCS tables

| OSC | Form | Use | Security posture |
|--|--|--|--|
| `0` / `2` title | `OSC 0;title ST` | Window/tab title | Escape or strip controls from title. |
| `8` hyperlink | `OSC 8;params;uri ST label OSC 8;; ST` | Clickable links | Show URI or provide reveal action; sanitize label and URI. |
| `52` clipboard | `OSC 52;c;base64 ST` | Clipboard copy | Require explicit user action; many terminals block. |
| `10/11/12` palette queries | `OSC 10;? ST` etc. | Foreground/background/cursor color | Optional; use short timeout and fallback theme. |
| Emulator-specific | varies | Images, notifications, marks | Progressive enhancement only. |

OSC termination:

- BEL termination: `ESC ] 0;title BEL` is common for titles and older tools.
- ST termination: `ESC ] 8;;https://example.invalid ESC \\ label ESC ] 8;; ESC \\` is safer for nested contexts and avoids accidental BEL bytes in payload handling.
- When parsing, accept both BEL and ST. When emitting OSC 8 or long structured payloads, prefer ST.

DCS examples:

| DCS | Example | Notes |
|--|--|--|
| tmux passthrough | `ESC Ptmux; ESC ESC]52;c;BASE64 ESC\\ ESC\\` | Outer DCS wraps an escaped inner sequence. |
| sixel | `ESC P q ... ESC\\` | Graphics support is fragmented; provide text fallback. |
| terminfo-style queries | terminal-specific | Do not depend on replies unless bounded and validated. |

Tmux DCS passthrough pattern for OSC 52:

```text
# Inner OSC: ESC ] 52 ; c ; BASE64 ST
# tmux DCS wrapper doubles ESC bytes inside the payload.
ESC P tmux ; ESC ESC ] 52 ; c ; BASE64 ESC ESC \\ ESC \\
```

In code, prefer a library that understands tmux passthrough. If hand-rolling, unit-test the exact bytes and provide a `--no-clipboard` or `--clipboard=never` switch.

## Query timeout cautions

Terminal queries are optional. Never block startup indefinitely waiting for `CSI 6 n`, OSC palette responses, Kitty keyboard negotiation, or DA replies.

Recommended pattern:

1. Start with conservative defaults from flags, TTY detection, terminfo, and environment hints.
2. Send a query only after entering a mode where you can read terminal input without stealing user keystrokes.
3. Wait tens to a few hundred milliseconds depending on context; make timeout configurable for remote links only if necessary.
4. Accept malformed, missing, delayed, or interleaved replies without crashing.
5. Cache the capability decision for the session; do not query every frame.

Delayed replies can arrive after the timeout and look like user input. Input parsers must route recognized reports separately and ignore stale replies where possible.

## Terminfo and termcap examples

Terminfo describes the terminal named by `TERM`, which may be a multiplexer such as `screen-256color` or `tmux-256color`, not the outer emulator.

Useful capabilities:

| Capability | Meaning | Example use |
|--|--|--|
| `cup` | cursor position | Move to row/col with parameterized sequence. |
| `clear` | clear screen | Initial draw in controlled full-screen apps. |
| `el` / `ed` | clear to end of line/display | Inline status and damage cleanup. |
| `smcup` / `rmcup` | enter/leave cursor-addressing mode | Often maps to alternate screen. |
| `civis` / `cnorm` | hide/show cursor | Restore with `cnorm`. |
| `setaf` / `setab` | set ANSI foreground/background | Use for 8/16/256-color paths. |
| `colors` | color count | Pick no/16/256-color palette. |
| `sitm` / `ritm` | italic enter/exit | May be absent even when emulator supports italic. |

Shell checks during debugging:

```sh
infocmp "$TERM" | less
printf '%s\n' "TERM=$TERM COLORTERM=${COLORTERM-} TMUX=${TMUX-}"
tput colors
tput smcup; printf 'alternate\n'; sleep 1; tput rmcup
```

Use terminfo through framework APIs where possible. Hard-coded xterm sequences are acceptable only for controlled, documented targets or progressive enhancements with fallbacks.

## Cursor and screen rules

- Cursor movement is safe only when stdout is an interactive terminal under the app's control.
- Avoid absolute cursor positioning in normal scrollback unless implementing a known inline progress region.
- Hide cursor only when you can restore it.
- Alternate screen is appropriate for full-screen TUIs, not for short commands where users expect scrollback.
- Logs must not contain raw control sequences from untrusted data; render escapes visibly in debug output.

## Keyboard protocols

Legacy terminal keyboard encoding is ambiguous: Esc can mean Escape or Alt-prefix; Ctrl combinations collide with control bytes; function keys vary. Modern protocols can disambiguate, but must be optional. If enabling Kitty keyboard protocol or xterm modified-key modes, push mode on entry, pop it on exit, and preserve ordinary shortcuts as fallbacks.

## Graphics and hyperlinks

OSC 8 hyperlinks, sixel, Kitty graphics, and iTerm2 images improve UX in capable terminals but are not universal. Provide text fallbacks. Do not put critical state only in an image or hyperlink.
