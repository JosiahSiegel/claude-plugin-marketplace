# React Master Plugin

Comprehensive React 19 expertise for Claude Code, covering modern React development patterns, hooks, server components, state management, testing, and performance optimization.

## Features

This plugin provides expertise in:

- **React 19 Fundamentals** - Server/client components, the `use` hook, server actions
- **Hooks Mastery** - All built-in hooks with advanced patterns
- **State Management** - Context, Redux, Zustand, Jotai, TanStack Query
- **Component Patterns** - Compound components, render props, HOCs, custom hooks
- **Performance** - Memoization, code splitting, concurrent features
- **Testing** - Vitest, Jest, React Testing Library
- **TypeScript** - Full type safety with React
- **Forms** - React Hook Form, controlled/uncontrolled patterns
- **Accessibility** - ARIA, keyboard navigation, screen readers

## Skills

| Skill | Description |
|-------|-------------|
| `react-fundamentals-19` | React 19 core concepts, JSX, components |
| `react-hooks-complete` | All hooks with patterns and best practices |
| `react-server-components` | RSC, client components, server actions |
| `react-state-management` | Context, external libraries, patterns |
| `react-performance` | Optimization, memoization, profiling |
| `react-testing` | Testing strategies and tools |
| `react-patterns` | Advanced component patterns |
| `react-typescript` | TypeScript with React |
| `react-forms` | Form handling and validation |

## Commands

| Command | Description |
|---------|-------------|
| `/react-component` | Create a new React component |
| `/react-hook` | Create a custom hook |
| `/react-test` | Generate component tests |
| `/react-optimize` | Analyze and optimize performance |

## Quick Reference

### React 19 New Features

```tsx
// Server Component (default in App Router)
async function ServerComponent() {
  const data = await fetchData();
  return <div>{data}</div>;
}

// Client Component
'use client';
function ClientComponent() {
  const [state, setState] = useState(0);
  return <button onClick={() => setState(s => s + 1)}>{state}</button>;
}

// Server Action
async function submitForm(formData: FormData) {
  'use server';
  await saveToDatabase(formData);
}

// use() hook for promises
function Comments({ commentsPromise }) {
  const comments = use(commentsPromise);
  return comments.map(c => <p key={c.id}>{c.text}</p>);
}
```

### Essential Hooks

```tsx
// State
const [state, setState] = useState(initialValue);
const [state, dispatch] = useReducer(reducer, initialState);

// Effects
useEffect(() => { /* side effect */ return cleanup; }, [deps]);
useLayoutEffect(() => { /* sync effect */ }, [deps]);

// Context
const value = useContext(MyContext);

// Refs
const ref = useRef(initialValue);
const callback = useCallback(fn, [deps]);
const memoized = useMemo(() => compute(), [deps]);

// React 19
const [isPending, startTransition] = useTransition();
const deferredValue = useDeferredValue(value);
const [state, action, isPending] = useActionState(serverAction, initial);
```

### Component Patterns

```tsx
// Compound Components
<Tabs>
  <Tabs.List>
    <Tabs.Tab>One</Tabs.Tab>
    <Tabs.Tab>Two</Tabs.Tab>
  </Tabs.List>
  <Tabs.Panels>
    <Tabs.Panel>Content 1</Tabs.Panel>
    <Tabs.Panel>Content 2</Tabs.Panel>
  </Tabs.Panels>
</Tabs>

// Render Props
<DataFetcher url="/api/data">
  {({ data, loading, error }) => (
    loading ? <Spinner /> : <DataView data={data} />
  )}
</DataFetcher>

// Custom Hook
function useLocalStorage<T>(key: string, initial: T) {
  const [value, setValue] = useState<T>(() => {
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : initial;
  });

  useEffect(() => {
    localStorage.setItem(key, JSON.stringify(value));
  }, [key, value]);

  return [value, setValue] as const;
}
```

### Performance Optimization

```tsx
// Memoize expensive components
const MemoizedComponent = React.memo(ExpensiveComponent);

// Memoize callbacks
const handleClick = useCallback(() => {
  doSomething(id);
}, [id]);

// Memoize computed values
const sortedItems = useMemo(() => {
  return items.sort((a, b) => a.name.localeCompare(b.name));
}, [items]);

// Code splitting
const LazyComponent = React.lazy(() => import('./HeavyComponent'));

// Suspense boundary
<Suspense fallback={<Loading />}>
  <LazyComponent />
</Suspense>
```

## Installation

```bash
# Add to your Claude Code project
claude mcp add react-master
```

## Usage

Simply ask questions about React development:

- "How do I implement a custom hook for form validation?"
- "What's the best way to handle global state in React 19?"
- "How do I optimize a slow-rendering list?"
- "How do I test components with React Testing Library?"

## Version Compatibility

- React 18.x and 19.x
- TypeScript 5.x
- Node.js 18+
