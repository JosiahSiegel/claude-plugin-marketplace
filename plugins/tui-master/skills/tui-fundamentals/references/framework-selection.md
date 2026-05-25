# TUI Framework Selection Reference

## Selection decision tree

1. **Is the output primarily read-only?** Use rich output libraries before a full-screen app: Rich or Spectre.Console for tables, progress, markdown, trees, logs, and status panels.
2. **Is the interaction mostly questions and answers?** Use prompt libraries: prompt_toolkit, Inquirer-style libraries, Spectre prompts, or Huh-like forms.
3. **Does the user need persistent navigation, panes, tables, editors, or live state?** Use a full-screen framework.
4. **Do you need complete control over cell rendering?** Use a low-level cell engine such as tcell, Crossterm/Ratatui backend abstractions, or ncurses.
5. **Do you need automation equally supported?** Ship CLI commands and machine-readable output beside the TUI.

## Ecosystem notes

### Rust

Ratatui is the default for modern Rust TUIs. It is immediate-mode: the app redraws the whole logical frame while the backend optimizes terminal writes. Pair with Crossterm for practical cross-platform support. Avoid scattering terminal setup across modules; use one terminal manager and an event loop that can shut down cleanly.

### Python

Textual is best for substantial applications: CSS-like styling, widgets, reactive state, workers, and test tooling. Rich is best for non-full-screen presentation. prompt_toolkit is best for shells, completions, multiline input, key bindings, and terminal prompt sophistication. curses is appropriate for small dependency-light classic TUIs, but demands careful cleanup and platform testing.

### Go

Bubble Tea is a good default when the Elm architecture fits: `Model`, `Update`, `View`, commands, and messages. Lip Gloss handles styling and layout. Bubbles provides common components. tview gives higher-level widgets over tcell. tcell is the lower-level portable cell abstraction when you need custom rendering.

### Node and TypeScript

Ink is strongest when React mental models and component tests matter. Blessed offers a DOM-like widget tree and has a large ecosystem, but verify maintenance, resize behavior, mouse handling, and Windows behavior for your target versions.

### .NET

Terminal.Gui is suited to full-screen keyboard-first apps with views and layout. Spectre.Console is suited to rich command-line output, prompts, progress, status, and command app composition.

## Avoid direct ANSI when

- You need robust input parsing.
- You need resize handling, mouse, paste, or raw mode.
- You need cross-platform Windows behavior.
- You need deterministic tests.
- You need complex layout or focus.

Direct ANSI is acceptable for tiny controlled surfaces, status lines, progress indicators, or library internals that already have capability fallbacks.
