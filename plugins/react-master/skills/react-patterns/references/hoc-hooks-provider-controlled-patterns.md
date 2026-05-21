# React Patterns: HOC, Custom Hooks, Provider, Controlled, Prop Getter, State Reducer

Full code examples for HOC, custom-hook-as-pattern, Provider pattern, controlled vs uncontrolled components, prop getter, and state reducer. SKILL.md keeps compound-components and render-props in full; this reference holds the remaining six patterns.

## Higher-Order Components (HOC)

### Basic HOC

```tsx
import { ComponentType } from 'react';

interface WithLoadingProps {
  isLoading: boolean;
}

function withLoading<P extends object>(
  WrappedComponent: ComponentType<P>
) {
  return function WithLoadingComponent(props: P & WithLoadingProps) {
    const { isLoading, ...rest } = props;

    if (isLoading) {
      return <div className="loading-spinner">Loading...</div>;
    }

    return <WrappedComponent {...(rest as P)} />;
  };
}

// Usage
interface UserListProps {
  users: User[];
}

function UserList({ users }: UserListProps) {
  return (
    <ul>
      {users.map((user) => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}

const UserListWithLoading = withLoading(UserList);

// In parent component
<UserListWithLoading isLoading={loading} users={users} />
```

### HOC with Injected Props

```tsx
import { ComponentType, useEffect, useState } from 'react';

interface User {
  id: string;
  name: string;
  email: string;
}

interface WithUserProps {
  user: User | null;
  userLoading: boolean;
}

function withUser<P extends WithUserProps>(
  WrappedComponent: ComponentType<P>
) {
  return function WithUserComponent(
    props: Omit<P, keyof WithUserProps>
  ) {
    const [user, setUser] = useState<User | null>(null);
    const [userLoading, setUserLoading] = useState(true);

    useEffect(() => {
      fetch('/api/me')
        .then((res) => res.json())
        .then((data) => {
          setUser(data);
          setUserLoading(false);
        })
        .catch(() => setUserLoading(false));
    }, []);

    return (
      <WrappedComponent
        {...(props as P)}
        user={user}
        userLoading={userLoading}
      />
    );
  };
}

// Usage
interface ProfileProps extends WithUserProps {
  showAvatar?: boolean;
}

function Profile({ user, userLoading, showAvatar = true }: ProfileProps) {
  if (userLoading) return <div>Loading user...</div>;
  if (!user) return <div>Not logged in</div>;

  return (
    <div>
      {showAvatar && <img src={`/avatars/${user.id}`} alt="" />}
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}

const ProfileWithUser = withUser(Profile);
```

### Composing Multiple HOCs

```tsx
import { ComponentType } from 'react';

// Utility for composing HOCs
function compose<P>(...hocs: Array<(c: ComponentType<any>) => ComponentType<any>>) {
  return (Component: ComponentType<P>) =>
    hocs.reduceRight((acc, hoc) => hoc(acc), Component);
}

// Usage
const EnhancedComponent = compose(
  withLoading,
  withUser,
  withTheme
)(BaseComponent);
```

## Custom Hooks as Patterns

### useToggle

```tsx
import { useState, useCallback } from 'react';

function useToggle(initialValue = false) {
  const [value, setValue] = useState(initialValue);

  const toggle = useCallback(() => setValue((v) => !v), []);
  const setTrue = useCallback(() => setValue(true), []);
  const setFalse = useCallback(() => setValue(false), []);

  return { value, toggle, setTrue, setFalse, setValue };
}

// Usage
function Modal() {
  const { value: isOpen, toggle, setFalse: close } = useToggle();

  return (
    <>
      <button onClick={toggle}>Open Modal</button>
      {isOpen && (
        <div className="modal">
          <button onClick={close}>Close</button>
        </div>
      )}
    </>
  );
}
```

### useDisclosure

```tsx
import { useState, useCallback } from 'react';

interface UseDisclosureReturn {
  isOpen: boolean;
  onOpen: () => void;
  onClose: () => void;
  onToggle: () => void;
  getDisclosureProps: () => { 'aria-expanded': boolean; 'aria-controls': string };
  getContentProps: () => { id: string; hidden: boolean };
}

function useDisclosure(
  id: string,
  { defaultOpen = false }: { defaultOpen?: boolean } = {}
): UseDisclosureReturn {
  const [isOpen, setIsOpen] = useState(defaultOpen);

  const onOpen = useCallback(() => setIsOpen(true), []);
  const onClose = useCallback(() => setIsOpen(false), []);
  const onToggle = useCallback(() => setIsOpen((prev) => !prev), []);

  const getDisclosureProps = useCallback(
    () => ({
      'aria-expanded': isOpen,
      'aria-controls': `${id}-content`,
    }),
    [isOpen, id]
  );

  const getContentProps = useCallback(
    () => ({
      id: `${id}-content`,
      hidden: !isOpen,
    }),
    [isOpen, id]
  );

  return {
    isOpen,
    onOpen,
    onClose,
    onToggle,
    getDisclosureProps,
    getContentProps,
  };
}
```

