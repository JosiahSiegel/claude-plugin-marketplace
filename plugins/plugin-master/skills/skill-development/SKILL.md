---
name: skill-development
description: |
  Canonical guide to authoring SKILL.md files for Claude Code plugin skills.
  PROACTIVELY activate for: (1) creating a new skill, (2) adding a skill to a plugin, (3) writing SKILL.md frontmatter, (4) fixing skills that never trigger, (5) organizing core vs references vs examples, (6) improving weak skill descriptions, (7) progressive disclosure design, (8) splitting oversized SKILL.md files, (9) imperative body style, (10) zero-frontmatter SKILL.md files, (11) removing boilerplate from YAML descriptions.
  Provides: skill template, trigger checklist, size rules, and validation process.
---

# Skill Development for Claude Code Plugins

## Overview

Skills are modular knowledge packages that extend Claude's capabilities with specialized workflows, domain expertise, and bundled resources. They transform Claude from a general-purpose agent into a specialized expert.

Skills use **progressive disclosure** - a three-level loading system that manages context efficiently:

1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - Loaded when skill triggers (~1,500-2,000 words)
3. **Bundled resources** - Loaded as needed by Claude (unlimited)

## Skill Structure

```text
skill-name/
├── SKILL.md              # Required: Core instructions
├── references/           # Optional: Detailed documentation
│   ├── patterns.md       #   Loaded when Claude needs detail
│   └── advanced.md
├── examples/             # Optional: Working code examples
│   └── example.sh        #   Users can copy and adapt
├── scripts/              # Optional: Executable utilities
│   └── validate.sh       #   Token-efficient, deterministic
└── assets/               # Optional: Output resources
    └── template.html     #   Used in output, not loaded into context
```

**Only create directories you actually need.** A minimal skill is just `SKILL.md`.

## SKILL.md Format

### Frontmatter (Required)

This is the canonical shape every new skill MUST follow. Deviating is the #1 cause of skills that never trigger.

```yaml
---
name: skill-name                                  # REQUIRED: kebab-case, matches directory name
description: One-sentence summary of what the skill covers. PROACTIVELY activate for: (1) concrete named trigger, (2) concrete named trigger, ..., (N) concrete named trigger. Provides: comma-separated capability nouns (concrete, not abstract).
---
```

Or, if the description is multi-line (only needed for very long descriptions — prefer single-line when practical):

```yaml
---
name: skill-name
description: |
  One-sentence summary. PROACTIVELY activate for: (1) trigger, (2) trigger, ..., (N) trigger. Provides: capability list.
---
```

### Hard rules for the frontmatter

1. **`name:` is required** and must match the enclosing directory name exactly (`skills/skill-name/SKILL.md` → `name: skill-name`).
2. **`description:` is required** and MUST contain BOTH the `PROACTIVELY activate for: (1)... (N)...` enumeration AND a `Provides: ...` capability list.
3. **A SKILL.md with NO frontmatter at all is broken.** It will never trigger, will not appear in skill discovery, and should be treated as a P0 bug. If you open a SKILL.md and the first line is not `---`, fix the frontmatter before doing anything else.
4. **Enumerate concrete, named triggers — not abstract capabilities.** "PROACTIVELY activate for: (1) creating Azure Functions, (2) binding config" is good. "Use this skill when working with Azure" is NOT.
5. **Describe WHEN to use, not WHAT it does.** The description drives routing, so it must read as a trigger list from the user's point of view. Put the capability summary in `Provides: ...` at the end.
6. **Keep descriptions single-line YAML-safe.** If you use `|` block scalar, do not embed unescaped colons or other YAML-confusing characters in the middle of lines.
7. **Target 400-1000 characters for the description; hard ceiling is 1024 characters (Claude Code API spec).** Claude's current listing cap is 1536 chars per entry (raised from 250 in v2.1.105), and the aggregate budget across all installed skills is ~1% of the model context window. Front-load trigger keywords. If you genuinely need more triggers than fit in ~1000 chars, prefer splitting into two skills over a bloated description.
8. **Do NOT put cross-cutting boilerplate (Windows paths, docs policy) inside the YAML description.** Put it in the markdown body.

### Canonical "good" description

```yaml
description: Expert guide to Terraform AzureRM provider for Azure infrastructure. PROACTIVELY activate for: (1) authoring AzureRM resource blocks, (2) state management (remote backends, state locking), (3) module design and composition, (4) variable and output patterns, (5) provider version pinning, (6) debugging plan/apply errors, (7) importing existing Azure resources, (8) CI/CD for Terraform (Azure DevOps, GitHub Actions). Provides: AzureRM provider patterns, state backend templates, module scaffolding, debugging playbook, and import recipes.
```

### Broken descriptions (each of these fails to route reliably)

```yaml
# BROKEN: no frontmatter at all
# (file starts with `# Skill Title` - will not appear in discovery)

# BROKEN: wrong shape, no enumeration
description: Use this skill when working with Terraform.

# BROKEN: abstract capability, no triggers
description: Provides Terraform expertise and guidance.

# BROKEN: WHAT-it-does instead of WHEN-to-use
description: This skill contains Terraform AzureRM provider documentation.

# BROKEN: second person (wrong voice)
description: You should load this skill when the user mentions Terraform.

# BROKEN: missing Provides list
description: PROACTIVELY activate for: (1) Terraform tasks. (No Provides section means the capability summary is lost.)

