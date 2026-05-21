# Multi-file context anti-patterns

Five concrete creation-order anti-patterns and their fixes. Use these as references when planning the order in which files will be written.

## Anti-pattern 1: JS modules before the main app file

**Wrong:**
```text
1. Create utils.js
2. Create helpers.js
3. Create api.js
4. Create app.js (main file that imports all the above)
Problem: Had to keep going back to app.js to add imports
```

**Right:**
```text
1. Think about module structure
2. Create app.js (with import statements planned)
3. Create utils.js (knowing what app.js needs)
4. Create helpers.js (knowing what app.js needs)
5. Create api.js (knowing what app.js needs)
Benefit: app.js structured correctly from the start
```

## Anti-pattern 2: Inline styles then extract later

**Wrong:**
```text
1. Create index.html with inline styles
2. Create about.html with inline styles
3. Realize styles are duplicated
4. Extract to styles.css
5. Update all HTML files to reference it
Problem: Redundant work, had to edit multiple files
```

**Right:**
```text
1. Think: These pages will share styling
2. Create styles.css first
3. Create HTML files that reference styles.css
Benefit: No duplication, no refactoring needed
```

## Anti-pattern 3: Components before data structure

**Wrong:**
```text
1. Create UserProfile.jsx component
2. Create UserList.jsx component
3. Realize data structure is unclear
4. Go back and modify components to match data
Problem: Components built on assumptions
```

**Right:**
```text
1. Think about data structure first
2. Create types.js or schema.js
3. Create components that use defined data structure
Benefit: Components built correctly from the start
```

## Anti-pattern 4: Pages before shared layout

**Wrong:**
```text
1. Create home.html with full layout
2. Create about.html with full layout
3. Realize layout should be shared
4. Extract to layout component/template
5. Refactor all pages
Problem: Major refactoring required
```

**Right:**
```text
1. Think: Pages will share layout
2. Create layout.html or Layout component
3. Create pages that use the layout
Benefit: DRY from the start
```

## Anti-pattern 5: Config files last

**Wrong:**
```text
1. Create multiple files with hardcoded values
2. Realize config should be centralized
3. Create config.js
4. Update all files to use config
Problem: Config scattered, hard to change
```

**Right:**
```text
1. Think: What values will be used across files?
2. Create config.js first
3. Create other files that import config
Benefit: Centralized configuration from start
```
