---
description: Create a custom React hook following best practices
---

# Generate React Custom Hook

Create a custom React hook following best practices.

## Arguments
- `$ARGUMENTS` - Hook name and description (e.g., "useDebounce - debounce a value with delay")

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
