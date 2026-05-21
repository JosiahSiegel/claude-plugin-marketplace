# Canonical Pre-Publish Checklist

Every item below must be true before publishing any plugin in this marketplace.

- [ ] `plugin.json` exists at `.claude-plugin/plugin.json` and is valid JSON
- [ ] `name` is kebab-case
- [ ] `author` is an object `{ "name": "..." }` — not a string
- [ ] `version` is a string `"1.0.0"` — not a number
- [ ] `keywords` is an array — not a string
- [ ] No `agents` / `skills` / `slashCommands` fields in `plugin.json` (auto-discovered)
- [ ] Every agent file starts with `---` (YAML frontmatter present)
- [ ] Every agent has a `name:` field (not the deprecated `agent: true` flag)
- [ ] Every agent has `model: inherit`
- [ ] Every agent has `<example>` blocks **if its body exceeds 2,500 words** (3-5 preferred). Lean orchestrators under 2,500 words are exempt — see `agent-development` SKILL.md "Example-block requirement by agent body size".
- [ ] Every agent has a `color:` field
- [ ] Every agent has `tools:` (minimal set) or omits the field for full tool access
- [ ] Every `SKILL.md` starts with `---` (NOT `# Title`)
- [ ] Every skill `description:` contains `PROACTIVELY activate for:` enumeration
- [ ] Every skill `description:` contains `Provides:` capability list
- [ ] Every skill `description:` is under 1024 characters (target 400-1000)
- [ ] No Windows / docs / cross-cutting boilerplate inside any YAML `description:` field
- [ ] No verbatim duplicate blocks across skills — the mandatory DRY-gate grep (see `references/size-and-dry-gates.md`) has been run for every newly added block and any 2nd-copy hit was extracted to `skills/_shared/` or `references/` before commit
- [ ] No smart-punctuation inside fenced code blocks — see "Code-sample sanity pass" section below
- [ ] Every fenced code block has a language tag — see "Code-sample sanity pass" section below
- [ ] Every executable snippet is dual-form (POSIX + PowerShell) or explicitly platform-tagged — see "Code-sample sanity pass" section below
- [ ] Every SKILL.md is under the 3,000-word ceiling, and any skill within 200 words of the ceiling has had its largest reference-style sections extracted to `references/` (see `references/size-and-dry-gates.md`)
- [ ] If the plugin ships any vendored, derived, or licensed third-party content, `NOTICES.md` exists at the plugin root, has no duplicate H2 sections for the same upstream, preserves required license text, and is cross-referenced from `README.md` and `plugin.json` where applicable (see `plugin-master` skill, `references/publishing-guide.md` publishing checklist)
- [ ] If a `marketplace.json` exists at repo root, the plugin is registered there with matching `description` and `keywords`
