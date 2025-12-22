---
description: Debug Tailwind CSS issues, missing styles, and configuration problems
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Tailwind CSS Debugging

## Purpose
Diagnose and resolve Tailwind CSS issues including missing styles, configuration problems, and build errors.

## Workflow

### 1. Identify the Problem

Common issues:
- Styles not applying
- Build errors
- Missing classes
- Dark mode not working
- Plugins not loading
- Slow builds

### 2. Quick Diagnostic Checks

#### Check Installation
```bash
# Verify packages installed
npm ls tailwindcss
npm ls @tailwindcss/postcss
npm ls @tailwindcss/vite
```

#### Check CSS Import
```css
/* Must have this import */
@import "tailwindcss";
```

#### Verify Build is Running
```bash
# Restart dev server
npm run dev
```

### 3. Styles Not Applying

#### A. Check Class Name Completeness
```javascript
// BAD - Dynamic classes won't be detected
const color = 'blue'
className={`bg-${color}-500`}

// GOOD - Complete class names
const colorClasses = {
  blue: 'bg-blue-500',
  red: 'bg-red-500'
}
className={colorClasses[color]}
```

#### B. Check Content Detection
```css
/* Add explicit sources if needed */
@source "./src/**/*.{html,js,jsx,ts,tsx,vue,svelte}";
@source "./components/**/*.{js,jsx,ts,tsx}";
```

#### C. Check CSS Specificity
```html
<!-- Use !important if needed -->
<div class="!mt-0">

<!-- Or check for conflicting styles in DevTools -->
```

#### D. Clear Caches
```bash
# Vite
rm -rf node_modules/.vite

# Next.js
rm -rf .next

# General
rm -rf node_modules && npm install
```

### 4. v4 Migration Issues

#### PostCSS Plugin
```javascript
// OLD (v3)
plugins: {
  tailwindcss: {},
  autoprefixer: {}
}

// NEW (v4)
plugins: {
  '@tailwindcss/postcss': {}
}
```

#### Configuration Location
```css
/* v4 - Configure in CSS */
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.6 0.2 250);
}
```

#### Dark Mode
```css
/* Add for selector strategy */
@custom-variant dark (&:where(.dark, .dark *));
```

### 5. Plugin Issues

#### Typography Not Working
```css
/* Verify plugin is loaded */
@plugin "@tailwindcss/typography";
```

```html
<!-- Use prose class -->
<article class="prose dark:prose-invert">
  Content
</article>
```

#### Forms Not Styled
```html
<!-- Forms plugin requires type attribute -->
<input type="text" />  <!-- ✓ Works -->
<input />              <!-- ✗ No styling -->
```

### 6. Build Errors

#### "Cannot find module"
```bash
npm install -D tailwindcss @tailwindcss/postcss
```

#### "Unknown at-rule @theme"
- Using v3 tooling with v4 syntax
- Update packages to latest versions

#### Large Bundle Size
- Check for dynamic class generation
- Review safelisted classes
- Remove unused plugins

### 7. Browser DevTools Debugging

1. **Right-click** element → **Inspect**
2. **Styles panel** → See applied rules
3. Look for **crossed-out** styles (overridden)
4. Check **Computed** tab for final values
5. Search for specific classes

### 8. Generate Debug Output

```bash
# Output compiled CSS
npx tailwindcss -o output.css

# Verbose logging
DEBUG=tailwindcss:* npm run build
```

### 9. Common Fixes

| Problem | Solution |
|---------|----------|
| Styles missing | Check content sources, restart dev |
| Wrong colors | Check @theme, dark mode config |
| Layout broken | Check flex/grid classes |
| Slow builds | Ensure using v4, check globs |
| Plugins fail | Update to v4-compatible versions |

### 10. Verification

```html
<!-- Add this to verify Tailwind is working -->
<div class="p-4 m-4 bg-blue-500 text-white rounded-lg">
  If this is blue with white text, Tailwind works!
</div>
```

## Output

Provide:
1. Specific diagnosis of the issue
2. Root cause explanation
3. Step-by-step fix
4. Prevention tips
5. Verification steps
