---
name: skill-development
description: Canonical guide to authoring SKILL.md files for Claude Code plugin skills. PROACTIVELY activate for: (1) creating a new skill, (2) adding a skill to a plugin, (3) writing SKILL.md frontmatter (name, description with PROACTIVELY/Provides enumeration), (4) fixing skills that never trigger, (5) organizing skill content (core vs references vs examples vs scripts vs assets), (6) improving a weak skill description, (7) setting up progressive disclosure (3-level loading), (8) splitting oversized SKILL.md (>2000 words) into references, (9) writing skill body in imperative voice, (10) diagnosing and fixing zero-frontmatter SKILL.md files, (11) moving cross-cutting boilerplate (Windows paths, docs policy) out of YAML descriptions. Provides: canonical skill frontmatter template, broken-pattern catalog, progressive-disclosure layout, trigger-phrase completeness checklist, size guidelines and enforcement process, and a validation checklist covering every known mistake that breaks skill triggering.
---

# Skill Development for Claude Code Plugins

## Overview

Skills are modular knowledge packages that extend Claude's capabilities with specialized workflows, domain expertise, and bundled resources. They transform Claude from a general-purpose agent into a specialized expert.

Skills use **progressive disclosure** - a three-level loading system that manages context efficiently:

1. **Metadata** (name + description) - Always in context (~100 words)
2. **SKILL.md body** - Loaded when skill triggers (~1,500-2,000 words)
3. **Bundled resources** - Loaded as needed by Claude (unlimited)

## Skill Structure

```
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
7. **Target under ~800 characters for the description.** Longer descriptions dilute matching. If you genuinely need more triggers, prefer splitting into two skills over a bloated description.
8. **Do NOT put cross-cutting boilerplate (Windows paths, docs policy) inside the YAML description.** Put it in the markdown body.

### Canonical "good" description

```yaml
description: Expert guide to Terraform AzureRM provider for Azure infrastructure. PROACTIVELY activate for: (1) authoring AzureRM resource blocks, (2) state management (remote backends, state locking), (3) module design and composition, (4) variable and output patterns, (5) provider version pinning, (6) debugging plan/apply errors, (7) importing existing Azure resources, (8) CI/CD for Terraform (Azure DevOps, GitHub Actions). Provides: AzureRM provider patterns, state backend templates, module scaffolding, debugging playbook, and import recipes.
```

### Broken descriptions (each of these fails to route reliably)

```yaml
# BROKEN: no frontmatter at all
# (file starts with `# Skill Title` — will not appear in discovery)

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
```
To create a hook, define the event type.
Configure the MCP server with authentication.
Validate settings before use.
Start by reading the configuration file.
```

**Incorrect (second person):**
```
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

## Skill Creation Process

### Step 1: Understand Use Cases

Identify concrete examples of how the skill will be used. Ask:
- What functionality should this skill support?
- What would a user say that should trigger this skill?
- What tasks does this skill help with?

### Step 2: Plan Resources

Analyze each use case to identify what reusable resources would help:
- **Scripts**: Code that gets rewritten repeatedly → `scripts/`
- **References**: Documentation Claude should consult → `references/`
- **Assets**: Files used in output → `assets/`
- **Examples**: Working code to copy → `examples/`

### Step 3: Create Structure

```bash
mkdir -p plugin-name/skills/skill-name/{references,examples,scripts}
touch plugin-name/skills/skill-name/SKILL.md
```

Only create directories you actually need.

### Step 4: Write Content

1. Start with reusable resources (scripts/, references/, assets/)
2. Write SKILL.md:
   - Frontmatter with third-person description and trigger phrases
   - Lean body (1,500-2,000 words) in imperative form
   - Reference supporting files explicitly

### Step 5: Validate

- [ ] SKILL.md has valid YAML frontmatter with `name` and `description`
- [ ] Description uses third person ("This skill should be used when...")
- [ ] Description includes specific trigger phrases (minimum 5 distinct phrases)
- [ ] Description includes common synonyms and informal terms users actually type
- [ ] Description includes problem-oriented phrases, not just feature names
- [ ] Body uses imperative/infinitive form (not second person)
- [ ] Body is under 3,000 words (ideally 1,500-2,000; detailed content in references/)
- [ ] No duplicate tables, lists, or content blocks within the same SKILL.md
- [ ] No duplicated information between SKILL.md and references/
- [ ] All referenced files actually exist
- [ ] Examples are complete and working
- [ ] Scripts are executable

### Step 6: Iterate

After using the skill on real tasks:
1. Notice struggles or inefficiencies
2. Strengthen trigger phrases in description
3. Move long sections from SKILL.md to references/
4. Add missing examples or scripts
5. Clarify ambiguous instructions

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Weak trigger description ("Provides guidance") | Add specific phrases: "create X", "configure Y" |
| Missing synonyms in description | Add informal terms users actually type: "slow report" not just "performance optimization" |
| Duplicate table/block within same SKILL.md | Search the file before adding any table — never repeat the same content block |
| Everything in one SKILL.md (8,000 words) | Move details to references/, keep SKILL.md under 2,000 |
| Second person ("You should...") | Imperative form ("Configure the server...") |
| Missing resource references | Add "Additional Resources" section listing references/ and examples/ |
| Duplicated content across files | Put info in SKILL.md OR references/, never both |
| Same block copied into multiple SKILL.md files | Cross-cutting content (platform guidelines, etc.) belongs in the agent body or one shared reference — NEVER copied into each skill |
| Wrong person in description | Third person: "This skill should be used when..." |
| Description too long (>500 chars) | Condense description; use plugin.json keywords for breadth |
| Agent body duplicates skill content | Agent is a lean orchestrator — domain knowledge belongs in skills only |
| Skill body too large (>3,000 words) | Split into core SKILL.md + references/ files |

## Auto-Discovery

Claude Code automatically discovers skills:
1. Scans `skills/` directory for subdirectories containing `SKILL.md`
2. Loads metadata (name + description) at startup
3. Loads SKILL.md body when skill triggers based on description match
4. Loads references/examples when Claude determines they're needed

No configuration needed - just place `SKILL.md` in the right location.
