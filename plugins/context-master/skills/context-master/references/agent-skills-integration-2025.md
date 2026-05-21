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


# Agent Skills Integration (2025)

## Overview
Integration patterns between context-master and Agent Skills for autonomous context management in 2025 Claude Code.

## Core Pattern: Context-Aware Agent Skills

### What Are Agent Skills?
Context-efficient knowledge packages that:
- Activate automatically based on context
- Provide specialized guidance
- Stay lean (avoid context bloat)
- Delegate heavy lifting to subagents

### Context Master + Agent Skills Synergy

**Context Master provides:**
- Planning frameworks for multi-file projects
- Thinking delegation architecture
- Context optimization strategies
- Session management patterns

**Agent Skills provide:**
- Domain-specific knowledge
- Automated activation triggers
- Custom tool integration
- Team-wide consistency

## Pattern 1: Context-First Agent Skill

```markdown
# My Custom Agent Skill

## Activation Triggers
- User mentions "create [N]+ files"
- Request involves "architecture"
- Task needs "planning"

## Instructions

### Step 1: Context Check
Before proceeding, ask:
- Are we working with multi-file project? (YES → use context-master)
- Is thinking delegation needed? (YES → delegate)

### Step 2: Leverage Context Master
- Use /plan-project command for architecture
- Use thinking delegation for deep analysis
- Reference context-master patterns

### Step 3: Your Domain Work
- Implement using domain expertise
- Verify structure using /verify-structure
- Document decisions in DECISIONS.md
```

## Pattern 2: Autonomous Context Delegation

Instead of doing analysis in Agent Skill context:

**Bad (fills Agent Skill context):**
```text
"Let me think deeply about the architecture..."
[5K tokens of thinking in Agent Skill context]
```

**Good (preserves Agent Skill context):**
```text
"This needs deep analysis. Let me delegate:
/agent deep-analyzer "Ultrathink about [architecture]"
[Deep analysis happens in isolated agent context]
[Returns summary to Agent Skill - clean]
```

## Pattern 3: Project-Specific Context Strategy

**In your Agent Skill:**

```markdown
## When This Skill Activates

1. Check if CLAUDE.md exists
2. If yes: Load context strategy from CLAUDE.md
3. If no: Use default context-master patterns
```

## Recommended CLAUDE.md Strategy for This Skill

Include in your project's CLAUDE.md:

```yaml
ContextStrategy:
  - Use subagents for: [domain-specific searches]
  - Keep in main for: [your domain decisions]
  - Compact when: [context grows beyond X]
  - Clear before: [major phase transitions]
```

## Pattern 4: Team Consistency

### Create Standard Agent Skill Template

```markdown
# Team Agent Skill Template

## Activation
Activates for: [domain work]

## Context Management

Before doing any analysis:
1. Reference /plan-project for multi-file work
2. Use thinking delegation for complex decisions
3. Document findings in [DOMAIN]_FINDINGS.md
4. Leave main context clean for other agents

## Integration Points
- Works with: context-master, plugin-master
- Delegates to: deep_analyzer for critical choices
- Outputs to: Structured documents, not context
```

## Pattern 5: Cascading Deep Analysis

**For complex domains requiring multiple analyses:**

```text
User Request → Triggers Your Agent Skill
              ↓
Agent Skill identifies sub-questions:
  Q1: Frontend implications?
  Q2: Backend implications?
  Q3: Data implications?
  Q4: Integrated recommendation?
              ↓
Delegates each:
  /agent frontend-deep-analyzer "Ultrathink Q1"
  /agent backend-deep-analyzer "Ultrathink Q2"
  /agent data-deep-analyzer "Ultrathink Q3"
  /agent synthesis-analyzer "Ultrathink Q4"
              ↓
Receives 4 summaries (~200 tokens each)
              ↓
Agent Skill synthesizes in clean context
              ↓
Returns integrated recommendation to main
```

**Context used in main:** ~1,200 tokens (4 summaries + synthesis)
**vs Traditional:** 20K+ tokens (all thinking in main)
**Efficiency:** 16-17x

## Pattern 6: Progressive Context Loading

Avoid loading all project context upfront:

```text
// In your Agent Skill:

Step 1: Minimal context
- Load just CLAUDE.md
- Understand strategy

Step 2: Selective context
- Load only relevant files (use subagent search)
- Get summaries, not full content

Step 3: Deep dive only if needed
- Load full context only for specific modules
- Use Progressive disclosure pattern
```

## Implementation Checklist

- [ ] Agent Skill documentation mentions context-master
- [ ] Activation triggers align with planning needs
- [ ] Uses /plan-project for multi-file work
- [ ] Delegates deep analysis to subagents
- [ ] Documents decisions outside of context
- [ ] CLAUDE.md includes skill-specific strategies
- [ ] Team training covers thinking delegation
- [ ] Hooks configured for auto-management

## Advanced: Agent Skill + Plugin Creation Workflow

For creating domain-specific plugins:

```text
1. User wants new plugin for domain X
2. Agent Skill → plugin-master integration:
   /agent plugin-architect "Design plugin for X"
   
3. plugin-architect:
   - Thinks about structure
   - Considers context implications
   - References context-master patterns
   
4. Returns design
5. User/Agent Skill creates plugin
6. New plugin includes context-master references
```

## Real-World Example: Frontend Agent Skill

```markdown
# Frontend Agent Skill

## When This Activates
- User: "Create a React component..."
- User: "Build a multi-page website..."
- User: "Design component architecture..."

## Instructions

### Multi-File Check
If creating 3+ files:
1. "/plan-project - Think about component structure"
2. Wait for analysis
3. Implement files in recommended order
4. "/verify-structure - Check component references"

### Complex Decisions
If component architecture is complex:
1. "/agent frontend-analyzer - Think about patterns"
2. Receive analysis
3. Design components in main context (clean)

### Documentation
1. Save component decisions to COMPONENT_DECISIONS.md
2. Leave main context for next task
3. Reference document as needed
```

## Measuring Success

**Good indicators:**
- Main context stays under 50K tokens for complex work
- Multiple features/analyses per session without degradation
- Clear decision logs without context bloat
- Smooth team collaboration

**Warning signs:**
- Main context consistently >80K
- Responses getting less focused
- Need to restart sessions more often
- Team members report context issues

