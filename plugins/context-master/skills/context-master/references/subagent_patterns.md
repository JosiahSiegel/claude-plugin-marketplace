# Subagent Patterns

Common patterns and best practices for using subagents in Claude Code, with emphasis on thinking delegation for context efficiency.

## The Thinking Delegation Paradigm

**Core insight:** Subagents have isolated context windows. When subagents use extended thinking, that reasoning happens in THEIR context, not the main session's context.

**This enables:**
- Deep analysis (5K+ thinking tokens)
- Main context receives summaries (~200 tokens)
- 23x context efficiency while maintaining analytical rigor
- Sustainable long sessions with multiple complex analyses

**The architecture:**
```text
Main Session: Makes decisions, stays focused
    ↓ delegates with thinking trigger
Subagent: Uses extended thinking in isolation (5K tokens)
    ↑ returns summary
Main Session: Receives actionable conclusion (200 tokens)
```

**Context math:**
- Traditional: 7K tokens per analysis in main context
- With delegation: 300 tokens per analysis in main context
- Efficiency gain: 23x

## Thinking-Enabled Subagent Types

### Deep Analyzer (Type: deep_analyzer)

**Purpose:** Complex decisions requiring extensive analysis

**What it does:**
- ALWAYS uses "ultrathink" for analysis
- Evaluates multiple approaches
- Considers tradeoffs and implications
- Returns well-reasoned recommendations

**When to use:**
- Architecture decisions
- Technology evaluations
- Design pattern selection
- Performance optimization strategies
- Security assessments
- Refactoring approach planning

**Example usage:**
```text
/agent architecture-advisor "Should we use microservices or modular monolith 
for a 10M user e-commerce platform with 8 developers?"

[Subagent thinks deeply in isolation - 5K tokens]
[Returns to main: ~200 token summary with recommendation]
```

### Pattern Researcher (Type: researcher)

**Purpose:** Research with analytical thinking

**What it does:**
- Searches documentation/code
- Uses "think hard" for multi-source analysis
- Synthesizes insights with reasoning
- Returns analysis, not just data

**When to use:**
- API pattern research
- Best practice discovery
- Technology comparison
- Design pattern evaluation

**Example usage:**
```text
/agent pattern-researcher "Research authentication patterns in our codebase 
and think hard about which approach fits our scale requirements"

[Subagent searches + analyzes - 3K tokens thinking]
[Returns: Summary of patterns with reasoned recommendation]
```

### Code Analyzer (Type: analyzer)

**Purpose:** Architectural insights and deep code analysis

**What it does:**
- Analyzes code structure
- Uses "think harder" for architecture
- Identifies implications and opportunities
- Returns actionable insights

**When to use:**
- Architecture assessment
- Technical debt identification
- Performance bottleneck analysis
- Refactoring opportunity discovery

**Example usage:**
```text
/agent code-analyzer "Think deeply about our authentication system's 
architecture and identify improvement opportunities"

[Subagent analyzes + thinks - 4K tokens]
[Returns: Key findings with prioritized recommendations]
```

### Test Analyzer (Type: tester)

**Purpose:** Test execution with failure analysis

**What it does:**
- Runs test suites
- Uses "think hard" when tests fail
- Analyzes root causes
- Returns actionable diagnostics

**When to use:**
- Test suite execution
- Failure diagnosis
- Regression analysis
- Coverage assessment

**Example usage:**
```text
/agent test-analyzer "Run the auth test suite and if failures occur, 
think hard about root causes"

[Subagent runs tests, analyzes failures - 2K tokens thinking]
[Returns: Test status + root cause analysis if needed]
```

## Core Principles

**Subagents have isolated context windows** - They only send relevant information back to the main orchestrator, not their full context. This makes them ideal for tasks that generate lots of intermediary results.

**When to use subagents:**
- Searching through large codebases
- Analyzing multiple files for patterns
- Research tasks with extensive documentation
- Running tests or builds
- Any investigation that doesn't need full project context

