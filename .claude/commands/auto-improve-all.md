---
description: Fully autonomous plugin improvement - agents discover, decide, and complete all improvements with minimal context usage
---

# Auto-Improve All Plugins

## Purpose
**Fully autonomous improvement** of every plugin in the claude-plugin-marketplace repository. Each plugin's expert agent will:
1. **Self-determine** what needs improvement using web search and Context7
2. **Autonomously decide** what features/fixes to add
3. **Complete all improvements** themselves (no pausing, no asking)
4. **Minimize context usage** by doing all work within agent contexts

This command uses **agent-driven execution** to keep primary context window usage minimal while maximizing improvement quality.

## Process

**DO NOT do the work yourself.** Launch agents and let them do ALL the work autonomously.

### Step 1: Launch All Plugin Expert Agents in Parallel

Use a **single message with multiple Task tool calls** to launch all agents simultaneously. This keeps your context usage minimal.

**Plugins to Improve (14 total):**
- adf-master → `adf-master:adf-expert`
- ado-master → `ado-master:ado-expert`
- azure-master → `azure-master:azure-resources-expert`
- azure-to-docker-master → `azure-to-docker-master:docker-compose-generator`
- bash-master → `general-purpose` agent
- context-master → `Explore` agent (very thorough)
- docker-master → `docker-master:docker-expert`
- git-master → `general-purpose` agent
- plugin-master → `plugin-master:plugin-architect`
- powershell-master → `powershell-master:powershell-expert`
- salesforce-master → `salesforce-master:sf-integration-expert`
- ssdt-master → `ssdt-master:ssdt-expert`
- terraform-master → `terraform-master:terraform-expert`
- test-master → `test-master:test-expert`

### Step 2: Provide Autonomous Improvement Instructions

Give each agent these instructions (they will work independently in their own contexts):

```
You are the expert for the [PLUGIN_NAME] plugin in the claude-plugin-marketplace repository.

Your task: AUTONOMOUSLY IMPROVE your plugin. You will:
1. Self-determine what needs improvement (no one will tell you what to do)
2. Decide what features/fixes to add (use your expert judgment)
3. Complete ALL improvements yourself (do not pause or ask for approval)
4. Work entirely within your own context (minimize main context usage)

AUTONOMOUS IMPROVEMENT PROCESS:

1. **SELF-ASSESS Your Plugin (You Decide What's Needed)**
   - Read all files in plugins/[PLUGIN_NAME]/ directory
   - Use your expert knowledge to identify gaps
   - Compare against your domain expertise
   - Look for outdated patterns, missing features, verbose content

2. **DISCOVER 2025 State-of-the-Art (Web Search + Context7)**
   - WebSearch: "[TECHNOLOGY] new features 2025"
   - WebSearch: "[TECHNOLOGY] breaking changes 2025"
   - WebSearch: "[TECHNOLOGY] latest version 2025"
   - WebSearch: "[TECHNOLOGY] best practices 2025"
   - Context7: Get current library documentation
   - YOU DECIDE what's worth adding based on findings

3. **AUTONOMOUSLY DECIDE Improvements to Make**
   Based on your assessment and research, decide:
   - Which 2025 features to add (pick the most valuable ones)
   - What bugs/issues to fix (prioritize critical ones)
   - What content to optimize (target 20-40% reduction)
   - What new files to create (if gaps are significant)
   - What version bump is appropriate

   DO NOT ask for approval. Use your expert judgment.

4. **COMPLETE ALL IMPROVEMENTS (No Pausing)**
   Execute your decisions:
   - CREATE new command/skill files for new capabilities
   - EDIT existing files to add features and fix issues
   - UPDATE version numbers to current 2025 versions
   - REMOVE duplicate content across files
   - REPLACE deprecated features with current alternatives
   - VALIDATE all examples work with current versions
   - **BUMP version in BOTH plugin.json AND marketplace.json** (MANDATORY - versions MUST match)
   - **ALIGN versions**: Ensure plugins/[PLUGIN_NAME]/.claude-plugin/plugin.json and .claude-plugin/marketplace.json have IDENTICAL version numbers
   - **ENSURE PORTABILITY** - Remove all user-specific paths, machine names, personal info

   Complete everything before returning results.

5. **REPORT Your Autonomous Improvements**
   After completing all improvements, provide:
   - **Decisions Made**: What you decided to improve and why
   - **New Features Added**: List new 2025 features now documented
   - **Files Created**: New command/skill files created
   - **Files Enhanced**: Existing files updated with improvements
   - **Bugs Fixed**: Critical issues corrected
   - **Content Optimized**: Deduplication percentage achieved
   - **Version Bumped**: New version number in BOTH files (plugin.json + marketplace.json) - MUST be identical
   - **Version Alignment Verified**: plugins/[PLUGIN_NAME]/.claude-plugin/plugin.json matches .claude-plugin/marketplace.json
   - **Portability Verified**: No user-specific paths or personal information
   - **Production Ready**: Assessment with any remaining gaps

AUTONOMOUS DECISION-MAKING GUIDELINES:
- YOU decide what improvements are most valuable (3-5 major features minimum)
- YOU decide appropriate version bump based on changes made
- YOU decide what content to deduplicate (target 20-40% reduction)
- YOU decide when examples need updating
- YOU complete everything without asking permission

CRITICAL RULES:
✓ COMPLETE all improvements before reporting (no pausing)
✓ MAKE actual changes (do not just identify issues)
✓ USE your expert judgment to prioritize improvements
✓ WORK within your own context (minimal main context usage)
✓ **ALWAYS increment version** in plugin.json AND marketplace.json (MANDATORY - MUST match)
✓ **VERIFY version alignment** - plugins/[PLUGIN_NAME]/.claude-plugin/plugin.json and .claude-plugin/marketplace.json MUST have IDENTICAL versions
✓ **KEEP CONTENT PORTABLE** - No user paths, machine names, personal info
✗ DO NOT ask for approval or confirmation
✗ DO NOT pause mid-improvement to check in
✗ DO NOT create placeholder content
✗ DO NOT include hardcoded paths like C:\Users\John, /home/username, D:\repos
✗ DO NOT include machine-specific hostnames or IP addresses
✗ DO NOT include personal email addresses or usernames in examples

BEGIN AUTONOMOUS IMPROVEMENT NOW. Self-assess, decide, and complete all improvements.
```

