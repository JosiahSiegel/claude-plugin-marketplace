---
name: tui-fundamentals
description: |
  This skill should be used when the user asks to design, create, choose, modernize, or review a terminal UI, text user interface, curses app, dashboard, wizard, REPL shell, prompt flow, or CLI with interactive screens. PROACTIVELY activate for: TUI architecture, terminal-ui design, framework selection, curses vs modern framework, full-screen vs inline UI, app state modeling, widget composition, command palette, keyboard-first workflow, terminal dashboard, interactive CLI UX, and cross-platform terminal product planning. Provides: architecture patterns, framework decision rules, UX guardrails, scope boundaries, and production readiness checklists.
---

# TUI Fundamentals, Architecture, and Framework Selection

Use this skill when the task is about the shape of the terminal product: what kind of TUI to build, which abstraction to use, how to organize state, or whether a full-screen terminal UI is the right answer.

## First decision: is a TUI appropriate?

Prefer a rich TUI when users need continuous visual feedback, multi-step navigation, keyboard-driven exploration, selection among many items, or a dashboard-like control surface. Prefer a line-oriented CLI, prompts, or plain output when the flow is short, scriptable, primarily automation-focused, or likely to be used by screen readers and CI systems.

A production terminal product often ships both:

- A scriptable CLI surface for automation, accessibility, logs, and non-TTY use.
- An optional TUI for exploration, monitoring, bulk selection, or guided workflows.

## Architecture rules

1. **Separate model, update, and view.** Business state should not print directly to the terminal. Rendering consumes state; input produces events; update logic transforms state.
2. **Treat terminal size as input.** Layout must be recomputed from width and height on every resize. Never bake in one terminal size.
3. **Own terminal lifecycle in one place.** Raw mode, alternate screen, mouse, focus, keyboard protocols, and cleanup should be centralized.
4. **Make every action keyboard-operable.** Mouse support is an enhancement, not the primary navigation model.
5. **Design for degradation.** `TERM=dumb`, non-TTY output, missing color, Windows console differences, tmux/screen, SSH, and CI should have clear behavior.
6. **Avoid hidden global terminal writes.** Logs, progress, and background task output must not corrupt the screen.

## Framework selection quick matrix

| Need | Strong default |
|--|--|
| Rust full-screen app with precise rendering | Ratatui + Crossterm |
| Python product-grade app with widgets, CSS, async workers | Textual |
| Python rich output, progress, tables, markdown, logs | Rich |
| Python REPL, shell, completions, complex prompt input | prompt_toolkit |
| Classic dependency-light Unix TUI | curses/ncurses |
| Go Elm-style app with composable commands | Bubble Tea + Bubbles + Lip Gloss |
| Go batteries-included forms/tables/tree views | tview over tcell |
| Go portable low-level cell engine | tcell |
| React-style terminal components in Node | Ink |
| Node DOM-like full-screen widgets | Blessed |
| .NET full-screen views | Terminal.Gui |
| .NET rich CLI output and prompts | Spectre.Console |

Read `references/framework-selection.md` before committing to a framework in a new project.

## Product design checklist

- Define the primary user journey in one sentence.
- Decide whether the app is full-screen, inline, prompt-based, or hybrid.
- List required environments: Windows Terminal, classic conhost, macOS Terminal, iTerm2, GNOME Terminal, Alacritty, SSH, tmux/screen, CI, and logs.
- Define minimum terminal dimensions and the small-screen fallback.
- Define exit keys, destructive confirmation rules, and recovery instructions.
- Define non-interactive equivalents for every essential action.
- Decide how help is exposed: footer hints, `?`, command palette, `--help`, docs.

## Failure modes

- Building a full-screen UI for a workflow that should be scriptable.
- Choosing a low-level escape-sequence approach when a framework already solves layout, input, cleanup, and testing.
- Mixing business logic with terminal writes, making tests brittle and rendering inconsistent.
- Ignoring screen-reader users, CI, pipes, and `TERM=dumb` until late.
- Assuming color, Unicode icons, Nerd Fonts, or mouse support are always available.

## Reference files

- `references/framework-selection.md` - Detailed ecosystem comparison and decision tree.
- `references/tui-architecture.md` - State, event, lifecycle, logging, and distribution patterns.
