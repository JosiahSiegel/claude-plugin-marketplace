# Bundle Size Optimization

## Measuring Your Bundle

### Check Raw CSS Size

```bash
# File size
ls -lh dist/assets/*.css

# Gzipped size (what users actually download)
gzip -c dist/assets/main.css | wc -c

# Brotli size (even smaller)
brotli -c dist/assets/main.css | wc -c
```

### Target Sizes

| App Type | Target CSS Size | Gzipped |
|----------|-----------------|---------|
| Landing page | < 15KB | < 5KB |
| Small app | < 30KB | < 10KB |
| Large app | < 50KB | < 15KB |
| Design system | < 80KB | < 25KB |

## Reducing Theme Size

### Minimal Color Palette

```css
@theme {
  /* Reset all defaults */
  --color-*: initial;

  /* Define only what you need */
  --color-primary-500: oklch(0.55 0.2 250);
  --color-primary-600: oklch(0.48 0.2 250);
  --color-gray-50: oklch(0.98 0 0);
  --color-gray-100: oklch(0.95 0 0);
  --color-gray-500: oklch(0.55 0 0);
  --color-gray-900: oklch(0.15 0 0);
  --color-white: oklch(1 0 0);
  --color-black: oklch(0 0 0);
}
```

### Limited Spacing Scale

```css
@theme {
  /* Reset defaults */
  --spacing-*: initial;

  /* 4px base scale */
  --spacing-0: 0;
  --spacing-1: 0.25rem;  /* 4px */
  --spacing-2: 0.5rem;   /* 8px */
  --spacing-3: 0.75rem;  /* 12px */
  --spacing-4: 1rem;     /* 16px */
  --spacing-6: 1.5rem;   /* 24px */
  --spacing-8: 2rem;     /* 32px */
  --spacing-12: 3rem;    /* 48px */
  --spacing-16: 4rem;    /* 64px */
}
```

### Essential Breakpoints Only

```css
@theme {
  --breakpoint-*: initial;

  /* Mobile-first essentials */
  --breakpoint-sm: 640px;   /* Tablet */
  --breakpoint-lg: 1024px;  /* Desktop */
  /* Skip md, xl, 2xl if not using */
}
```

## Plugin Optimization

### Load Only What You Need

```css
/* Only load plugins you actually use */
@plugin "@tailwindcss/typography";

/* Don't load if not using */
/* @plugin "@tailwindcss/forms"; */
/* @plugin "@tailwindcss/container-queries"; */
```

### Typography Plugin Optimization

```css
@plugin "@tailwindcss/typography" {
  /* Use shorter class name */
  className: prose;

  /* Disable unused modifiers if needed */
  /* modifiers: ["lg", "xl"]; */
}
```

## Static Theme Mode

For maximum performance when CSS variables aren't needed:

```css
@import "tailwindcss/theme.css" theme(static);
@import "tailwindcss/utilities.css";
```

This inlines all theme values instead of using CSS variables, resulting in:
- Smaller output (no variable declarations)
- Faster paint (no variable resolution)
- No dynamic theming capability

## Code Splitting CSS

### Route-Based Splitting

```javascript
// vite.config.js
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks(id) {
          // Split CSS by route
          if (id.includes('/admin/')) {
            return 'admin'
          }
          if (id.includes('/dashboard/')) {
            return 'dashboard'
          }
        }
      }
    }
  }
})
```

### Lazy Load Feature CSS

```tsx
// Only load when component mounts
const ChartComponent = lazy(async () => {
  await import('./chart-styles.css')
  return import('./Chart')
})
```

## Minification

### Vite with LightningCSS

```javascript
// vite.config.js
export default defineConfig({
  css: {
    transformer: 'lightningcss',
  },
  build: {
    cssMinify: 'lightningcss',
  }
})
```

### PostCSS with cssnano

```javascript
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {},
    ...(process.env.NODE_ENV === 'production' ? {
      cssnano: {
        preset: ['default', {
          discardComments: { removeAll: true },
          normalizeWhitespace: true,
        }]
      }
    } : {})
  }
}
```

## Identifying Bloat

### Find Large Selectors

```bash
# Count unique selectors
grep -o '\.[a-zA-Z0-9_-]*' dist/output.css | sort -u | wc -l

# Find most repeated patterns
grep -o '\.[a-zA-Z0-9_-]*' dist/output.css | sort | uniq -c | sort -rn | head -20
```

### Check for Unused Classes

Use PurgeCSS in audit mode:

```javascript
// purgecss.config.js
module.exports = {
  content: ['./src/**/*.{tsx,jsx,html}'],
  css: ['./dist/assets/*.css'],
  output: './purgecss-report.json',
  rejected: true, // Show what would be removed
}
```

### Bundle Analyzer

```bash
# Install
npm install -D vite-bundle-visualizer

# Run
npx vite-bundle-visualizer
```

## Common Bloat Sources

| Issue | Solution |
|-------|----------|
| Full color palette | Use `--color-*: initial` and define only needed |
| All breakpoint variants | Limit breakpoints in theme |
| Unused plugins | Remove unused `@plugin` directives |
| Safe-listed classes | Review and minimize safelist |
| Dynamic class patterns | Use complete class names |

## Production Checklist

- [ ] `NODE_ENV=production` is set
- [ ] CSS minification enabled
- [ ] Gzip/Brotli compression on server
- [ ] Theme limited to used tokens
- [ ] Only necessary plugins loaded
- [ ] No unnecessary safelist entries
- [ ] Bundle size within targets
