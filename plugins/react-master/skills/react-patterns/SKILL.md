---
name: react-patterns
description: |
  Complete React component patterns system.
  PROACTIVELY activate for: (1) Compound components with context, (2) Render props pattern, (3) Higher-Order Components (HOC), (4) Custom hooks as patterns, (5) Provider pattern with reducer, (6) Controlled vs uncontrolled components, (7) Prop getter pattern, (8) State reducer pattern.
  Provides: Pattern implementations, composition strategies, reusable component APIs, flexible state control.
  Ensures clean, maintainable component architecture.
---

## Quick Reference

| Pattern | Use Case | Example |
|---------|----------|---------|
| Compound Components | Related components sharing state | `<Tabs><Tab /><Panel /></Tabs>` |
| Render Props | Dynamic rendering with shared logic | `<Mouse>{({x,y}) => ...}</Mouse>` |
| HOC | Cross-cutting concerns | `withAuth(Component)` |
| Custom Hooks | Stateful logic reuse | `useToggle()`, `useDebounce()` |
| Provider Pattern | Global/shared state | `<CartProvider>...</CartProvider>` |
| Controlled/Uncontrolled | Form input flexibility | `value` vs `defaultValue` |
| Prop Getters | Accessible component APIs | `getButtonProps()` |
| State Reducer | Customizable state logic | `useReducer(customReducer)` |

## When to Use This Skill

Use for **React component architecture**:
- Building flexible, reusable component APIs
- Implementing compound component patterns
- Creating render props for dynamic content
- Developing custom hooks for logic reuse
- Managing controlled vs uncontrolled inputs
- Designing accessible component interfaces

**For state management**: see `react-state-management`

---

# React Component Patterns

## Compound Components

### Basic Compound Component

```tsx
import { createContext, useContext, useState, ReactNode } from 'react';

// Context for sharing state
interface TabsContextType {
  activeTab: string;
  setActiveTab: (tab: string) => void;
}

const TabsContext = createContext<TabsContextType | null>(null);

function useTabsContext() {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('Tabs components must be used within a Tabs provider');
  }
  return context;
}

// Parent component
interface TabsProps {
  defaultTab: string;
  children: ReactNode;
}

function Tabs({ defaultTab, children }: TabsProps) {
  const [activeTab, setActiveTab] = useState(defaultTab);

  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

// Tab List
function TabList({ children }: { children: ReactNode }) {
  return <div className="tab-list" role="tablist">{children}</div>;
}

// Tab Button
interface TabProps {
  value: string;
  children: ReactNode;
}

function Tab({ value, children }: TabProps) {
  const { activeTab, setActiveTab } = useTabsContext();

  return (
    <button
      role="tab"
      aria-selected={activeTab === value}
      onClick={() => setActiveTab(value)}
      className={activeTab === value ? 'active' : ''}
    >
      {children}
    </button>
  );
}

// Tab Panel
interface TabPanelProps {
  value: string;
  children: ReactNode;
}

function TabPanel({ value, children }: TabPanelProps) {
  const { activeTab } = useTabsContext();

  if (activeTab !== value) return null;

  return (
    <div role="tabpanel" className="tab-panel">
      {children}
    </div>
  );
}

// Attach sub-components
Tabs.List = TabList;
Tabs.Tab = Tab;
Tabs.Panel = TabPanel;

export { Tabs };

// Usage
function App() {
  return (
    <Tabs defaultTab="overview">
      <Tabs.List>
        <Tabs.Tab value="overview">Overview</Tabs.Tab>
        <Tabs.Tab value="features">Features</Tabs.Tab>
        <Tabs.Tab value="pricing">Pricing</Tabs.Tab>
      </Tabs.List>
      <Tabs.Panel value="overview">Overview content</Tabs.Panel>
      <Tabs.Panel value="features">Features content</Tabs.Panel>
      <Tabs.Panel value="pricing">Pricing content</Tabs.Panel>
    </Tabs>
  );
}
```

### Flexible Compound Component with Slot Pattern

```tsx
import { createContext, useContext, useState, ReactNode, isValidElement, Children, cloneElement } from 'react';

interface AccordionContextType {
  openItems: Set<string>;
  toggleItem: (id: string) => void;
  allowMultiple: boolean;
}

const AccordionContext = createContext<AccordionContextType | null>(null);

interface AccordionProps {
  children: ReactNode;
  allowMultiple?: boolean;
  defaultOpen?: string[];
}

function Accordion({ children, allowMultiple = false, defaultOpen = [] }: AccordionProps) {
  const [openItems, setOpenItems] = useState<Set<string>>(new Set(defaultOpen));

  const toggleItem = (id: string) => {
    setOpenItems((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        if (!allowMultiple) next.clear();
        next.add(id);
      }
      return next;
    });
  };

  return (
    <AccordionContext.Provider value={{ openItems, toggleItem, allowMultiple }}>
      <div className="accordion">{children}</div>
    </AccordionContext.Provider>
  );
}

interface AccordionItemProps {
  id: string;
  children: ReactNode;
}

function AccordionItem({ id, children }: AccordionItemProps) {
  const context = useContext(AccordionContext);
  if (!context) throw new Error('AccordionItem must be within Accordion');

  const isOpen = context.openItems.has(id);

  return (
    <div className={`accordion-item ${isOpen ? 'open' : ''}`} data-state={isOpen ? 'open' : 'closed'}>
      {Children.map(children, (child) => {
        if (isValidElement(child)) {
          return cloneElement(child as React.ReactElement<{ itemId?: string; isOpen?: boolean }>, {
            itemId: id,
            isOpen,
          });
        }
        return child;
      })}
    </div>
  );
}

interface AccordionTriggerProps {
  children: ReactNode;
  itemId?: string;
  isOpen?: boolean;
}

function AccordionTrigger({ children, itemId, isOpen }: AccordionTriggerProps) {
  const context = useContext(AccordionContext);
  if (!context || !itemId) return null;

  return (
    <button
      className="accordion-trigger"
      aria-expanded={isOpen}
      onClick={() => context.toggleItem(itemId)}
    >
      {children}
      <span className="icon">{isOpen ? '−' : '+'}</span>
    </button>
  );
}

interface AccordionContentProps {
  children: ReactNode;
  isOpen?: boolean;
}

function AccordionContent({ children, isOpen }: AccordionContentProps) {
  if (!isOpen) return null;

  return <div className="accordion-content">{children}</div>;
}

Accordion.Item = AccordionItem;
Accordion.Trigger = AccordionTrigger;
Accordion.Content = AccordionContent;

export { Accordion };
```

