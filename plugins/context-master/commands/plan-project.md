---
description: Plan optimal file creation order for multi-file projects before implementation
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

**Examples:**
- WRONG: `D:/repos/project/file.tsx`
- CORRECT: `D:
epos\projectile.tsx`

This applies to:
- Edit tool file_path parameter
- Write tool file_path parameter
- All file operations on Windows systems

### Windows/Git Bash Path Conversion

When using Git Bash on Windows, automatic path conversion may occur:
- Unix paths (`/foo`) convert to Windows paths automatically
- This usually works transparently
- See WINDOWS_GIT_BASH_GUIDE.md for advanced scenarios and troubleshooting

### Documentation Guidelines

**NEVER create new documentation files unless explicitly requested by the user.**

- **Priority**: Update existing README.md files rather than creating new documentation
- **Repository cleanliness**: Keep repository root clean - only README.md unless user requests otherwise
- **Style**: Documentation should be concise, direct, and professional
- **User preference**: Only create additional .md files when user specifically asks

---

# Plan Project

## Purpose
Before creating any files in a multi-file project (3+ related files), this command helps you plan the optimal creation order, identify dependencies, and prevent redundant work.

## When to Use
- Creating websites with multiple pages
- Building applications with multiple components
- Projects with shared dependencies (CSS, config files)
- API implementations with multiple endpoints
- Documentation sets with multiple files
- Any task involving 3+ related files

## Instructions

### Step 1: Extended Thinking for Architecture
IMMEDIATELY use extended thinking to analyze the project:

```bash
"Think hard about the architecture for this [project type]:
- What files are needed and what is their purpose?
- What are the shared dependencies (CSS, config, base classes)?
- What is the optimal creation order and why?
- What are the cross-file references?
- What could go wrong if we create files in the wrong order?"
```

### Step 2: Create Architecture Plan
Based on the thinking, create a plan following this template:

```bash
ARCHITECTURE PLAN:

FILES NEEDED:
  - [filename]: [purpose]
  - [filename]: [purpose]

SHARED DEPENDENCIES (must be created first):
  - [dependency]: [what files need this]

CREATION ORDER (numbered with reasoning):
  1. [file] - Reason: [why this first]
  2. [file] - Reason: [why this second]
  3. [file] - Reason: [why this third]

CROSS-FILE REFERENCES:
  - [file A] references [file B] via [method]

POTENTIAL ISSUES TO AVOID:
  - [what could go wrong]
  - [common mistake]
```

### Step 3: Announce the Plan to User
Tell the user your file creation order before starting:

```text
"I'll create these files in this order:
1. [file] - [reason]
2. [file] - [reason]
3. [file] - [reason]
...

This order ensures all dependencies are in place before files that need them."
```

### Step 4: Create Files in Optimal Order
Follow the plan:
- Create foundation files first (CSS, config, base classes)
- Create dependent files after their dependencies exist
- Keep consistent naming and structure
- Add comments about dependencies

### Step 5: Verify
After creating all files, verify:
- All file paths are correct
- CSS/JS references load properly
- Navigation between pages works
- Cross-file dependencies resolve
- No broken links or missing file references

## Key Principles

**Foundations First:**
- CSS files before HTML files that use them
- Configuration files before code that needs them
- Base classes before derived classes

**Core Before Features:**
- index.html before other pages
- main.js before feature modules
- Core API before additional endpoints

**Structure Before Content:**
- HTML structure before detailed content
- API structure before implementation details
- Component scaffolds before full logic

## Token Savings
- Without planning: ~8,000 tokens (redundant work + fixes)
- With planning: ~3,000 tokens (efficient creation)
- **Savings: ~5,000 tokens (62% reduction) per project**

## Example: Portfolio Website

**User Request:** "Create a portfolio with home, about, projects, and contact pages"

**Your Response:**
1. Use extended thinking to plan
2. Announce: "I'll create: 1. styles.css, 2. index.html, 3. about.html, 4. projects.html, 5. contact.html"
3. Create files in that order
4. Verify all HTML files reference styles.css correctly

**Result:** Efficient, no refactoring needed!

## Windows/Git Bash Notes

On Windows with Git Bash:
- Path planning uses forward slashes (Unix format)
- Actual file creation uses backslashes (Windows format)
- Verification handles both formats automatically
- See WINDOWS_GIT_BASH_GUIDE.md for detailed guidance
