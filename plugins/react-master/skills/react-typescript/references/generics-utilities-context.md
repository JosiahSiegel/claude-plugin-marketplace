# React + TypeScript: Generics, Utilities, Context

Full code for generic component patterns, type utilities (`PropsWithChildren`, `ComponentProps`, etc.), and type-safe React Context. SKILL.md keeps props / event handlers / hooks; this reference has the advanced material.

## Generic Components

### Generic List

```tsx
interface ListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => ReactNode;
  keyExtractor: (item: T) => string | number;
  emptyMessage?: string;
}

function List<T>({
  items,
  renderItem,
  keyExtractor,
  emptyMessage = 'No items',
}: ListProps<T>) {
  if (items.length === 0) {
    return <p>{emptyMessage}</p>;
  }

  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>{renderItem(item, index)}</li>
      ))}
    </ul>
  );
}

// Usage
interface Product {
  id: string;
  name: string;
  price: number;
}

function ProductList({ products }: { products: Product[] }) {
  return (
    <List
      items={products}
      keyExtractor={(product) => product.id}
      renderItem={(product) => (
        <div>
          <span>{product.name}</span>
          <span>${product.price}</span>
        </div>
      )}
    />
  );
}
```

### Generic Select

```tsx
interface SelectOption<T> {
  value: T;
  label: string;
}

interface SelectProps<T> {
  options: SelectOption<T>[];
  value: T | null;
  onChange: (value: T) => void;
  placeholder?: string;
  getOptionValue?: (option: SelectOption<T>) => string;
}

function Select<T>({
  options,
  value,
  onChange,
  placeholder = 'Select...',
  getOptionValue = (opt) => String(opt.value),
}: SelectProps<T>) {
  const selectedOption = options.find((opt) => opt.value === value);

  return (
    <select
      value={selectedOption ? getOptionValue(selectedOption) : ''}
      onChange={(e) => {
        const option = options.find(
          (opt) => getOptionValue(opt) === e.target.value
        );
        if (option) {
          onChange(option.value);
        }
      }}
    >
      <option value="" disabled>
        {placeholder}
      </option>
      {options.map((option) => (
        <option key={getOptionValue(option)} value={getOptionValue(option)}>
          {option.label}
        </option>
      ))}
    </select>
  );
}

// Usage
type Status = 'draft' | 'published' | 'archived';

function StatusSelect() {
  const [status, setStatus] = useState<Status | null>(null);

  const options: SelectOption<Status>[] = [
    { value: 'draft', label: 'Draft' },
    { value: 'published', label: 'Published' },
    { value: 'archived', label: 'Archived' },
  ];

  return <Select options={options} value={status} onChange={setStatus} />;
}
```

### Generic Table

```tsx
interface Column<T> {
  key: keyof T | string;
  header: string;
  render?: (item: T) => ReactNode;
  width?: string | number;
}

interface TableProps<T> {
  data: T[];
  columns: Column<T>[];
  keyExtractor: (item: T) => string | number;
  onRowClick?: (item: T) => void;
}

function Table<T extends Record<string, unknown>>({
  data,
  columns,
  keyExtractor,
  onRowClick,
}: TableProps<T>) {
  const getCellValue = (item: T, column: Column<T>): ReactNode => {
    if (column.render) {
      return column.render(item);
    }
    const value = item[column.key as keyof T];
    return value as ReactNode;
  };

  return (
    <table>
      <thead>
        <tr>
          {columns.map((column) => (
            <th key={String(column.key)} style={{ width: column.width }}>
              {column.header}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((item) => (
          <tr
            key={keyExtractor(item)}
            onClick={() => onRowClick?.(item)}
            style={{ cursor: onRowClick ? 'pointer' : 'default' }}
          >
            {columns.map((column) => (
              <td key={String(column.key)}>{getCellValue(item, column)}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

// Usage
interface User {
  id: string;
  name: string;
  email: string;
  status: 'active' | 'inactive';
  createdAt: Date;
}

function UsersTable({ users }: { users: User[] }) {
  const columns: Column<User>[] = [
    { key: 'name', header: 'Name' },
    { key: 'email', header: 'Email' },
    {
      key: 'status',
      header: 'Status',
      render: (user) => (
        <span className={`badge badge-${user.status}`}>{user.status}</span>
      ),
    },
    {
      key: 'createdAt',
      header: 'Created',
      render: (user) => user.createdAt.toLocaleDateString(),
    },
  ];

  return (
    <Table
      data={users}
      columns={columns}
      keyExtractor={(user) => user.id}
      onRowClick={(user) => console.log('Clicked:', user)}
    />
  );
}
```

