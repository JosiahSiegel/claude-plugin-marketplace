---
description: Create a Next.js Server Action with validation and proper error handling
argument-hint: "Action name and purpose (e.g., 'createPost with validation', 'deleteUser with auth')"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Generate Next.js Server Action

Create a Server Action with validation and proper error handling.

## Arguments
- `$ARGUMENTS` - Action name and description (e.g., "createPost with title and content validation")

## Instructions

Create a Server Action based on the provided specifications:

1. **Analyze Requirements**
   - Parse action name from `$ARGUMENTS`
   - Identify required input fields
   - Determine validation requirements
   - Check if revalidation is needed

2. **Implementation**
   - Create in actions.ts or separate file
   - Add 'use server' directive
   - Implement Zod validation
   - Handle errors properly

3. **Features to Include**
   - Input validation with Zod
   - Type-safe return values
   - Proper error handling
   - Cache revalidation
   - Redirect if needed

## Example Output

### Basic Server Action
```tsx
// app/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { z } from 'zod';

const CreatePostSchema = z.object({
  title: z.string().min(1, 'Title is required').max(200, 'Title too long'),
  content: z.string().min(1, 'Content is required'),
  published: z.boolean().default(false),
});

export type CreatePostState = {
  errors?: {
    title?: string[];
    content?: string[];
    published?: string[];
  };
  message?: string;
  success?: boolean;
};

export async function createPost(
  prevState: CreatePostState,
  formData: FormData
): Promise<CreatePostState> {
  // Validate input
  const validatedFields = CreatePostSchema.safeParse({
    title: formData.get('title'),
    content: formData.get('content'),
    published: formData.get('published') === 'true',
  });

  if (!validatedFields.success) {
    return {
      errors: validatedFields.error.flatten().fieldErrors,
      message: 'Validation failed',
    };
  }

  try {
    // Create post in database
    await db.posts.create({
      data: validatedFields.data,
    });
  } catch (error) {
    return {
      message: 'Database error: Failed to create post',
    };
  }

  // Revalidate and redirect
  revalidatePath('/posts');
  redirect('/posts');
}
```

### Type-Safe Action with next-safe-action (Recommended 2025+)
```tsx
// lib/safe-action.ts
import { createSafeActionClient } from 'next-safe-action';
import { auth } from '@/auth';

export const actionClient = createSafeActionClient({
  handleServerError: (e) => {
    console.error('Action error:', e);
    return 'Something went wrong';
  },
});

export const authActionClient = actionClient.use(async ({ next }) => {
  const session = await auth();
  if (!session?.user) {
    throw new Error('Unauthorized');
  }
  return next({ ctx: { user: session.user } });
});
```

```tsx
// app/posts/actions.ts
'use server';

import { z } from 'zod';
import { authActionClient } from '@/lib/safe-action';
import { revalidatePath } from 'next/cache';

const createPostSchema = z.object({
  title: z.string().min(1, 'Title required').max(200),
  content: z.string().min(1, 'Content required'),
  published: z.boolean().default(false),
});

export const createPost = authActionClient
  .schema(createPostSchema)
  .action(async ({ parsedInput, ctx }) => {
    const { title, content, published } = parsedInput;
    const { user } = ctx;

    const post = await db.posts.create({
      data: {
        title,
        content,
        published,
        authorId: user.id,
      },
    });

    revalidatePath('/posts');
    return { success: true, postId: post.id };
  });
```

### Action with Authentication
```tsx
// app/actions.ts
'use server';

import { auth } from '@/auth';
import { revalidateTag } from 'next/cache';

export async function deletePost(postId: string) {
  const session = await auth();

  if (!session) {
    return { error: 'Not authenticated' };
  }

  const post = await db.posts.findUnique({
    where: { id: postId },
  });

  if (!post) {
    return { error: 'Post not found' };
  }

  if (post.authorId !== session.user.id && session.user.role !== 'admin') {
    return { error: 'Not authorized' };
  }

  try {
    await db.posts.delete({ where: { id: postId } });
    revalidateTag('posts');
    return { success: true };
  } catch (error) {
    return { error: 'Failed to delete post' };
  }
}
```

### Action with Bound Arguments
```tsx
// app/actions.ts
'use server';

export async function updatePostStatus(
  postId: string,
  status: 'draft' | 'published',
  formData: FormData
) {
  await db.posts.update({
    where: { id: postId },
    data: { status },
  });

  revalidatePath(`/posts/${postId}`);
  return { success: true };
}
```

```tsx
// components/PublishButton.tsx
'use client';

import { updatePostStatus } from '@/app/actions';

export function PublishButton({ postId }: { postId: string }) {
  const publishPost = updatePostStatus.bind(null, postId, 'published');

  return (
    <form action={publishPost}>
      <button type="submit">Publish</button>
    </form>
  );
}
```

### Using the Action in a Form
```tsx
// app/posts/new/page.tsx
'use client';

import { useActionState } from 'react';
import { createPost, CreatePostState } from '@/app/actions';

const initialState: CreatePostState = {};

export default function NewPostPage() {
  const [state, formAction, isPending] = useActionState(createPost, initialState);

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="title">Title</label>
        <input id="title" name="title" required />
        {state.errors?.title && (
          <p className="error">{state.errors.title[0]}</p>
        )}
      </div>

      <div>
        <label htmlFor="content">Content</label>
        <textarea id="content" name="content" required />
        {state.errors?.content && (
          <p className="error">{state.errors.content[0]}</p>
        )}
      </div>

      {state.message && <p className="message">{state.message}</p>}

      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

### Using with next-safe-action Hook
```tsx
// components/CreatePostForm.tsx
'use client';

import { useAction } from 'next-safe-action/hooks';
import { createPost } from '@/app/posts/actions';

export function CreatePostForm() {
  const { execute, result, isExecuting } = useAction(createPost, {
    onSuccess: ({ data }) => {
      toast.success(`Post created: ${data?.postId}`);
    },
    onError: ({ error }) => {
      toast.error(error.serverError || 'Failed to create post');
    },
  });

  return (
    <form action={(formData) => {
      execute({
        title: formData.get('title') as string,
        content: formData.get('content') as string,
        published: formData.get('published') === 'on',
      });
    }}>
      <input name="title" required />
      {result.validationErrors?.title && (
        <span className="error">{result.validationErrors.title[0]}</span>
      )}

      <textarea name="content" required />

      <button type="submit" disabled={isExecuting}>
        {isExecuting ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```
