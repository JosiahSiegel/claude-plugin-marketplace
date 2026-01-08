# React Testing Recipes

Complete testing patterns and solutions for common React scenarios.

## Test Setup

### Vitest Configuration

```ts
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.ts'],
    include: ['**/*.test.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: ['node_modules/', 'src/test/'],
    },
  },
});
```

### Test Setup File

```ts
// src/test/setup.ts
import '@testing-library/jest-dom';
import { cleanup } from '@testing-library/react';
import { afterEach, vi } from 'vitest';

// Cleanup after each test
afterEach(() => {
  cleanup();
  vi.clearAllMocks();
});

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
});

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));

// Mock ResizeObserver
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}));
```

### Custom Render with Providers

```tsx
// src/test/utils.tsx
import { ReactElement, ReactNode } from 'react';
import { render, RenderOptions } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { BrowserRouter } from 'react-router-dom';

interface WrapperProps {
  children: ReactNode;
}

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: {
        retry: false,
        gcTime: 0,
      },
    },
  });
}

function AllProviders({ children }: WrapperProps) {
  const queryClient = createTestQueryClient();

  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        {children}
      </BrowserRouter>
    </QueryClientProvider>
  );
}

function customRender(
  ui: ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) {
  return render(ui, { wrapper: AllProviders, ...options });
}

// Re-export everything
export * from '@testing-library/react';
export { customRender as render };
```

## Component Testing Patterns

### Basic Component Test

```tsx
import { render, screen } from '@/test/utils';
import { describe, it, expect } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const defaultProps = {
    name: 'John Doe',
    email: 'john@example.com',
    role: 'Developer',
  };

  it('renders user information', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
    expect(screen.getByText('Developer')).toBeInTheDocument();
  });

  it('renders avatar when provided', () => {
    render(<UserCard {...defaultProps} avatar="/avatar.jpg" />);

    const avatar = screen.getByRole('img', { name: /john doe/i });
    expect(avatar).toHaveAttribute('src', '/avatar.jpg');
  });

  it('shows placeholder when no avatar', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.getByTestId('avatar-placeholder')).toBeInTheDocument();
  });
});
```

### Testing User Interactions

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { Counter } from './Counter';

describe('Counter', () => {
  it('increments count when plus button is clicked', async () => {
    const user = userEvent.setup();
    render(<Counter initialCount={0} />);

    expect(screen.getByText('Count: 0')).toBeInTheDocument();

    await user.click(screen.getByRole('button', { name: /increment/i }));

    expect(screen.getByText('Count: 1')).toBeInTheDocument();
  });

  it('decrements count when minus button is clicked', async () => {
    const user = userEvent.setup();
    render(<Counter initialCount={5} />);

    await user.click(screen.getByRole('button', { name: /decrement/i }));

    expect(screen.getByText('Count: 4')).toBeInTheDocument();
  });

  it('calls onChange when count changes', async () => {
    const user = userEvent.setup();
    const handleChange = vi.fn();
    render(<Counter initialCount={0} onChange={handleChange} />);

    await user.click(screen.getByRole('button', { name: /increment/i }));

    expect(handleChange).toHaveBeenCalledWith(1);
  });
});
```

### Testing Forms

```tsx
import { render, screen, waitFor } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { ContactForm } from './ContactForm';

