# TailwindCSS Master Plugin

Master Tailwind CSS v4 with expert knowledge of CSS-first configuration, responsive design, dark mode, plugins, and framework integration following 2025 best practices.

## Overview

The TailwindCSS Master plugin equips Claude Code with comprehensive Tailwind CSS v4 expertise, enabling you to build modern, responsive, and performant user interfaces.

## Features

### Commands

- **`/tailwind-setup`** - Set up Tailwind CSS with optimal configuration for your project and framework
- **`/tailwind-component`** - Create reusable Tailwind CSS components with proper patterns
- **`/tailwind-responsive`** - Implement responsive designs with breakpoints and mobile-first patterns
- **`/tailwind-debug`** - Debug Tailwind CSS issues, missing styles, and configuration problems

### Agents

- **TailwindCSS Expert Agent** - Comprehensive Tailwind CSS expert with knowledge of:
  - Tailwind CSS v4 CSS-first configuration
  - @theme, @utility, and @custom-variant directives
  - Responsive design and breakpoints
  - Dark mode implementation (media/selector strategies)
  - Official plugins (@tailwindcss/typography, @tailwindcss/forms)
  - Framework integration patterns

### Skills

- **tailwindcss-fundamentals-v4** - Tailwind CSS v4 core concepts, CSS-first configuration, installation
- **tailwindcss-responsive-darkmode** - Responsive design, breakpoints, dark mode patterns
- **tailwindcss-plugins** - Official plugins (typography, forms), custom plugin creation
- **tailwindcss-performance** - JIT optimization, tree-shaking, production builds
- **tailwindcss-framework-integration** - React, Vue, Next.js, Vite integration patterns
- **tailwindcss-animations** - Transitions, animations, motion utilities
- **tailwindcss-debugging** - Common issues, troubleshooting, VS Code setup

## Installation

### Via Marketplace

```bash
/plugin marketplace add JosiahSiegel/claude-plugin-marketplace
/plugin install tailwindcss-master@claude-plugin-marketplace
```

## Usage

### Project Setup

```bash
/tailwind-setup
```

Claude will:
1. Determine your project type and framework
2. Install Tailwind CSS v4 with appropriate plugin (Vite/PostCSS)
3. Configure your CSS file with @import and @theme
4. Set up VS Code and Prettier extensions

### Component Creation

```bash
/tailwind-component
```

Claude will:
1. Analyze your design requirements
2. Create reusable component patterns
3. Apply responsive and accessibility best practices
4. Provide dark mode variants

### Responsive Design

```bash
/tailwind-responsive
```

Claude will:
1. Implement mobile-first responsive patterns
2. Use appropriate breakpoint variants
3. Apply container queries where appropriate
4. Ensure cross-device compatibility

### Debugging

```bash
/tailwind-debug
```

Claude will:
1. Diagnose why styles aren't applying
2. Check configuration and content detection
3. Identify CSS specificity issues
4. Provide solutions with explanations

## What's New in Tailwind CSS v4

### Released January 22, 2025

**Performance Improvements**
- Up to 5x faster full builds
- Over 100x faster incremental builds (microseconds)
- New Rust-based core engine

**CSS-First Configuration**
```css
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.7 0.15 200);
  --font-display: "Satoshi", sans-serif;
  --breakpoint-3xl: 120rem;
}
```

**New Directives**
- `@theme` - Define design tokens in CSS
- `@utility` - Create custom utilities in CSS
- `@custom-variant` - Create custom variants in CSS
- `@plugin` - Load JavaScript plugins

**Built-in Features**
- Automatic @import handling
- Built-in vendor prefixing (no autoprefixer needed)
- Native CSS nesting support
- Automatic content detection

### Breaking Changes from v3

| Feature | v3 | v4 |
|---------|----|----|
| Configuration | tailwind.config.js | CSS @theme |
| Plugins | require() in config | @plugin directive |
| Border default | gray-200 | currentColor |
| Ring default | 3px blue | 1px currentColor |
| Button cursor | pointer | default |
| PostCSS plugin | tailwindcss | @tailwindcss/postcss |

### Browser Support

- Safari 16.4+
- Chrome 111+
- Firefox 128+

## Quick Reference

### Installation (v4)

```bash
# Vite projects (recommended)
npm install -D tailwindcss @tailwindcss/vite

# PostCSS projects
npm install -D tailwindcss @tailwindcss/postcss
```

