# Custom Utilities Deep Dive

## Static Utilities

### Basic Definition

```css
@utility scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

@utility scrollbar-hide::-webkit-scrollbar {
  display: none;
}
```

### Multi-Property Utilities

```css
@utility skeleton {
  background: linear-gradient(
    90deg,
    var(--color-gray-200) 25%,
    var(--color-gray-300) 50%,
    var(--color-gray-200) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s infinite;
}

@keyframes skeleton-shimmer {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### State-Aware Utilities

```css
@utility glass {
  background: oklch(1 0 0 / 0.1);
  backdrop-filter: blur(12px);
  border: 1px solid oklch(1 0 0 / 0.2);
}

/* Dark mode variant applied automatically */
.dark .glass {
  background: oklch(0 0 0 / 0.2);
  border-color: oklch(1 0 0 / 0.1);
}
```

## Functional Utilities

### With Integer Values

```css
@utility tab-* {
  tab-size: --value(integer);
}

@utility columns-* {
  columns: --value(integer);
}

@utility z-* {
  z-index: --value(integer);
}
```

Usage:
```html
<pre class="tab-4">Code</pre>
<div class="columns-3">Multi-column text</div>
<div class="z-50">High z-index</div>
```

### With Length Values

```css
@utility inset-* {
  inset: --value([length]);
}

@utility blur-* {
  filter: blur(--value([length]));
}

@utility tracking-* {
  letter-spacing: --value([length]);
}
```

Usage:
```html
<div class="inset-[10px]">Absolute positioning</div>
<div class="blur-[4px]">Blurred element</div>
<span class="tracking-[0.05em]">Tracked text</span>
```

### With Theme References

```css
@utility gap-safe-* {
  gap: max(--value(--spacing-*), env(safe-area-inset-bottom));
}

@utility text-color-* {
  color: --value(--color-*);
}

@utility bg-gradient-* {
  background: linear-gradient(to right, --value(--color-*), transparent);
}
```

Usage:
```html
<div class="gap-safe-4">Safe-area aware gap</div>
<p class="text-color-primary-500">Themed text</p>
<div class="bg-gradient-blue-500">Gradient fade</div>
```

### With Multiple Value Types

```css
@utility shadow-text-* {
  text-shadow: 0 0 --value([length]) --value(--color-*, currentColor);
}

/* Alternative: Parse specific formats */
@utility clamp-* {
  font-size: clamp(--value([length]), --value([percentage]), --value([length]));
}
```

## Responsive & Variant-Aware Utilities

Custom utilities automatically work with all variants:

```html
<!-- Responsive -->
<div class="scrollbar-hide md:scrollbar-visible">

<!-- State variants -->
<div class="hover:glass focus:glass">

<!-- Dark mode -->
<div class="glass dark:glass-dark">
```

## Complex Utility Patterns

### Container Query Utilities

```css
@utility @container-* {
  container-type: --value(size, inline-size, normal);
  container-name: --value(identifier, none);
}
```

### Aspect Ratio Utilities

```css
@utility aspect-* {
  aspect-ratio: --value(ratio);
}

/* Named aspects */
@utility aspect-video {
  aspect-ratio: 16 / 9;
}

@utility aspect-square {
  aspect-ratio: 1 / 1;
}

@utility aspect-portrait {
  aspect-ratio: 3 / 4;
}
```

### Line Clamp Utilities

```css
@utility line-clamp-* {
  display: -webkit-box;
  -webkit-line-clamp: --value(integer);
  -webkit-box-orient: vertical;
  overflow: hidden;
}

@utility line-clamp-none {
  display: block;
  -webkit-line-clamp: unset;
  -webkit-box-orient: unset;
  overflow: visible;
}
```

### Scroll Snap Utilities

```css
@utility snap-x {
  scroll-snap-type: x mandatory;
}

@utility snap-y {
  scroll-snap-type: y mandatory;
}

@utility snap-start {
  scroll-snap-align: start;
}

@utility snap-center {
  scroll-snap-align: center;
}

@utility snap-proximity {
  scroll-snap-type: both proximity;
}
```

## Performance Considerations

### Avoid Overly Complex Utilities

```css
/* BAD - Too many properties */
@utility card {
  display: flex;
  flex-direction: column;
  padding: 1rem;
  background: white;
  border-radius: 0.5rem;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

/* GOOD - Use component or @apply in CSS */
@layer components {
  .card {
    @apply flex flex-col p-4 bg-white rounded-lg shadow-sm;
  }
}
```

### Keep Functional Utilities Focused

```css
/* GOOD - Single purpose */
@utility opacity-* {
  opacity: --value(percentage);
}

/* AVOID - Multiple unrelated properties */
@utility fancy-* {
  opacity: --value(percentage);
  transform: scale(1.1);
  filter: saturate(1.2);
}
```

## Debugging Custom Utilities

Check if utility is generated:

```bash
# Search compiled CSS
grep "scrollbar-hide" dist/output.css

# Use browser DevTools
# Elements > Styles > Search for class name
```

If not working:
1. Verify `@utility` syntax is correct
2. Check CSS file is imported after `@import "tailwindcss"`
3. Ensure class name is used in template (content detection)
