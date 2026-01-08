---
name: react-optimize
description: Analyze and optimize a React component for better performance
argument-hint: "ComponentName or path/to/Component.tsx"
---

# Optimize React Component Performance

Analyze and optimize a React component for better performance.

## Arguments
- `$ARGUMENTS` - Component name or file path to optimize

## Instructions

Analyze and optimize the specified React component:

1. **Performance Analysis**
   - Read the component file specified in `$ARGUMENTS`
   - Identify unnecessary re-renders
   - Find expensive computations
   - Check for missing memoization
   - Identify bundle size concerns

2. **Common Issues to Check**
   - Inline object/function creation in JSX
   - Missing React.memo on pure components
   - Missing useMemo for expensive calculations
   - Missing useCallback for callbacks passed to children
   - Large component bundles (code splitting opportunities)
   - Missing keys or unstable keys in lists

3. **Optimization Techniques**
   - Add React.memo for components that render often with same props
   - Use useMemo for expensive computations
   - Use useCallback for stable callback references
   - Implement code splitting with React.lazy
   - Add virtualization for long lists
   - Use useTransition for non-urgent updates

4. **Report Format**
   - List identified issues
   - Provide optimized code
   - Explain each optimization
   - Note any trade-offs

## Analysis Checklist

### Re-render Prevention
```tsx
// Before - new object every render
<Child style={{ color: 'red' }} />

// After - stable reference
const style = useMemo(() => ({ color: 'red' }), []);
<Child style={style} />
```

### Callback Stability
```tsx
// Before - new function every render
<List onItemClick={(id) => handleClick(id)} />

// After - stable callback
const handleItemClick = useCallback((id: string) => {
  handleClick(id);
}, [handleClick]);
<List onItemClick={handleItemClick} />
```

### Expensive Computation
```tsx
// Before - computed every render
const sortedItems = items.sort((a, b) => a.name.localeCompare(b.name));

// After - memoized
const sortedItems = useMemo(
  () => [...items].sort((a, b) => a.name.localeCompare(b.name)),
  [items]
);
```

### Component Memoization
```tsx
// Before
function ExpensiveList({ items }: Props) { ... }

// After
const ExpensiveList = memo(function ExpensiveList({ items }: Props) { ... });
```

### Code Splitting
```tsx
// Before - imported directly
import HeavyEditor from './HeavyEditor';

// After - lazy loaded
const HeavyEditor = lazy(() => import('./HeavyEditor'));

function App() {
  return (
    <Suspense fallback={<Loading />}>
      <HeavyEditor />
    </Suspense>
  );
}
```

### List Virtualization
```tsx
// Before - renders all items
{items.map(item => <Item key={item.id} {...item} />)}

// After - virtualized
import { FixedSizeList } from 'react-window';

<FixedSizeList height={400} itemCount={items.length} itemSize={50}>
  {({ index, style }) => (
    <Item style={style} {...items[index]} />
  )}
</FixedSizeList>
```

### Non-Urgent Updates
```tsx
// Before - blocks UI
setSearchResults(results);

// After - non-blocking
startTransition(() => {
  setSearchResults(results);
});
```

## Output Format

After analysis, provide:

1. **Issues Found**
   - List each performance issue with severity (High/Medium/Low)

2. **Optimized Code**
   - Show the optimized component code

3. **Changes Made**
   - Explain each optimization applied

4. **Additional Recommendations**
   - Suggest further improvements if applicable
