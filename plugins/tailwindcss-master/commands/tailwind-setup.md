---
name: tailwind-setup
description: Set up Tailwind CSS v4 with optimal configuration for your project and framework
argument-hint: "[framework] e.g., 'nextjs', 'vite react', 'vue', 'astro'"
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Tailwind CSS Setup

## Purpose
Configure Tailwind CSS v4 for a new or existing project with the optimal setup for your framework.

## Workflow

### 1. Determine Project Type

Ask user about:
- **Framework**: React (Vite), Next.js, Vue, Nuxt, Svelte, Astro, or vanilla
- **TypeScript**: Yes/No
- **Package Manager**: npm, pnpm, yarn, bun

### 2. Install Dependencies

#### Vite Projects (React, Vue, Svelte)
```bash
npm install -D tailwindcss @tailwindcss/vite
```

#### Next.js / PostCSS Projects
```bash
npm install -D tailwindcss @tailwindcss/postcss
```

### 3. Configure Build Tool

#### Vite Configuration
```javascript
// vite.config.ts
import tailwindcss from '@tailwindcss/vite'
import { defineConfig } from 'vite'

export default defineConfig({
  plugins: [tailwindcss()]
})
```

#### PostCSS Configuration
```javascript
// postcss.config.mjs
export default {
  plugins: {
    '@tailwindcss/postcss': {}
  }
}
```

### 4. Create CSS Entry Point

```css
/* src/index.css or app/globals.css */
@import "tailwindcss";

@theme {
  /* Custom design tokens */
  --color-primary: oklch(0.6 0.2 250);
  --color-secondary: oklch(0.7 0.15 180);
  --font-sans: "Inter", system-ui, sans-serif;
}
```

### 5. Add Dark Mode (Optional)

For selector-based dark mode:
```css
@import "tailwindcss";
@custom-variant dark (&:where(.dark, .dark *));
```

### 6. Add Plugins (Optional)

```css
@import "tailwindcss";

/* Typography for Markdown content */
@plugin "@tailwindcss/typography";

/* Form element resets */
@plugin "@tailwindcss/forms";

/* Container queries */
@plugin "@tailwindcss/container-queries";
```

### 7. Import CSS in Entry Point

```javascript
// main.ts / main.tsx
import './index.css'
```

### 8. Install Developer Tools

```bash
# VS Code extension
code --install-extension bradlc.vscode-tailwindcss

# Prettier plugin for class sorting
npm install -D prettier prettier-plugin-tailwindcss
```

Create `.prettierrc`:
```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

### 9. Verify Setup

```html
<!-- Test in any component -->
<div class="p-4 bg-blue-500 text-white rounded-lg">
  Tailwind is working!
</div>
```

## Framework-Specific Notes

### Next.js
- CSS file goes in `app/globals.css`
- Import in `app/layout.tsx`
- Use `suppressHydrationWarning` on `<html>` for dark mode

### Vue with Scoped Styles
- Use `@reference` directive in scoped styles
- Or use CSS variables directly

### Astro
- Add plugin to `astro.config.mjs` vite plugins
- Import CSS in layout files

## Output

Provide:
1. Complete installation commands for chosen setup
2. Configuration files with explanations
3. CSS entry point with recommended @theme setup
4. Framework-specific import instructions
5. Verification steps