### Step 3: Wait for Agent Results (They Work Independently)

After launching all agents in parallel:
1. Agents work autonomously in their own contexts
2. Each agent self-assesses, decides improvements, and completes them
3. Primary context usage remains minimal
4. Collect reports when all agents finish

### Step 4: Update README.md to Reflect Improvements

**CRITICAL: After all agents complete, update the main README.md**

The README.md must stay synchronized with plugin improvements:

1. **Read current marketplace.json** to get latest plugin descriptions and versions
2. **Read current README.md** to understand current structure
3. **Update plugin descriptions** in README.md to match marketplace.json exactly
4. **Verify all plugins are listed** in the correct categories
5. **Update version references** if mentioned in Quick Start or examples
6. **Maintain organizational structure** (Core Development, Cloud & Infrastructure, etc.)
7. **Keep formatting consistent** with existing README style

**Why this is critical:**
- README.md is the first thing users see
- Outdated descriptions reduce plugin discoverability
- Version mismatches confuse users
- Missing plugins mean lost adoption

**Implementation:**
```
After collecting all agent results:
1. Read .claude-plugin/marketplace.json
2. Read README.md
3. For each plugin in each category:
   - Update description to match marketplace.json
   - Verify install command is correct
   - Ensure link to plugin directory works
4. Update documentation links section
5. Update Quick Start examples if needed
```

### Step 5: Summarize Aggregate Results

After all agents complete and README.md is updated, summarize:
- **Total plugins improved**: Count (should be 14)
- **New features added**: Aggregate across all plugins
- **Files created**: Total new command/skill files
- **Files enhanced**: Total existing files improved
- **Bugs fixed**: Critical issues corrected
- **Content optimized**: Average deduplication percentage
- **Versions bumped**: List all plugins with version updates
- **README.md updated**: Confirm descriptions synchronized
- **Production ready**: Percentage of plugins production-ready

## Expected Outcomes

After running this command, you will have **measurably improved** all plugins:

1. **40+ New Features Added** - 2025 capabilities now documented across all plugins
2. **15-20 New Files Created** - Commands and skills for new 2025 features
3. **50+ Files Enhanced** - Existing content updated with current best practices
4. **10-15 Bugs Fixed** - Critical issues, outdated info, and deprecated code corrected
5. **25% Average Optimization** - Redundant content removed, clarity improved
6. **8-12 Version Bumps** - ALL plugins updated in both plugin.json AND marketplace.json
7. **README.md Synchronized** - Main README reflects all plugin improvements and current descriptions
8. **100% Portable** - No user-specific paths, machine names, or personal information
9. **100% Production Ready** - All plugins validated with working examples

## Usage Notes

**When to Run This Command:**
- **Quarterly maintenance** - Keep plugins current with latest features
- **After major releases** - Add new framework versions, APIs, breaking changes
- **Before marketplace updates** - Ensure production-ready quality
- **When gaps discovered** - User feedback reveals missing features
- **Continuous improvement** - Regular enhancement cycles

