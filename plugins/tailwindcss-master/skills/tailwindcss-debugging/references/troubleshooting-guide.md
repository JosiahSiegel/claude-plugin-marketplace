# Tailwind CSS Troubleshooting Guide

## Classes Not Working

### Symptom: Utility class has no effect

**1. Dynamic Class Names**

Most common issue. Tailwind can't detect dynamically constructed classes:

```tsx
// WON'T WORK
const color = 'blue'
className={`bg-${color}-500`}  // ❌

// WORKS
const bgColors = {
  blue: 'bg-blue-500',
  red: 'bg-red-500',
}
className={bgColors[color]}  // ✓
```

**2. Content Detection Failure**

v4 auto-detects files, but may miss custom locations:

```css
/* Add explicit source paths */
@import "tailwindcss";
@source "../custom-components/**/*.tsx";
@source "../../shared-ui/**/*.jsx";
```

**3. CSS Specificity Conflict**

Check browser DevTools for overridden styles:
- Look for crossed-out declarations
- Check for `!important` rules
- Look for more specific selectors (IDs, inline styles)

Fix: Use `!important` modifier or restructure CSS:
```html
<div class="!mt-0">Forces margin-top: 0</div>
```

**4. Cache Issues**

```bash
# Clear all caches
rm -rf node_modules/.cache .next/cache .vite

# Restart dev server
npm run dev
```

**5. Build Not Running**

Verify Tailwind is processing your CSS:

```bash
# Check for tailwind in output
grep "bg-blue-500" dist/output.css
```

## Dark Mode Not Working

### Symptom: `dark:` variants have no effect

**1. Missing dark mode configuration**

```css
/* globals.css */
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
```

**2. `dark` class not on html/body**

```html
<html class="dark">  <!-- Required for selector strategy -->
  <body>...</body>
</html>
```

**3. Using wrong strategy**

```css
/* For media query strategy (prefers-color-scheme) */
@custom-variant dark (media(prefers-color-scheme: dark));

/* For selector strategy (class-based) */
@custom-variant dark (&:where(.dark, .dark *));
```

## Responsive Breakpoints Not Working

### Symptom: `sm:`, `md:`, etc. have no effect

**1. Viewport too small**

Remember breakpoints are mobile-first (min-width):

| Prefix | Min-width |
|--------|-----------|
| `sm:` | 640px |
| `md:` | 768px |
| `lg:` | 1024px |
| `xl:` | 1280px |

**2. Parent container constraining width**

```html
<!-- Parent might limit width -->
<div class="max-w-sm">
  <div class="md:flex"><!-- md: won't trigger if parent is narrow --></div>
</div>
```

**3. Browser zoom affecting viewport**

Reset zoom to 100% for accurate testing.

## PostCSS / Build Errors

### "Unknown at-rule @import"

Missing PostCSS configuration:

```javascript
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {},
  }
}
```

### "Cannot find module 'tailwindcss'"

```bash
npm install -D tailwindcss @tailwindcss/postcss
```

### Vite-specific errors

```javascript
// vite.config.js
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [tailwindcss()],  // Must be in plugins
})
```

## IntelliSense Not Working

### VS Code autocomplete missing

**1. Install extension**
```bash
code --install-extension bradlc.vscode-tailwindcss
```

**2. Configure for custom locations**

```json
// .vscode/settings.json
{
  "tailwindCSS.includeLanguages": {
    "typescript": "javascript",
    "typescriptreact": "javascript"
  },
  "tailwindCSS.experimental.classRegex": [
    ["clsx\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"],
    ["cn\\(([^)]*)\\)", "(?:'|\"|`)([^']*)(?:'|\"|`)"],
    ["cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]"]
  ]
}
```

**3. Restart extension**
- Cmd/Ctrl + Shift + P
- "Tailwind CSS: Reload Extension"

## Performance Issues

### Slow builds

**1. Too many files in content scan**

```css
/* Be specific with @source */
@source "./src/**/*.{tsx,jsx}";
@source not "./src/**/*.test.tsx";
@source not "./node_modules/**";
```

**2. Large safelist**

Minimize or remove safelist:
```css
/* Avoid large safelists */
@source inline("bg-red-500 bg-blue-500");  /* Only when necessary */
```

### Large CSS output

**1. Check for dynamic class patterns**

```bash
# Find potential issues
grep -r "bg-\${" src/ --include="*.tsx"
grep -r "text-\${" src/ --include="*.tsx"
```

**2. Analyze output**

```bash
# Check CSS size
ls -lh dist/assets/*.css

# Count selectors
grep -o '\.[a-zA-Z]' dist/output.css | wc -l
```

## Common Migration Issues (v3 → v4)

### Border color changed

```css
/* v3: border used gray-200 by default */
/* v4: border uses currentColor */

/* Fix: Set explicit color */
.legacy-borders {
  @apply border-gray-200;
}
```

### Ring defaults changed

```css
/* v3: ring was 3px blue-500 */
/* v4: ring is 1px currentColor */

/* Fix: Be explicit */
@theme {
  --default-ring-width: 3px;
  --default-ring-color: var(--color-blue-500);
}
```

### theme() function deprecated

```css
/* v3 */
.element {
  background: theme(colors.blue.500);
}

/* v4 */
.element {
  background: var(--color-blue-500);
}
```

## Debugging Checklist

### Quick Verification

Add this test element to any page:

```html
<div class="bg-red-500 p-4 text-white fixed top-0 right-0 z-50">
  Tailwind Working
</div>
```

### Full Debug Steps

1. ✓ Check browser DevTools for the class
2. ✓ Search compiled CSS for the class name
3. ✓ Verify PostCSS config exists
4. ✓ Check for dynamic class name issues
5. ✓ Clear caches and restart
6. ✓ Check console for errors
7. ✓ Verify file is in content detection path
8. ✓ Check for CSS specificity conflicts

### Browser DevTools

```
1. Right-click element → Inspect
2. Check "Styles" panel for your class
3. If present but crossed out → specificity issue
4. If missing → content detection or build issue
5. Check "Computed" panel for final values
```

### Verbose Build Output

```bash
# See what Tailwind is processing
DEBUG=tailwindcss:* npm run build
```