# BROKEN: cross-cutting Windows boilerplate inside YAML
description: |
  Terraform expert. MANDATORY: Always Use Backslashes on Windows for File Paths...
  (This is routing-match pollution. Move Windows rules to the body.)
```


### Body - Writing Style

Write the entire skill body using **imperative/infinitive form** (verb-first instructions):

**Correct (imperative):**
```text
To create a hook, define the event type.
Configure the MCP server with authentication.
Validate settings before use.
Start by reading the configuration file.
```

**Incorrect (second person):**
```bash
You should create a hook by defining the event type.
You need to configure the MCP server.
You can use the grep tool to search.
```

### Body - Structure

```markdown
# Skill Title

## Overview
[Purpose and when to use - 2-3 sentences]

## Quick Reference
[Tables with key facts, common values, or patterns]

## Core Content
[Essential procedures and workflows - the main value]

## Additional Resources

### Reference Files
- **`references/patterns.md`** - Common patterns
- **`references/advanced.md`** - Advanced techniques

### Example Files
- **`examples/example.sh`** - Working example
```

### Body - Size Guidelines

| Target | Words |
|--------|-------|
| Ideal | 1,500-2,000 |
| Maximum | 3,000 (absolute hard limit) |

**If SKILL.md exceeds 2,000 words**, move detailed content to `references/` files.

**Size enforcement process:**
1. After writing SKILL.md, count words (exclude frontmatter). Use `wc -w` or estimate ~5 words per line.
2. If over 2,000 words, identify sections that are reference material (detailed tables, exhaustive lists, server-specific configs, troubleshooting matrices) and extract them to `references/`.
3. If over 3,000 words after extraction, the skill is too broad — split into two skills or move more content to references.
4. **Never leave a section in SKILL.md just because it was written there first.** Always evaluate whether each section earns its place in the core file.

### Body - Avoiding Duplicate Content

**Within a single SKILL.md**, never repeat the same table, list, or block of content. Before adding any table or reference block, search the file for similar content already present.

**Across SKILL.md and references/**, information lives in one place only. If a detailed table is in `references/patterns.md`, SKILL.md should contain only a brief summary and a pointer to the reference file — not a copy of the table.

### The "≥ 2 verbatim copies = extract" gate (MANDATORY)

When authoring or revising any skill, before pasting a paragraph, table, checklist, or fenced code block into a SKILL.md or reference file, run this check:

```bash
# From the plugin root - adjust path to the candidate paragraph's first distinctive line:
grep -rn "FIRST_DISTINCTIVE_LINE_OF_THE_BLOCK" skills/ agents/ commands/ README.md
```

**Decision rule** (apply without exception):

| grep finds the block in | Action |
|---|---|
| 0 other files | Safe to add. Proceed. |
| 1 other file (this will be the 2nd copy) | **STOP.** Extract to `skills/_shared/<topic>.md` (cross-skill content) or `skills/<this-skill>/references/<topic>.md` (single-skill detail). Replace both call sites with a one-line pointer. |
| 2+ other files | Treat as a P1 bug. Extract immediately, then audit for further occurrences. |

This rule applies to canonical procedure paragraphs, checklists, audit tables, and any block that reads "this is the one true definition of X." It does NOT apply to short one-line definitions, frontmatter examples, or generic phrases like "Use this skill when..." — those are too small to extract usefully.

**Why "treat slices independently" is the bug it sounds like:** when revising one file at a time without grepping the rest of the plugin tree, identical canonical text ends up landing in two files. The fix is mechanical: every time you are about to commit a block longer than ~3 lines, grep first.

## Resource Types

### references/ - Documentation loaded as needed

- Detailed patterns, advanced techniques, API docs, migration guides
- Keeps SKILL.md lean while making information discoverable
- Each file can be 2,000-5,000+ words
- For large files (>10k words), include grep search patterns in SKILL.md
- **Avoid duplication**: information lives in SKILL.md OR references/, not both

### examples/ - Working code users can copy

- Complete, runnable scripts and configuration files
- Template files and real-world usage examples

### scripts/ - Executable utilities

- Validation tools, testing helpers, automation scripts
- Token-efficient (executed without loading into context)
- Should be executable and documented

### assets/ - Output resources (not loaded into context)

- Templates, images, icons, boilerplate code, fonts
- Used within the output Claude produces, not for Claude to read

## Skill Creation Process & Common Mistakes

Six-step process (use cases -> plan resources -> create structure -> write content -> validate -> iterate) and the full common-mistakes table live in `references/creation-process-and-mistakes.md`. Core distillation:

1. Identify concrete use cases and trigger phrases a user would actually say.
2. Plan reusable resources: `scripts/`, `references/`, `assets/`, `examples/`.
3. Create only the directories you need.
4. Start with the resources, then write a lean SKILL.md (third-person description, imperative body, ~1,500-2,000 words).
5. Validate frontmatter, trigger-phrase count (5+), no duplicate blocks, body under 3,000 words, all referenced files exist.
6. Iterate based on real-task usage — strengthen triggers, extract long sections to `references/`.

Common-mistake highlights: weak triggers, missing synonyms, duplicate blocks within a single SKILL.md, everything-in-one-file (8,000-word) skills, second-person body, descriptions over the 1024-char ceiling.

## Auto-Discovery

Claude Code automatically discovers skills:
1. Scans `skills/` directory for subdirectories containing `SKILL.md`
2. Loads metadata (name + description) at startup
3. Loads SKILL.md body when skill triggers based on description match
4. Loads references/examples when Claude determines they're needed

No configuration needed - just place `SKILL.md` in the right location.
