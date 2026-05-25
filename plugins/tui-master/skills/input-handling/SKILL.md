---
name: input-handling
description: |
  This skill should be used when the user asks about TUI input handling, raw mode, cbreak mode, terminal keyboard parsing, Esc vs Alt ambiguity, Ctrl-C, shortcuts, focus management, mouse events, scroll wheel, bracketed paste, paste safety, command palettes, forms, text editing, resize events, or keybinding design. PROACTIVELY activate for: raw mode, keyboard input, keybindings, mouse support, paste handling, focus model, terminal forms, text input, vim/emacs-style shortcuts, input conflicts, and cross-platform Windows/macOS/Linux input behavior. Provides: input architecture, shortcut rules, focus patterns, paste/mouse safety, and failure-mode triage.
---

# TUI Input Handling, Raw Mode, Keyboard, Mouse, Paste, and Focus

Use this skill when a TUI reads keys, handles shortcuts, supports mouse, edits text, manages focus, or needs safe paste behavior.

## Input contract

- Only enter raw or cbreak mode for interactive TTY sessions.
- Provide non-interactive alternatives for scripts, pipes, and CI.
- Keep input decoding separate from application actions.
- Make every action reachable by keyboard.
- Treat mouse support as optional progressive enhancement.
- Preserve expected terminal shortcuts unless the user can rebind them.

## Raw mode rules

Raw mode disables line discipline and changes signal behavior. Centralize it and restore it reliably. Verify behavior for Ctrl-C, Ctrl-Z/suspend where supported, EOF, resize, terminal close, and fatal exceptions. Passwords and tokens must not echo.

## Keybinding design

Good keybindings are discoverable, consistent, and conflict-aware.

- Always provide visible help for common actions.
- Use `q`, Esc, or Ctrl-C for quit/cancel only when consistent with workflow risk.
- Confirm destructive actions; require stronger confirmation for irreversible work.
- Avoid stealing common terminal, shell, editor, and multiplexer shortcuts unless configurable.
- Support both mnemonic shortcuts and navigational keys where possible.
- Distinguish global shortcuts from focused-widget shortcuts.

## Focus model

Every interactive element needs:

- A stable identity.
- Focus eligibility rules.
- A visible focus indicator that does not rely on color alone.
- Tab/Shift-Tab or arrow navigation when appropriate.
- Clear behavior for disabled, hidden, modal, and nested controls.
- Mouse click behavior that updates focus before activating actions.

## Paste and mouse safety

Enable bracketed paste for shells, editors, command palettes, and multiline inputs. Parse paste start/end markers and treat pasted text as data, not a sequence of commands. For mouse input, validate coordinates against the current layout and ignore stale events after resize.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Esc feels delayed | parser waiting to distinguish Alt prefix | tune timeout or use framework protocol support |
| Ctrl-C does not exit | raw mode swallowed signal | map Ctrl-C explicitly and restore terminal |
| Paste triggers actions | no bracketed paste or paste treated as keystrokes | enable paste protocol and route as text |
| Mouse clicks wrong row | stale layout after resize or scroll | validate coordinates against current viewport |
| Focus disappears | no focused fallback after removing widget | compute next eligible focus target |

## Reference files

- `references/input-protocols.md` - Keyboard, mouse, paste, focus, and resize event details.
- `references/keybinding-design.md` - Shortcut design, conflict avoidance, and forms/editors.