**When NOT to use subagents:**
- Quick single-file edits
- Simple queries that need immediate response
- Tasks requiring full project context for decision-making

## Common Patterns

### Pattern 1: Research → Plan → Implement

**Main Context:**
```text
1. "Use a subagent to search our codebase for similar authentication implementations"
2. [Review subagent findings]
3. "think about the best approach based on those examples"
4. [Implement in main context]
```

**Why it works:** Research generates lots of search results that would clutter main context. Main agent only sees the summary.

---

### Pattern 2: Parallel Investigation

**Main Context:**
```text
"Spin up three subagents:
1. One to analyze our error handling patterns
2. One to check test coverage
3. One to review documentation

Report back with key findings from each."
```

**Why it works:** Each subagent has its own context window. They can work in parallel without interfering with each other.

---

## 🚨 CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- ❌ WRONG: `D:/repos/project/file.tsx`
- ✅ CORRECT: `D:\repos\project\file.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems


### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional - avoid AI-generated tone
- **User preference**: Only create additional .md files when user specifically asks for documentation


---

### Pattern 3: Test-Driven Workflow

**Main Context:**
```text
1. Write tests in main context
2. "Use a subagent to run the test suite and report results"
3. [Implement fixes based on failures]
4. "Subagent: run tests again"
5. [Repeat until passing]
```

**Why it works:** Test output can be verbose. Subagent filters it down to pass/fail status and specific failures.

---

### Pattern 4: Build Verification

**Main Context:**
```text
1. Make code changes
2. "Subagent: run the build and verify it succeeds"
3. [If build fails, review error]
4. [Fix and repeat]
```

**Why it works:** Build logs are long. Subagent only reports success/failure and relevant errors.

---

### Pattern 5: Multi-File Analysis

**Main Context:**
```text
"Use a subagent to:
1. Find all files using the old API
2. Analyze migration complexity
3. Return list of files and complexity assessment"

[Review findings]
"Create a migration plan based on that analysis"
```

**Why it works:** File searching and analysis stays in subagent. Main context gets clean summary for planning.

## Usage Syntax

### Starting a Subagent

```text
/agent <agent-name> <task-description>
```

or in natural language:

```text
"Use a subagent to [task]"
"Spin up a subagent for [task]"
"Delegate [task] to a subagent"
```

### Pre-configured vs Ad-hoc

**Pre-configured agents** (stored in `.claude/agents/`):
```text
/agent test-runner run the full test suite
```

**Ad-hoc agents** (created on the fly):
```text
"Use a subagent to search the codebase for error handling patterns"
```

## Example Subagent Configurations

### Research Subagent

**File:** `.claude/agents/researcher.md`

```markdown
# Researcher

Documentation and code search specialist

## Instructions

Search through documentation and code efficiently. Return only the most 
relevant information with specific file paths and line numbers. 
Summarize findings concisely.

## Allowed Tools
- read
- search
- web_search

## Autonomy Level
Medium - Take standard search actions autonomously
```

### Test Runner Subagent

**File:** `.claude/agents/test-runner.md`

```markdown
# Test Runner

Automated test execution and reporting

## Instructions

Execute test suites and report results clearly. Focus on:
- Pass/fail status
- Specific failing tests
- Error messages and stack traces
- Coverage metrics if available

## Allowed Tools
- bash
- read

## Autonomy Level
High - Execute tests fully autonomously
```

### Code Analyzer Subagent

**File:** `.claude/agents/analyzer.md`

```markdown
# Analyzer

Code analysis and pattern detection

## Instructions

Analyze code structure and identify:
- Duplicate patterns
- Complexity hotspots
- Dependency relationships
- Potential issues

Provide actionable insights with specific locations.

## Allowed Tools
- read
- search
- bash

