# Charts and Terminal Data Visualization

## Visualization rules

- Every chart needs a textual summary for accessibility, logs, and no-color modes.
- Label axes or ranges unless the scale is obvious.
- Use units consistently.
- Prefer stable scales for dashboards; constantly rescaling charts hides change.
- Avoid charts when sorted numbers or a table would answer the question better.

## Horizontal bars

Horizontal bars are the most robust terminal chart.

Recommended structure: label, bar, value, unit. Right-align values and keep labels truncated consistently. Use block elements for Unicode mode and `#`, `=`, or `-` for ASCII mode. For negative values, include a zero baseline or use separate positive/negative columns.

## Vertical bars

Vertical bars can look impressive but need height. Use them for small category counts or time buckets. Add bottom labels only when they fit; otherwise use a legend or focused detail readout.

## Sparklines

Sparklines show trend, not exact values. Pair them with current, min, max, and direction text. Braille or block sparklines are compact but require Unicode fallback. Keep sampling strategy stable so changes are meaningful.

## Progress bars

Determinate progress should include at least one of: percentage, current/total, bytes, elapsed/remaining time, or current phase. Indeterminate progress should state what is happening and provide cancel instructions when possible. Segmented bars are useful for multi-phase work, but label segments or expose details on focus.

## Gauges and meters

Use gauges for bounded values such as CPU, memory, quota, health, or confidence. Show thresholds with labels, not just color. Avoid gauge shapes that consume many rows unless they are central to the product experience.

## Tables

- Separate header from rows with style or a rule.
- Align text left and numbers right.
- Keep padding predictable, usually one cell between columns.
- Freeze important identifiers when horizontal scrolling.
- Use zebra striping only as a secondary aid; selection must work without color.
- Provide sorting indicators and current sort text.

## Trees and hierarchy

Tree views need clear expansion state, indentation, and selected-node context. Use ASCII tree fallbacks for box drawing. For large trees, show path breadcrumbs, match counts, and viewport position.

## Heat maps and matrices

Heat maps require legends, no-color alternatives, and careful palette choice. Use symbols, intensity characters, or numeric overlays for users who cannot distinguish colors. Keep row and column labels visible when scrolling.

## Dashboard density

A dashboard should support decisions, not merely display metrics. Group related cards, keep refresh cadence visible, and distinguish stale data from live data. Prefer drill-down detail panes over stuffing every metric into the first screen.
