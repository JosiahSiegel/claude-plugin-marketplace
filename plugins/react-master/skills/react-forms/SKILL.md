---
name: react-forms
description: |
  Complete React forms system.
  PROACTIVELY activate for: (1) Controlled form patterns, (2) React Hook Form setup and validation, (3) Zod schema validation, (4) Dynamic fields with useFieldArray, (5) Server Actions with forms, (6) useOptimistic for optimistic updates, (7) File upload handling, (8) Multi-step form wizards.
  Provides: Form validation, error handling, field arrays, file drag-drop, form state management.
  Ensures robust form handling with proper validation and UX.
---

# React Forms Skill

Use this skill for robust React forms: controlled inputs, React Hook Form, Zod validation, dynamic arrays, Server Actions, optimistic updates, reusable fields, file uploads, drag-and-drop, and multi-step wizards.

## When to Use This Skill

Use when the user asks for tasks covered by the frontmatter triggers, especially implementation guidance, debugging, architecture choices, production hardening, or performance-sensitive decisions in this domain. Start from this orchestrator, then load the focused reference file that matches the requested detail level.

## Core Workflow

1. Choose the form model: controlled state for simple forms, React Hook Form for complex client forms, or Server Actions for framework-native submissions.
2. Define validation near the data contract; prefer schema validation such as Zod when the shape is shared or complex.
3. Wire accessibility from the start with labels, `aria-invalid`, `aria-describedby`, error text near fields, and disabled/loading submit states.
4. For dynamic fields, use stable field IDs from `useFieldArray` and preserve validation paths as items are added, removed, or moved.
5. For file uploads, validate type/size, generate previews only when appropriate, and submit via `FormData`.
6. For multi-step forms, validate only the current step before advancing and keep one form context across steps when data must persist.

## Key Gotchas

- Do not mix controlled and uncontrolled patterns on the same input without a deliberate bridge component.
- Disable submit while pending to prevent duplicate submissions.
- Always surface server-side validation errors, even when client validation exists.
- File previews can leak memory if object URLs are not revoked; Data URLs can be large for big files.
- In Server Actions, keep progressive enhancement and pending/error states visible to the user.

## Reference Map

- [references/react-forms-complete-guide.md](references/react-forms-complete-guide.md) - Full original guide covering controlled forms, validation, React Hook Form, Zod, field arrays, conditional fields, Server Actions, optimistic updates, custom components, uploads, drag-and-drop, multi-step forms, and best practices.

## Response Guidance

- Preserve the user's existing framework, library, and tooling choices unless there is a clear compatibility or performance reason to suggest an alternative.
- Give copy-pasteable code only for the exact task at hand; otherwise point to the relevant reference section.
- Call out tradeoffs, failure modes, and verification steps for production workflows.
- Prefer accessible, maintainable, measurable solutions over clever micro-optimizations.