## Autonomy Level
Medium - Analyze autonomously, ask before making suggestions
```

## Anti-Patterns

### ❌ Using Subagents for Everything

**Bad:**
```text
"Use a subagent to edit this single file"
```

**Why:** Overhead of subagent isn't worth it for simple tasks.

**Good:**
```text
"Edit this file to add the new function"
```

---

### ❌ Not Providing Clear Task Scope

**Bad:**
```text
"Use a subagent to look at the code"
```

**Why:** Too vague. Subagent doesn't know what to focus on.

**Good:**
```text
"Use a subagent to search for all database query patterns and assess 
which ones are vulnerable to SQL injection"
```

---

### ❌ Expecting Full Context Transfer

**Bad:**
```yaml
Main: [Long discussion about architecture]
Then: "Subagent: implement that plan we just discussed"
```

**Why:** Subagent doesn't have access to your conversation history.

**Good:**
```text
"Subagent: implement the authentication module with:
- JWT tokens
- Refresh token rotation
- Rate limiting
Based on our existing user service patterns."
```

## Performance Tips

1. **Front-load research** - Use subagents early for research, then implement in main context
2. **Batch similar tasks** - One subagent for all file searches, not separate subagents per file
3. **Clear instructions** - Be specific about what the subagent should return
4. **Iterate in main context** - Use main context for back-and-forth refinement
5. **Trust the summary** - Don't ask subagent to return full documents

## Advanced: Chaining Subagents

**Scenario:** Complex analysis requiring multiple specialized agents

```text
1. "Subagent: search for all API endpoints and list them"
2. [Review list]
3. "Subagent: for each endpoint in that list, check test coverage"
4. [Review coverage report]
5. "Subagent: analyze the untested endpoints and estimate testing effort"
```

**Why chaining works:** Each subagent builds on the previous results without cluttering the main context with intermediary data.

---

## Thinking Delegation Patterns

### Pattern 1: Deep Decision Analysis

**Problem:** Need to make complex architectural decision

**Traditional approach (main context):**
```text
"Think deeply about microservices vs monolith"
[5K tokens of thinking in main context]
```

**Thinking delegation approach:**
```text
/agent deep-analyzer "Ultrathink about microservices vs monolith 
for 10M user platform, 8 dev team, considering deployment, maintenance, 
scaling, and team velocity"