### useClickOutside

```tsx
import { useEffect, useRef, RefObject } from 'react';

function useClickOutside<T extends HTMLElement>(
  handler: () => void,
  events: Array<'mousedown' | 'mouseup' | 'touchstart' | 'touchend'> = ['mousedown', 'touchstart']
): RefObject<T> {
  const ref = useRef<T>(null);

  useEffect(() => {
    const listener = (event: Event) => {
      const target = event.target as Node;
      if (!ref.current || ref.current.contains(target)) {
        return;
      }
      handler();
    };

    events.forEach((event) => document.addEventListener(event, listener));

    return () => {
      events.forEach((event) => document.removeEventListener(event, listener));
    };
  }, [handler, events]);

  return ref;
}

// Usage
function Dropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const ref = useClickOutside<HTMLDivElement>(() => setIsOpen(false));

  return (
    <div ref={ref}>
      <button onClick={() => setIsOpen(true)}>Open</button>
      {isOpen && <div className="dropdown-menu">Menu content</div>}
    </div>
  );
}
```

## Provider Pattern

### Context with Reducer

```tsx
import { createContext, useContext, useReducer, ReactNode, Dispatch } from 'react';

// Types
interface CartItem {
  id: string;
  name: string;
  price: number;
  quantity: number;
}

interface CartState {
  items: CartItem[];
  total: number;
}

type CartAction =
  | { type: 'ADD_ITEM'; payload: Omit<CartItem, 'quantity'> }
  | { type: 'REMOVE_ITEM'; payload: string }
  | { type: 'UPDATE_QUANTITY'; payload: { id: string; quantity: number } }
  | { type: 'CLEAR_CART' };

// Reducer
function cartReducer(state: CartState, action: CartAction): CartState {
  switch (action.type) {
    case 'ADD_ITEM': {
      const existingItem = state.items.find((item) => item.id === action.payload.id);

      if (existingItem) {
        const items = state.items.map((item) =>
          item.id === action.payload.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
        return { items, total: calculateTotal(items) };
      }

      const items = [...state.items, { ...action.payload, quantity: 1 }];
      return { items, total: calculateTotal(items) };
    }
    case 'REMOVE_ITEM': {
      const items = state.items.filter((item) => item.id !== action.payload);
      return { items, total: calculateTotal(items) };
    }
    case 'UPDATE_QUANTITY': {
      const items = state.items.map((item) =>
        item.id === action.payload.id
          ? { ...item, quantity: action.payload.quantity }
          : item
      );
      return { items, total: calculateTotal(items) };
    }
    case 'CLEAR_CART':
      return { items: [], total: 0 };
    default:
      return state;
  }
}

function calculateTotal(items: CartItem[]): number {
  return items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

// Context
interface CartContextType {
  state: CartState;
  dispatch: Dispatch<CartAction>;
  addItem: (item: Omit<CartItem, 'quantity'>) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clearCart: () => void;
}

const CartContext = createContext<CartContextType | null>(null);

// Provider
function CartProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(cartReducer, { items: [], total: 0 });

  const addItem = (item: Omit<CartItem, 'quantity'>) => {
    dispatch({ type: 'ADD_ITEM', payload: item });
  };

  const removeItem = (id: string) => {
    dispatch({ type: 'REMOVE_ITEM', payload: id });
  };

  const updateQuantity = (id: string, quantity: number) => {
    dispatch({ type: 'UPDATE_QUANTITY', payload: { id, quantity } });
  };

  const clearCart = () => {
    dispatch({ type: 'CLEAR_CART' });
  };

  return (
    <CartContext.Provider
      value={{ state, dispatch, addItem, removeItem, updateQuantity, clearCart }}
    >
      {children}
    </CartContext.Provider>
  );
}

// Hook
function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
}

export { CartProvider, useCart };
```

## Controlled vs Uncontrolled Components

### Controlled Input

```tsx
import { useState, ChangeEvent } from 'react';

function ControlledInput() {
  const [value, setValue] = useState('');

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    setValue(e.target.value);
  };

  return (
    <input
      type="text"
      value={value}
      onChange={handleChange}
      placeholder="Controlled input"
    />
  );
}
```

### Uncontrolled Input

```tsx
import { useRef, FormEvent } from 'react';

function UncontrolledInput() {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    console.log('Value:', inputRef.current?.value);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input ref={inputRef} type="text" defaultValue="" />
      <button type="submit">Submit</button>
    </form>
  );
}
```

### Hybrid Controlled/Uncontrolled Component

