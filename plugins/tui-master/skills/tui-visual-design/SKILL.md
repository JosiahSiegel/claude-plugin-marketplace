---
name: tui-visual-design
description: |
  This skill should be used when the user asks to make a terminal UI beautiful, polished, readable, premium, modern, branded, or visually distinctive; improve visual hierarchy, spacing, typography, borders, color palettes, charts, progress displays, icons, prompts, forms, dashboards, or framework styling. PROACTIVELY activate for: TUI visual design, aesthetic polish, layout composition, terminal typography, color systems, box drawing, chart styling, animation, glyph/icon usage, prompt styling, design critique, visual anti-patterns, and framework-specific styling guidance. Provides: terminal design principles, polish checklists, visual recipes, and accessibility-aware aesthetics.
---

# TUI Visual Design and Aesthetic Polish

Use this skill when a terminal UI needs to look deliberate, elegant, readable, and production-grade, not merely functional. Good TUI design is the craft of using cells, text, whitespace, color, borders, glyphs, rhythm, and motion under harsh terminal constraints.

## Design operating principles

1. **Start with information architecture.** Decide what the user must notice first, what is secondary, and what can be hidden until requested.
2. **Design in cells.** Every visual decision consumes fixed-width character cells. Padding, borders, scrollbars, and icons must earn their space.
3. **Use fewer treatments, consistently.** A polished TUI usually has one border language, one spacing scale, one heading system, and semantic color roles.
4. **Prefer calm defaults.** High-intensity color, heavy borders, inverse video, animation, and icons should highlight state changes or actions, not decorate every element.
5. **Make degradation intentional.** Every visual design should still work in no-color, ASCII, narrow-width, light theme, remote SSH, and screen-reader-friendly modes.

## Visual hierarchy and composition

Create hierarchy with, in order: placement, spacing, grouping, text labels, alignment, weight, then color. Do not make color carry the entire hierarchy.

- Put the main task or current selection in the strongest visual anchor: top-left for scanning, centered only for modal or landing states.
- Reserve full borders for important regions; use whitespace or subtle separators for secondary grouping.
- Use a spacing scale such as 0, 1, 2, and 4 cells. Random padding makes TUIs look improvised.
- Give forms and empty states breathing room. Give dashboards density, but cluster related metrics and leave gutters between groups.
- Use progressive disclosure: collapsed sections, detail panes, command palettes, and help overlays keep the default screen calm.

## Typography and text presentation

Terminals do not give you real fonts inside the app, but they still have typographic systems.

- Treat headings as a hierarchy: title, section label, field label, hint, status. Use predictable casing and punctuation.
- Bold is best for headings, selected labels, and important values. Dim is for optional hints only, never required text.
- Italic is inconsistent across terminals; use sparingly. Underline suggests links or focus. Strikethrough is niche. Avoid blink except for legacy compatibility indicators, and never for attention grabbing.
- Align labels left, numbers right, table text left, units consistently, and actions by interaction order.
- Truncate with intent: keep IDs unique, preserve file extensions, show start and end of paths when needed, and expose full text on focus or detail view.
- Wrap prose at word boundaries and preserve indentation for code, logs, and structured output.

## Borders, boxes, and containers

Borders are punctuation. Too many boxes create visual noise.

- Use full borders for modals, focused panels, and major regions.
- Use left-only or bottom-only rules for navigation rails, active sections, and subtle grouping.
- Avoid deep nested boxes. Prefer whitespace, headings, or separators inside a bordered panel.
- Pick one border family for the product: plain ASCII, single-line, rounded, thick, or double-line. Mix only to express hierarchy.
- Padding inside a border is usually one cell horizontally. Zero padding feels cramped; excessive padding wastes terminal space.
- Shadow/depth tricks using half-blocks or dark backgrounds can look premium in controlled truecolor terminals, but need no-shadow fallback.

## Color design

Use semantic roles before raw colors: primary, accent, success, warning, error, info, muted, selected, focused, disabled, border, background, surface.

- Keep a small palette. One accent plus semantic states is enough for most TUIs.
- Avoid large background fills unless building a full-screen app with theme control. Many users customize terminal backgrounds.
- Support dark and light backgrounds. Yellow, blue, dim gray, and low-saturation colors often fail on one of them.
- Downsample deliberately for 256-color and 16-color modes. In 16-color, prefer named terminal colors over fragile RGB assumptions.
- Never encode meaning by color alone. Pair red errors with words like `Error`, icons, placement, or borders.
- Gradients can add polish to banners, charts, and progress bars in truecolor, but must collapse to solid semantic color in constrained modes.

