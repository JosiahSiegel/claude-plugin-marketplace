# Common context-management workflows

These six workflows cover the recurring complex tasks across Claude Code and Web/API. Each one starts with a planning or delegation step, then proceeds in clearly named phases.

## Workflow 0: Multi-file website/project creation (most common)

If the user said "create a website/app with multiple pages", you are in this workflow.

**Mandatory sequence:**

```text
STEP 1: STOP AND THINK (always first)
   Output: "Think hard about the architecture for this [project]..."
   [Extended thinking plans: files needed, creation order, dependencies]

STEP 2: ANNOUNCE THE PLAN
   Output: "I'll create these files in this order:
            1. styles.css (shared styling)
            2. index.html (home page)
            3. about.html
            4. projects.html
            5. contact.html"

STEP 3: CREATE FOUNDATION FILES FIRST
   Create: styles.css

STEP 4: CREATE DEPENDENT FILES
   Create: index.html (references styles.css)
   Create: about.html (references styles.css)
   Create: projects.html (references styles.css)
   Create: contact.html (references styles.css)

STEP 5: VERIFY
   Check: All HTML files reference styles.css correctly
```

### Example: portfolio website

```text
User: "Create a portfolio website with home, about, projects, and contact pages"

Before creating any files, output:

"Let me think hard about the architecture first..."

[Extended thinking plans:
 - Files needed: index.html, about.html, projects.html, contact.html, styles.css
 - Optimal order: styles.css FIRST (shared dependency), then HTML pages
 - Dependencies: All HTML files reference styles.css
 - Structure: Simple multi-page site with shared stylesheet]

Then announce the plan:

"I'll create the files in this order:

1. styles.css - Shared styling for all pages
2. index.html - Home page (references styles.css)
3. about.html - About page (references styles.css)
4. projects.html - Projects page (references styles.css)
5. contact.html - Contact page (references styles.css)

This ensures dependencies are in place before files that need them."

Then create files in that exact order.
```

### Wrong vs right

```text
WRONG:
User: "Create a portfolio website with home, about, projects, and contact pages"
[Immediately creates index.html without thinking]
[Creates about.html]
[Creates projects.html]
[Realizes CSS should be shared, has to go back and add it]
This wastes effort and context.
```

```text
RIGHT:
User: "Create a portfolio website with home, about, projects, and contact pages"
"Think hard about architecture..." [Plans first]
"I'll create in this order: CSS first, then HTML pages" [Announces plan]
[Creates styles.css]
[Creates HTML pages that reference styles.css]
Efficient - no redundant work.
```

## Workflow 1: Complex decision-making

**Claude Code:**
```text
User: "Should we use microservices or monolith?"

1. /agent deep-analyzer "Ultrathink about architecture choice
   for 10M user e-commerce platform, 8 dev team"
2. [Receives well-reasoned recommendation in main context]
3. Make decision based on analysis
4. Proceed with implementation
```

**Web/API:**
```text
User: "Should we use microservices or monolith?"

1. "Create a deep-analysis.md artifact and ultrathink about this"
2. [Artifact contains extended thinking + conclusion]
3. Main conversation: "Based on analysis, recommend monolith because..."
4. Proceed with implementation
```

Context efficiency: deep thinking happens, main context stays clean.

## Workflow 2: Complex feature development

```text
Phase 1: Architecture analysis
Claude Code: /agent deep-analyzer "Think deeply about architecture for [feature]"
Web/API: "Create architecture-analysis artifact with deep thinking"
[Isolated thinking → summary to main]

Phase 2: Design planning
"Based on that analysis, create implementation plan artifact"
[Main context references analysis conclusions]

Phase 3: Implementation
"Implement component A based on the plan"
[Create code artifact]

Phase 4: Testing
Claude Code: /agent test-runner "Run tests and analyze failures"
Web/API: "Run tests" [test output in separate space]

Phase 5: Integration
"Integrate based on architecture plan"
```

Why it works: each phase has a clear purpose, thinking isolated where needed.

## Workflow 3: Research & technology evaluation

```text
Phase 1: Deep research
Claude Code: /agent pattern-researcher "Research and think hard about
  authentication approaches, analyze tradeoffs"
Web/API: "Create research-findings artifact and think through options"

Phase 2: Synthesis
[Receives summary of findings]
"Create comparison table artifact"

Phase 3: Recommendation
Claude Code: /agent deep-analyzer "Based on research, recommend approach"
Web/API: "Based on research artifact, ultrathink and recommend"

Phase 4: Implementation
"Implement recommended approach"
```

Why it works: research and deep analysis isolated, implementation focused.

## Workflow 4: Code generation & iteration

```text
1. "Create a [language] script that [functionality]"
   → Artifact created

2. "Add [feature] to the script"
   → Artifact updated

3. "Optimize the [specific part]"
   → Targeted update

4. "Add error handling"
   → Incremental improvement
```

Why it works: all code lives in the artifact; conversation stays focused on what to change.

## Workflow 5: Refactoring with analysis

**Claude Code:**
```text
1. /agent analyzer "Think hard about refactoring approach
   for legacy auth system"
2. [Receives analysis in main: strategy, risks, order]
3. "Create REFACTOR.md plan based on analysis"
4. /clear
5. For each module:
   - Refactor according to plan
   - /agent test-runner "verify changes"
   - Commit
   - /clear before next
```

**Web/API:**
```text
1. "Create refactoring-analysis artifact, think deeply about approach"
2. [Artifact has thinking + strategy]
3. "Create refactoring-plan artifact based on analysis"
4. Implement module by module
5. Reference plan artifact as you work
```

Why it works: deep analysis happens once (isolated), execution follows a clean plan.
