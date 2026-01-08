---
name: tailwind-component
description: Create reusable Tailwind CSS components with proper patterns
argument-hint: "<component-type> e.g., 'button', 'card', 'modal', 'form input'"
---

## CRITICAL GUIDELINES

### Windows File Path Requirements

**MANDATORY: Always Use Backslashes on Windows for File Paths**

When using Edit or Write tools on Windows, you MUST use backslashes (`\`) in file paths, NOT forward slashes (`/`).

---

# Tailwind CSS Component Creation

## Purpose
Create well-structured, reusable components using Tailwind CSS best practices.

## Workflow

### 1. Gather Requirements

Ask user about:
- **Component type**: Button, Card, Modal, Form, Navigation, etc.
- **Variants**: Primary/secondary, sizes, states
- **Framework**: React, Vue, Svelte, or vanilla HTML
- **Accessibility needs**: ARIA labels, keyboard navigation

### 2. Component Patterns

#### Button Component (React)
```tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost'
  size?: 'sm' | 'md' | 'lg'
  disabled?: boolean
  children: React.ReactNode
  onClick?: () => void
}

const variants = {
  primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
  secondary: 'bg-gray-200 text-gray-900 hover:bg-gray-300 focus:ring-gray-500',
  outline: 'border-2 border-blue-600 text-blue-600 hover:bg-blue-50 focus:ring-blue-500',
  ghost: 'text-gray-600 hover:bg-gray-100 focus:ring-gray-500'
}

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-base',
  lg: 'px-6 py-3 text-lg'
}

export function Button({
  variant = 'primary',
  size = 'md',
  disabled = false,
  children,
  onClick
}: ButtonProps) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      className={`
        inline-flex items-center justify-center
        font-medium rounded-lg
        transition-colors duration-200
        focus:outline-none focus:ring-2 focus:ring-offset-2
        disabled:opacity-50 disabled:cursor-not-allowed
        ${variants[variant]}
        ${sizes[size]}
      `}
    >
      {children}
    </button>
  )
}
```

#### Card Component
```tsx
interface CardProps {
  title?: string
  children: React.ReactNode
  footer?: React.ReactNode
}

export function Card({ title, children, footer }: CardProps) {
  return (
    <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 overflow-hidden">
      {title && (
        <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            {title}
          </h3>
        </div>
      )}
      <div className="p-6">
        {children}
      </div>
      {footer && (
        <div className="px-6 py-4 bg-gray-50 dark:bg-gray-900 border-t border-gray-200 dark:border-gray-700">
          {footer}
        </div>
      )}
    </div>
  )
}
```

#### Input Component
```tsx
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  hint?: string
}

export function Input({ label, error, hint, id, ...props }: InputProps) {
  const inputId = id || label?.toLowerCase().replace(/\s/g, '-')

  return (
    <div className="space-y-1">
      {label && (
        <label
          htmlFor={inputId}
          className="block text-sm font-medium text-gray-700 dark:text-gray-300"
        >
          {label}
        </label>
      )}
      <input
        id={inputId}
        className={`
          block w-full rounded-lg border px-3 py-2
          text-gray-900 dark:text-white
          placeholder-gray-400 dark:placeholder-gray-500
          bg-white dark:bg-gray-800
          focus:outline-none focus:ring-2 focus:ring-offset-0
          transition-colors
          ${error
            ? 'border-red-500 focus:border-red-500 focus:ring-red-500'
            : 'border-gray-300 dark:border-gray-600 focus:border-blue-500 focus:ring-blue-500'
          }
        `}
        {...props}
      />
      {error && (
        <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
      )}
      {hint && !error && (
        <p className="text-sm text-gray-500 dark:text-gray-400">{hint}</p>
      )}
    </div>
  )
}
```

### 3. Use clsx/tailwind-merge

```bash
npm install clsx tailwind-merge
```

```tsx
import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Usage
<button className={cn(
  "base-styles",
  variant === 'primary' && "primary-styles",
  disabled && "disabled-styles",
  className // Allow overrides
)}>
```

### 4. Accessibility Checklist

- [ ] Semantic HTML elements
- [ ] Focus states visible
- [ ] ARIA labels where needed
- [ ] Keyboard navigation
- [ ] Color contrast (4.5:1 for text)
- [ ] Reduced motion support

### 5. Dark Mode Support

```tsx
// Always include dark mode variants
className="
  bg-white dark:bg-gray-800
  text-gray-900 dark:text-white
  border-gray-200 dark:border-gray-700
"
```

## Output

Provide:
1. Complete component code with TypeScript types
2. All variants and sizes
3. Dark mode support
4. Accessibility features
5. Usage examples
6. Props documentation
