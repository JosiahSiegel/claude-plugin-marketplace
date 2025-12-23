# test-master

Complete management plugin for **Vitest 4.0 + Playwright 1.55 + MSW 2.11+** testing infrastructure (2025). This production-ready plugin provides comprehensive test automation, AI-powered test generation, visual regression testing, debugging, mutation testing, test annotation, and infrastructure management for modern JavaScript projects.

## 🚀 Features

### Core Test Management
- **Run all tests** with intelligent selection based on changed files
- **Unit, integration, and E2E test execution** with separate commands
- **Watch mode** for continuous testing during development
- **Coverage analysis** with detailed reports and gap identification
- **Interactive debugging** with trace analysis and headed mode

### Test File Management
- **Auto-scaffolding** for unit, integration, and E2E tests with proper boilerplate
- **Helper utilities** for assertions, DOM manipulation, fixtures, mocks, and state
- **Fixture generation** for consistent mock data across tests
- **Test infrastructure** organization following best practices

### MSW Integration
- **Mock handler generation** for API endpoints (GET, POST, PUT, DELETE, PATCH)
- **Fixture management** for API response data
- **MSW debugging** to diagnose interception issues
- **Stateful mocks** for complex testing scenarios

### Coverage Analysis
- **Comprehensive reports** in multiple formats (text, HTML, JSON, LCOV)
- **Gap analysis** to identify untested code
- **Threshold management** for per-file and global coverage requirements
- **Prioritized suggestions** for improving coverage

### Test Debugging
- **Automatic fix suggestions** for common test failures
- **Snapshot management** with guided updates
- **Playwright trace analysis** with timeline, screenshots, and network activity
- **Headed mode execution** for visual debugging

### CI/CD Integration
- **GitHub Actions workflow** generation
- **GitLab CI configuration** generation
- **Parallel execution** optimization
- **Test artifact management** (traces, screenshots, videos)

## 📦 Installation

### Via GitHub Marketplace (Recommended)

```bash
# Add the marketplace
/plugin marketplace add claude-code-marketplace/claude-code-marketplace

# Install the plugin
/plugin install test-master@claude-plugin-marketplace
```

### Local Installation (Mac/Linux)

⚠️ **Windows users:** Use GitHub marketplace installation method instead.

```bash
# Extract to plugins directory
unzip test-master.zip -d ~/.local/share/claude/plugins/
```

## 🎯 Technology Stack (2025)

- **Vitest 4.0** (Released: October 22, 2025) - Unit, integration, and browser testing
  - **Browser Mode (Stable)** - Production-ready browser testing with Chromium, Firefox, WebKit
  - **Visual Regression Testing** - Screenshot comparison with `toMatchScreenshot()` matcher
  - **Playwright Trace Integration** - Generate Playwright traces for browser tests
  - **Type-Aware Hooks** - Better TypeScript support in lifecycle hooks
  - **Annotation API (3.2+)** - Add metadata and attachments to tests
  - **Line Number Filtering (3.0+)** - Run tests by line number from IDE
  - **Improved Watch Mode** - Smarter change detection, faster rebuilds
  - **Enhanced Reporting** - Reduced flicker, clearer output
  - **Workspace Projects** - Multi-project support in single config
  - **toBeInViewport Matcher** - Check element visibility with IntersectionObserver API
- **Playwright 1.56** (October 2025) - E2E browser testing
  - **AI Test Agents** - Planner, Generator, and Healer agents for LLM-powered test automation
  - **testStepInfo.titlePath** - Full test hierarchy for better debugging
  - **VS Code 1.105+ Integration** - Seamless agentic experience in VS Code
  - **Debian 13 Support** - Modern CI/CD environment compatibility
  - **Chromium 140+, Firefox 141, WebKit 26** - Latest browser support
  - **Flaky Test Detection** - `--fail-on-flaky-tests` CLI flag
  - **Enhanced File Downloads** - Simplified download handling
  - **Custom Reporters** - Integration with third-party tools
  - **Role-Based Locators** - `getByRole()` for accessible testing
  - **Auto-Waiting** - Intelligent wait mechanisms
- **MSW (Mock Service Worker) 2.11+** (Latest: 2025) - API mocking following 2025 patterns
  - **Fetch API Primitives** - Full Fetch API support (ReadableStream, ESM-compatible)
  - **Happy-Path-First** - Success scenarios as baseline
  - **Domain-Based Organization** - Structured handler grouping by feature
  - **Runtime Overrides** - Flexible test-specific mocking with `server.use()`
  - **Node.js 18+ Required** - Modern runtime support