### Vite Configuration

```javascript
// vite.config.js
import tailwindcss from '@tailwindcss/vite'

export default {
  plugins: [tailwindcss()]
}
```

### PostCSS Configuration

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
/* app.css */
@import "tailwindcss";

@theme {
  --color-primary: oklch(0.6 0.2 250);
  --font-sans: "Inter", sans-serif;
}
```

## Responsive Design

### Breakpoints

| Prefix | Min Width | CSS |
|--------|-----------|-----|
| `sm:` | 640px | @media (min-width: 640px) |
| `md:` | 768px | @media (min-width: 768px) |
| `lg:` | 1024px | @media (min-width: 1024px) |
| `xl:` | 1280px | @media (min-width: 1280px) |
| `2xl:` | 1536px | @media (min-width: 1536px) |

### Mobile-First Example

```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  <!-- Responsive grid -->
</div>
```

## Dark Mode

### Media Strategy (System Preference)

```css
@import "tailwindcss";
/* Dark mode follows OS preference automatically */
```

```html
<div class="bg-white dark:bg-gray-900">
  <p class="text-gray-900 dark:text-white">Content</p>
</div>
```

### Selector Strategy (Manual Toggle)

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));
```

```javascript
// Toggle dark mode
document.documentElement.classList.toggle('dark');
```

## Official Plugins

### Typography

```css
@plugin "@tailwindcss/typography";
```

```html
<article class="prose lg:prose-xl dark:prose-invert">
  {{ markdown_content }}
</article>
```

### Forms

```css
@plugin "@tailwindcss/forms";
```

```html
<input type="email" class="rounded-lg border-gray-300 focus:ring-blue-500">
```

## Custom Utilities (v4)

```css
/* CSS-based custom utility */
@utility content-auto {
  content-visibility: auto;
}

/* Functional utility with values */
@utility tab-* {
  tab-size: --value(integer);
}
```

## Animation Reference

### Built-in Animations

| Class | Effect |
|-------|--------|
| `animate-spin` | Linear rotation |
| `animate-ping` | Radar ping effect |
| `animate-pulse` | Fade in/out |
| `animate-bounce` | Bounce effect |

### Transitions

```html
<button class="transition-colors duration-200 hover:bg-blue-600">
  Hover me
</button>
```

### Reduced Motion

```html
<div class="motion-safe:animate-spin motion-reduce:animate-none">
  <!-- Respects user preferences -->
</div>
```

## Best Practices

### Performance

- Use specific transitions (`transition-colors`) instead of `transition-all`
- Enable JIT mode (default in v4)
- Avoid dynamic class generation at runtime
- Use the Prettier plugin for consistent class ordering

### Organization

- Extract repeated patterns into components
- Use CSS variables from @theme consistently
- Leverage @layer for custom styles
- Keep utility classes in logical order

### Accessibility

- Use semantic HTML elements
- Provide focus states (`focus:ring-2`)
- Support reduced motion preferences
- Ensure sufficient color contrast

## Tools & Extensions

### VS Code

```bash
# Install Tailwind CSS IntelliSense
code --install-extension bradlc.vscode-tailwindcss
```

### Prettier Plugin

```bash
npm install -D prettier-plugin-tailwindcss
```

```json
{
  "plugins": ["prettier-plugin-tailwindcss"]
}
```

### Debug Screens

```bash
npm install -D @tailwindcss/debug-screens
```

## Migration from v3

Use the official upgrade tool:

```bash
npx @tailwindcss/upgrade@latest
```

The tool handles:
- Updating dependencies
- Migrating tailwind.config.js to CSS
- Updating class names in templates
- Converting plugin usage

## Requirements

- Node.js 20 or higher (for upgrade tool)
- Modern browser (Safari 16.4+, Chrome 111+, Firefox 128+)

## Contributing

Found an issue or want to add support for new Tailwind CSS features? Contributions are welcome.

## License

MIT

## Support

For issues or questions:
- Use `/tailwind-debug` for troubleshooting
- Use `/agent tailwindcss-expert` for complex questions
- Check skills for detailed documentation
- Refer to official [Tailwind CSS documentation](https://tailwindcss.com/docs)

---

**Build beautiful, responsive interfaces with confidence.** This plugin ensures you follow 2025 best practices, leverage Tailwind CSS v4 features, and create maintainable, performant styles.
