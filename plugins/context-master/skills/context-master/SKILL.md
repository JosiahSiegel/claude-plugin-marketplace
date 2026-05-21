---
name: context-master
description: |
  Universal context management and planning system. PROACTIVELY activate for: (1) ANY complex task requiring planning, (2) Multi-file projects/websites/apps, (3) Architecture decisions, (4) Research tasks, (5) Refactoring, (6) Long coding sessions, (7) Tasks with 3+ sequential steps. Provides: optimal file creation order, context-efficient workflows, extended-thinking delegation (~23x context efficiency), passive deep-analysis architecture, progressive task decomposition. Environment-agnostic — works for Web, API, and Claude Code CLI.
---

# Context Master

Universal context management and planning skill for complex tasks, long sessions, and multi-file projects. Works the same way whether you are in the Web app, the API, or Claude Code CLI; CLI-specific bonuses live in `references/claude-code-cli.md`.

This SKILL.md is intentionally short. Detailed material lives in `references/` — load only what you need.

## When to activate

Activate proactively whenever the request matches one of:

- Multi-file project (3+ related files, websites, apps, APIs, doc sets).
- Architecture or technology decision ("should we use X or Y", "which approach…").
- Research / comparison / tradeoff analysis.
- Refactoring or migration work.
- Long coding session where context efficiency matters.
- Any task with 3+ sequential steps or shared dependencies.

If the request is a single file with no dependencies, skip this skill.

## The 5-step workflow (memorize this)

For **any** multi-file project — websites, apps, APIs, documentation sets — run these five steps in order:

1. **STOP** — do not create any files yet.
2. **PLAN** — use extended thinking *or* a planning document (both equally valid; see `references/multi-file-planning.md`).
3. **ANNOUNCE** — state the file list and creation order to the user.
4. **CREATE** — write files in optimal order (foundations before dependents).
5. **VERIFY** — check that every reference resolves; fix issues before declaring done.

### Worked example (portfolio website)

```text
User: "Create a portfolio with home, about, projects, and contact pages."

Step 1 STOP    -- do not start with index.html.
Step 2 PLAN    -- "Think hard about architecture: 5 files needed,
                  styles.css is the shared dependency."
Step 3 ANNOUNCE -- "I'll create:
                  1. styles.css       (shared styling)
                  2. index.html       (references styles.css)
                  3. about.html
                  4. projects.html
                  5. contact.html"
Step 4 CREATE   -- write files in that order.
Step 5 VERIFY   -- every HTML file links styles.css; navigation resolves.

Result: no refactor, no re-export, no broken links.
```

The full template, optimal-order patterns by project type (website / React / backend API / etc.), and verification checklists are in `references/multi-file-planning.md`.

## Core principles (one line each)

1. **Plan before you write** — extended thinking or planning doc, never both skipped.
2. **Foundations first** — shared dependencies (CSS, config, base classes, schemas) precede dependents.
3. **Delegate deep analysis to isolated contexts** — subagents (CLI) or thinking artifacts (Web/API) keep the main thread clean.
4. **Phase boundaries** — name each phase ("Phase 1 complete; moving to Phase 2: …") so context doesn't blur.
5. **Artifacts over inline content** — long code or docs live in artifacts/files, not chat history.
6. **Progressive disclosure** — ask for one slice at a time; don't batch unrelated steps.
7. **Signal resets** — say "setting aside the previous approach…" when changing direction.
8. **Reflect after large projects** — was it planned? Did references break? Use the post-project checklist in `references/multi-file-planning.md`.

Full rationale and examples for every principle: `references/universal-best-practices.md`.

## Token-savings rule of thumb

| Project size | Without planning | With planning | Savings |
|---|---|---|---|
| Small (3-4 files) | ~6,000 tokens | ~2,500 tokens | ~58% |
| Medium (7-8 files) | ~12,000 tokens | ~4,500 tokens | ~63% |
| Large (20+ files) | ~35,000 tokens | ~12,000 tokens | ~66% |