- **Stryker Mutator** - Mutation testing for test quality verification
- **happy-dom** - Fast DOM simulation for Vitest unit tests
- **@vitest/coverage-v8** - Code coverage analysis

## 📖 Commands

### Core Test Management

| Command | Description |
|---------|-------------|
| `/test-master:run` | Run all tests with intelligent selection |
| `/test-master:unit` | Run Vitest unit tests only |
| `/test-master:integration` | Run Vitest integration tests |
| `/test-master:e2e` | Run Playwright E2E tests |
| `/test-master:watch` | Start Vitest watch mode |
| `/test-master:coverage` | Generate coverage reports |
| `/test-master:debug` | Debug failing tests interactively |
| `/test-master:annotate` | Add metadata/attachments to tests (Vitest 3.2+) |
| `/test-master:mutation-test` | Run mutation testing for quality verification |
| `/test-master:ai-generate` | Generate tests using Playwright AI agents (Playwright 1.55+) |

### Test File Management

| Command | Description |
|---------|-------------|
| `/test-master:create-unit <module>` | Scaffold unit test with boilerplate |
| `/test-master:create-integration <feature>` | Scaffold integration test |
| `/test-master:create-e2e <workflow>` | Scaffold Playwright E2E test |
| `/test-master:create-helper <type>` | Create test helper utility |
| `/test-master:create-fixture` | Create mock data fixture |

### Configuration Management

| Command | Description |
|---------|-------------|
| `/test-master:init` | Initialize complete test infrastructure |
| `/test-master:configure` | Interactive configuration wizard |
| `/test-master:validate-config` | Validate all test configurations |

### MSW Integration

| Command | Description |
|---------|-------------|
| `/test-master:create-mock <api-name>` | Generate MSW handler for endpoint |
| `/test-master:update-fixtures` | Update mock response data |
| `/test-master:debug-msw` | Debug MSW request handling |

### Coverage Analysis

| Command | Description |
|---------|-------------|
| `/test-master:coverage-report` | Generate and display coverage |
| `/test-master:coverage-gaps` | Find untested code |
| `/test-master:set-thresholds` | Update coverage thresholds |

### Test Debugging

| Command | Description |
|---------|-------------|
| `/test-master:fix-failing` | Analyze and fix failing tests |
| `/test-master:update-snapshots` | Update Vitest snapshots |
| `/test-master:trace` | Analyze Playwright traces |
| `/test-master:headed` | Run E2E tests in visible browser |

### CI/CD Integration

| Command | Description |
|---------|-------------|
| `/test-master:ci-config` | Generate CI/CD test workflows |
| `/test-master:parallel` | Configure parallel execution |
| `/test-master:artifacts` | Manage test artifacts |

## 🤖 Specialized Agent

The plugin includes the **test-expert** agent that provides:

- Comprehensive test strategy and architecture
- Advanced debugging techniques
- Testing best practices and patterns
- Mock data architecture guidance
- E2E test patterns and selectors
- Coverage optimization strategies
- Production-ready test infrastructure design

The agent **proactively activates** when you:
- Mention testing, Vitest, Playwright, or MSW
- Ask about test creation or debugging
- Need test infrastructure guidance
- Have failing tests or coverage issues

## 📁 Expected Test Structure

The plugin works best with this recommended structure:

```
tests/
├── unit/                      # Pure function/module tests
│   └── *.test.js
├── integration/               # Multi-module interaction tests
│   └── *.test.js
├── e2e/                       # Playwright browser tests
│   └── *.spec.js
├── helpers/                   # Shared test utilities
│   ├── assertions.js          # Custom assertions
│   ├── dom.js                 # DOM setup/teardown
│   ├── fixtures.js            # Test data factories
│   ├── mocks.js               # Mock creators
│   └── state.js               # State management
├── fixtures/                  # Mock data files
│   ├── mock-data.json
│   └── api-responses.json
├── mocks/                     # MSW setup
│   ├── handlers.js            # Request handlers
│   └── server.js              # MSW server
├── setup.js                   # Global setup (MSW + DOM)
├── setup-msw-only.js          # MSW-only setup
├── vitest-global-setup.js     # Global hooks
└── README.md                  # Testing documentation
```

## 🚀 Quick Start

### 1. Initialize Test Infrastructure

```bash
/test-master:init
```

This sets up:
- Directory structure
- Configuration files (vitest.config.js, playwright.config.js)
- MSW mock server
- Sample tests
- NPM scripts

### 2. Create Your First Test

