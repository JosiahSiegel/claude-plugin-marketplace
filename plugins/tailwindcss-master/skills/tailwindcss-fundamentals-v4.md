# Tailwind CSS v4 Fundamentals (2025)

## Overview

Tailwind CSS v4.0 was released January 22, 2025, featuring a complete rewrite with a Rust-based engine, CSS-first configuration, and significant performance improvements.

## Installation

### Vite Projects (Recommended)

```bash
npm install -D tailwindcss @tailwindcss/vite
```

```javascript
// vite.config.js
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [tailwindcss()]
})
```

### PostCSS Projects

```bash
npm install -D tailwindcss @tailwindcss/postcss
```

```javascript
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {}
  }
}
```

### CSS Entry Point

```css
/* app.css - The only required CSS file */
@import "tailwindcss";
```

## CSS-First Configuration

### The @theme Directive

Replace tailwind.config.js with CSS-based configuration:

```css
@import "tailwindcss";

@theme {
  /* Colors using modern oklch */
  --color-primary: oklch(0.6 0.2 250);
  --color-secondary: oklch(0.7 0.15 180);
  --color-accent: oklch(0.8 0.2 30);

  /* Typography */
  --font-display: "Satoshi", sans-serif;
  --font-body: "Inter", sans-serif;

  /* Custom spacing */
  --spacing-xs: 0.25rem;
  --spacing-sm: 0.5rem;
  --spacing-md: 1rem;
  --spacing-lg: 2rem;
  --spacing-xl: 4rem;

  /* Custom breakpoints */
  --breakpoint-xs: 475px;
  --breakpoint-3xl: 1920px;
}
```

### Theme Variables Reference

| Category | Variable Pattern | Example |
|----------|-----------------|---------|
| Colors | `--color-*` | `--color-brand-500` |
| Fonts | `--font-*` | `--font-heading` |
| Spacing | `--spacing-*` | `--spacing-4` |
| Breakpoints | `--breakpoint-*` | `--breakpoint-3xl` |
| Radius | `--radius-*` | `--radius-lg` |
| Shadows | `--shadow-*` | `--shadow-xl` |
| Animations | `--animate-*` | `--animate-fade-in` |
| Easing | `--ease-*` | `--ease-bounce` |

### Disabling Defaults

```css
@theme {
  /* Start fresh - disable all default theme values */
  --*: initial;

  /* Define only what you need */
  --spacing: 4px;
  --font-body: Inter, sans-serif;
  --color-primary: oklch(0.72 0.11 221.19);
  --color-secondary: oklch(0.74 0.17 40.24);
}
```

## Custom Utilities

### Static Utilities

```css
/* Define custom utility in CSS */
@utility content-auto {
  content-visibility: auto;
}

@utility text-balance {
  text-wrap: balance;
}

@utility scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

@utility scrollbar-hide::-webkit-scrollbar {
  display: none;
}
```

Usage:
```html
<div class="content-auto scrollbar-hide">
  <h1 class="text-balance">Long headline that should balance nicely</h1>
</div>
```

### Functional Utilities

```css
/* Utility that accepts values */
@utility tab-* {
  tab-size: --value(integer);
}

@utility text-shadow-* {
  text-shadow: 0 0 --value([length]) currentColor;
}

/* With theme reference */
@utility gap-safe-* {
  gap: max(--value(--spacing-*), env(safe-area-inset-bottom));
}
```

Usage:
```html
<pre class="tab-4">Code with 4-space tabs</pre>
<h1 class="text-shadow-[2px]">Glowing text</h1>
<div class="gap-safe-4">Safe area aware gap</div>
```

## Custom Variants

### The @custom-variant Directive

```css
/* Dark mode with selector */
@custom-variant dark (&:where(.dark, .dark *));

/* Custom state variants */
@custom-variant hocus (&:hover, &:focus);
@custom-variant group-hocus (:merge(.group):hover &, :merge(.group):focus &);

/* Data attribute variants */
@custom-variant data-loading (&[data-loading="true"]);
@custom-variant data-active (&[data-state="active"]);

/* Child selectors */
@custom-variant children (& > *);
@custom-variant not-first (& > *:not(:first-child));
```

Usage:
```html
<button class="hocus:bg-blue-600">Hover or focus</button>
<div class="data-loading:opacity-50" data-loading="true">Loading...</div>
<ul class="children:border-b not-first:pt-2">
  <li>Item 1</li>
  <li>Item 2</li>
</ul>
```

## Loading Plugins

### The @plugin Directive

```css
@import "tailwindcss";

/* Load official plugins */
@plugin "@tailwindcss/typography";
@plugin "@tailwindcss/forms";
@plugin "@tailwindcss/container-queries";

/* Load local plugin */
@plugin "./my-plugin.js";
```

### Plugin with Options

