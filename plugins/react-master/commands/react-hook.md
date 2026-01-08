---
name: react-hook
description: Create a custom React hook following best practices
argument-hint: "useHookName - description of functionality"
---

# Generate React Custom Hook

Create a custom React hook following best practices.

## Arguments
- `$ARGUMENTS` - Hook name and description (e.g., "useDebounce - debounce a value with delay" or "useLocalStorage - persist state to localStorage")

## Instructions

Create a custom hook based on the provided name and description:

1. **Analyze Requirements**
   - Parse hook name from `$ARGUMENTS` (must start with "use")
   - Identify the core functionality
   - Determine parameters and return types
   - Check for existing similar hooks in the codebase

2. **Hook Structure**
   - Name must start with "use"
   - Proper TypeScript generics if needed
   - Clear parameter and return type definitions
   - JSDoc comments for documentation

3. **Implementation Checklist**
   - [ ] Follows Rules of Hooks
   - [ ] Proper dependency arrays
   - [ ] Cleanup in useEffect if needed
   - [ ] Memoization where appropriate
   - [ ] Handles edge cases
   - [ ] TypeScript types for all parameters and returns
   - [ ] SSR-safe (check for `window`/`document`)

4. **File Location**
   - Place in hooks/ directory
   - Use consistent naming (useHookName.ts)
   - Export from index if using barrel exports

## Example Output

```tsx
// hooks/useDebounce.ts
import { useState, useEffect } from 'react';

/**
 * Debounce a value by the specified delay
 * @param value - The value to debounce
 * @param delay - Delay in milliseconds (default: 500)
 * @returns The debounced value
 */
export function useDebounce<T>(value: T, delay = 500): T {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);

  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedValue(value);
    }, delay);

    return () => {
      clearTimeout(timer);
    };
  }, [value, delay]);

  return debouncedValue;
}
```

## Common Hook Patterns

### State + Actions Pattern
```tsx
function useCounter(initial = 0) {
  const [count, setCount] = useState(initial);

  const increment = useCallback(() => setCount(c => c + 1), []);
  const decrement = useCallback(() => setCount(c => c - 1), []);
  const reset = useCallback(() => setCount(initial), [initial]);

  return { count, increment, decrement, reset };
}
```

### Async Data Pattern
```tsx
function useFetch<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    const controller = new AbortController();

    fetch(url, { signal: controller.signal })
      .then(res => res.json())
      .then(setData)
      .catch(setError)
      .finally(() => setLoading(false));

    return () => controller.abort();
  }, [url]);

  return { data, loading, error };
}
```

### Subscription Pattern
```tsx
function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const mediaQuery = window.matchMedia(query);
    setMatches(mediaQuery.matches);

    const handler = (e: MediaQueryListEvent) => setMatches(e.matches);
    mediaQuery.addEventListener('change', handler);

    return () => mediaQuery.removeEventListener('change', handler);
  }, [query]);

  return matches;
}
```

### Ref-Based Pattern
```tsx
function useClickOutside<T extends HTMLElement>(handler: () => void) {
  const ref = useRef<T>(null);

  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      if (!ref.current || ref.current.contains(event.target as Node)) {
        return;
      }
      handler();
    };

    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);

    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, [handler]);

  return ref;
}
```

### Storage Pattern (SSR-Safe)
```tsx
function useLocalStorage<T>(key: string, initialValue: T) {
  const [storedValue, setStoredValue] = useState<T>(() => {
    if (typeof window === 'undefined') {
      return initialValue;
    }
    try {
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = useCallback((value: T | ((prev: T) => T)) => {
    setStoredValue((prev) => {
      const newValue = value instanceof Function ? value(prev) : value;
      window.localStorage.setItem(key, JSON.stringify(newValue));
      return newValue;
    });
  }, [key]);

  return [storedValue, setValue] as const;
}
```

## Rules of Hooks Reminder

1. **Only call hooks at the top level** - Never inside loops, conditions, or nested functions
2. **Only call hooks from React functions** - Function components or custom hooks
3. **Consistent order** - Hooks must be called in the same order every render
