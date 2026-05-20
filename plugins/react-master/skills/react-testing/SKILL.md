---
name: react-testing
description: |
  Complete React testing system.
  PROACTIVELY activate for: (1) Vitest/Jest setup and configuration, (2) React Testing Library patterns, (3) Component testing with userEvent, (4) Custom hook testing with renderHook, (5) Mocking modules and components, (6) Async component testing, (7) Context and provider testing, (8) Accessibility testing with jest-axe.
  Provides: Test setup, query priority, user simulation, mock patterns, integration testing.
  Ensures reliable tests that focus on user behavior.
---

# React Testing Skill

Use this skill for React tests that focus on user behavior: Vitest/Jest setup, Testing Library queries, user-event flows, async UI, hooks, providers, mocks, integration tests, accessibility checks, and media component tests.

## When to Use This Skill

Use when the user asks for tasks covered by the frontmatter triggers, especially implementation guidance, debugging, architecture choices, production hardening, or performance-sensitive decisions in this domain. Start from this orchestrator, then load the focused reference file that matches the requested detail level.

## Core Workflow

1. Set up the runner and jsdom environment first, then centralize `@testing-library/jest-dom`, cleanup, and browser API mocks in test setup.
2. Write tests from the user perspective using role, label, text, placeholder, and display-value queries before falling back to test IDs.
3. Use `userEvent.setup()` for interactions and `waitFor` or findBy queries for async state changes.
4. Mock at module or network boundaries, not internal component state, and reset mocks between tests.
5. Create provider-aware render utilities for context, routers, query clients, themes, and other app-wide wrappers.
6. For media components, mock jsdom gaps such as `HTMLMediaElement.play`, `pause`, `load`, metadata properties, and IntersectionObserver.

## Key Gotchas

- Avoid asserting implementation details such as component state; assert visible behavior and accessibility state.
- `fireEvent` is lower-level than `userEvent`; prefer `userEvent` unless directly firing browser/media events is necessary.
- Async assertions should wait for UI changes, not arbitrary timers.
- jsdom does not implement real media playback, layout, or browser codecs; mock those APIs deliberately.
- Provider state can leak between tests unless render utilities create fresh clients and cleanup runs after each test.

## Reference Map

- [references/react-testing-complete-guide.md](references/react-testing-complete-guide.md) - Full original guide covering setup, component tests, forms, async components, hooks, context, mocks, integration tests, accessibility tests, testing utilities, and video/media testing.
- [references/testing-recipes.md](references/testing-recipes.md) - Additional testing recipes already maintained for this skill.

## Response Guidance

- Preserve the user's existing framework, library, and tooling choices unless there is a clear compatibility or performance reason to suggest an alternative.
- Give copy-pasteable code only for the exact task at hand; otherwise point to the relevant reference section.
- Call out tradeoffs, failure modes, and verification steps for production workflows.
- Prefer accessible, maintainable, measurable solutions over clever micro-optimizations.
