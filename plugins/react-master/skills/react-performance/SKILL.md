---
name: react-performance
description: |
  Complete React performance optimization system.
  PROACTIVELY activate for: (1) React.memo and memoization, (2) useMemo and useCallback usage, (3) Code splitting with React.lazy, (4) List virtualization (react-window, react-virtuoso), (5) Avoiding unnecessary re-renders, (6) useTransition and useDeferredValue, (7) Bundle optimization, (8) Web Vitals and profiling.
  Provides: Profiler setup, memoization patterns, lazy loading, virtualization config, state colocation.
  Ensures optimal React performance with measurable improvements.
---

# React Performance Skill

Use this skill to diagnose and improve React rendering, bundle size, Web Vitals, list performance, image/media loading, state placement, and responsiveness with measurable before/after evidence.

## When to Use This Skill

Use when the user asks for tasks covered by the frontmatter triggers, especially implementation guidance, debugging, architecture choices, production hardening, or performance-sensitive decisions in this domain. Start from this orchestrator, then load the focused reference file that matches the requested detail level.

## Core Workflow

1. Measure first with React DevTools Profiler, Web Vitals, browser performance tools, or a bundle analyzer before changing code.
2. Identify the bottleneck class: unnecessary re-renders, expensive calculations, large lists, large bundles, slow interactions, image/media loading, or state placed too high.
3. Apply the smallest targeted fix: state colocation, composition, memoization, virtualization, lazy loading, dynamic import, or concurrent rendering APIs.
4. For media-heavy UIs, protect video element identity, avoid remounting, use refs for imperative controls, and lazy-load sources with IntersectionObserver.
5. Re-measure after each change and keep only optimizations that improve duration, Web Vitals, memory, decoder churn, or bundle size.

## Key Gotchas

- Memoization has overhead; use `React.memo`, `useMemo`, and `useCallback` for measured hotspots or stable prop boundaries, not everywhere.
- Custom `React.memo` comparisons can be slower than rendering if they perform deep equality on large structures.
- Index keys in filtered/reordered lists can cause remounts and state loss, especially costly for video elements.
- Video elements are stateful browser resources; remounting can destroy hardware decoders and buffered playback state.
- Concurrent features improve responsiveness but do not make expensive work disappear; they schedule non-urgent work.

## Reference Map

- [references/react-performance-complete-guide.md](references/react-performance-complete-guide.md) - Full original guide covering measurement, memoization, code splitting, virtualization, render avoidance, concurrent features, images, bundles, media elements, decoder pools, and mobile video performance.
- [references/virtualization-guide.md](references/virtualization-guide.md) - Detailed virtualized-list guide already maintained for this skill.

## Response Guidance

- Preserve the user's existing framework, library, and tooling choices unless there is a clear compatibility or performance reason to suggest an alternative.
- Give copy-pasteable code only for the exact task at hand; otherwise point to the relevant reference section.
- Call out tradeoffs, failure modes, and verification steps for production workflows.
- Prefer accessible, maintainable, measurable solutions over clever micro-optimizations.
