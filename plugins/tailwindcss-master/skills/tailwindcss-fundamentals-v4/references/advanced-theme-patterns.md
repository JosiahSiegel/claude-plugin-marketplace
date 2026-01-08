# Advanced @theme Patterns

## Semantic Color Tokens

Create a layered token system for maintainable themes:

```css
@theme {
  /* Base palette (raw values) */
  --color-blue-500: oklch(0.55 0.2 250);
  --color-blue-600: oklch(0.48 0.2 250);
  --color-slate-100: oklch(0.95 0.01 260);
  --color-slate-900: oklch(0.15 0.01 260);

  /* Semantic tokens (reference base palette) */
  --color-primary: var(--color-blue-500);
  --color-primary-hover: var(--color-blue-600);
  --color-background: var(--color-slate-100);
  --color-foreground: var(--color-slate-900);

  /* Component tokens (reference semantic tokens) */
  --color-button-primary-bg: var(--color-primary);
  --color-button-primary-bg-hover: var(--color-primary-hover);
  --color-card-bg: var(--color-background);
  --color-card-text: var(--color-foreground);
}
```

## Dynamic Theme Switching

```css
@theme {
  /* Light mode defaults */
  --color-surface: oklch(0.99 0 0);
  --color-on-surface: oklch(0.15 0 0);
  --color-border: oklch(0.9 0 0);
}

@custom-variant dark (&:where(.dark, .dark *));

/* Override in dark mode using CSS variables */
.dark {
  --color-surface: oklch(0.15 0.01 260);
  --color-on-surface: oklch(0.95 0 0);
  --color-border: oklch(0.25 0.01 260);
}
```

## Responsive Theme Values

Use CSS custom properties with media queries for responsive themes:

```css
@theme {
  --spacing-container: 1rem;
  --text-hero: 2rem;
}

@media (min-width: 768px) {
  :root {
    --spacing-container: 2rem;
    --text-hero: 3rem;
  }
}

@media (min-width: 1024px) {
  :root {
    --spacing-container: 4rem;
    --text-hero: 4rem;
  }
}
```

## Composite Tokens

Define complex values as theme tokens:

```css
@theme {
  /* Shadows with consistent opacity */
  --shadow-sm: 0 1px 2px oklch(0 0 0 / 0.05);
  --shadow-md: 0 4px 6px oklch(0 0 0 / 0.07), 0 2px 4px oklch(0 0 0 / 0.05);
  --shadow-lg: 0 10px 15px oklch(0 0 0 / 0.1), 0 4px 6px oklch(0 0 0 / 0.05);
  --shadow-xl: 0 20px 25px oklch(0 0 0 / 0.1), 0 8px 10px oklch(0 0 0 / 0.04);

  /* Elevation shadows that include color */
  --shadow-elevation-1: 0 1px 3px oklch(0.25 0.02 260 / 0.12);
  --shadow-elevation-2: 0 4px 6px oklch(0.25 0.02 260 / 0.15);
  --shadow-elevation-3: 0 10px 20px oklch(0.25 0.02 260 / 0.2);

  /* Gradients */
  --gradient-primary: linear-gradient(135deg, var(--color-primary-400), var(--color-primary-600));
  --gradient-surface: linear-gradient(180deg, var(--color-surface), var(--color-surface-alt));
}
```

## Typography Scale

Define a complete type scale with matching line heights:

```css
@theme {
  /* Modular scale (1.25 ratio) */
  --text-xs: 0.64rem;      /* 10.24px */
  --text-xs--line-height: 1rem;

  --text-sm: 0.8rem;       /* 12.8px */
  --text-sm--line-height: 1.25rem;

  --text-base: 1rem;       /* 16px */
  --text-base--line-height: 1.5rem;

  --text-lg: 1.25rem;      /* 20px */
  --text-lg--line-height: 1.75rem;

  --text-xl: 1.563rem;     /* 25px */
  --text-xl--line-height: 2rem;

  --text-2xl: 1.953rem;    /* 31.25px */
  --text-2xl--line-height: 2.25rem;

  --text-3xl: 2.441rem;    /* 39px */
  --text-3xl--line-height: 2.5rem;

  --text-4xl: 3.052rem;    /* 48.8px */
  --text-4xl--line-height: 1;
}
```

## Namespace Isolation

Use prefixes to avoid conflicts in multi-tenant systems:

```css
@import "tailwindcss" prefix(app);

@theme {
  --color-brand: oklch(0.6 0.2 250);
}
```

```html
<!-- All utilities prefixed -->
<div class="app:flex app:bg-brand app:p-4">
  Content
</div>
```

## Theme Inheritance Patterns

Create theme variants that extend a base:

```css
/* Base theme */
@theme {
  --color-primary-50: oklch(0.97 0.02 250);
  --color-primary-500: oklch(0.55 0.2 250);
  --color-primary-900: oklch(0.2 0.1 250);
}

/* Brand variant - override in a separate file */
/* brand-theme.css */
@layer theme {
  :root[data-brand="acme"] {
    --color-primary-50: oklch(0.97 0.03 150);
    --color-primary-500: oklch(0.55 0.2 150);
    --color-primary-900: oklch(0.2 0.12 150);
  }

  :root[data-brand="beta"] {
    --color-primary-50: oklch(0.97 0.02 30);
    --color-primary-500: oklch(0.6 0.18 30);
    --color-primary-900: oklch(0.25 0.1 30);
  }
}
```

## Motion & Animation Tokens

```css
@theme {
  /* Durations */
  --duration-instant: 50ms;
  --duration-fast: 150ms;
  --duration-normal: 300ms;
  --duration-slow: 500ms;

  /* Easings */
  --ease-default: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-in: cubic-bezier(0.4, 0, 1, 1);
  --ease-out: cubic-bezier(0, 0, 0.2, 1);
  --ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
  --ease-elastic: cubic-bezier(0.68, -0.6, 0.32, 1.6);

  /* Animations */
  --animate-fade-in: fade-in var(--duration-normal) var(--ease-out);
  --animate-slide-up: slide-up var(--duration-normal) var(--ease-out);
  --animate-scale: scale var(--duration-fast) var(--ease-bounce);
}

@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slide-up {
  from { transform: translateY(10px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@keyframes scale {
  from { transform: scale(0.95); }
  to { transform: scale(1); }
}
```
