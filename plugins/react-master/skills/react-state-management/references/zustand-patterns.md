# Zustand Patterns Guide

Advanced patterns and best practices for Zustand state management.

## Core Concepts

### Basic Store Setup

```tsx
import { create } from 'zustand';

interface BearStore {
  bears: number;
  increase: () => void;
  decrease: () => void;
  reset: () => void;
}

const useBearStore = create<BearStore>((set) => ({
  bears: 0,
  increase: () => set((state) => ({ bears: state.bears + 1 })),
  decrease: () => set((state) => ({ bears: Math.max(0, state.bears - 1) })),
  reset: () => set({ bears: 0 }),
}));

// Usage
function BearCounter() {
  const bears = useBearStore((state) => state.bears);
  const increase = useBearStore((state) => state.increase);

  return (
    <div>
      <span>{bears} bears</span>
      <button onClick={increase}>Add bear</button>
    </div>
  );
}
```

### Using get() for Current State

```tsx
const useStore = create<Store>((set, get) => ({
  items: [],
  selectedId: null,

  // Use get() to access current state in actions
  getSelectedItem: () => {
    const { items, selectedId } = get();
    return items.find((item) => item.id === selectedId) ?? null;
  },

  // Use get() for conditional logic
  addItem: (item) => {
    const { items } = get();
    if (items.length >= 100) {
      console.warn('Item limit reached');
      return;
    }
    set({ items: [...items, item] });
  },
}));
```

## Selectors and Performance

### Selecting Primitive Values

```tsx
// GOOD - Only re-renders when count changes
const count = useStore((state) => state.count);

// BAD - Re-renders on ANY state change
const { count, items, users } = useStore();
```

### Selecting Derived Data

```tsx
// GOOD - Shallow comparison with useMemo-like behavior
const expensiveItems = useStore(
  (state) => state.items.filter((item) => item.price > 100),
  // Custom equality function
  (a, b) => a.length === b.length && a.every((item, i) => item.id === b[i].id)
);

// Using shallow from zustand
import { shallow } from 'zustand/shallow';

const { count, total } = useStore(
  (state) => ({ count: state.count, total: state.total }),
  shallow
);
```

### Creating Reusable Selectors

```tsx
// selectors.ts
export const selectUser = (state: StoreState) => state.user;
export const selectIsAuthenticated = (state: StoreState) => state.user !== null;
export const selectCartTotal = (state: StoreState) =>
  state.cart.reduce((sum, item) => sum + item.price * item.quantity, 0);

// Component
function Cart() {
  const total = useStore(selectCartTotal);
  return <span>Total: ${total}</span>;
}
```

### Using useShallow for Object Selection

```tsx
import { useShallow } from 'zustand/react/shallow';

// Prevents re-renders when unrelated state changes
function UserProfile() {
  const { name, email, avatar } = useStore(
    useShallow((state) => ({
      name: state.user.name,
      email: state.user.email,
      avatar: state.user.avatar,
    }))
  );

  return (
    <div>
      <img src={avatar} alt={name} />
      <h1>{name}</h1>
      <p>{email}</p>
    </div>
  );
}
```

## Middleware Patterns

### Persist Middleware - Local Storage

```tsx
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';

interface CartStore {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  clearCart: () => void;
}

const useCartStore = create<CartStore>()(
  persist(
    (set) => ({
      items: [],
      addItem: (item) =>
        set((state) => ({
          items: [...state.items, item],
        })),
      clearCart: () => set({ items: [] }),
    }),
    {
      name: 'cart-storage', // localStorage key
      storage: createJSONStorage(() => localStorage),
      // Only persist certain fields
      partialize: (state) => ({ items: state.items }),
    }
  )
);
```

### Persist with SessionStorage

```tsx
const useSessionStore = create<Store>()(
  persist(
    (set) => ({
      // ...
    }),
    {
      name: 'session-data',
      storage: createJSONStorage(() => sessionStorage),
    }
  )
);
```

### Persist with Async Storage (React Native)

```tsx
import AsyncStorage from '@react-native-async-storage/async-storage';

const useStore = create<Store>()(
  persist(
    (set) => ({
      // ...
    }),
    {
      name: 'app-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

### DevTools Middleware

```tsx
import { create } from 'zustand';
import { devtools } from 'zustand/middleware';

const useStore = create<Store>()(
  devtools(
    (set) => ({
      count: 0,
      increment: () =>
        set(
          (state) => ({ count: state.count + 1 }),
          false, // replace state?
          'increment' // action name for devtools
        ),
    }),
    { name: 'MyStore' } // Store name in devtools
  )
);
```

### Combining Middlewares

```tsx
import { create } from 'zustand';
import { devtools, persist, subscribeWithSelector } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';