describe('ContactForm', () => {
  it('submits form with entered data', async () => {
    const user = userEvent.setup();
    const handleSubmit = vi.fn();
    render(<ContactForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.type(screen.getByLabelText(/message/i), 'Hello world');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(handleSubmit).toHaveBeenCalledWith({
      name: 'John Doe',
      email: 'john@example.com',
      message: 'Hello world',
    });
  });

  it('shows validation errors for empty fields', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByText(/name is required/i)).toBeInTheDocument();
    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
  });

  it('shows error for invalid email', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    await user.type(screen.getByLabelText(/email/i), 'invalid-email');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
  });

  it('disables submit button while submitting', async () => {
    const user = userEvent.setup();
    const handleSubmit = vi.fn(() => new Promise((r) => setTimeout(r, 100)));
    render(<ContactForm onSubmit={handleSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    expect(screen.getByRole('button', { name: /submitting/i })).toBeDisabled();

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /submit/i })).toBeEnabled();
    });
  });
});
```

### Testing with Select and Radio

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { FilterForm } from './FilterForm';

describe('FilterForm', () => {
  it('selects option from dropdown', async () => {
    const user = userEvent.setup();
    render(<FilterForm />);

    await user.selectOptions(screen.getByLabelText(/category/i), 'electronics');

    expect(screen.getByRole('option', { name: /electronics/i })).toBeSelected();
  });

  it('selects radio option', async () => {
    const user = userEvent.setup();
    render(<FilterForm />);

    await user.click(screen.getByLabelText(/high to low/i));

    expect(screen.getByLabelText(/high to low/i)).toBeChecked();
  });

  it('toggles checkbox', async () => {
    const user = userEvent.setup();
    render(<FilterForm />);

    const checkbox = screen.getByLabelText(/in stock only/i);

    expect(checkbox).not.toBeChecked();

    await user.click(checkbox);
    expect(checkbox).toBeChecked();

    await user.click(checkbox);
    expect(checkbox).not.toBeChecked();
  });
});
```

## Async Testing Patterns

### Testing Loading States

```tsx
import { render, screen, waitFor } from '@/test/utils';
import { describe, it, expect, vi } from 'vitest';
import { UserList } from './UserList';

// Mock fetch
global.fetch = vi.fn();

describe('UserList', () => {
  it('shows loading state initially', () => {
    (fetch as any).mockImplementation(() => new Promise(() => {})); // Never resolves
    render(<UserList />);

    expect(screen.getByText(/loading/i)).toBeInTheDocument();
  });

  it('displays users after loading', async () => {
    (fetch as any).mockResolvedValueOnce({
      ok: true,
      json: () =>
        Promise.resolve([
          { id: '1', name: 'John' },
          { id: '2', name: 'Jane' },
        ]),
    });

    render(<UserList />);

    await waitFor(() => {
      expect(screen.getByText('John')).toBeInTheDocument();
      expect(screen.getByText('Jane')).toBeInTheDocument();
    });
  });

  it('shows error message on failure', async () => {
    (fetch as any).mockRejectedValueOnce(new Error('Network error'));

    render(<UserList />);

    await waitFor(() => {
      expect(screen.getByText(/error loading users/i)).toBeInTheDocument();
    });
  });
});
```

### Testing with waitFor

```tsx
import { render, screen, waitFor, waitForElementToBeRemoved } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { AsyncSearch } from './AsyncSearch';

describe('AsyncSearch', () => {
  it('shows results after typing', async () => {
    const user = userEvent.setup();
    render(<AsyncSearch />);

    await user.type(screen.getByRole('searchbox'), 'react');

    // Wait for loading to appear and disappear
    await waitFor(() => {
      expect(screen.getByText(/searching/i)).toBeInTheDocument();
    });

    await waitForElementToBeRemoved(() => screen.queryByText(/searching/i));

    expect(screen.getByText(/results for "react"/i)).toBeInTheDocument();
  });

  it('debounces search input', async () => {
    const user = userEvent.setup();
    const searchFn = vi.fn();
    render(<AsyncSearch onSearch={searchFn} />);

    // Type quickly
    await user.type(screen.getByRole('searchbox'), 'react');

    // Should only call once after debounce
    await waitFor(() => {
      expect(searchFn).toHaveBeenCalledTimes(1);
      expect(searchFn).toHaveBeenCalledWith('react');
    });
  });
});
```

### Testing with findBy Queries

```tsx
import { render, screen } from '@/test/utils';
import { describe, it, expect } from 'vitest';
import { Dashboard } from './Dashboard';

describe('Dashboard', () => {
  it('loads and displays data', async () => {
    render(<Dashboard />);

    // findBy* waits for element (combines waitFor + getBy)
    const greeting = await screen.findByText(/welcome, john/i);
    expect(greeting).toBeInTheDocument();

    // Multiple findBy calls
    const stats = await screen.findByTestId('stats-card');
    expect(stats).toBeInTheDocument();
  });

  it('handles findBy timeout', async () => {
    render(<Dashboard />);

    // Increase timeout for slow operations
    const element = await screen.findByText(/complex data/i, {}, { timeout: 5000 });
    expect(element).toBeInTheDocument();
  });
});
```

