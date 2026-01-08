---
name: react-component
description: Create a new React component following best practices for React 19
argument-hint: "ComponentName [with props: prop1, prop2] [--client] [--server]"
---

# Generate React Component

Create a new React component following best practices for React 19.

## Arguments
- `$ARGUMENTS` - Component name and optional specifications (e.g., "UserCard with props for name, email, avatar" or "ProductList --client")

## Instructions

Create a React component based on the provided name and specifications:

1. **Analyze Requirements**
   - Parse component name from `$ARGUMENTS`
   - Identify required props and their types
   - Determine if it should be a Server or Client Component:
     - `--client` flag: Force Client Component
     - `--server` flag: Force Server Component
     - No flag: Auto-detect based on needs
   - Check for existing patterns in the codebase

2. **Component Structure**
   - Use function component syntax
   - Add proper TypeScript interface for props
   - Include 'use client' directive only if needed (useState, useEffect, event handlers)
   - Follow project naming conventions

3. **Implementation Checklist**
   - [ ] Proper prop types with TypeScript
   - [ ] Destructured props with defaults where appropriate
   - [ ] Proper accessibility attributes (aria-*, role, etc.)
   - [ ] Error boundaries if needed
   - [ ] Loading/error states if applicable
   - [ ] Proper key usage for lists

4. **File Location**
   - Check project structure for component directories
   - Place in appropriate folder (components/, features/, etc.)
   - Use consistent file naming (PascalCase.tsx)

## Example Output

```tsx
// components/UserCard.tsx
interface UserCardProps {
  name: string;
  email: string;
  avatar?: string;
  onEdit?: (id: string) => void;
}

export function UserCard({ name, email, avatar, onEdit }: UserCardProps) {
  return (
    <article className="user-card">
      {avatar && <img src={avatar} alt={`${name}'s avatar`} />}
      <h3>{name}</h3>
      <p>{email}</p>
      {onEdit && (
        <button onClick={() => onEdit(email)} aria-label={`Edit ${name}`}>
          Edit
        </button>
      )}
    </article>
  );
}
```

## Client Component Example

```tsx
// components/Counter.tsx
'use client';

import { useState } from 'react';

interface CounterProps {
  initialCount?: number;
  step?: number;
  onChange?: (count: number) => void;
}

export function Counter({ initialCount = 0, step = 1, onChange }: CounterProps) {
  const [count, setCount] = useState(initialCount);

  const handleIncrement = () => {
    const newCount = count + step;
    setCount(newCount);
    onChange?.(newCount);
  };

  return (
    <div className="counter">
      <span aria-live="polite">{count}</span>
      <button onClick={handleIncrement} aria-label="Increment count">
        +{step}
      </button>
    </div>
  );
}
```

## When to Use 'use client'

Only add 'use client' when the component:
- Uses hooks like useState, useEffect, useRef
- Has event handlers (onClick, onChange, etc.)
- Uses browser-only APIs (window, document, localStorage)
- Needs to be interactive

Server Components (no 'use client') when:
- Only displaying data
- Fetching data directly
- No interactivity needed
- Rendering static content