// Order matters! devtools should be outer, persist inner
const useStore = create<Store>()(
  devtools(
    subscribeWithSelector(
      persist(
        immer((set) => ({
          // Store definition
        })),
        { name: 'storage-key' }
      )
    ),
    { name: 'StoreName' }
  )
);
```

### Immer Middleware - Mutable Updates

```tsx
import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

interface TodoStore {
  todos: Todo[];
  addTodo: (text: string) => void;
  toggleTodo: (id: string) => void;
  updateTodo: (id: string, text: string) => void;
}

const useTodoStore = create<TodoStore>()(
  immer((set) => ({
    todos: [],

    addTodo: (text) =>
      set((state) => {
        // Mutate directly - Immer handles immutability
        state.todos.push({
          id: crypto.randomUUID(),
          text,
          completed: false,
        });
      }),

    toggleTodo: (id) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) {
          todo.completed = !todo.completed;
        }
      }),

    updateTodo: (id, text) =>
      set((state) => {
        const todo = state.todos.find((t) => t.id === id);
        if (todo) {
          todo.text = text;
        }
      }),
  }))
);
```

## Store Organization Patterns

### Slice Pattern - Split Large Stores

```tsx
// slices/userSlice.ts
export interface UserSlice {
  user: User | null;
  setUser: (user: User | null) => void;
  logout: () => void;
}

export const createUserSlice: StateCreator<
  UserSlice & CartSlice, // Full store type
  [],
  [],
  UserSlice
> = (set) => ({
  user: null,
  setUser: (user) => set({ user }),
  logout: () => set({ user: null }),
});

// slices/cartSlice.ts
export interface CartSlice {
  items: CartItem[];
  addItem: (item: CartItem) => void;
  clearCart: () => void;
}

export const createCartSlice: StateCreator<
  UserSlice & CartSlice,
  [],
  [],
  CartSlice
> = (set) => ({
  items: [],
  addItem: (item) => set((state) => ({ items: [...state.items, item] })),
  clearCart: () => set({ items: [] }),
});

// store.ts
import { create, StateCreator } from 'zustand';

type StoreState = UserSlice & CartSlice;

const useStore = create<StoreState>()((...args) => ({
  ...createUserSlice(...args),
  ...createCartSlice(...args),
}));
```

### Domain-Specific Stores

```tsx
// stores/authStore.ts
export const useAuthStore = create<AuthStore>((set) => ({
  user: null,
  token: null,
  login: async (credentials) => {
    const { user, token } = await api.login(credentials);
    set({ user, token });
  },
  logout: () => set({ user: null, token: null }),
}));

// stores/uiStore.ts
export const useUIStore = create<UIStore>((set) => ({
  sidebarOpen: false,
  theme: 'light',
  toggleSidebar: () => set((s) => ({ sidebarOpen: !s.sidebarOpen })),
  setTheme: (theme) => set({ theme }),
}));

// stores/cartStore.ts
export const useCartStore = create<CartStore>((set) => ({
  // Cart specific logic
}));
```

## Async Actions

### Basic Async Pattern

```tsx
interface DataStore {
  data: Item[] | null;
  loading: boolean;
  error: Error | null;
  fetchData: () => Promise<void>;
}

const useDataStore = create<DataStore>((set) => ({
  data: null,
  loading: false,
  error: null,

  fetchData: async () => {
    set({ loading: true, error: null });

    try {
      const response = await fetch('/api/data');
      const data = await response.json();
      set({ data, loading: false });
    } catch (error) {
      set({
        error: error instanceof Error ? error : new Error('Unknown error'),
        loading: false,
      });
    }
  },
}));
```

### Async with Abort Controller

```tsx
interface SearchStore {
  query: string;
  results: SearchResult[];
  loading: boolean;
  setQuery: (query: string) => void;
  search: () => Promise<void>;
}

const useSearchStore = create<SearchStore>((set, get) => {
  let abortController: AbortController | null = null;

  return {
    query: '',
    results: [],
    loading: false,

    setQuery: (query) => set({ query }),

    search: async () => {
      // Cancel previous request
      abortController?.abort();
      abortController = new AbortController();

      const { query } = get();
      if (!query.trim()) {
        set({ results: [] });
        return;
      }

      set({ loading: true });

      try {
        const response = await fetch(`/api/search?q=${query}`, {
          signal: abortController.signal,
        });
        const results = await response.json();
        set({ results, loading: false });
      } catch (error) {
        if (error instanceof Error && error.name !== 'AbortError') {
          set({ loading: false });
        }
      }
    },
  };
});
```

## Subscriptions and Side Effects

### Subscribe to State Changes

```tsx
import { subscribeWithSelector } from 'zustand/middleware';

