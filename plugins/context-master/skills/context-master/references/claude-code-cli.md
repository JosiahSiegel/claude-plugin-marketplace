# Claude Code CLI tooling

Bonus features only available when using Claude Code CLI. Web and API users can skip this reference.

## Generate CLAUDE.md

Create a context-optimized CLAUDE.md for your project:

```bash
python scripts/generate_claude_md.py --type [TYPE] --output ./CLAUDE.md
```

Available types:
- `general` - general-purpose projects
- `backend` - API/service projects
- `frontend` - web applications
- `fullstack` - full-stack applications
- `data` - data science / ML projects
- `library` - library / package development

Claude Code reads CLAUDE.md automatically, providing persistent project guidance across sessions.

## Create subagents

For recurring tasks, create dedicated subagents:

```bash
python scripts/create_subagent.py [NAME] --type [TYPE] --output [DIR]
```

Types:
- `researcher` - documentation searches with deep analysis
- `tester` - test execution with failure analysis
- `analyzer` - code analysis with architectural insights
- `builder` - build / deployment tasks
- `deep_analyzer` - complex decisions requiring extensive thinking (recommended for architecture, tech choices, design patterns)

This writes `.claude/agents/[NAME].md`. Invoke with:
```text
/agent [NAME] [task description]
```

## Built-in commands

- `/clear` - reset context between tasks
- `/compact` - compress context while preserving key decisions
- `/continue` - resume previous session
- `/agent [NAME]` - delegate task to a subagent with isolated context

## Patterns

### Deep-analysis delegation
```text
1. /clear (start fresh)
2. /agent deep-analyzer "Ultrathink about [complex decision]"
3. [Receives well-reasoned analysis in ~200 tokens]
4. Make decision and implement
5. Main context stayed clean throughout
```

### Research with thinking
```text
1. /agent pattern-researcher "Research [topic] and think hard about implications"
2. [Subagent searches + thinks in isolation]
3. Review findings in main context
4. Proceed with informed decision
```

### TDD with analysis
```text
1. Write test in main context
2. /agent test-runner "Run test and think hard if it fails"
3. [Subagent analyzes root cause in isolation]
4. Implement fix based on analysis
5. /agent test-runner "verify"
6. If passing: commit and /clear
```

### Architecture evolution
```text
1. /agent analyzer "Think deeply about current architecture issues"
2. [Receives analysis: bottlenecks, technical debt, opportunities]
3. /agent deep-analyzer "Recommend evolution strategy"
4. Create EVOLUTION.md plan
5. /clear
6. Execute plan phase by phase
```

### Large refactoring with thinking
```text
1. /agent analyzer "Think hard about refactoring scope and risks"
2. [Receives risk assessment + strategy]
3. Create REFACTOR.md plan
4. /clear
5. For each file:
   - Load and refactor
   - /agent test-runner "analyze test results"
   - /clear before next
```

For detailed Claude Code patterns see `subagent_patterns.md` and `context_strategies.md`.

## Scripts

### `generate_claude_md.py`

```bash
python scripts/generate_claude_md.py --type TYPE --output PATH
```

Options:
- `--type` project type (general, backend, frontend, fullstack, data, library)
- `--output` output path (default: `./CLAUDE.md`)

### `create_subagent.py`

```bash
python scripts/create_subagent.py NAME --type TYPE --output DIR
```

Options:
- `NAME` agent name (e.g., `test-runner`, `doc-searcher`)
- `--type` agent type (researcher, tester, analyzer, builder, deep_analyzer)
- `--output` output directory (default: current directory)
