# Keybinding Design Reference

## Shortcut hierarchy

1. Global lifecycle keys: help, quit, cancel, command palette.
2. Navigation keys: arrows, Tab, Shift-Tab, PageUp/PageDown, Home/End.
3. Focused widget keys: editor movement, list selection, table sorting.
4. Mode-specific keys: vim-style normal/insert, search, multi-select.
5. Destructive actions: require confirmation and visible labels.

## Conflict avoidance

Be careful with shortcuts commonly used by shells, terminals, editors, OSes, and multiplexers: Ctrl-C, Ctrl-D, Ctrl-Z, Ctrl-S, Ctrl-Q, Ctrl-L, Ctrl-R, Ctrl-A/E, Ctrl-U/K/W, Ctrl-Left/Right, Cmd/Ctrl-C/V for copy/paste, tmux prefix combinations, and terminal search shortcuts. Make advanced bindings configurable.

## Text input behavior

Users expect familiar editing behavior: left/right by grapheme, word movement, deletion, selection where supported, paste as literal text, history navigation in command prompts, masked secrets, and validation errors near the field. Do not measure cursor position by bytes.

## Discoverability

Show a footer for primary actions, context-specific help for focused widgets, and a complete help overlay or command palette. Help text should mention how to exit, how to recover from display corruption, and how to run non-interactively.
