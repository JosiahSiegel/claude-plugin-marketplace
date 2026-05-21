# Context Management Strategies

Detailed workflows and strategies for managing context efficiently in Claude Code.

## Understanding Context Usage

**Context window size:**
- Standard: 200K tokens (~150K words)
- Extended (API): 1M tokens (~750K words)

**What consumes context:**
- Conversation history (messages back and forth)
- File contents loaded into context
- Tool call results (bash output, test results, etc.)
- CLAUDE.md configuration
- Extended thinking blocks

**Context awareness:** Claude Sonnet 4.5 tracks remaining context and reports it with each tool call.

## Core Commands

### `/clear` - Reset Context
**When to use:**
- Between major features or tasks
- After completing a self-contained piece of work
- When switching between different parts of the codebase
- If you notice Claude getting distracted or referencing old context

**Example workflow:**
```text
1. Complete feature A
2. Run tests and commit
3. /clear
4. Start feature B with fresh context
```

### `/compact` - Compress Context
**When to use:**
- Before starting complex multi-step work
- When approaching context limits (~80% full)
- To preserve key decisions while clearing clutter

**What it does:** Summarizes conversation history while retaining key information.

**Example workflow:**
```text
1. Long research and planning session
2. /compact "Summarize architecture decisions and open TODOs"
3. Continue with implementation
```

### `/continue` - Resume Session
**When to use:**
- Returning to previous work
- After a break
- To pick up where you left off

**Combines well with:**
```text
claude --continue  # Resume last session in current project
```

## Strategy 1: Task Isolation

**Goal:** Keep each task in its own context bubble.

**Workflow:**
```text
1. Start task → /clear (if needed)
2. Use subagents for research/analysis
3. Main context focuses on implementation
4. Complete and test
5. /clear before next task
```

**When to use:**
- Multiple independent features
- Bug fixes that don't require historical context
- Refactoring isolated modules

**Benefits:**
- Each task starts with clean slate
- No cross-contamination between tasks
- More predictable context usage

---

## Strategy 2: Progressive Context Management

**Goal:** Build up context deliberately, clearing non-essential information.

**Workflow:**
```text
1. Research phase
   - Subagents search and analyze
   - Main context reviews summaries
   
2. Planning phase
   - "think hard" to create plan
   - Save plan to document/issue
   
3. /compact "Keep architecture decisions and plan"
   
4. Implementation phase
   - Reference plan document
   - Focus on current file/module
   
5. Testing phase
   - Subagent runs tests
   - Main context addresses failures
   
6. /clear before next feature
```

**When to use:**
- Large features requiring multiple steps
- Complex refactoring
- Projects with extensive research phase

**Benefits:**
- Intentional context building
- Clear phase transitions
- Preserved key decisions

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

## Strategy 3: Parallel Workstreams

**Goal:** Work on multiple aspects simultaneously using subagents.

**Workflow:**
```text
1. Main context: High-level orchestration
2. Subagent A: Frontend work
3. Subagent B: Backend work  
4. Subagent C: Test execution
5. Main context: Integration and coordination
```

**When to use:**
- Full-stack features
- Multi-component changes
- When different aspects are independent

**Benefits:**
- Efficient use of subagent isolation
- Parallel progress
- Main context stays focused on coordination

---

## Strategy 4: Test-Driven Context Management

**Goal:** Keep context focused on current test/implementation cycle.

**Workflow:**
```text
1. Write test in main context
2. /agent test-runner "run new test"
3. Implement feature to pass test
4. /agent test-runner "run test suite"
5. If fail → fix in main context
6. If pass → commit and /clear
```

**When to use:**
- TDD workflows
- Bug fixes with test coverage
- API endpoint development

**Benefits:**
- Tight feedback loop
- Context stays focused on current test
- Test output doesn't clutter main context

---

## Strategy 5: Documentation-First Development

**Goal:** Use CLAUDE.md as persistent memory across sessions.

