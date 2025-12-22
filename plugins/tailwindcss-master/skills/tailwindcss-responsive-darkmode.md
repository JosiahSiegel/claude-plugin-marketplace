# Tailwind CSS Responsive Design & Dark Mode

## Responsive Design

### Mobile-First Approach

Tailwind uses a mobile-first breakpoint system. Unprefixed utilities apply to all screen sizes, while prefixed utilities apply at that breakpoint and above.

### Default Breakpoints

| Prefix | Min Width | CSS Media Query |
|--------|-----------|-----------------|
| (none) | 0px | All sizes |
| `sm:` | 640px | `@media (min-width: 640px)` |
| `md:` | 768px | `@media (min-width: 768px)` |
| `lg:` | 1024px | `@media (min-width: 1024px)` |
| `xl:` | 1280px | `@media (min-width: 1280px)` |
| `2xl:` | 1536px | `@media (min-width: 1536px)` |

### Custom Breakpoints

```css
@theme {
  /* Add custom breakpoints */
  --breakpoint-xs: 475px;
  --breakpoint-3xl: 1920px;

  /* Override existing breakpoint */
  --breakpoint-sm: 600px;
}
```

Usage:
```html
<div class="grid xs:grid-cols-2 3xl:grid-cols-6">
  <!-- Custom breakpoints work like built-in ones -->
</div>
```

### Responsive Examples

#### Responsive Grid

```html
<div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
  <div>Item 4</div>
</div>
```

#### Responsive Typography

```html
<h1 class="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-bold">
  Responsive Heading
</h1>

<p class="text-sm md:text-base lg:text-lg leading-relaxed">
  Responsive paragraph text
</p>
```

#### Responsive Spacing

```html
<section class="py-8 md:py-12 lg:py-16 px-4 md:px-8 lg:px-12">
  <div class="max-w-4xl mx-auto">
    Content with responsive padding
  </div>
</section>
```

#### Responsive Navigation

```html
<nav class="flex flex-col md:flex-row items-center justify-between">
  <div class="hidden md:flex gap-4">
    <!-- Desktop navigation -->
  </div>
  <button class="md:hidden">
    <!-- Mobile menu button -->
  </button>
</nav>
```

#### Show/Hide Based on Screen Size

```html
<!-- Hidden on mobile, visible on desktop -->
<div class="hidden md:block">Desktop only</div>

<!-- Visible on mobile, hidden on desktop -->
<div class="block md:hidden">Mobile only</div>

<!-- Different content per breakpoint -->
<span class="sm:hidden">XS</span>
<span class="hidden sm:inline md:hidden">SM</span>
<span class="hidden md:inline lg:hidden">MD</span>
<span class="hidden lg:inline xl:hidden">LG</span>
<span class="hidden xl:inline 2xl:hidden">XL</span>
<span class="hidden 2xl:inline">2XL</span>
```

### Container Queries (v4)

Use container queries for component-based responsive design:

```css
@plugin "@tailwindcss/container-queries";
```

```html
<div class="@container">
  <div class="flex flex-col @md:flex-row @lg:gap-8">
    <!-- Responds to container size, not viewport -->
  </div>
</div>
```

### Max-Width Breakpoints

Target screens below a certain size:

```html
<!-- Only on screens smaller than md (< 768px) -->
<div class="md:hidden">Small screens only</div>

<!-- Custom max-width media query -->
<div class="[@media(max-width:600px)]:text-sm">
  Custom max-width
</div>
```

## Dark Mode

### Strategy: Media (Default)

Dark mode follows the user's operating system preference using `prefers-color-scheme`:

```css
@import "tailwindcss";
/* No additional configuration needed */
```

```html
<div class="bg-white dark:bg-gray-900">
  <h1 class="text-gray-900 dark:text-white">Title</h1>
  <p class="text-gray-600 dark:text-gray-300">Content</p>
</div>
```

### Strategy: Selector (Manual Toggle)

Control dark mode with a CSS class:

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));
```

```html
<!-- Add .dark class to html or body to enable dark mode -->
<html class="dark">
  <body>
    <div class="bg-white dark:bg-gray-900">
      Content
    </div>
  </body>
</html>
```

### JavaScript Toggle

```javascript
// Simple toggle
function toggleDarkMode() {
  document.documentElement.classList.toggle('dark');
}

// With localStorage persistence
function initDarkMode() {
  const isDark = localStorage.getItem('darkMode') === 'true' ||
    (!localStorage.getItem('darkMode') &&
     window.matchMedia('(prefers-color-scheme: dark)').matches);

  document.documentElement.classList.toggle('dark', isDark);
}

function toggleDarkMode() {
  const isDark = document.documentElement.classList.toggle('dark');
  localStorage.setItem('darkMode', isDark);
}

// Initialize on page load
initDarkMode();
```

### Three-Way Toggle (Light/Dark/System)

```javascript
const themes = ['light', 'dark', 'system'];

function setTheme(theme) {
  localStorage.setItem('theme', theme);
  applyTheme();
}

