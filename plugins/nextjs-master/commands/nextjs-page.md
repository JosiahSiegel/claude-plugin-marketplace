---
description: Create a new Next.js App Router page with proper structure
argument-hint: "Page path (e.g., 'dashboard/settings', 'posts/[slug]', 'products/[[...category]]')"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Generate Next.js Page

Create a new Next.js App Router page with proper structure.

## Arguments
- `$ARGUMENTS` - Page path and optional specifications (e.g., "dashboard/settings with user data fetching")

## Instructions

Create a Next.js page based on the provided path and specifications:

1. **Analyze Requirements**
   - Parse page path from `$ARGUMENTS`
   - Determine if page needs data fetching
   - Check if it requires dynamic routing ([slug], [...slug], [[...slug]])
   - Identify if page should be static or dynamic

2. **File Structure**
   - Create page.tsx in correct directory
   - Add loading.tsx for loading state
   - Add error.tsx for error handling
   - Consider layout.tsx if needed

3. **Component Type**
   - Default to Server Component (no 'use client')
   - Add 'use client' only if interactive
   - Use async function for data fetching

4. **Implementation Checklist**
   - [ ] Proper TypeScript types for params/searchParams (Promise in Next.js 16)
   - [ ] generateMetadata for SEO
   - [ ] generateStaticParams if applicable
   - [ ] Loading and error states
   - [ ] Proper data fetching pattern

## Example Output

### Static Page
```tsx
// app/about/page.tsx
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'About Us',
  description: 'Learn more about our company',
};

export default function AboutPage() {
  return (
    <div>
      <h1>About Us</h1>
      <p>Content here...</p>
    </div>
  );
}
```

### Dynamic Page with Data Fetching (Next.js 16)
```tsx
// app/posts/[slug]/page.tsx
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';

interface PageProps {
  params: Promise<{ slug: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { slug } = await params;
  const post = await getPost(slug);

  return {
    title: post?.title || 'Post Not Found',
    description: post?.excerpt,
  };
}

export async function generateStaticParams() {
  const posts = await getPosts();
  return posts.map((post) => ({ slug: post.slug }));
}

export default async function PostPage({ params, searchParams }: PageProps) {
  const { slug } = await params;
  const { page } = await searchParams;

  const post = await getPost(slug);

  if (!post) {
    notFound();
  }

  return (
    <article>
      <h1>{post.title}</h1>
      <div dangerouslySetInnerHTML={{ __html: post.content }} />
    </article>
  );
}
```

### Loading State
```tsx
// app/posts/[slug]/loading.tsx
export default function Loading() {
  return (
    <div className="animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-3/4 mb-4" />
      <div className="h-4 bg-gray-200 rounded w-full mb-2" />
      <div className="h-4 bg-gray-200 rounded w-5/6" />
    </div>
  );
}
```

### Error Boundary
```tsx
// app/posts/[slug]/error.tsx
'use client';

export default function Error({
  error,
  reset,
}: {
  error: Error;
  reset: () => void;
}) {
  return (
    <div>
      <h2>Something went wrong!</h2>
      <button onClick={() => reset()}>Try again</button>
    </div>
  );
}
```

### Cached Page with use cache (Next.js 16)
```tsx
// app/products/page.tsx
'use cache'

import { cacheLife, cacheTag } from 'next/cache';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Products',
  description: 'Browse our products',
};

export default async function ProductsPage() {
  cacheLife('hours');
  cacheTag('products');

  const products = await db.products.findMany({
    orderBy: { createdAt: 'desc' },
  });

  return (
    <div>
      <h1>Products</h1>
      <ProductGrid products={products} />
    </div>
  );
}
```