**Setup:**
```markdown
# CLAUDE.md

## Current Focus
Sprint goal: User authentication system

## Recent Decisions
- Using JWT with refresh tokens
- PostgreSQL for user storage
- Redis for session management

## Next Tasks
- [ ] Implement token refresh endpoint
- [ ] Add rate limiting
- [ ] Write integration tests

## Architecture Notes
[Key decisions that inform all work]
```

**Workflow:**
```text
1. CLAUDE.md provides persistent context
2. Each session references current focus
3. Update CLAUDE.md with new decisions
4. /clear frequently - CLAUDE.md persists
```

**When to use:**
- Multi-day projects
- Team collaboration (CLAUDE.md in git)
- Complex projects needing persistent memory

**Benefits:**
- Survives /clear commands
- Shared team knowledge
- Consistent across sessions

---

## Scenario-Based Strategies

### Scenario: Large Refactoring

**Challenge:** Need broad codebase understanding but context fills quickly.

**Strategy:**
```text
1. Subagent: "Map all files using old pattern"
2. Review map, create refactoring plan
3. Save plan to REFACTOR.md
4. /clear
5. For each file:
   a. Load file
   b. Refactor based on plan
   c. Test
   d. /clear before next file
```

---

### Scenario: Bug Investigation

**Challenge:** Unknown cause, need to search widely but track findings.

**Strategy:**
```text
1. Create BUG_NOTES.md to track findings
2. Subagent: "Search logs for error X"
3. Document findings in BUG_NOTES.md
4. Subagent: "Analyze code paths that could cause X"
5. Document in BUG_NOTES.md
6. /compact "Keep bug theory and evidence"
7. Implement fix
8. /agent test-runner "verify fix"
```

---

### Scenario: New Feature with Unknown Patterns

**Challenge:** Need to research existing patterns without cluttering context.

**Strategy:**
```text
1. Subagent: "Find similar features in codebase"
2. Subagent: "Extract common patterns from those features"
3. Main context reviews patterns
4. "think about best approach for new feature"
5. Create implementation plan
6. /clear
7. Implement based on plan
8. Reference plan doc if needed
```

---

### Scenario: Multi-File Feature

**Challenge:** Changes span many files, hard to keep all in context.

**Strategy:**
```text
1. Create FEATURE.md with:
   - Overall design
   - File change checklist
   - Cross-file dependencies
   
2. For each file:
   a. Load just that file
   b. Reference FEATURE.md for context
   c. Make changes
   d. Test
   e. /compact if context getting full
   
3. Final integration test
4. /clear and move to next feature
```

---

## Advanced Techniques

### Technique: Context Checkpoints

**Save key state to files before clearing:**

```text
1. Long planning session
2. "Create PLAN.md with our architecture decisions"
3. /clear
4. Reference PLAN.md during implementation
```

### Technique: Layered Context Loading

**Load information progressively as needed:**

```text
1. Start with just current file
2. If need more context: "show me the caller"
3. If need more: "show me the config"
4. Don't load everything upfront
```

### Technique: Subagent Summarization

**Use subagents to create digestible summaries:**

```text
Subagent: "Analyze all 50 test files and create a summary:
- Total coverage percentage
- Files with <50% coverage
- Most complex tests"

Then work from the summary, not the raw test files.
```

### Technique: Incremental /compact

**Compress context multiple times in long sessions:**

```text
1. Research phase → /compact "Keep research findings"
2. Planning phase → /compact "Keep findings and plan"
3. Implementation → /compact "Keep plan and decisions"
```

## Monitoring Context Health

**Signs context is getting cluttered:**
- Claude references old, irrelevant information
- Responses become less focused
- Performance seems to degrade
- You're >80% through context budget

**Remedies:**
1. `/compact` for quick compression
2. `/clear` for fresh start
3. Move key info to files before clearing
4. Use subagents more aggressively

## Best Practices Summary

1. **Use /clear liberally** between tasks
2. **Front-load subagent usage** for research
3. **Document decisions** in CLAUDE.md or files
4. **Load files progressively** as needed
5. **Test in subagents** to keep output isolated
6. **/compact before** complex multi-step work
7. **Think first** to plan before implementing
8. **Reference plans** instead of keeping full context
9. **Batch similar operations** in single subagent
10. **Monitor context usage** and respond proactively
