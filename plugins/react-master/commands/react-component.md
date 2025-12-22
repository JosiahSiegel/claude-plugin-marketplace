# Generate React Component

Create a new React component following best practices for React 19.

## Arguments
- `$ARGUMENTS` - Component name and optional specifications (e.g., "UserCard with props for name, email, avatar")

## Instructions

Create a React component based on the provided name and specifications:

1. **Analyze Requirements**
   - Parse component name from `$ARGUMENTS`
   - Identify required props and their types
   - Determine if it should be a Server or Client Component
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

## When to Use 'use client'

Only add 'use client' when the component:
- Uses hooks like useState, useEffect, useRef
- Has event handlers (onClick, onChange, etc.)
- Uses browser-only APIs
- Needs to be interactive

Server Components (no 'use client') when:
- Only displaying data
- Fetching data directly
- No interactivity needed