```tsx
import { useState, useCallback, ChangeEvent } from 'react';

interface InputProps {
  value?: string;
  defaultValue?: string;
  onChange?: (value: string) => void;
}

function Input({ value: controlledValue, defaultValue = '', onChange }: InputProps) {
  const [internalValue, setInternalValue] = useState(defaultValue);

  const isControlled = controlledValue !== undefined;
  const value = isControlled ? controlledValue : internalValue;

  const handleChange = useCallback(
    (e: ChangeEvent<HTMLInputElement>) => {
      const newValue = e.target.value;

      if (!isControlled) {
        setInternalValue(newValue);
      }

      onChange?.(newValue);
    },
    [isControlled, onChange]
  );

  return <input type="text" value={value} onChange={handleChange} />;
}

// Usage - Controlled
function ControlledUsage() {
  const [value, setValue] = useState('');
  return <Input value={value} onChange={setValue} />;
}

// Usage - Uncontrolled
function UncontrolledUsage() {
  return <Input defaultValue="initial" onChange={console.log} />;
}
```

## Prop Getter Pattern

```tsx
import { useState, useCallback, HTMLAttributes, InputHTMLAttributes } from 'react';

interface UseSelectReturn<T> {
  selectedItem: T | null;
  isOpen: boolean;
  highlightedIndex: number;
  getToggleButtonProps: () => HTMLAttributes<HTMLButtonElement>;
  getMenuProps: () => HTMLAttributes<HTMLUListElement>;
  getItemProps: (options: { item: T; index: number }) => HTMLAttributes<HTMLLIElement>;
  getInputProps: () => InputHTMLAttributes<HTMLInputElement>;
}

function useSelect<T extends { id: string; label: string }>(
  items: T[]
): UseSelectReturn<T> {
  const [selectedItem, setSelectedItem] = useState<T | null>(null);
  const [isOpen, setIsOpen] = useState(false);
  const [highlightedIndex, setHighlightedIndex] = useState(-1);

  const getToggleButtonProps = useCallback(
    () => ({
      onClick: () => setIsOpen((prev) => !prev),
      'aria-haspopup': 'listbox' as const,
      'aria-expanded': isOpen,
    }),
    [isOpen]
  );

  const getMenuProps = useCallback(
    () => ({
      role: 'listbox' as const,
      'aria-activedescendant': highlightedIndex >= 0 ? items[highlightedIndex]?.id : undefined,
      hidden: !isOpen,
    }),
    [isOpen, highlightedIndex, items]
  );

  const getItemProps = useCallback(
    ({ item, index }: { item: T; index: number }) => ({
      role: 'option' as const,
      id: item.id,
      'aria-selected': selectedItem?.id === item.id,
      onClick: () => {
        setSelectedItem(item);
        setIsOpen(false);
      },
      onMouseEnter: () => setHighlightedIndex(index),
    }),
    [selectedItem]
  );

  const getInputProps = useCallback(
    () => ({
      value: selectedItem?.label || '',
      readOnly: true,
      onClick: () => setIsOpen(true),
    }),
    [selectedItem]
  );

  return {
    selectedItem,
    isOpen,
    highlightedIndex,
    getToggleButtonProps,
    getMenuProps,
    getItemProps,
    getInputProps,
  };
}

// Usage
function Select({ items }: { items: Array<{ id: string; label: string }> }) {
  const {
    selectedItem,
    isOpen,
    highlightedIndex,
    getToggleButtonProps,
    getMenuProps,
    getItemProps,
    getInputProps,
  } = useSelect(items);

  return (
    <div className="select">
      <input {...getInputProps()} placeholder="Select an item" />
      <button {...getToggleButtonProps()}>▼</button>
      <ul {...getMenuProps()}>
        {isOpen &&
          items.map((item, index) => (
            <li
              key={item.id}
              {...getItemProps({ item, index })}
              className={highlightedIndex === index ? 'highlighted' : ''}
            >
              {item.label}
            </li>
          ))}
      </ul>
    </div>
  );
}
```

## State Reducer Pattern

```tsx
import { useReducer, Reducer } from 'react';

// Types
type ToggleState = { on: boolean };
type ToggleAction = { type: 'toggle' } | { type: 'reset'; initialState: ToggleState };

// Default reducer
function toggleReducer(state: ToggleState, action: ToggleAction): ToggleState {
  switch (action.type) {
    case 'toggle':
      return { on: !state.on };
    case 'reset':
      return action.initialState;
    default:
      return state;
  }
}

interface UseToggleOptions {
  initialOn?: boolean;
  reducer?: Reducer<ToggleState, ToggleAction>;
}

function useToggleWithReducer({
  initialOn = false,
  reducer = toggleReducer,
}: UseToggleOptions = {}) {
  const initialState = { on: initialOn };
  const [state, dispatch] = useReducer(reducer, initialState);

  const toggle = () => dispatch({ type: 'toggle' });
  const reset = () => dispatch({ type: 'reset', initialState });

  return { ...state, toggle, reset, dispatch };
}

// Usage with custom reducer
function App() {
  const customReducer: Reducer<ToggleState, ToggleAction> = (state, action) => {
    // Custom logic: can only toggle if some condition
    if (action.type === 'toggle' && state.on) {
      // Prevent turning off
      return state;
    }
    return toggleReducer(state, action);
  };

  const { on, toggle } = useToggleWithReducer({ reducer: customReducer });

  return (
    <button onClick={toggle}>
      {on ? 'ON (cannot turn off)' : 'OFF'}
    </button>
  );
}
```