## Testing Custom Hooks

### Basic Hook Testing

```tsx
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useCounter } from './useCounter';

describe('useCounter', () => {
  it('returns initial count', () => {
    const { result } = renderHook(() => useCounter(5));

    expect(result.current.count).toBe(5);
  });

  it('increments count', () => {
    const { result } = renderHook(() => useCounter(0));

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('decrements count', () => {
    const { result } = renderHook(() => useCounter(5));

    act(() => {
      result.current.decrement();
    });

    expect(result.current.count).toBe(4);
  });

  it('resets count', () => {
    const { result } = renderHook(() => useCounter(10));

    act(() => {
      result.current.increment();
      result.current.increment();
      result.current.reset();
    });

    expect(result.current.count).toBe(10);
  });
});
```

### Testing Async Hooks

```tsx
import { renderHook, waitFor } from '@testing-library/react';
import { describe, it, expect, vi } from 'vitest';
import { useFetch } from './useFetch';

describe('useFetch', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('fetches data successfully', async () => {
    global.fetch = vi.fn().mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve({ name: 'John' }),
    });

    const { result } = renderHook(() => useFetch('/api/user'));

    expect(result.current.loading).toBe(true);

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toEqual({ name: 'John' });
    expect(result.current.error).toBeNull();
  });

  it('handles fetch error', async () => {
    global.fetch = vi.fn().mockRejectedValueOnce(new Error('Network error'));

    const { result } = renderHook(() => useFetch('/api/user'));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toBeNull();
    expect(result.current.error?.message).toBe('Network error');
  });

  it('refetches when url changes', async () => {
    global.fetch = vi.fn()
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ id: 1 }),
      })
      .mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ id: 2 }),
      });

    const { result, rerender } = renderHook(({ url }) => useFetch(url), {
      initialProps: { url: '/api/users/1' },
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({ id: 1 });
    });

    rerender({ url: '/api/users/2' });

    await waitFor(() => {
      expect(result.current.data).toEqual({ id: 2 });
    });

    expect(fetch).toHaveBeenCalledTimes(2);
  });
});
```

### Testing Hooks with Context

```tsx
import { renderHook } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useAuth } from './useAuth';
import { AuthProvider } from './AuthContext';

function wrapper({ children }: { children: React.ReactNode }) {
  return <AuthProvider>{children}</AuthProvider>;
}

describe('useAuth', () => {
  it('provides user from context', () => {
    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.user).toBeDefined();
  });

  it('throws when used outside provider', () => {
    // Suppress console.error for this test
    const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => {
      renderHook(() => useAuth());
    }).toThrow('useAuth must be used within AuthProvider');

    consoleSpy.mockRestore();
  });
});
```

## Mocking Patterns

### Mocking Modules

```tsx
import { vi } from 'vitest';

// Mock entire module
vi.mock('@/lib/api', () => ({
  fetchUsers: vi.fn(),
  createUser: vi.fn(),
}));

// Import after mocking
import { fetchUsers, createUser } from '@/lib/api';

describe('UserService', () => {
  it('calls fetchUsers', async () => {
    (fetchUsers as any).mockResolvedValueOnce([{ id: 1, name: 'John' }]);

    const users = await fetchUsers();
    expect(users).toHaveLength(1);
  });
});
```

### Mocking External Libraries

```tsx
// Mock react-router-dom
vi.mock('react-router-dom', async () => {
  const actual = await vi.importActual('react-router-dom');
  return {
    ...actual,
    useNavigate: () => vi.fn(),
    useParams: () => ({ id: '123' }),
  };
});

// Mock date-fns
vi.mock('date-fns', () => ({
  format: vi.fn((date) => '2024-01-01'),
  parseISO: vi.fn((str) => new Date(str)),
}));
```

### Mocking Timers