```css
@plugin "@tailwindcss/typography" {
  className: wysiwyg;
}

@plugin "@tailwindcss/forms" {
  strategy: class;
}
```

## Using Prefixes

```css
@import "tailwindcss" prefix(tw);

@theme {
  /* Define without prefix */
  --font-display: "Satoshi", sans-serif;
}
```

```html
<!-- Use with prefix -->
<div class="tw:flex tw:bg-red-500 tw:hover:bg-red-600">
  Content
</div>
```

Generated CSS variables include prefix:
```css
:root {
  --tw-font-display: "Satoshi", sans-serif;
}
```

## CSS Variables in Code

### Replace theme() with var()

```css
/* v3 approach (deprecated) */
.old-way {
  background-color: theme(colors.red.500);
}

/* v4 approach */
.new-way {
  background-color: var(--color-red-500);
}

/* In media queries, use CSS variable names */
@media (width >= theme(--breakpoint-xl)) {
  /* styles */
}
```

## Core Utility Categories

### Layout

```html
<!-- Flexbox -->
<div class="flex flex-col md:flex-row items-center justify-between gap-4">

<!-- Grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">

<!-- Container -->
<div class="container mx-auto px-4">
```

### Spacing

```html
<!-- Padding -->
<div class="p-4 px-6 py-2">

<!-- Margin -->
<div class="m-4 mx-auto my-8">

<!-- Gap -->
<div class="gap-4 gap-x-6 gap-y-2">
```

### Typography

```html
<!-- Font size -->
<p class="text-sm md:text-base lg:text-lg">

<!-- Font weight -->
<h1 class="font-bold">

<!-- Text color -->
<p class="text-gray-600 dark:text-gray-300">

<!-- Line height -->
<p class="leading-relaxed">
```

### Colors

```html
<!-- Background -->
<div class="bg-white dark:bg-gray-900">

<!-- Text -->
<p class="text-blue-600">

<!-- Border -->
<div class="border border-gray-200">

<!-- Ring -->
<button class="focus:ring-2 focus:ring-blue-500">
```

### Sizing

```html
<!-- Width -->
<div class="w-full md:w-1/2 lg:w-1/3">

<!-- Height -->
<div class="h-screen min-h-[500px]">

<!-- Max width -->
<div class="max-w-xl mx-auto">
```

## Arbitrary Values

```html
<!-- Use any CSS value -->
<div class="top-[117px] left-[calc(50%-4rem)]">

<!-- With CSS variables -->
<div class="bg-[var(--my-color)]">

<!-- Complex values -->
<div class="grid-cols-[1fr_500px_2fr]">
```

## Important Modifier

```html
<!-- Force important -->
<div class="!mt-0">

<!-- With variants -->
<div class="hover:!bg-red-500">
```

## Built-in Features (No Config Needed)

| Feature | v3 Requirement | v4 |
|---------|---------------|-----|
| @import handling | postcss-import | Built-in |
| Vendor prefixing | autoprefixer | Built-in |
| CSS nesting | postcss-nested | Built-in |
| Content detection | content config | Automatic |

## Layers

```css
/* Use native CSS layers */
@layer base {
  h1 {
    @apply text-2xl font-bold;
  }
}

@layer components {
  .btn {
    @apply px-4 py-2 rounded font-medium;
  }
}

@layer utilities {
  /* Custom utilities via @utility directive instead */
}
```

## Best Practices

### 1. Use CSS Variables Consistently

```css
@theme {
  --color-brand: oklch(0.6 0.2 250);
}

/* In custom CSS */
.custom-element {
  border-color: var(--color-brand);
}
```

### 2. Organize Theme by Category

```css
@theme {
  /* Colors first */
  --color-primary: oklch(0.6 0.2 250);
  --color-secondary: oklch(0.7 0.15 180);

  /* Then typography */
  --font-sans: Inter, sans-serif;
  --font-mono: "Fira Code", monospace;

  /* Then spacing */
  --spacing-page: 2rem;

  /* Then other tokens */
  --radius-default: 0.5rem;
}
```

### 3. Keep @utility Definitions Simple

```css
/* Good - single purpose */
@utility truncate-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Avoid - too complex */
@utility card-fancy {
  /* Too many properties - use a component instead */
}
```

## Common Migration Issues

### Border Color Default

```css
/* v3: border used gray-200 by default */
/* v4: border uses currentColor */

/* Fix: explicitly set color */
@theme {
  --default-border-color: var(--color-gray-200);
}
```

### Ring Default

```css
/* v3: ring was 3px blue-500 */
/* v4: ring is 1px currentColor */

/* Fix: restore v3 behavior */
@theme {
  --default-ring-width: 3px;
  --default-ring-color: var(--color-blue-500);
}
```

### Button Cursor

```css
/* v4: buttons use cursor: default */
/* Fix: add pointer globally if needed */
button {
  cursor: pointer;
}
```