## Render Props Pattern

### Basic Render Props

```tsx
import { useState, ReactNode } from 'react';

interface ToggleRenderProps {
  on: boolean;
  toggle: () => void;
  setOn: (value: boolean) => void;
}

interface ToggleProps {
  defaultOn?: boolean;
  children: (props: ToggleRenderProps) => ReactNode;
}

function Toggle({ defaultOn = false, children }: ToggleProps) {
  const [on, setOn] = useState(defaultOn);

  const toggle = () => setOn((prev) => !prev);

  return <>{children({ on, toggle, setOn })}</>;
}

// Usage
function App() {
  return (
    <Toggle defaultOn={false}>
      {({ on, toggle }) => (
        <div>
          <p>The toggle is {on ? 'ON' : 'OFF'}</p>
          <button onClick={toggle}>Toggle</button>
        </div>
      )}
    </Toggle>
  );
}
```

### Mouse Position Tracker

```tsx
import { useState, useEffect, ReactNode } from 'react';

interface MousePosition {
  x: number;
  y: number;
}

interface MouseTrackerProps {
  children: (position: MousePosition) => ReactNode;
}

function MouseTracker({ children }: MouseTrackerProps) {
  const [position, setPosition] = useState<MousePosition>({ x: 0, y: 0 });

  useEffect(() => {
    const handleMouseMove = (e: MouseEvent) => {
      setPosition({ x: e.clientX, y: e.clientY });
    };

    window.addEventListener('mousemove', handleMouseMove);
    return () => window.removeEventListener('mousemove', handleMouseMove);
  }, []);

  return <>{children(position)}</>;
}

// Usage
function App() {
  return (
    <MouseTracker>
      {({ x, y }) => (
        <div
          style={{
            position: 'absolute',
            left: x + 10,
            top: y + 10,
            background: 'black',
            color: 'white',
            padding: '4px 8px',
            borderRadius: '4px',
          }}
        >
          {x}, {y}
        </div>
      )}
    </MouseTracker>
  );
}
```

### Data Fetching Render Props

```tsx
import { useState, useEffect, ReactNode } from 'react';

interface FetchState<T> {
  data: T | null;
  loading: boolean;
  error: Error | null;
  refetch: () => void;
}

interface FetchProps<T> {
  url: string;
  children: (state: FetchState<T>) => ReactNode;
}

function Fetch<T>({ url, children }: FetchProps<T>) {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await fetch(url);
      if (!response.ok) throw new Error('Failed to fetch');
      const result = await response.json();
      setData(result);
    } catch (err) {
      setError(err instanceof Error ? err : new Error('Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [url]);

  return <>{children({ data, loading, error, refetch: fetchData })}</>;
}

// Usage
function UserList() {
  return (
    <Fetch<User[]> url="/api/users">
      {({ data, loading, error, refetch }) => {
        if (loading) return <p>Loading...</p>;
        if (error) return <p>Error: {error.message}</p>;

        return (
          <div>
            <button onClick={refetch}>Refresh</button>
            <ul>
              {data?.map((user) => (
                <li key={user.id}>{user.name}</li>
              ))}
            </ul>
          </div>
        );
      }}
    </Fetch>
  );
}
```

## Best Practices Summary

| Pattern | Use Case |
|---------|----------|
| Compound Components | Related components sharing implicit state |
| Render Props | Dynamic rendering with shared logic |
| HOC | Cross-cutting concerns, code reuse |
| Custom Hooks | Stateful logic reuse |
| Provider Pattern | Global/shared state management |
| Controlled/Uncontrolled | Form input flexibility |
| Prop Getters | Accessible component APIs |
| State Reducer | Customizable state logic |

## Additional React Patterns

For full code examples of the remaining six patterns, see `references/hoc-hooks-provider-controlled-patterns.md`:

- **Higher-Order Components (HOC)** — function that takes a component and returns a new component with added behavior.
- **Custom Hooks as Patterns** — encapsulate stateful logic in `useX` hooks; favored over HOCs and render props in modern React.
- **Provider Pattern** — `React.createContext` plus a `useContext` consumer hook.
- **Controlled vs Uncontrolled Components** — value-driven via props vs ref-driven internal state.
- **Prop Getter Pattern** — return a `getProps()` callback that hands the consumer pre-wired props (used by Downshift, Headless UI).
- **State Reducer Pattern** — accept a reducer prop so consumers can override state transitions (Kent C. Dodds canonical implementation).
