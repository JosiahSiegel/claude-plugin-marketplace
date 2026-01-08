---
name: react-test
description: Create comprehensive tests for a React component using React Testing Library
argument-hint: "ComponentName or path/to/Component.tsx"
---

# Generate React Component Tests

Create comprehensive tests for a React component using React Testing Library.

## Arguments
- `$ARGUMENTS` - Component name or file path to test (e.g., "UserCard" or "src/components/UserCard.tsx")

## Instructions

Generate tests for the specified React component:

1. **Analyze Component**
   - Read the component file specified in `$ARGUMENTS`
   - Identify all props and their types
   - Find all interactive elements (buttons, inputs, links)
   - Identify conditional rendering logic
   - Check for async operations or side effects

2. **Test Categories to Cover**
   - Rendering tests (component renders without errors)
   - Props tests (handles different prop values correctly)
   - Interaction tests (clicks, typing, form submission)
   - Accessibility tests (roles, labels, keyboard navigation)
   - Edge cases (empty states, error states, loading states)

3. **Implementation Checklist**
   - [ ] Import component and testing utilities
   - [ ] Set up necessary providers/mocks
   - [ ] Test default render
   - [ ] Test all prop variations
   - [ ] Test user interactions
   - [ ] Test accessibility
   - [ ] Test error handling

4. **File Location**
   - Place test file next to component: `Component.test.tsx`
   - Or in __tests__ folder: `__tests__/Component.test.tsx`

## Example Output

```tsx
// components/UserCard.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { describe, it, expect, vi } from 'vitest';
import { UserCard } from './UserCard';

describe('UserCard', () => {
  const defaultProps = {
    name: 'John Doe',
    email: 'john@example.com',
  };

  it('renders user name and email', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.getByText('John Doe')).toBeInTheDocument();
    expect(screen.getByText('john@example.com')).toBeInTheDocument();
  });

  it('renders avatar when provided', () => {
    render(<UserCard {...defaultProps} avatar="/avatar.jpg" />);

    const avatar = screen.getByRole('img', { name: /john doe's avatar/i });
    expect(avatar).toHaveAttribute('src', '/avatar.jpg');
  });

  it('does not render avatar when not provided', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.queryByRole('img')).not.toBeInTheDocument();
  });

  it('calls onEdit when edit button is clicked', async () => {
    const user = userEvent.setup();
    const handleEdit = vi.fn();

    render(<UserCard {...defaultProps} onEdit={handleEdit} />);

    await user.click(screen.getByRole('button', { name: /edit john doe/i }));

    expect(handleEdit).toHaveBeenCalledWith('john@example.com');
  });

  it('does not render edit button when onEdit is not provided', () => {
    render(<UserCard {...defaultProps} />);

    expect(screen.queryByRole('button')).not.toBeInTheDocument();
  });
});
```

## Testing Patterns

### Testing with Providers
```tsx
function renderWithProviders(ui: React.ReactElement) {
  return render(
    <QueryClientProvider client={new QueryClient()}>
      <ThemeProvider>
        {ui}
      </ThemeProvider>
    </QueryClientProvider>
  );
}
```

### Testing Async Components
```tsx
it('loads and displays data', async () => {
  render(<UserList />);

  expect(screen.getByText('Loading...')).toBeInTheDocument();

  await waitFor(() => {
    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });
});
```

### Testing Forms
```tsx
it('submits form with entered data', async () => {
  const user = userEvent.setup();
  const handleSubmit = vi.fn();

  render(<ContactForm onSubmit={handleSubmit} />);

  await user.type(screen.getByLabelText('Name'), 'John');
  await user.type(screen.getByLabelText('Email'), 'john@example.com');
  await user.click(screen.getByRole('button', { name: /submit/i }));

  expect(handleSubmit).toHaveBeenCalledWith({
    name: 'John',
    email: 'john@example.com',
  });
});
```

### Testing Custom Hooks
```tsx
import { renderHook, act } from '@testing-library/react';

it('increments counter', () => {
  const { result } = renderHook(() => useCounter());

  act(() => {
    result.current.increment();
  });

  expect(result.current.count).toBe(1);
});
```

## Query Priority (Best Practices)

1. **Accessible queries (preferred)**
   - `getByRole` - Most semantic
   - `getByLabelText` - Form elements
   - `getByPlaceholderText` - Input placeholders
   - `getByText` - Non-interactive elements
   - `getByDisplayValue` - Current input value

2. **Semantic queries**
   - `getByAltText` - Images
   - `getByTitle` - Title attribute

3. **Test IDs (last resort)**
   - `getByTestId` - When no semantic option exists

## Mocking Best Practices

```tsx
// Mock fetch
global.fetch = vi.fn().mockResolvedValue({
  ok: true,
  json: () => Promise.resolve({ data: 'test' }),
});

// Mock modules
vi.mock('@/lib/api', () => ({
  fetchUsers: vi.fn(),
}));

// Mock router
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn() }),
  useParams: () => ({ id: '123' }),
}));
```
