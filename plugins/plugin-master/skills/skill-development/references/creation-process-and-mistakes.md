# Skill Creation Process & Common Mistakes

Six-step process for authoring a skill plus the full common-mistakes table. SKILL.md keeps a brief summary; this reference has the details.

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
| Description over 1024 chars (API spec ceiling) | Split into two focused skills; do not bloat to fit |
| Description over 1000 chars but under 1024 (dilutes matching) | Front-load triggers; collapse near-duplicate enumeration items |
| Agent body duplicates skill content | Agent is a lean orchestrator — domain knowledge belongs in skills only |
| Skill body too large (>3,000 words) | Split into core SKILL.md + references/ files |

