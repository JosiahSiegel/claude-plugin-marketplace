# Layout, Visual Hierarchy, and Typography

## Composition checklist

- Define the primary user question for each view, then place the answer in the strongest location.
- Use a consistent spacing scale: 0 for dense tables, 1 for panels and lists, 2 for section gaps, 4 for empty states or landing screens.
- Keep gutters between split panes. If panes touch, add a separator or contrasting heading.
- Leave at least one cell between text and a border when space allows.
- Align related elements on the same columns across screens to create rhythm.
- Use progressive disclosure: summary first, details on focus, expanded rows, side panels, or command palette.

## Visual weight ladder

Use weight deliberately from quiet to loud:

1. Plain text and whitespace.
2. Muted text, small labels, section spacing.
3. Separators or single-side borders.
4. Bold headings or selected values.
5. Full borders, inverse video, or accent color.
6. Modal overlay, danger color, or high-intensity fill.

If many items use levels 5-6, nothing is important.

## Information density patterns

- **Minimal prompts:** one question, one hint, one error region, one action path.
- **Spacious forms:** labels in a stable column, inputs aligned, help below focused field, group separators.
- **Dense dashboards:** compact cards, abbreviated labels, clear units, grouped metrics, detail drill-down.
- **Data explorers:** table/list takes primary space; filters, status, and help remain peripheral.

## Common layout recipes

Use sketches during design review. They expose impossible density before implementation.

```text
Sidebar/detail          Table/detail             Wizard
┌──────┬─────────┐      ┌────────────────┐       ┌─ Step 2 of 4 ───┐
│ nav  │ detail  │      │ filter         │       │ Label [____]    │
│ > a  │ title   │      ├────┬────┬──────┤       │ Error near field│
│   b  │ body    │      │ >  │ id │ msg  │       │ Back Next Cancel│
└──────┴─────────┘      ├────┴────┴──────┤       └─────────────────┘
footer: quit/help       │ selected detail│
                        └────────────────┘

Dashboard               Tiny fallback
┌ CPU ┐ ┌ Mem ┐         App needs 60x15.
│ 42% │ │ 7G  │         Current: 32x8.
└─────┘ └─────┘         Use --plain or --json.
┌ logs/status ─┐        q quit
└──────────────┘
```

Recipe rules:

- Sidebar/detail: separate navigation selection from detail scroll; collapse navigation first on narrow screens.
- Table/detail: render only visible rows; keep full selected content in a detail pane.
- Wizard: show progress, field-local validation, Back/Next/Cancel, and non-interactive equivalents.
- Dashboard: include units and text values; throttle updates and support reduced motion.
- Tiny fallback: define minimum dimensions and keep quit/recovery instructions visible.

## Terminal typography

Terminal apps inherit user fonts. Do not assume Nerd Fonts, ligatures, or emoji rendering. Recommend programming fonts for users only when documenting setup; the app itself must survive ordinary monospace fonts.

- Use title case or sentence case consistently.
- Keep headings short; terminals punish verbose labels.
- Use bold for headings and key values. Use dim for hints only.
- Avoid blink. Use italic and underline only where terminal support is acceptable.
- Use monospace affordances: columns, indentation, rulers, and stable prefixes.

## Alignment rules

- Left-align text, commands, labels, filenames, and descriptions.
- Right-align numbers, durations, counts, percentages, and sizes.
- Align decimals when comparing numeric values.
- Put units in a consistent suffix column or repeat them in every value when scanning matters.
- Center only banners, empty states, and modal titles; never center dense tabular content.

## Wrapping and truncation

- Wrap prose on word boundaries and preserve paragraphs.
- Do not wrap table cells unless row height expansion is part of the design.
- For paths, prefer middle truncation: keep root or context plus basename and extension.
- For hashes and IDs, keep enough prefix/suffix to distinguish values.
- For commands, preserve leading tokens and show continuation markers.
- Expose full truncated content in a detail pane, tooltip-like help, copy action, or expanded row.