```bash
# Unit test
/test-master:create-unit myFunction

# Integration test
/test-master:create-integration userWorkflow

# E2E test
/test-master:create-e2e loginFlow
```

### 3. Run Tests

```bash
# All tests
/test-master:run

# Specific type
/test-master:unit
/test-master:e2e

# With coverage
/test-master:coverage
```

### 4. Debug Failures

```bash
# Interactive debugging
/test-master:debug

# Visual debugging (E2E)
/test-master:headed

# Trace analysis
/test-master:trace
```

## 💡 Usage Examples

### Create and Mock an API Endpoint

```bash
# 1. Create MSW handler
/test-master:create-mock /api/users

# 2. Create integration test
/test-master:create-integration userApi

# 3. Run tests
/test-master:integration
```

### Set Up CI/CD

```bash
# Generate GitHub Actions workflow
/test-master:ci-config

# Configure parallel execution
/test-master:parallel

# Validate everything works
/test-master:run
```

### Improve Coverage

```bash
# Generate coverage report
/test-master:coverage

# Find gaps
/test-master:coverage-gaps

# Set new thresholds
/test-master:set-thresholds
```

## 🎯 Best Practices Supported (2025)

### Vitest 3.x Annotation API

```javascript
test('payment flow', async ({ task }) => {
  task.meta.annotation = {
    message: 'Tests Stripe integration',
    attachments: [
      { name: 'ticket', content: 'JIRA-123' },
      { name: 'config', content: JSON.stringify(config) }
    ]
  };
  // Test implementation
});
```

### Line Number Filtering

```bash
# Run specific test by line number
vitest run src/auth.test.js:42

# Works from IDE - click line number in gutter
```

### Mutation Testing

```bash
# Verify test quality
npm run test:mutation

# Measure how many code mutations tests catch
```

### AI-Powered Test Generation (Playwright 1.56+)

```bash
# Use Playwright Test Agents for LLM-powered test creation
/test-master:ai-generate

# Three specialized agents available:
# - Planner: Explore app and create comprehensive test plan
# - Generator: Convert plan to runnable Playwright code with working selectors
# - Healer: Watch for broken tests and fix them automatically

# Setup (requires VS Code 1.105+)
npx playwright init-agents --loop=vscode|claude|opencode
```

**Key Benefits:**
- Generates test cases you might not think of (security, accessibility, performance)
- Creates working code with real selectors, not brittle hardcoded ones
- Self-healing tests that automatically fix when they break
- Analyzes console logs, network, and page snapshots to identify root causes

### Playwright Role-Based Locators (2025 Best Practice)

```javascript
// Prioritize role-based selectors (mirrors user/accessibility view)
await page.getByRole('button', { name: 'Submit' }).click();
await page.getByRole('textbox', { name: 'Email' }).fill('[email protected]');
await page.getByRole('heading', { name: 'Welcome' }).isVisible();
```

### MSW 2.x Happy-Path-First Pattern (2025)

```javascript
// handlers.js - SUCCESS scenarios as baseline
export const userHandlers = [
  http.get('/api/users', () => HttpResponse.json({ users: [...] }))
];

// Combine by domain
export const handlers = [...userHandlers, ...productHandlers];

// Override in test for errors
test('handles error', () => {
  server.use(
    http.get('/api/users', () => HttpResponse.json({ error }, { status: 500 }))
  );
});
```

### Coverage with Per-File Thresholds

```javascript
coverage: {
  thresholds: {
    lines: 80,
    'src/critical/**/*.js': { lines: 95, functions: 100 }
  }
}
```

## 🔧 Configuration

The plugin automatically handles configuration for:

- **vitest.config.js** - Test runner, coverage, environments
- **playwright.config.js** - Browsers, devices, artifacts
- **tests/setup.js** - Global test setup with MSW
- **tests/mocks/server.js** - MSW server instance
- **tests/mocks/handlers.js** - HTTP request handlers

Use `/test-master:configure` for interactive configuration wizard.

## 📊 Coverage Integration

Works seamlessly with:

- **Codecov** - Automatic upload via CI
- **Coveralls** - LCOV report generation
- **SonarQube** - Quality gate integration
- **GitHub Actions** - Coverage status checks

## 🐛 Debugging Support

### Vitest Debugging
- Verbose output with stack traces
- Node.js debugger integration
- VS Code debugging support
- Watch mode for rapid iteration

### Playwright Debugging
- Headed mode (visible browser)
- Trace viewer with timeline
- Screenshot on failure
- Video recording
- Inspector with step-through