```tsx
import { render, screen, act } from '@/test/utils';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { CountdownTimer } from './CountdownTimer';

describe('CountdownTimer', () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('counts down every second', () => {
    render(<CountdownTimer seconds={5} />);

    expect(screen.getByText('5')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(1000);
    });
    expect(screen.getByText('4')).toBeInTheDocument();

    act(() => {
      vi.advanceTimersByTime(2000);
    });
    expect(screen.getByText('2')).toBeInTheDocument();
  });

  it('calls onComplete when finished', () => {
    const handleComplete = vi.fn();
    render(<CountdownTimer seconds={3} onComplete={handleComplete} />);

    act(() => {
      vi.advanceTimersByTime(3000);
    });

    expect(handleComplete).toHaveBeenCalled();
  });
});
```

### Mocking API with MSW

```tsx
// src/test/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/users', () => {
    return HttpResponse.json([
      { id: 1, name: 'John' },
      { id: 2, name: 'Jane' },
    ]);
  }),

  http.post('/api/users', async ({ request }) => {
    const body = await request.json();
    return HttpResponse.json({ id: 3, ...body }, { status: 201 });
  }),

  http.delete('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ deleted: params.id });
  }),
];

// src/test/mocks/server.ts
import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);

// src/test/setup.ts
import { server } from './mocks/server';

beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

// In tests - override handlers
import { server } from '@/test/mocks/server';
import { http, HttpResponse } from 'msw';

it('handles error response', async () => {
  server.use(
    http.get('/api/users', () => {
      return new HttpResponse(null, { status: 500 });
    })
  );

  render(<UserList />);
  expect(await screen.findByText(/error/i)).toBeInTheDocument();
});
```

## Accessibility Testing

### Basic A11y Tests

```tsx
import { render, screen } from '@/test/utils';
import { describe, it, expect } from 'vitest';
import { axe, toHaveNoViolations } from 'jest-axe';
import { ContactForm } from './ContactForm';

expect.extend(toHaveNoViolations);

describe('ContactForm accessibility', () => {
  it('has no accessibility violations', async () => {
    const { container } = render(<ContactForm onSubmit={vi.fn()} />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('has proper form labels', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    expect(screen.getByLabelText(/name/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/message/i)).toBeInTheDocument();
  });

  it('has accessible button', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    const button = screen.getByRole('button', { name: /submit/i });
    expect(button).toBeInTheDocument();
    expect(button).toHaveAttribute('type', 'submit');
  });

  it('marks required fields', () => {
    render(<ContactForm onSubmit={vi.fn()} />);

    expect(screen.getByLabelText(/name/i)).toBeRequired();
    expect(screen.getByLabelText(/email/i)).toBeRequired();
  });

  it('associates error messages with inputs', async () => {
    const user = userEvent.setup();
    render(<ContactForm onSubmit={vi.fn()} />);

    await user.click(screen.getByRole('button', { name: /submit/i }));

    const emailInput = screen.getByLabelText(/email/i);
    const errorId = emailInput.getAttribute('aria-describedby');

    expect(errorId).toBeTruthy();
    expect(document.getElementById(errorId!)).toHaveTextContent(/required/i);
  });
});
```

### Testing Keyboard Navigation

```tsx
import { render, screen } from '@/test/utils';
import userEvent from '@testing-library/user-event';
import { describe, it, expect } from 'vitest';
import { Modal } from './Modal';

describe('Modal keyboard navigation', () => {
  it('traps focus within modal', async () => {
    const user = userEvent.setup();
    render(
      <Modal isOpen onClose={vi.fn()}>
        <button>First</button>
        <button>Second</button>
        <button>Close</button>
      </Modal>
    );

    const firstButton = screen.getByRole('button', { name: /first/i });
    const closeButton = screen.getByRole('button', { name: /close/i });

    expect(firstButton).toHaveFocus();

    // Tab through all buttons
    await user.tab();
    expect(screen.getByRole('button', { name: /second/i })).toHaveFocus();

    await user.tab();
    expect(closeButton).toHaveFocus();

    // Tab should wrap to first
    await user.tab();
    expect(firstButton).toHaveFocus();
  });

  it('closes on Escape key', async () => {
    const user = userEvent.setup();
    const handleClose = vi.fn();
    render(
      <Modal isOpen onClose={handleClose}>
        Content
      </Modal>
    );

    await user.keyboard('{Escape}');

    expect(handleClose).toHaveBeenCalled();
  });
});
```