## Charts, data visualization, and density

Terminal charts should answer a question faster than reading raw numbers.

- Horizontal bars are the safest chart: label left, value right, bar in the middle.
- Sparklines are useful for trend, not exact value. Add min/max/current text.
- Progress bars need labels, percentage or count, and a distinct incomplete region.
- Tables need alignment, padding, stable column order, and a clear focused row. Zebra striping is optional and should not replace row separators in no-color mode.
- Heat maps need legends and text alternatives because color perception and terminal palettes vary.
- For dashboards, group by decision: health, throughput, latency, errors, queue, resources. Do not fill every cell just because space exists.

## Animation and motion

Motion should communicate waiting, progress, transition, or attention; otherwise it is noise.

- Use low-frequency spinners for unknown waits and determinate bars when progress is known.
- Pause or simplify animation over SSH, in CI, in logs, with reduced-motion settings, or when rendering is expensive.
- Avoid flashing more than three times per second.
- Transitions such as slide or fade can help users maintain context, but they must be interruptible and cheap.
- Smooth scrolling is attractive for local terminals; page-based movement may be better over remote links.

## Icons, glyphs, and decorative elements

Glyphs improve scanability when they are predictable and optional.

- Use simple status symbols with labels: success, failure, warning, info, loading.
- Do not require Nerd Fonts or private-use glyphs. Offer `--ascii` or a plain icon set.
- Test emoji width and rendering before using emoji in aligned layouts.
- Use arrows and chevrons for hierarchy and navigation, but avoid ambiguous symbols in critical confirmations.
- Decorative banners, particles, and mascots should disappear in plain, narrow, CI, and accessibility modes.

## Prompts and interactive elements

A beautiful prompt makes the next action obvious.

- Put validation near the field that failed, with a clear correction path.
- Show defaults and destructive consequences in text, not just color.
- Use focus indicators that survive no-color mode: prefix marker, border change, label, or cursor position.
- Keep selection menus visually stable. Avoid moving choices while the user navigates.
- Confirmation dialogs should use calm layout, explicit action labels, and safe defaults for destructive operations.
- Toasts and notifications should be short-lived only when non-critical; persistent errors need a stable region or log panel.

## Framework styling defaults

- **Ratatui:** compose `Layout` constraints, `Block` borders, `Paragraph` wrapping, `Table` widths, and semantic `Style`s. Snapshot at fixed sizes and color modes.
- **Textual:** use CSS classes, component variants, theme variables, and transitions carefully; keep custom widgets visually consistent with built-ins.
- **Bubble Tea + Lip Gloss:** centralize styles, compose margins/padding/borders, and test `Width`/`Height` calculations with wide Unicode.
- **Rich:** define `Theme` roles, use tables/panels/progress consistently, and avoid nesting panels until output becomes visually heavy.
- **Ink:** use flex layout deliberately, centralize style tokens, and remember terminal width changes can reflow React component trees.
- **Terminal.Gui:** define color schemes and focus styles per view class; verify mouse and keyboard focus indicators match.
- **Spectre.Console:** use markup, tables, trees, rules, panels, and progress with a restrained theme and no-color fallback.

## Visual anti-patterns

- Rainbow palettes with no semantic system.
- Every widget in a heavy border.
- Tiny text crammed against borders or terminal edges.
- Color-only errors, selections, or warnings.
- Center-aligned tables or numbers.
- Icons from Nerd Fonts with no fallback.
- Animated dashboards that redraw faster than data changes.
- Designs that only work at 120 columns.
- Ignoring light terminal themes, `NO_COLOR`, `TERM=dumb`, and non-TTY output.

## Reference files

- `references/layout-typography.md` - Visual hierarchy, spacing, rhythm, typography, alignment, wrapping, and truncation.
- `references/color-design.md` - Semantic palettes, contrast, theme adaptation, gradients, and constrained color modes.
- `references/borders-icons-prompts.md` - Box drawing, containers, glyphs, icons, prompts, forms, dialogs, and notifications.
- `references/charts-visualization.md` - Bars, sparklines, gauges, progress, tables, trees, heat maps, and dashboard density.
- `references/animation-motion.md` - Spinners, motion design, transitions, scrolling, decorative effects, and performance limits.
- `references/framework-styling.md` - Visual styling recipes for Ratatui, Textual, Bubble Tea/Lip Gloss, Rich, Ink, Terminal.Gui, and Spectre.Console.