function applyTheme() {
  const theme = localStorage.getItem('theme') || 'system';
  const isDark = theme === 'dark' ||
    (theme === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);

  document.documentElement.classList.toggle('dark', isDark);
}

// Listen for system preference changes
window.matchMedia('(prefers-color-scheme: dark)')
  .addEventListener('change', () => {
    if (localStorage.getItem('theme') === 'system') {
      applyTheme();
    }
  });

applyTheme();
```

### Data Attribute Strategy

```css
@custom-variant dark (&:where([data-theme="dark"], [data-theme="dark"] *));
```

```html
<html data-theme="dark">
  <body>
    <div class="bg-white dark:bg-gray-900">Content</div>
  </body>
</html>
```

### Dark Mode with Next.js (next-themes)

```bash
npm install next-themes
```

```jsx
// app/providers.tsx
'use client';

import { ThemeProvider } from 'next-themes';

export function Providers({ children }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="system">
      {children}
    </ThemeProvider>
  );
}
```

```jsx
// app/layout.tsx
import { Providers } from './providers';

export default function RootLayout({ children }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
```

```jsx
// components/ThemeToggle.tsx
'use client';

import { useTheme } from 'next-themes';

export function ThemeToggle() {
  const { theme, setTheme } = useTheme();

  return (
    <button onClick={() => setTheme(theme === 'dark' ? 'light' : 'dark')}>
      Toggle Theme
    </button>
  );
}
```

### Dark Mode Color Palette

```html
<!-- Text colors -->
<p class="text-gray-900 dark:text-gray-100">Primary text</p>
<p class="text-gray-600 dark:text-gray-400">Secondary text</p>
<p class="text-gray-400 dark:text-gray-500">Muted text</p>

<!-- Background colors -->
<div class="bg-white dark:bg-gray-900">Page background</div>
<div class="bg-gray-50 dark:bg-gray-800">Card background</div>
<div class="bg-gray-100 dark:bg-gray-700">Elevated background</div>

<!-- Border colors -->
<div class="border border-gray-200 dark:border-gray-700">Bordered element</div>

<!-- Interactive elements -->
<button class="bg-blue-500 hover:bg-blue-600 dark:bg-blue-600 dark:hover:bg-blue-700">
  Button
</button>
```

### Dark Mode with CSS Variables

```css
@theme {
  /* Light mode colors (default) */
  --color-bg-primary: oklch(1 0 0);
  --color-bg-secondary: oklch(0.98 0 0);
  --color-text-primary: oklch(0.15 0 0);
  --color-text-secondary: oklch(0.4 0 0);
}

/* Dark mode overrides */
@media (prefers-color-scheme: dark) {
  :root {
    --color-bg-primary: oklch(0.15 0 0);
    --color-bg-secondary: oklch(0.2 0 0);
    --color-text-primary: oklch(0.95 0 0);
    --color-text-secondary: oklch(0.7 0 0);
  }
}
```

```html
<div class="bg-[var(--color-bg-primary)] text-[var(--color-text-primary)]">
  Semantic colors
</div>
```

### Typography Plugin Dark Mode

```html
<article class="prose dark:prose-invert">
  <!-- Markdown content automatically adapts to dark mode -->
</article>
```

## Combining Responsive and Dark Mode

```html
<!-- Different layouts AND colors based on screen size and theme -->
<div class="
  grid grid-cols-1 md:grid-cols-2
  bg-white dark:bg-gray-900
  p-4 md:p-8
  text-gray-900 dark:text-white
">
  <div class="hidden dark:md:block">
    Only visible on md+ screens in dark mode
  </div>
</div>
```

## Best Practices

### 1. Start Mobile, Then Enhance

```html
<!-- Good: Mobile-first -->
<div class="text-sm md:text-base lg:text-lg">

<!-- Avoid: Desktop-first thinking -->
<div class="lg:text-lg md:text-base text-sm">
```

### 2. Use Semantic Dark Mode Colors

```css
@theme {
  /* Instead of raw colors, use semantic names */
  --color-surface: oklch(1 0 0);
  --color-surface-dark: oklch(0.15 0 0);
  --color-on-surface: oklch(0.1 0 0);
  --color-on-surface-dark: oklch(0.95 0 0);
}
```

### 3. Test All Breakpoints

Use the debug-screens plugin during development:

```bash
npm install -D @tailwindcss/debug-screens
```

```css
@plugin "@tailwindcss/debug-screens";
```

### 4. Reduce Repetition with Components

```css
/* components.css */
@layer components {
  .card {
    @apply bg-white dark:bg-gray-800 rounded-lg p-6 shadow-sm;
  }

  .section {
    @apply py-12 md:py-16 lg:py-24;
  }
}
```

### 5. Consider Color Contrast

Ensure sufficient contrast in both light and dark modes:

```html
<!-- Good contrast in both modes -->
<button class="
  bg-blue-600 text-white
  dark:bg-blue-500 dark:text-white
  hover:bg-blue-700 dark:hover:bg-blue-400
">
  Action
</button>
```
