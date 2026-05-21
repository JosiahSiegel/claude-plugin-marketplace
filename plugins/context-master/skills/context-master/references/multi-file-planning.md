# Multi-file project planning

Detailed planning procedure for any project that touches three or more related files. The headline workflow lives in `SKILL.md`; this reference holds the full template, the optimal-order patterns by project type, and the verification checklists.

## Two planning methods

Both are equally effective. Pick based on project complexity.

### Method A: extended thinking

```text
"Think hard about the architecture for this [project]:
- What files are needed and their purpose?
- What are shared dependencies?
- What is optimal creation order?
- What are cross-file references?
- What could go wrong?"
```

Best for: quick projects, straightforward structures, when planning fits in a thinking block.

### Method B: planning document

```text
Create ARCHITECTURE_PLAN.md (via Write tool or artifact):
- Files needed with purposes
- Shared dependencies
- Numbered creation order with reasoning
- Cross-file reference map
- Potential issues to avoid
```

Best for: complex projects, when you want a reference document, when planning is extensive.

## Architecture plan template

```text
ARCHITECTURE PLAN TEMPLATE

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
  - [file C] imports [file D] via [method]

POTENTIAL ISSUES TO AVOID:
  - [what could go wrong]
  - [common mistake]
```

### Filled example: portfolio website

```text
ARCHITECTURE PLAN

FILES NEEDED:
  - styles.css: Shared styling for all pages
  - index.html: Home page with navigation
  - about.html: About page
  - projects.html: Portfolio showcase
  - contact.html: Contact form

SHARED DEPENDENCIES:
  - styles.css: All HTML files need this for consistent styling

CREATION ORDER:
  1. styles.css - Shared dependency, all HTML files will reference it
  2. index.html - Main entry point, establishes structure
  3. about.html - References styles.css which now exists
  4. projects.html - References styles.css which now exists
  5. contact.html - References styles.css which now exists

CROSS-FILE REFERENCES:
  - All HTML files link to styles.css via <link rel="stylesheet">
  - All HTML pages link to each other via <a href="...">

POTENTIAL ISSUES TO AVOID:
  - Creating HTML before CSS - would require going back to add links
  - Inline styles in HTML - would require extraction later
  - Inconsistent navigation - hard to maintain across files
```

## Optimal file creation order

General principles:

1. **Foundations first** - shared dependencies before dependents (CSS before HTML, config before code, base classes before derived classes).
2. **Core before features** - essential files first (`index.html` before other pages, `main.js` before feature modules).
3. **Structure before content** - layout before details (HTML structure before detailed content, API skeleton before endpoint implementations).

Common patterns by project type:

```text
Website project:
1. styles.css        (shared styling)
2. index.html        (home page - references styles.css)
3. about.html        (references styles.css)
4. projects.html     (references styles.css)
5. contact.html      (references styles.css)
6. script.js         (if needed)

React application:
1. package.json      (dependencies)
2. App.js            (main component)
3. components/Header.js
4. components/Footer.js
5. pages/Home.js
6. pages/About.js
7. styles/main.css

Backend API:
1. config.js         (configuration)
2. database.js       (DB connection)
3. models/User.js    (data models)
4. routes/auth.js    (route handlers)
5. routes/api.js
6. server.js         (entry point)
```

## Token-savings illustration

| Project size | Without planning | With planning | Savings |
|---|---|---|---|
| Small (3-4 files) - portfolio website | ~6,000 tokens | ~2,500 tokens | ~3,500 (58%) |
| Medium (7-8 files) - multi-page app | ~12,000 tokens | ~4,500 tokens | ~7,500 (63%) |
| Large (20+ files) - full application | ~35,000 tokens | ~12,000 tokens | ~23,000 (66%) |

Context-window capacity: with planning you can complete ~16-17 medium projects per 200K window vs ~7-8 without (2.1x effective increase).

## Step 3: create files with awareness

As each file is written:

- Reference what was already created.
- Note what future files will depend on this one.
- Keep naming and structure consistent.
- Add comments about dependencies where helpful.

## Step 4: verify

### File-path verification
```text
- CSS links: <link href="styles.css"> (not "style.css" or "css/styles.css")
- JS scripts: <script src="script.js">
- Images: <img src="image.png">
- Relative paths match actual file structure
```

### Reference-loading verification
```text
- HTML files find the CSS file
- JavaScript imports resolve correctly
- No 404 errors for missing files
- Correct syntax in link / script tags
```

### Navigation verification (for websites)
```text
- All navigation links point to correct files
- Links use correct relative paths
- No broken navigation
- Back / forward navigation works logically
```

### Cross-file reference verification
```text
- Components import correctly
- Modules can access exported functions
- Shared utilities are accessible
- API calls reference correct endpoints
```

### Consistency verification
```text
- Naming conventions consistent
- Styling uniform (if using shared CSS)
- Code structure follows same patterns
- Documentation style matches across files
```

### Filled verification: portfolio website

```text
After creating styles.css, index.html, about.html, projects.html, contact.html:

[OK] All HTML files have <link rel="stylesheet" href="styles.css">
[OK] styles.css exists and has content
[OK] Navigation links:
     - index.html links to about.html, projects.html, contact.html
     - All other pages link back to index.html
[OK] All pages use consistent styling from styles.css
[OK] No broken links or missing file references

Result: project structure verified, ready to use.
```

If verification fails, fix issues before considering the project complete.

## When to use this planning approach

**Always plan first for:**
- Websites with multiple pages (3+ HTML files)
- Applications with multiple components
- Projects with shared dependencies (CSS, config files)
- API implementations with multiple endpoints
- Documentation sets with multiple files
- Any project where files reference each other

**Skip planning for:**
- Single-file creations
- Truly independent files with no relationships
- Simple, obvious structures

## Post-project reflection

```text
1. Did you plan before creating files? [Yes/No]
2. How many files did you create? [Number]
3. Did you have to refactor or fix file references? [Yes/No]
4. If you planned first:
   - Estimated context used: ~[2,500-4,500] tokens for [3-8] files
5. If you skipped planning:
   - You likely used: ~[6,000-12,000] tokens
   - Potential savings missed: ~[3,500-7,500] tokens
```

Success indicators:
- Created foundation files (CSS, config) before dependent files.
- No major refactoring needed after file creation.
- All file references worked on first try.
- Could describe file creation order before starting.
- Spent more time planning than fixing.

Improvement signals:
- Had to go back and add shared dependencies.
- Needed to refactor file structure after creation.
- Found broken references between files.
- Created files in no particular order.
- Spent more time fixing than planning.
