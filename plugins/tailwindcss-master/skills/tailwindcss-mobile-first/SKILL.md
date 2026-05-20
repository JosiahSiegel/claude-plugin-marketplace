---
name: tailwindcss-mobile-first
description: |
  Mobile-first responsive design patterns with Tailwind CSS v4 (2025-2026).
  PROACTIVELY activate for: (1) mobile-first design with Tailwind breakpoints (sm:, md:, lg:, xl:, 2xl:), (2) responsive utility ordering (default = mobile, then breakpoints), (3) responsive typography (text-base sm:text-lg lg:text-xl), (4) responsive grids and flexbox, (5) hide/show across breakpoints (hidden md:block), (6) max-* breakpoints for desktop-down overrides, (7) container queries (@container) for component-level responsiveness, (8) safe-area insets and notch handling, (9) landscape vs portrait orientation, (10) touch vs hover (hover: with @media).
  Provides: breakpoint reference, mobile-first patterns, container-query examples, safe-area recipes, and touch/hover handling.
---

# Tailwind Mobile-First Skill

Use this skill for Tailwind CSS mobile-first responsive design: breakpoint strategy, fluid typography and spacing, touch targets, container queries, safe areas, responsive layouts, media, navigation, and mobile performance.

## When to Use This Skill

Use when the user asks for tasks covered by the frontmatter triggers, especially implementation guidance, debugging, architecture choices, production hardening, or performance-sensitive decisions in this domain. Start from this orchestrator, then load the focused reference file that matches the requested detail level.

## Core Workflow

1. Start with unprefixed utilities for the mobile baseline, then progressively enhance with `sm:`, `md:`, `lg:`, `xl:`, and `2xl:`.
2. Choose breakpoints from content needs rather than device names; override Tailwind v4 theme breakpoints only when the design system requires it.
3. Use fluid typography and spacing with `clamp()` for smoother scaling between breakpoints while preserving accessibility via `rem + vw`.
4. Make interactive elements touch-safe with 44px recommended targets, adequate spacing, clear labels, and mobile navigation patterns.
5. Use container queries for reusable components that must respond to their own width instead of viewport width.
6. Reserve media dimensions with aspect-ratio utilities and use safe-area utilities for notched devices and fixed mobile UI.

## Key Gotchas

- Unprefixed Tailwind classes apply at every size; breakpoint-prefixed utilities apply at that breakpoint and above.
- Ordering classes desktop-first does not make the design desktop-first, but it often obscures intent and increases bugs.
- Hover-only interactions fail on touch devices; pair hover states with focus, active, or explicit controls.
- Videos and images without reserved aspect ratios can cause Cumulative Layout Shift.
- Fixed bottom navigation must account for safe-area insets and add content padding to avoid overlap.

## Reference Map

- [references/mobile-first-complete-guide.md](references/mobile-first-complete-guide.md) - Full original guide covering philosophy, breakpoints, fluid type/spacing, touch targets, container queries, layouts, responsive images/type, navigation, safe areas, mobile performance, testing, and responsive video patterns.

## Response Guidance

- Preserve the user's existing framework, library, and tooling choices unless there is a clear compatibility or performance reason to suggest an alternative.
- Give copy-pasteable code only for the exact task at hand; otherwise point to the relevant reference section.
- Call out tradeoffs, failure modes, and verification steps for production workflows.
- Prefer accessible, maintainable, measurable solutions over clever micro-optimizations.
