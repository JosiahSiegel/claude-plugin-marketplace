---
name: tailwind-responsive
description: Implement responsive designs with breakpoints and mobile-first patterns
argument-hint: "[layout] e.g., 'card grid', 'sidebar layout', 'hero section'"
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Tailwind CSS Responsive Design

## Purpose
Implement responsive layouts using Tailwind's mobile-first breakpoint system.

## Workflow

### 1. Understand Requirements

Ask user about:
- **Breakpoints needed**: Mobile, tablet, desktop, wide
- **Layout type**: Grid, flexbox, container
- **Content priority**: What shows/hides at each size
- **Custom breakpoints**: Any non-standard sizes

### 2. Default Breakpoints

| Prefix | Min Width | Target Devices |
|--------|-----------|----------------|
| (none) | 0px | Mobile (default) |
| `sm:` | 640px | Large phones, small tablets |
| `md:` | 768px | Tablets |
| `lg:` | 1024px | Laptops |
| `xl:` | 1280px | Desktops |
| `2xl:` | 1536px | Large desktops |

### 3. Common Responsive Patterns

#### Responsive Grid
```html
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
  <div>Item 1</div>
  <div>Item 2</div>
  <div>Item 3</div>
  <div>Item 4</div>
</div>
```

#### Responsive Navigation
```html
<nav class="flex flex-col md:flex-row md:items-center md:justify-between p-4">
  <div class="flex items-center justify-between">
    <a href="/" class="text-xl font-bold">Logo</a>
    <button class="md:hidden p-2">
      <!-- Mobile menu button -->
    </button>
  </div>
  <div class="hidden md:flex md:items-center md:space-x-4">
    <a href="/about">About</a>
    <a href="/contact">Contact</a>
  </div>
</nav>
```

#### Responsive Hero
```html
<section class="py-12 md:py-16 lg:py-24 px-4 md:px-8">
  <div class="max-w-4xl mx-auto text-center">
    <h1 class="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold">
      Headline
    </h1>
    <p class="mt-4 text-lg md:text-xl text-gray-600 max-w-2xl mx-auto">
      Description text
    </p>
    <div class="mt-8 flex flex-col sm:flex-row gap-4 justify-center">
      <button class="px-6 py-3 bg-blue-600 text-white rounded-lg">
        Primary
      </button>
      <button class="px-6 py-3 border border-gray-300 rounded-lg">
        Secondary
      </button>
    </div>
  </div>
</section>
```

#### Responsive Sidebar Layout
```html
<div class="flex flex-col lg:flex-row min-h-screen">
  <!-- Sidebar -->
  <aside class="w-full lg:w-64 lg:flex-shrink-0 bg-gray-100">
    <nav class="p-4">
      <!-- Sidebar content -->
    </nav>
  </aside>

  <!-- Main content -->
  <main class="flex-1 p-4 lg:p-8">
    <!-- Main content -->
  </main>
</div>
```

#### Responsive Card Grid
```html
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
  <article class="bg-white rounded-lg shadow-sm overflow-hidden">
    <img class="w-full h-48 object-cover" src="..." alt="">
    <div class="p-4 md:p-6">
      <h3 class="text-lg md:text-xl font-semibold">Title</h3>
      <p class="mt-2 text-gray-600 text-sm md:text-base">Description</p>
    </div>
  </article>
</div>
```

### 4. Show/Hide Patterns

```html
<!-- Mobile only -->
<div class="block md:hidden">Mobile content</div>

<!-- Desktop only -->
<div class="hidden md:block">Desktop content</div>

<!-- Different content per breakpoint -->
<div class="md:hidden">Mobile nav</div>
<div class="hidden md:flex lg:hidden">Tablet nav</div>
<div class="hidden lg:flex">Desktop nav</div>
```

### 5. Responsive Typography

```html
<h1 class="
  text-2xl sm:text-3xl md:text-4xl lg:text-5xl xl:text-6xl
  font-bold leading-tight
">
  Responsive Heading
</h1>

<p class="
  text-base md:text-lg
  leading-relaxed md:leading-loose
">
  Responsive paragraph
</p>
```

### 6. Responsive Spacing

```html
<section class="
  py-8 md:py-12 lg:py-16 xl:py-24
  px-4 md:px-8 lg:px-12
">
  <div class="
    max-w-7xl mx-auto
    space-y-6 md:space-y-8 lg:space-y-12
  ">
    Content
  </div>
</section>
```

### 7. Custom Breakpoints

```css
@theme {
  /* Add custom breakpoints */
  --breakpoint-xs: 475px;
  --breakpoint-3xl: 1920px;
}
```

```html
<div class="grid xs:grid-cols-2 3xl:grid-cols-6">
  Custom breakpoints
</div>
```

### 8. Container Queries

```css
@plugin "@tailwindcss/container-queries";
```

```html
<!-- Respond to container size, not viewport -->
<div class="@container">
  <div class="flex flex-col @md:flex-row @lg:gap-8">
    Component content
  </div>
</div>
```

## Testing Checklist

- [ ] Test at each breakpoint
- [ ] Check intermediate sizes
- [ ] Verify touch targets on mobile (min 44px)
- [ ] Test with actual content
- [ ] Check landscape orientation

## Output

Provide:
1. Complete responsive HTML structure
2. Explanation of breakpoint choices
3. Show/hide logic for each screen size
4. Mobile-first progressive enhancement
5. Testing recommendations
