# Universal best practices

Eight rules that apply regardless of environment (Web, API, Claude Code CLI).

## 1. Delegate complex analysis to isolated contexts

The single most powerful pattern for context efficiency.

**Claude Code:**
```text
GOOD: /agent deep-analyzer "Ultrathink about [complex decision]"
BAD:  "Think about [complex decision]"   (happens in main context)
```

**Web/API:**
```text
GOOD: "Create analysis artifact and ultrathink about [decision]"
BAD:  "Ultrathink about [decision]"      (thinking stays in conversation)
```

Benefit: ~5K tokens of reasoning happens in isolation, main context receives ~200 token summary. 23x context efficiency while maintaining analytical depth.

## 2. Use extended thinking for planning

Before diving into implementation:
```text
"think hard about the approach for [task]"
```

Even better with delegation:
- Claude Code: delegate to deep_analyzer subagent.
- Web/API: use thinking artifact.

Benefit: reasoning stays out of main context, you get thoughtful plans.

## 3. Create artifacts for substantial content

Don't inline long code or documents in conversation:
```text
GOOD: "Create a Python script artifact that [functionality]"
BAD:  "Show me the Python code for [functionality]"
```

Benefit: content lives in artifacts, not conversation history.

## 4. Break complex tasks into explicit phases

State phase transitions clearly:
```text
"Phase 1 complete. Moving to Phase 2: [description]"
```

With thinking delegation:
```text
Phase 1: /agent deep-analyzer "analyze approaches"
Phase 2: Implement based on analysis
```

Benefit: each phase has clear purpose and boundaries.

## 5. Document decisions in artifacts

Create persistent references:
```text
"Create a decisions.md artifact tracking our key choices"
```

Benefit: you can reference decisions without re-explaining full context.

## 6. Progressive disclosure

Don't request everything at once:
```text
GOOD: "First, analyze the requirements"
      "Now, design the data model"
      "Now, implement the core logic"

BAD:  "Analyze requirements, design data model, and implement everything"
```

Benefit: each step builds on the last without overwhelming context.

## 7. Use thinking for exploration

When uncertain about approach:
```text
"ultrathink about multiple approaches and recommend the best one"
```

Even better: delegate to deep_analyzer (Claude Code) or thinking artifact (Web/API).

Benefit: deep analysis without context clutter.

## 8. Signal context resets

When changing direction:
```text
"Setting aside the previous approach, let's try a different angle..."
```

Benefit: clear boundaries prevent old context from interfering.

## Advanced patterns

### Iterative refinement
```text
1. "Create initial version of [artifact]"
2. Review
3. "Improve [specific aspect]"
4. Review
5. "Add [feature]"
6. Continue iterating
```

### Multi-artifact projects
```text
1. "Create architecture.md artifact"
2. "Create database-schema.sql artifact"
3. "Create api-spec.yaml artifact"
4. "Now implement based on these artifacts"
```

### Thinking → document → execute
```text
1. "ultrathink about [complex problem]"
2. "Document the decision in a plan artifact"
3. "Execute phase 1 of the plan"
4. Reference plan artifact as you continue
```

### Chunked content generation
```text
1. "Create outline artifact"
2. "Write introduction (add to artifact)"
3. "Write section 1 (add to artifact)"
4. Continue section by section
```