A 200K-token context window holds roughly 16-17 medium projects with planning, 7-8 without — a 2.1x effective increase. Numbers and methodology in `references/multi-file-planning.md`.

## Passive deep-thinking architecture

The single most powerful pattern for context efficiency: route deep reasoning into an isolated space and return a short summary to the main thread.

- **Claude Code CLI**: `/agent deep-analyzer "Ultrathink about [decision]"` — ~5K tokens of reasoning happens out-of-band; main context receives a ~200-token summary (~23x efficiency).
- **Web / API**: `"Create a deep-analysis artifact and ultrathink about [decision]"` — same idea, artifact instead of subagent.

Triggers, anti-patterns, and ready-made prompts: `references/thinking-delegation.md`.

## Common workflows (pointers only)

Each of these has a step-by-step procedure in `references/workflows.md`:

- Workflow 0 — Multi-file website/project creation (the default — same 5 steps above with extra detail).
- Workflow 1 — Complex decision-making (architecture, tech choice).
- Workflow 2 — Complex feature development (analysis → design → implement → test → integrate).
- Workflow 3 — Research and technology evaluation.
- Workflow 4 — Code generation and iteration via artifacts.
- Workflow 5 — Refactoring with isolated analysis.

## Anti-patterns (avoid these)

Quick list — examples and fixes in `references/anti-patterns.md`:

1. Creating files before planning — wastes context on refactors.
2. Asking for everything at once — overloads context and produces shallow output.
3. Inlining long code/docs in chat — bloats history; use artifacts/files.
4. Letting deep reasoning happen in main thread — costs ~5K tokens that could be ~200.
5. No phase boundaries — context blurs across unrelated subtasks.

## Troubleshooting

When sessions drift (responses unfocused, conversations getting too long, code regenerating instead of editing, extended thinking not engaging), see `references/troubleshooting.md` for a symptom → remedy table covering Web/API and CLI separately.

## Claude Code CLI bonuses

If you are running in Claude Code CLI, you also get:

- `/clear`, `/compact`, `/continue` — built-in context controls.
- `/agent <name>` — delegate to an isolated subagent.
- `CLAUDE.md` — persistent project memory.
- Helper scripts for generating `CLAUDE.md` and subagent definitions.

Details, script invocations, and the deep-analysis delegation patterns: `references/claude-code-cli.md`.

Skill–subagent integration patterns (when both are available) live in `references/agent-skills-integration-2025.md`. Long-form context strategies and subagent prompt patterns: `references/context_strategies.md` and `references/subagent_patterns.md`.

## Reference map

| File | Use when |
|---|---|
| `references/multi-file-planning.md` | Planning template, optimal-order patterns by project type, verification checklists, post-project reflection. |
| `references/universal-best-practices.md` | Need the rationale or examples for any of the 8 core principles. |
| `references/workflows.md` | Need a step-by-step procedure for a specific scenario (decision, feature, research, refactor). |
| `references/thinking-delegation.md` | Designing a deep-analysis delegation or writing the thinking prompt. |
| `references/anti-patterns.md` | Reviewing whether the current approach is wasting context. |
| `references/troubleshooting.md` | Session is drifting, slow, or producing too much explanation. |
| `references/claude-code-cli.md` | Running in Claude Code CLI and want subagent / CLAUDE.md tooling. |
| `references/agent-skills-integration-2025.md` | Combining skills with subagents in CLI. |
| `references/context_strategies.md` | Long-form strategy notes. |
| `references/subagent_patterns.md` | Subagent prompt patterns. |

## Success indicators

- You announced the plan before creating any file.
- Foundation files (CSS, config, schemas) were written before dependents.
- No reference broke on first run; no refactor was needed.
- Deep reasoning happened in a subagent or artifact, not the main thread.
- Phases were named as you crossed them.

If any of those failed, walk back through `references/anti-patterns.md` and `references/multi-file-planning.md` post-project section before the next task.
