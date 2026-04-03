---
name: skill-development
description: |
  This skill should be used when the user asks to "create a skill", "add a skill to a plugin",
  "write SKILL.md", "organize skill content", "improve skill description", "set up progressive disclosure",
  "add references to a skill", "write skill frontmatter", or needs guidance on skill structure,
  progressive disclosure, writing style, or skill development best practices for Claude Code plugins.
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

```yaml
---
name: skill-name
description: |
  This skill should be used when the user asks to "specific phrase 1",
  "specific phrase 2", "specific phrase 3". Include exact phrases users
  would say that should trigger this skill.
---
```

**Description rules:**
- Use **third person**: "This skill should be used when..." (NOT "Use this skill when...")
- Include **specific trigger phrases** users would actually say
- Be **concrete**: "create a hook", "add a PreToolUse hook" (NOT "helps with hooks")
- List multiple trigger phrases to maximize activation
- **Include common synonyms** — users say "slow DAX" not "DAX performance optimization", "semantic model" not "data model", "slow query" not "query performance tuning"
- **Keep under 500 characters** — rely on keywords in plugin.json for breadth

**Trigger phrase completeness checklist:**
Before finalizing a skill description, verify it covers:
1. The skill's primary domain terms (e.g., "Power Query M" for an ETL skill)
2. Common synonyms and informal phrases users actually type (e.g., "slow report", "merge queries", "pivot/unpivot")
3. Action verbs for tasks the skill handles (e.g., "optimize", "debug", "migrate", "configure")
4. Abbreviations and acronyms users may use (e.g., "PQ" for Power Query, "DAX" for Data Analysis Expressions)
5. Problem-oriented phrases (e.g., "report is slow" not just "performance optimization")

**Good example:**
```yaml
description: |
  This skill should be used when the user asks to "create a hook",
  "add a PreToolUse hook", "validate tool use", or mentions hook events
  (PreToolUse, PostToolUse, Stop). Provides hook development guidance.
```

**Bad examples:**
```yaml
description: Use this skill when working with hooks.    # Wrong person, vague
description: Provides hook guidance.                     # No trigger phrases
description: Load when user needs hook help.             # Not third person
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
