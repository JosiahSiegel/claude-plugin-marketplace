---
name: framework-recipes
description: |
  This skill should be used when the user asks for implementation recipes, examples, migration guidance, troubleshooting, or best practices for specific TUI frameworks and libraries: Rust Ratatui/Crossterm/Termion/Cursive, Python Textual/Rich/prompt_toolkit/curses/Urwid/asciimatics, Go Bubble Tea/Lip Gloss/Bubbles/tview/tcell/termui/gocui, Node Ink/Blessed/Inquirer/Prompts, .NET Terminal.Gui/Spectre.Console, C/C++ ncurses/notcurses/FTXUI, Zig vaxis, and SwiftTUI. PROACTIVELY activate for: framework-specific app structure, cleanup, testing, widgets, migration, library comparison, framework troubleshooting, API gotchas, and porting between TUI frameworks. Provides: framework defaults, gotchas, testing hooks, and selection recipes.
---

# Framework Ecosystem Recipes

Use this skill when the user names a specific terminal UI framework or needs practical ecosystem guidance. Fetch current official docs when exact API syntax or version-specific behavior matters.

## Rust recipes

**Ratatui + Crossterm** is the modern default for Rust full-screen TUIs. Structure apps around explicit state, event handling, and rendering functions. Use Crossterm for cross-platform terminal setup and events. Snapshot widgets at fixed sizes and integration-test the event loop through a PTY.

Guidelines:

- Keep terminal setup/cleanup in one guard.
- Render from immutable state where possible.
- Use constraints and layout primitives instead of absolute coordinates.
- Treat panics as terminal-cleanup events.

## Python recipes

**Textual** fits substantial apps with widgets, CSS-like styling, workers, and test automation. **Rich** fits rich output, progress, markdown, tables, panels, and logging. **prompt_toolkit** fits shells, REPLs, completions, multiline editing, and custom key bindings. **curses/ncurses** fits classic dependency-light TUIs with careful cleanup.

Guidelines:

- For curses, use wrapper/finally cleanup and remember coordinates are y,x.
- For Textual, separate app state from workers and test with framework-supported pilots.
- For Rich, avoid full-screen complexity when rich scrollback output solves the problem.

## Go recipes

**Bubble Tea** uses Elm-style `Model`, `Update`, and `View`. Pair with Bubbles for common controls and Lip Gloss for styles/layout. **tview** gives widget-rich apps over **tcell**. Use **tcell** directly for lower-level cell control.

Guidelines:

- Keep update logic pure where possible.
- Send long work through commands/goroutines that return messages.
- Test `Update` and `View` separately before PTY tests.

## Node and TypeScript recipes

**Ink** is best for React-style terminal components, hooks, and component testing. **Blessed** fits DOM-like widget trees and manual screen lifecycle. Prompt libraries are often better than full-screen apps for short questionnaires.

Guidelines:

- Verify resize, mouse, and Windows behavior for the exact library version.
- Keep side effects out of render functions.
- Use PTY integration tests for flows that depend on terminal behavior.

## .NET recipes

**Terminal.Gui** fits full-screen applications with views, keyboard navigation, mouse, themes, and layout. **Spectre.Console** fits rich CLI output, prompts, progress, status, trees, tables, and command app composition.

Guidelines:

- Choose Spectre.Console before Terminal.Gui when the UI can remain line-oriented.
- Abstract console I/O for tests.
- Provide non-interactive command equivalents for automation.

## C/C++, Zig, and Swift recipes

**ncurses** remains the classic portable C TUI layer. **notcurses** is useful for modern visuals, rich cells, images where supported, and high-performance terminal graphics with fallbacks. **FTXUI** offers composable C++ components and layout. **zig-vaxis** is a modern Zig TUI toolkit with Unicode-aware terminal handling. **SwiftTUI** and related Swift terminal libraries fit Swift-native CLIs, but verify platform and terminal coverage carefully.

Guidelines:

- Low-level frameworks demand explicit cleanup, Unicode measurement, and capability fallback tests.
- Prefer maintained libraries with documented Windows, tmux, and Unicode behavior.
- Avoid image/graphics features as hard requirements unless the deployment terminal is controlled.

## Reference files

- `references/rust-python-go.md` - Practical patterns for Ratatui, Textual/Rich/prompt_toolkit/curses, Bubble Tea/tview/tcell.
- `references/node-dotnet-and-selection.md` - Ink, Blessed, Terminal.Gui, Spectre.Console, migration, and selection gotchas.
- `references/low-level-and-emerging.md` - C/C++ ncurses/notcurses/FTXUI, Zig vaxis, SwiftTUI, and emerging toolkit cautions.