[Subagent's isolated context: 6K tokens of thinking]
[Main receives: 250 token summary + recommendation]
```

**Context saved:** 5,750 tokens (~97%)

---

### Pattern 2: Research → Think → Recommend

**Problem:** Need to research options and provide reasoned recommendation

**Workflow:**
```text
Step 1: Research phase
/agent pattern-researcher "Research state management libraries 
and think hard about tradeoffs"

[Subagent searches + analyzes in isolation]
[Returns: Options with pros/cons]

Step 2: Decision phase
/agent deep-analyzer "Based on these options, ultrathink and 
recommend best fit for our use case"

[Subagent thinks deeply in isolation]
[Returns: Recommendation with rationale]

Step 3: Implementation
[Main context implements based on recommendation]
```

**Why it works:** Research and analysis isolated, implementation focused

---

### Pattern 3: Iterative Analysis Refinement

**Problem:** Need to analyze multiple aspects without context accumulation

**Workflow:**
```text
Round 1: /agent analyzer "Think about performance implications"
[Returns summary to main]

Round 2: /agent analyzer "Think about security implications"  
[Returns summary to main]

Round 3: /agent deep-analyzer "Synthesize performance and security 
analyses, recommend approach"
[Returns final recommendation to main]

Main context: Make decision with 3 concise summaries (~600 tokens total)
```

**vs Traditional:**
```text
"Think about performance" [3K tokens in main]
"Think about security" [3K tokens in main]
"Synthesize" [needs both analyses in context]
Total: 6K+ tokens
```

**Context efficiency:** 10x improvement

---

### Pattern 4: Parallel Deep Analysis

**Problem:** Multiple independent analyses needed

**Workflow:**
```text
/agent analyzer-1 "Think deeply about database options"
/agent analyzer-2 "Think deeply about caching strategies"
/agent analyzer-3 "Think deeply about API design patterns"

[Each analyzes in parallel, isolated contexts]
[Each returns summary]

/agent deep-analyzer "Synthesize these analyses into coherent architecture"
[Returns integrated recommendation]
```

**Why it works:** Multiple deep analyses happen without accumulating in main context

---

### Pattern 5: Test-Driven Development with Thinking

**Problem:** TDD cycle fills context with test output and debugging analysis

**Traditional TDD:**
```text
Write test → Run test (verbose output) → Debug (thinking in main) → Fix → Repeat
[Context fills with test output + debugging thinking]
```

**Thinking delegation TDD:**
```text
1. Write test in main context (focused)
2. /agent test-analyzer "Run test, if failure think hard about root cause"
3. [Subagent runs + analyzes in isolation]
4. [Returns: Status + root cause analysis if needed]
5. Fix based on analysis in main context
6. /agent test-analyzer "Verify fix"
7. Repeat until passing
```

**Why it works:** Test output and failure analysis isolated, main context stays implementation-focused

---

### Pattern 6: Refactoring with Deep Assessment

**Problem:** Large refactoring needs strategy without filling main context

**Workflow:**
```text
Step 1: Assessment
/agent analyzer "Think deeply about refactoring scope, risks, 
and approach for legacy auth system"

[Subagent analyzes codebase + thinks in isolation - 4K tokens]
[Returns: Risk assessment + strategy - 300 tokens]

Step 2: Planning
Create REFACTOR.md in main context based on strategy

Step 3: Execution
/clear
For each module:
  - Refactor based on plan
  - /agent test-analyzer "verify changes"
  - Commit
  - /clear
```

**Why it works:** Deep analysis happens once (isolated), execution follows clean plan

---

### Pattern 7: Compound Decision Making

**Problem:** Multi-layer decision with dependencies

**Workflow:**
```text
Layer 1: Foundation decision
/agent deep-analyzer "Ultrathink: Relational vs NoSQL for our use case"
[Returns: Relational recommended]

Layer 2: Specific technology
/agent deep-analyzer "Given relational choice, ultrathink: 
PostgreSQL vs MySQL vs MariaDB"
[Returns: PostgreSQL recommended with reasoning]

Layer 3: Architecture details
/agent deep-analyzer "Given PostgreSQL, ultrathink: Replication 
strategy for our scale"
[Returns: Streaming replication recommended]

Main context: Has 3 clear decisions (~600 tokens total)
```

**vs Traditional:** All thinking would accumulate in main context (12K+ tokens)

---

## Advanced Thinking Patterns

### Meta-Pattern: Thinking Chain

For extremely complex decisions requiring multiple analytical lenses:

```text
1. /agent deep-analyzer "Analyze from business perspective"
2. /agent deep-analyzer "Analyze from technical perspective"
3. /agent deep-analyzer "Analyze from security perspective"
4. /agent deep-analyzer "Analyze from cost perspective"
5. /agent deep-analyzer "Synthesize all perspectives and recommend"

Main context receives: 5 concise analyses → integrated recommendation
Total in main: ~1K tokens
vs Traditional: 25K+ tokens of accumulated thinking
```

### Meta-Pattern: Thinking Cascade

When decision depends on answering prior questions:

```yaml
Q1: /agent deep-analyzer "Should we build or buy?"
    [Returns: Build recommended because...]

Q2: /agent deep-analyzer "Given building, which framework?"
    [Returns: React recommended because...]

Q3: /agent deep-analyzer "Given React, which state management?"
    [Returns: Zustand recommended because...]

Each analysis builds on previous conclusion, not previous reasoning
```

---


