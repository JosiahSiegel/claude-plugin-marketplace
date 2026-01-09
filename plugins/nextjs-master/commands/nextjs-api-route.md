---
description: Create a Next.js Route Handler with proper HTTP methods and error handling
argument-hint: "API route path and methods (e.g., 'posts with GET,POST', 'users/[id] with CRUD')"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Generate Next.js API Route

Create a Next.js Route Handler with proper HTTP methods and error handling.

## Arguments
- `$ARGUMENTS` - API route path and methods (e.g., "posts with GET, POST, PUT, DELETE")

## Instructions

Create a Route Handler based on the provided path and methods:

1. **Analyze Requirements**
   - Parse route path from `$ARGUMENTS`
   - Identify required HTTP methods
   - Determine if route is dynamic ([id], [slug])
   - Check if authentication is needed

2. **Implementation**
   - Create route.ts in app/api directory
   - Implement requested HTTP methods
   - Add proper TypeScript types
   - Include error handling

3. **Best Practices**
   - Validate input data
   - Return appropriate status codes
   - Handle errors gracefully
   - Add proper headers when needed

## Example Output

### Basic CRUD Route Handler
```tsx
// app/api/posts/route.ts
import { NextResponse } from 'next/server';
import { z } from 'zod';

const PostSchema = z.object({
  title: z.string().min(1).max(200),
  content: z.string().min(1),
  published: z.boolean().optional(),
});

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');

    const posts = await db.posts.findMany({
      skip: (page - 1) * limit,
      take: limit,
      orderBy: { createdAt: 'desc' },
    });

    const total = await db.posts.count();

    return NextResponse.json({
      data: posts,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error('GET /api/posts error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch posts' },
      { status: 500 }
    );
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const validatedData = PostSchema.parse(body);

    const post = await db.posts.create({
      data: validatedData,
    });

    return NextResponse.json(post, { status: 201 });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: 'Validation failed', details: error.errors },
        { status: 400 }
      );
    }

    console.error('POST /api/posts error:', error);
    return NextResponse.json(
      { error: 'Failed to create post' },
      { status: 500 }
    );
  }
}
```

### Dynamic Route Handler (Next.js 16 - Async Params)
```tsx
// app/api/posts/[id]/route.ts
import { NextResponse } from 'next/server';

interface RouteContext {
  params: Promise<{ id: string }>;
}

export async function GET(request: Request, context: RouteContext) {
  try {
    const { id } = await context.params;

    const post = await db.posts.findUnique({
      where: { id },
    });

    if (!post) {
      return NextResponse.json(
        { error: 'Post not found' },
        { status: 404 }
      );
    }

    return NextResponse.json(post);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch post' },
      { status: 500 }
    );
  }
}

export async function PUT(request: Request, context: RouteContext) {
  try {
    const { id } = await context.params;
    const body = await request.json();

    const post = await db.posts.update({
      where: { id },
      data: body,
    });

    return NextResponse.json(post);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update post' },
      { status: 500 }
    );
  }
}

export async function DELETE(request: Request, context: RouteContext) {
  try {
    const { id } = await context.params;

    await db.posts.delete({
      where: { id },
    });

    return new NextResponse(null, { status: 204 });
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to delete post' },
      { status: 500 }
    );
  }
}
```

### Authenticated Route
```tsx
// app/api/user/route.ts
import { NextResponse } from 'next/server';
import { auth } from '@/auth';

export async function GET() {
  const session = await auth();

  if (!session) {
    return NextResponse.json(
      { error: 'Unauthorized' },
      { status: 401 }
    );
  }

  const user = await db.users.findUnique({
    where: { id: session.user.id },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
    },
  });

  return NextResponse.json(user);
}
```

### Streaming Response
```tsx
// app/api/stream/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 0; i < 10; i++) {
        const data = JSON.stringify({ count: i, timestamp: Date.now() });
        controller.enqueue(encoder.encode(`data: ${data}\n\n`));
        await new Promise(resolve => setTimeout(resolve, 1000));
      }
      controller.close();
    },
  });

  return new NextResponse(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}
```

### Route with Cache Headers
```tsx
// app/api/products/route.ts
import { NextResponse } from 'next/server';

export async function GET() {
  const products = await db.products.findMany();

  return NextResponse.json(products, {
    headers: {
      'Cache-Control': 'public, s-maxage=60, stale-while-revalidate=300',
    },
  });
}
```

### File Upload Route
```tsx
// app/api/upload/route.ts
import { NextResponse } from 'next/server';
import { writeFile } from 'fs/promises';
import { join } from 'path';

export async function POST(request: Request) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;

    if (!file) {
      return NextResponse.json(
        { error: 'No file provided' },
        { status: 400 }
      );
    }

    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);

    const filename = `${Date.now()}-${file.name}`;
    const path = join(process.cwd(), 'public/uploads', filename);

    await writeFile(path, buffer);

    return NextResponse.json({
      url: `/uploads/${filename}`,
      filename,
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Upload failed' },
      { status: 500 }
    );
  }
}

export const config = {
  api: {
    bodyParser: false,
  },
};
```
