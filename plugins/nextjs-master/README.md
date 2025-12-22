# Next.js Master Plugin

Comprehensive Next.js 15 plugin for Claude Code, covering App Router, Server Components, Server Actions, caching, middleware, authentication, and deployment.

## Features

### Skills
- **App Router Fundamentals** - Layouts, pages, loading, error handling, parallel routes
- **Data Fetching** - Server Components, streaming, Suspense, incremental adoption
- **Server Actions** - Form handling, mutations, validation, optimistic updates
- **Caching** - Request memoization, data cache, full route cache, revalidation
- **Middleware** - Authentication, redirects, rewrites, headers, geolocation
- **Advanced Routing** - Dynamic routes, parallel routes, intercepting routes, route groups
- **Authentication** - NextAuth.js, session management, protected routes
- **Deployment** - Vercel, self-hosting, Docker, edge runtime

### Commands
- `/nextjs-page` - Generate a new Next.js page with proper structure
- `/nextjs-api-route` - Create a Route Handler with proper HTTP methods
- `/nextjs-server-action` - Create a Server Action with validation
- `/nextjs-middleware` - Set up middleware with common patterns

### Agent
- **Next.js Expert** - Specialized agent for Next.js architecture and implementation

## Quick Reference

### App Router Structure
```
app/
├── layout.tsx          # Root layout (required)
├── page.tsx            # Home page
├── loading.tsx         # Loading UI
├── error.tsx           # Error UI
├── not-found.tsx       # 404 page
├── dashboard/
│   ├── layout.tsx      # Dashboard layout
│   ├── page.tsx        # /dashboard
│   └── settings/
│       └── page.tsx    # /dashboard/settings
├── blog/
│   ├── page.tsx        # /blog
│   └── [slug]/
│       └── page.tsx    # /blog/:slug
└── api/
    └── users/
        └── route.ts    # /api/users
```

### Key Concepts

#### Server Components (Default)
```tsx
// app/posts/page.tsx - Server Component
async function PostsPage() {
  const posts = await db.posts.findMany();
  return <PostList posts={posts} />;
}
```

#### Client Components
```tsx
'use client';

import { useState } from 'react';

export function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

#### Server Actions
```tsx
// actions.ts
'use server';

export async function createPost(formData: FormData) {
  await db.posts.create({ data: { title: formData.get('title') } });
  revalidatePath('/posts');
}
```

#### Data Fetching with Caching
```tsx
// Cached by default
const data = await fetch('https://api.example.com/data');

// Opt out of caching
const data = await fetch(url, { cache: 'no-store' });

// Revalidate every 60 seconds
const data = await fetch(url, { next: { revalidate: 60 } });
```

## Installation

```bash
# Using Claude Code CLI
claude plugins add nextjs-master

# Or manually copy to your plugins directory
```

## Usage

The plugin automatically activates when working with Next.js projects (detected via `next.config.*` or App Router file patterns).

### Example Prompts
- "Create a new dashboard page with authentication"
- "Add a server action for form submission"
- "Set up middleware for protected routes"
- "Implement ISR for blog posts"

## Compatibility

- Next.js 13.4+ (App Router)
- Next.js 14.x (recommended)
- Next.js 15.x (full support)
- React 18+
- TypeScript 5+

## License

MIT