const useStore = create<Store>()(
  subscribeWithSelector((set) => ({
    count: 0,
    increment: () => set((s) => ({ count: s.count + 1 })),
  }))
);

// Subscribe to specific state changes
const unsubscribe = useStore.subscribe(
  (state) => state.count,
  (count, prevCount) => {
    console.log(`Count changed from ${prevCount} to ${count}`);
  }
);

// With options
useStore.subscribe(
  (state) => state.count,
  (count) => {
    console.log('Count is now:', count);
  },
  {
    equalityFn: (a, b) => a === b, // Custom equality
    fireImmediately: true, // Fire on subscribe
  }
);
```

### React Integration with useEffect

```tsx
function Analytics() {
  const count = useStore((s) => s.count);

  useEffect(() => {
    // Track analytics when count changes
    analytics.track('count_changed', { count });
  }, [count]);

  return null;
}
```

## Computed Values

### Using get() for Computed Properties

```tsx
interface CartStore {
  items: CartItem[];
  getTotal: () => number;
  getItemCount: () => number;
}

const useCartStore = create<CartStore>((set, get) => ({
  items: [],

  getTotal: () => {
    const { items } = get();
    return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
  },

  getItemCount: () => {
    const { items } = get();
    return items.reduce((sum, item) => sum + item.quantity, 0);
  },
}));

// Usage
function CartSummary() {
  const getTotal = useCartStore((s) => s.getTotal);
  const getItemCount = useCartStore((s) => s.getItemCount);

  // Note: These are functions, call them to get values
  return (
    <div>
      <span>{getItemCount()} items</span>
      <span>${getTotal()}</span>
    </div>
  );
}
```

### Selector-Based Computed Values

```tsx
// More efficient - computed at selection time
function CartSummary() {
  const total = useCartStore((s) =>
    s.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  );

  return <span>${total}</span>;
}
```

## Store Outside React

### Accessing Store Outside Components

```tsx
// Access state directly
const currentState = useStore.getState();
console.log(currentState.count);

// Call actions directly
useStore.getState().increment();

// Set state directly
useStore.setState({ count: 100 });

// Subscribe outside React
const unsubscribe = useStore.subscribe(console.log);
```

### Use in API Interceptors

```tsx
// api/client.ts
import axios from 'axios';
import { useAuthStore } from '@/stores/authStore';

const client = axios.create({ baseURL: '/api' });

client.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

client.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
    }
    return Promise.reject(error);
  }
);
```

## Testing Patterns

### Testing Store Actions

```tsx
import { beforeEach, describe, expect, it } from 'vitest';
import { useCartStore } from './cartStore';

describe('cartStore', () => {
  beforeEach(() => {
    // Reset store before each test
    useCartStore.setState({ items: [] });
  });

  it('adds item to cart', () => {
    const item = { id: '1', name: 'Product', price: 10, quantity: 1 };

    useCartStore.getState().addItem(item);

    expect(useCartStore.getState().items).toHaveLength(1);
    expect(useCartStore.getState().items[0]).toEqual(item);
  });

  it('calculates total correctly', () => {
    useCartStore.setState({
      items: [
        { id: '1', name: 'A', price: 10, quantity: 2 },
        { id: '2', name: 'B', price: 5, quantity: 3 },
      ],
    });

    expect(useCartStore.getState().getTotal()).toBe(35);
  });
});
```

### Testing Components with Store

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { useCartStore } from './cartStore';
import { Cart } from './Cart';

beforeEach(() => {
  useCartStore.setState({ items: [] });
});

it('displays cart items', () => {
  useCartStore.setState({
    items: [{ id: '1', name: 'Test Product', price: 10, quantity: 1 }],
  });

  render(<Cart />);

  expect(screen.getByText('Test Product')).toBeInTheDocument();
});

it('removes item when delete is clicked', async () => {
  const user = userEvent.setup();
  useCartStore.setState({
    items: [{ id: '1', name: 'Test Product', price: 10, quantity: 1 }],
  });

  render(<Cart />);
  await user.click(screen.getByRole('button', { name: /remove/i }));

  expect(useCartStore.getState().items).toHaveLength(0);
});
```
