# State, Configuration, Distribution, and Security Reference

## MVU and reducer patterns

A robust TUI can usually be expressed as:

- `Model`: domain data plus UI state such as focus, viewport, theme, terminal size, selected IDs, modal stack, pending edits, and async status.
- `Message/Event`: decoded keyboard, mouse, paste, resize, timers, worker replies, process output, and errors.
- `Update`: pure or mostly pure state transition that returns next state and effects.
- `View`: deterministic rendering from model and terminal dimensions.
- `Effect/Command`: async work that reports completion as messages.

Do not let effects write to the screen. Effects should send messages; the renderer owns terminal output.

## Async and concurrency

- Use queues/channels/tasks to merge input, timers, worker results, and resize events.
- Make long work cancellable.
- Debounce search/filter and coalesce repeated progress updates.
- Preserve ordering for user-visible messages where it matters.
- Avoid data races between background work and rendering state.

## Configuration

- Prefer explicit CLI flags for temporary behavior and config files for persistent preferences.
- Unix-like paths: follow XDG config, state, cache, and data conventions when practical.
- Windows/macOS: use platform-appropriate app config locations rather than hard-coded dotfiles only.
- Make keybindings user-remappable; detect duplicates and conflicts.
- Store themes as semantic roles with color-level fallbacks: no-color, 16-color, 256-color, truecolor.
- Include an ASCII/Unicode preference and a reduced-motion preference.

Config path examples:

| Purpose | Unix-like | macOS | Windows |
|--|--|--|--|
| Config | `$XDG_CONFIG_HOME/app/config.toml` or `~/.config/app/config.toml` | `~/Library/Application Support/App/config.toml` | `%APPDATA%\App\config.toml` |
| State | `$XDG_STATE_HOME/app/state.json` or `~/.local/state/app/state.json` | `~/Library/Application Support/App/state.json` | `%LOCALAPPDATA%\App\state.json` |
| Cache | `$XDG_CACHE_HOME/app/` or `~/.cache/app/` | `~/Library/Caches/App/` | `%LOCALAPPDATA%\App\Cache\` |
| Data | `$XDG_DATA_HOME/app/` or `~/.local/share/app/` | `~/Library/Application Support/App/` | `%LOCALAPPDATA%\App\Data\` |

Document the exact paths in `app config paths` or `--help` output. Provide `--config`, `--no-config`, and environment overrides only when they are useful and testable.

## Packaging and distribution

- Static or mostly static binaries simplify Rust, Go, Zig, and some C/C++ deployments, but verify terminfo, TLS, and native dependencies.
- Cross-compile only if you also test on the target platform.
- Common channels include Homebrew, Scoop, Winget, MSI, distro packages, AppImage, language package managers, archives with checksums, and containers.
- Containers rarely have a rich TTY by default. Detect non-TTY and document `-it` usage if interactive mode is intended.
- Ship shell completions, examples, `--help`, manpage/docs, release notes, and an uninstall/config cleanup story.

Distribution checklist:

| Channel | Include | TUI-specific checks |
|--|--|--|
| Homebrew | formula, checksum, completions | macOS Terminal/iTerm smoke test; bottle architecture coverage. |
| Scoop | manifest, autoupdate, hash | Windows Terminal and PowerShell launch; path quoting. |
| Winget | installer manifest, version metadata | Silent install/uninstall; PATH and code-signing expectations. |
| Archives | `.tar.gz`/`.zip`, checksums, signatures | Executable bit on Unix archives; README with `--no-tui`. |
| Containers | image tags, entrypoint docs | `docker run -it`; TERM/locale; non-root config/cache path. |
| Language packages | npm/pip/cargo/nuget metadata | Native dependency availability and postinstall behavior. |

Release/upgrade checklist:

- Version is updated by the repository's version tooling, not by hand.
- Changelog includes terminal compatibility, keybinding, config, and accessibility changes.
- Config migrations are idempotent, backed up if destructive, and have `--dry-run` where appropriate.
- Exit codes remain documented: `0` success/normal quit, `1` generic failure, `2` usage/config error, `130` interrupted, plus domain-specific codes if needed.
- Upgrades do not silently enable mouse, clipboard, telemetry, or destructive keybindings.
- Old config paths either migrate or produce a clear message.
- Release artifacts are smoke-tested in non-TTY mode and at least one full-screen TUI mode.

## Terminal security

Untrusted strings can contain control bytes. If rendered raw, they may inject CSI/OSC/DCS sequences, change terminal title, create misleading hyperlinks, write clipboard data, hide output, or spoof prompts.

Malicious examples:

```text
"build failed\x1b[2J\x1b[HAll tests passed"        # clears screen and spoofs success
"name\x1b]0;prod shell\x07"                         # changes terminal title
"url\x1b]8;;https://evil.invalid\x1b\\click\x1b]8;;\x1b\\"  # misleading OSC 8 link
"copy\x1b]52;c;VE9LRU4=\x1b\\"                      # attempts clipboard write
"hide\x1b[?25l"                                      # hides cursor if not reset
"\x1b[31mERROR\x1b[0m"                               # forges styled severity
```

Safe rendering policy:

1. Treat all domain data, filenames, log lines, process output, network data, and pasted text as untrusted.
2. Style through structured spans owned by the renderer, not embedded escape sequences in data.
3. Strip or escape C0/C1 controls except explicitly allowed whitespace (`\n`, `\t`, optionally `\r` in progress parsing).
4. Replace `ESC` with visible `^[` or `\x1b` in debug/raw views.
5. Validate URLs before OSC 8; display the target URI in text or offer a reveal action.
6. Disable OSC 52 by default for untrusted content; require explicit copy action and a user setting.
7. Bound OSC/DCS parser payload length to avoid memory abuse.

Sanitization strategy:

```text
sanitize_for_terminal(input, mode):
  normalize line endings if needed
  for each grapheme or byte sequence:
    if printable Unicode scalar and not bidi-control-forbidden: keep
    else if char is allowed whitespace: keep
    else if mode == debug: append visible escape such as "\\x1b" or "^["
    else: append replacement marker or drop
  return safe text plus separate style metadata
```

For logs that may later be viewed in terminals, sanitize before writing or provide a safe viewer mode. Do not rely on downstream pagers to neutralize control sequences.

## OSC 8 and OSC 52 cautions

- OSC 8 hyperlinks should never hide a surprising destination. For package names, issue IDs, or hosts, show a visible URL in a detail panel or status line.
- OSC 52 clipboard writes can exfiltrate or overwrite clipboard data. Gate behind `--clipboard=always|ask|never`, default conservatively, and never trigger from untrusted text.
- Terminals, tmux, SSH policies, and security tools may block OSC 52. Treat failure as normal.
- When recording or sharing terminal logs, strip OSC 8/52 sequences so links and clipboard payloads are not executed by viewers.

## Error handling and restoration

- Use RAII/defer/finally/dispose guards for raw mode, alternate screen, cursor visibility, mouse, paste, focus, terminal title, palette, and keyboard modes.
- Cleanup must be idempotent and safe after partial initialization.
- Provide recovery instructions in help and docs: quit keys, `reset`, `stty sane`, reopen terminal, `--no-tui`.
- Preserve meaningful exit codes for normal quit, validation failure, interrupted operation, and unexpected crash.