**What This Command Does:**
- **Adds features** - Discovers and documents new 2025 capabilities
- **Fixes issues** - Corrects bugs, outdated info, deprecated code
- **Optimizes content** - Removes duplication, improves clarity
- **Creates files** - New commands/skills for missing capabilities
- **Bumps versions** - ALWAYS increments version in plugin.json AND marketplace.json
- **Updates README.md** - Synchronizes main README with all plugin improvements
- **Ensures portability** - Removes user paths, machine names, personal info

**Performance:**
- Takes 15-30 minutes for all 12 plugins
- Requires internet access for web searches and Context7
- Agents run in parallel for efficiency

## Manual Steps After Completion

1. **Review improvements**: `git diff` to see all enhancements
2. **Verify versions**: Confirm all plugin.json AND marketplace.json versions incremented
3. **Validate version alignment**: Ensure plugins/*/\*.claude-plugin/plugin.json versions match .claude-plugin/marketplace.json
4. **Verify README.md**: Confirm all plugin descriptions match marketplace.json and all plugins are listed
5. **Check portability**: Search for any remaining user paths (C:\Users, /home/, D:\repos)
6. **Test new features**: Validate new commands and examples work
7. **Commit improvements**: Descriptive message highlighting key additions
8. **Share updates**: Create PR or announce new capabilities to team

## Example Execution

```
User: /auto-improve-all
Assistant: Launching 14 expert agents in parallel for autonomous improvement...

[Using single message with 14 Task tool calls - minimal context usage]

✓ test-master:test-expert launched
✓ docker-master:docker-expert launched
✓ terraform-master:terraform-expert launched
✓ adf-master:adf-expert launched
✓ ado-master:ado-expert launched
✓ powershell-master:powershell-expert launched
✓ salesforce-master:sf-integration-expert launched
✓ ssdt-master:ssdt-expert launched
✓ plugin-master:plugin-architect launched
✓ azure-master:azure-resources-expert launched
✓ azure-to-docker-master:docker-compose-generator launched
✓ bash-master: general-purpose agent launched
✓ git-master: general-purpose agent launched
✓ context-master: Explore agent launched

[All agents working autonomously in their own contexts...]
[Agents self-assessing plugins, discovering 2025 features, deciding improvements]
[Web searches happening in agent contexts]
[Files being created and enhanced in agent contexts]
[Content being optimized in agent contexts]
[Versions being bumped in agent contexts]

[Collecting results from completed agents...]

[Updating README.md to reflect all improvements...]
✓ Read marketplace.json for current descriptions
✓ Read README.md for current structure
✓ Updated all 14 plugin descriptions to match marketplace.json
✓ Verified all categories have correct plugins
✓ Updated Quick Start examples
✓ Synchronized documentation links

AGGREGATE IMPROVEMENT SUMMARY:
✓ 14 plugins improved autonomously
✓ 43 new 2025 features added
✓ 18 new files created (commands + skills)
✓ 52 files enhanced
✓ 8 critical bugs fixed
✓ 27% average content optimization
✓ 14 version bumps (ALL plugins - plugin.json + marketplace.json)
✓ README.md synchronized with all improvements
✓ 100% portable (no user-specific content)
✓ 100% production ready

All plugins now include current 2025 best practices with minimal context usage!
```

## Troubleshooting

**Agent Not Found:**
- If a plugin's expert agent doesn't exist, fall back to general-purpose agent
- Document which plugins need agent creation

**Web Search Failures:**
- If web search unavailable, agents will use Context7 as fallback
- Manual verification may be needed afterward

**Agent Timeouts:**
- Some plugins may take longer than others (normal)
- Agents work independently so others continue

**Context Usage:**
- Should remain minimal (agents work in their own contexts)
- Only agent launch and results collection happen in main context

**Version Increments Not Happening:**
- Verify agent has write permissions to plugin.json and marketplace.json
- Check if version format is correct (semantic versioning: X.Y.Z)
- Ensure BOTH files are updated (not just one)
- Validate versions MATCH between plugin.json and marketplace.json (must be identical)

**User-Specific Content Found:**
- Search for patterns: C:\Users, /home/, D:\repos, @company.com
- Replace with generic examples: /path/to/project, user@example.com
- Use environment variables: $HOME, %USERPROFILE%, ${PLUGIN_ROOT}

**README.md Not Updated:**
- Verify marketplace.json has all plugin entries with descriptions
- Check that README.md categories match the organizational structure
- Ensure Edit tool used with correct file path (D:\repos\claude-plugin-marketplace\README.md or ./README.md)
- Manually verify all plugin links work (./plugins/PLUGIN_NAME/README.md)
- Confirm descriptions in README match marketplace.json exactly

## Related Commands

- `/plugin-master:validate-plugin` - Validate structure after improvements
- `/context-master:verify-structure` - Verify multi-file consistency
- `/git-master:git-cleanup` - Clean up after major updates
