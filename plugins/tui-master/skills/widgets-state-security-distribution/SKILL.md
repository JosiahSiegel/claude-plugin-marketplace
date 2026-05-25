---
name: widgets-state-security-distribution
description: |
  This skill should be used when the user asks about TUI widgets, forms, dialogs, tables, trees, charts, command palettes, split panes, scrollbars, validation, state management, Elm/MVU architecture, async message passing, configuration, packaging, distribution, terminal security, escape-sequence injection, paste sanitization, or production hardening. PROACTIVELY activate for: widget design, validation, virtual scrolling, config/keybinding files, XDG paths, packaging, secure terminal output, and release readiness. Provides: widget contracts, state patterns, config, security, and distribution checklists.
---

# Widgets, State, Configuration, Security, and Distribution

Use this skill when a TUI needs product-level interaction patterns, robust application state, secure terminal handling, user customization, or shipping guidance.

## Widget design principles

- Every widget has state, focus rules, keyboard behavior, mouse behavior if supported, validation, accessibility fallback, and snapshot tests.
- Keep interactions predictable: lists navigate, tables sort/filter/page, forms validate near fields, dialogs trap focus, command palettes search commands, and scrollbars indicate position without being required.
- Virtualize large lists/tables/trees and keep viewport offset, selection, and expanded nodes in state.
- For charts, progress bars, spinners, and dashboards, provide textual summaries and reduced-motion/no-animation modes.

## State and event architecture

Prefer an explicit model-update-view or reducer architecture:

1. Model stores domain state and UI state.
2. Events/messages represent keys, mouse, paste, resize, timers, worker results, and errors.
3. Update transforms state and schedules side effects.
4. View renders from state and dimensions.
5. Effects run asynchronously and return messages.

This keeps rendering deterministic, makes tests cheap, and prevents background tasks from writing directly to the terminal.

## Configuration and customization

- Use XDG base directories on Unix-like systems where appropriate; use platform-native config/cache/state locations on Windows and macOS.
- Allow keybinding remapping for advanced users and conflict-heavy environments such as tmux/Zellij.
- Store themes as semantic roles, not raw widget-specific colors.
- Validate config files strictly and show actionable errors in plain output if the TUI cannot start.

## Terminal security

Terminal output is an interpreter. Sanitize untrusted text before writing it to a terminal or logs that may later be viewed in a terminal. Escape-sequence injection can change titles, write clipboard data, spoof prompts, hide text, or corrupt display state.

- Strip or visibly escape control characters from untrusted data unless intentionally rendering them.
- Treat pasted text as data, not commands.
- Bound paste length and validate after paste completes.
- Avoid automatic OSC 52 clipboard writes from untrusted content.
- Make hyperlinks visible and avoid misleading link text.

## Distribution rules

- Document supported terminals and fallbacks.
- Ship a `--no-tui` path for automation, accessibility, and incident recovery.
- Package with platform conventions: static binaries where feasible, Homebrew/Scoop/Winget/MSI/packages as appropriate, shell completions, manpages, and checksums.
- In containers, detect missing TTY and provide line-oriented behavior.
- Ensure crash cleanup works in release builds, not just development.

## Reference files

- `references/widget-patterns.md` - Common terminal widgets, behavior contracts, and anti-patterns.
- `references/state-config-distribution-security.md` - MVU state, async effects, config, packaging, and terminal security.