## Type Utilities

### Common Utility Types

```tsx
// Partial - all properties optional
interface User {
  id: string;
  name: string;
  email: string;
}

type PartialUser = Partial<User>;
// { id?: string; name?: string; email?: string }

// Required - all properties required
interface Config {
  host?: string;
  port?: number;
}

type RequiredConfig = Required<Config>;
// { host: string; port: number }

// Pick - select specific properties
type UserPreview = Pick<User, 'id' | 'name'>;
// { id: string; name: string }

// Omit - exclude specific properties
type CreateUserInput = Omit<User, 'id'>;
// { name: string; email: string }

// Record - object with specific key/value types
type UserRoles = Record<string, 'admin' | 'user' | 'guest'>;
// { [key: string]: 'admin' | 'user' | 'guest' }

// Extract - extract types from union
type Status = 'idle' | 'loading' | 'success' | 'error';
type LoadingStates = Extract<Status, 'loading' | 'idle'>;
// 'loading' | 'idle'

// Exclude - exclude types from union
type ErrorStates = Exclude<Status, 'success'>;
// 'idle' | 'loading' | 'error'
```

### Component Props Utilities

```tsx
import { ComponentProps, ComponentPropsWithRef, ComponentPropsWithoutRef } from 'react';

// Get props of a component
type ButtonProps = ComponentProps<'button'>;
type DivProps = ComponentProps<'div'>;

// Get props of a custom component
function MyButton(props: { variant: 'primary' | 'secondary' }) {
  return <button {...props} />;
}
type MyButtonProps = ComponentProps<typeof MyButton>;

// Props with ref
type InputPropsWithRef = ComponentPropsWithRef<'input'>;

// Props without ref
type InputPropsNoRef = ComponentPropsWithoutRef<'input'>;
```

### Discriminated Unions

```tsx
// API response states
type ApiResponse<T> =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: T }
  | { status: 'error'; error: Error };

function useApiData<T>(url: string): ApiResponse<T> {
  // Implementation...
  return { status: 'idle' };
}

// Usage with type narrowing
function DataDisplay() {
  const response = useApiData<User[]>('/api/users');

  switch (response.status) {
    case 'idle':
      return <p>Ready to fetch</p>;
    case 'loading':
      return <p>Loading...</p>;
    case 'success':
      // TypeScript knows response.data exists here
      return <UserList users={response.data} />;
    case 'error':
      // TypeScript knows response.error exists here
      return <p>Error: {response.error.message}</p>;
  }
}
```

### Inference and Conditional Types

```tsx
// Infer return type
type ReturnTypeOf<T> = T extends (...args: any[]) => infer R ? R : never;

function fetchUser(id: string) {
  return { id, name: 'John', email: 'john@example.com' };
}

type FetchUserReturn = ReturnTypeOf<typeof fetchUser>;
// { id: string; name: string; email: string }

// Extract promise value
type Awaited<T> = T extends Promise<infer U> ? U : T;

async function getUsers() {
  return [{ id: '1', name: 'John' }];
}

type UsersData = Awaited<ReturnType<typeof getUsers>>;
// { id: string; name: string }[]

// Props inference from component
type PropsOf<T> = T extends React.ComponentType<infer P> ? P : never;
```

## Type-Safe Context

```tsx
import { createContext, useContext, ReactNode } from 'react';

// Create type-safe context factory
function createSafeContext<T>(displayName: string) {
  const Context = createContext<T | undefined>(undefined);
  Context.displayName = displayName;

  function useContextSafe() {
    const context = useContext(Context);
    if (context === undefined) {
      throw new Error(`use${displayName} must be used within ${displayName}Provider`);
    }
    return context;
  }

  return [Context.Provider, useContextSafe] as const;
}

// Usage
interface AuthContextValue {
  user: User | null;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const [AuthProvider, useAuth] = createSafeContext<AuthContextValue>('Auth');

// Provider component
function AuthContextProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);

  const login = async (email: string, password: string) => {
    // Implementation
  };

  const logout = () => {
    setUser(null);
  };

  return (
    <AuthProvider value={{ user, login, logout }}>
      {children}
    </AuthProvider>
  );
}

// Consumer component - fully type-safe
function Profile() {
  const { user, logout } = useAuth();
  // TypeScript knows user can be null
  if (!user) return <p>Please log in</p>;

  return (
    <div>
      <p>Welcome, {user.name}</p>
      <button onClick={logout}>Logout</button>
    </div>
  );
}
```