### MSW Debugging
- Request interception logging
- Handler matching diagnostics
- Response validation
- Network activity tracking

## 🌐 Cross-Platform Support

- **Windows** - Full support (use GitHub marketplace installation)
  - **Command Prompt** - Full support
  - **PowerShell** - Full support
  - **Git Bash/MINGW** - Full support with path conversion awareness
- **macOS** - Full support
- **Linux** - Full support
- **CI environments** - Optimized configurations for GitHub Actions, GitLab CI

### Windows and Git Bash Best Practices

When running tests on Windows, especially in Git Bash/MINGW environments:

**✅ Recommended Execution (All Shells):**
```bash
# Always use npm scripts - handles path conversion automatically
npm test
npm run test:unit
npm run test:e2e
npm run test:coverage
```

**✅ Path Configuration Best Practices:**
```javascript
// vitest.config.js - Use relative paths
export default defineConfig({
  test: {
    include: ['tests/unit/**/*.test.js'],    // ✅ Good
    setupFiles: ['./tests/setup.js'],         // ✅ Good
    // Avoid: '/c/project/tests/**/*.test.js' // ❌ Bad in Git Bash
  }
});
```

**Common Git Bash Issues and Solutions:**

Issue: "No such file or directory" errors
```bash
# Solution: Use npm scripts (recommended)
npm test

# Or disable path conversion
MSYS_NO_PATHCONV=1 vitest run
```

Issue: Test files not found
- Use relative paths in configuration
- Avoid absolute paths starting with /c/ or C:\
- Use forward slashes in glob patterns

Issue: Playwright browser launch failures
```bash
# Clear interfering environment variables
unset DISPLAY
npm run test:e2e
```

**Shell Detection (if needed):**
```javascript
// Detect Git Bash environment
function isGitBash() {
  return !!(process.env.MSYSTEM); // MINGW64, MINGW32, MSYS
}
```

For comprehensive Windows/Git Bash testing guidance, see the included `windows-git-bash-testing.md` skill file.

## 📚 Documentation

Each command includes comprehensive inline documentation:

```bash
# View command help
/help test-master:create-unit
```

The test-expert agent provides contextual guidance and best practices automatically.

## 🤝 Contributing

This plugin follows Claude Code plugin best practices:

- Convention over configuration
- Comprehensive error handling
- Cross-platform compatibility
- Production-ready defaults
- Extensive documentation

## 📝 Changelog

### Version 1.6.0 (2025)

**New Features:**
- Added comprehensive Windows/Git Bash compatibility support
- New skill: `windows-git-bash-testing.md` - Complete guide for cross-platform testing
- Shell detection methods for Git Bash/MINGW environments
- Path conversion helpers and troubleshooting guidance
- Updated to Vitest 4.0 (stable browser mode released October 22, 2025)
- Updated to Playwright 1.56 (AI Test Agents - Planner/Generator/Healer)
- Visual regression testing with `toMatchScreenshot()` matcher
- Playwright Trace integration for Vitest browser mode
- New `toBeInViewport()` matcher for visibility testing

**Enhancements:**
- Enhanced agent with Windows/Git Bash awareness
- Updated all commands with cross-platform execution guidance
- Added npm scripts recommendations for reliable test execution
- Improved path configuration best practices
- Added shell-specific troubleshooting sections
- Updated technology stack with 2025 release dates
- Enhanced AI Test Agents documentation with setup instructions

**Documentation:**
- Comprehensive Windows/Git Bash compatibility guide
- Path conversion issue resolution
- Shell detection patterns
- Cross-platform best practices
- Updated Vitest 4.0 browser mode syntax
- Updated Playwright 1.56 AI agents information

**Bug Fixes:**
- Corrected Vitest 4.0 browser mode provider syntax
- Updated package versions to October 2025 releases

### Version 1.5.0 (Previous)
- Initial comprehensive testing system
- Vitest 3.x support
- Playwright 1.50+ support
- MSW 2.x integration

## 📝 License

MIT

## 🔗 Links

- **Plugin Repository:** [claude-code-marketplace](https://github.com/claude-code-marketplace/claude-code-marketplace)
- **Vitest Docs:** https://vitest.dev/
- **Playwright Docs:** https://playwright.dev/
- **MSW Docs:** https://mswjs.io/

## 💬 Support

For issues, questions, or contributions:
- Use the test-expert agent for testing guidance
- Check command documentation with `/help`
- Report issues via GitHub

---

**Made with ❤️ for modern JavaScript testing**

Ensure production-ready testing infrastructure with Vitest + Playwright + MSW.
