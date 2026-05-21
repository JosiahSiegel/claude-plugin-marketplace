# Passive deep-thinking architecture

The key insight: extended thinking can happen in isolated contexts (subagents on Claude Code, thinking artifacts on web/API), keeping the main session lean while still getting deep analysis.

## Architectural pattern

```text
Main Session (Orchestrator)
├─ Stays high-level and focused
├─ Makes decisions based on summaries
└─ Delegates complex analysis

        ↓ delegates with thinking triggers ↓

Analysis Layer (Agents/Artifacts)
├─ Extended thinking happens HERE (5K+ tokens)
├─ Deep reasoning happens HERE
├─ Context-heavy work happens HERE
└─ Returns concise summaries UP (~200 tokens)

        ↑ returns actionable conclusions ↑

Main Session
└─ Receives well-reasoned recommendations
└─ Context stays clean for sustained work
```

## How this achieves passive deep thinking

**Without thinking delegation:**

- Extended thinking happens in main context.
- Reasoning accumulates (~5K tokens per analysis).
- Context fills quickly over long sessions.
- Eventually hits limits.

**With thinking delegation:**

- Subagents/artifacts do extended thinking in isolation.
- Main context only receives summaries (~200 tokens).
- Can sustain 25+ analyses before context issues.
- Deep thinking happens passively through architecture.

**Key benefit:** You get the depth of extended thinking without the context cost.

## Implementation by environment

### Claude Code: thinking subagents

```bash
# Create a deep analyzer for complex decisions
python scripts/create_subagent.py architecture-advisor --type deep_analyzer

# Create thinking-enabled researcher
python scripts/create_subagent.py pattern-researcher --type researcher
```

Usage:
```text
Main session: "I need to decide between microservices and monolith"
↓
/agent architecture-advisor "Analyze microservices vs monolith
for an e-commerce platform with 10M users, considering team size
of 8 developers"
↓
Subagent's isolated context:
  - Uses "ultrathink" automatically
  - 5K+ tokens of deep reasoning
  - Evaluates tradeoffs thoroughly
↓
Returns to main: "After deep analysis, I recommend starting with
a modular monolith because [3 key reasons]. Microservices would
add complexity your team size can't support yet."
↓
Main session: Receives actionable advice, context clean
```

Context saved: ~4,800 tokens per analysis.

### Web/API: thinking artifacts

```text
User: "Analyze the best database for this use case"

Claude: "I'll create a deep analysis artifact where I can think
through this thoroughly."

[Creates artifact: "database-analysis.md"]
[Inside artifact:
  - Extended thinking block (collapsed in UI)
  - Detailed analysis
  - Comparison tables
  - Final recommendation
]

Main conversation: "Based on the analysis artifact, I recommend
PostgreSQL because [2-sentence summary]. See artifact for complete
reasoning including performance comparisons and scaling considerations."
```

Why this works:

- Thinking is visually separated (in artifact).
- Main conversation stays summary-focused.
- User can reference artifact when needed.
- Conversational context stays lean.

## When to delegate vs keep in main

**Delegate to thinking agents/artifacts for:**

- Architecture decisions
- Technology evaluations
- Complex tradeoff analysis
- Multi-factor comparisons
- Design pattern selection
- Performance optimization strategies
- Security assessment
- Refactoring approach planning

**Keep in main context for:**

- Simple implementation
- Quick queries
- Tactical decisions with obvious answers
- Tasks requiring full project context

## Example: state management for React app

**Traditional approach (main context):**
```text
User: "What state management should I use?"
Claude: [5K tokens of thinking in main context]
Claude: [Another 2K tokens explaining recommendation]
Total: ~7K tokens consumed
```

**Thinking-delegation approach:**
```text
User: "What state management should I use for a large e-commerce app?"

Claude Code:
"This warrants deep analysis. Let me delegate to a deep analyzer."
/agent architecture-advisor "Think deeply about state management
options (Redux, Zustand, Jotai, Context) for large-scale e-commerce
with real-time inventory"

[Subagent uses ultrathink in isolated context - 5K tokens]
[Returns summary - 200 tokens]

Main context: "The advisor recommends Zustand for these reasons..."
Total in main: ~300 tokens
```

Context efficiency: 23x improvement while maintaining analytical depth.

## Compound effect over long sessions

**Without delegation:**

- Analysis 1: 7K tokens
- Analysis 2: 7K tokens
- Analysis 3: 7K tokens
- Analysis 4: 7K tokens
- Analysis 5: 7K tokens
- Total: 35K tokens (17% of 200K context)

**With delegation:**

- Analysis 1: 300 tokens
- Analysis 2: 300 tokens
- Analysis 3: 300 tokens
- Analysis 4: 300 tokens
- Analysis 5: 300 tokens
- Total: 1.5K tokens (0.75% of 200K context)

Result: 23x more analyses in the same context window while maintaining analytical rigor.
