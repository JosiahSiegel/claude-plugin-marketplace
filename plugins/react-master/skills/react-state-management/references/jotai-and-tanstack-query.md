# React State Management: Jotai and TanStack Query

Detailed patterns for Jotai atom-based state management and TanStack Query (React Query) server-state management: atoms, derived atoms, async atoms, query clients, mutations, invalidation, optimistic updates, and cache tuning. SKILL.md keeps built-in state, Context API, Zustand, SWR, and best-practice selection guidance.

## Jotai

### Basic Jotai Atoms

```tsx
import { atom, useAtom, useAtomValue, useSetAtom } from 'jotai';
import { atomWithStorage } from 'jotai/utils';

// Primitive atoms
const countAtom = atom(0);
const textAtom = atom('');

// Derived atom (computed value)
const doubleCountAtom = atom((get) => get(countAtom) * 2);

// Writable derived atom
const uppercaseTextAtom = atom(
  (get) => get(textAtom).toUpperCase(),
  (get, set, newValue: string) => set(textAtom, newValue.toLowerCase())
);

// Async atom
const userAtom = atom(async () => {
  const response = await fetch('/api/user');
  return response.json();
});

// Persisted atom
const themeAtom = atomWithStorage<'light' | 'dark'>('theme', 'light');

// Usage
function Counter() {
  const [count, setCount] = useAtom(countAtom);
  const doubleCount = useAtomValue(doubleCountAtom);

  return (
    <div>
      <p>Count: {count}</p>
      <p>Double: {doubleCount}</p>
      <button onClick={() => setCount((c) => c + 1)}>Increment</button>
    </div>
  );
}
```

### Jotai with Async Actions

```tsx
import { atom, useAtom } from 'jotai';
import { atomWithQuery, atomWithMutation } from 'jotai-tanstack-query';

// Query atom
const postsAtom = atomWithQuery(() => ({
  queryKey: ['posts'],
  queryFn: async () => {
    const res = await fetch('/api/posts');
    return res.json();
  },
}));

// Mutation atom
const createPostAtom = atomWithMutation(() => ({
  mutationFn: async (newPost: { title: string; content: string }) => {
    const res = await fetch('/api/posts', {
      method: 'POST',
      body: JSON.stringify(newPost),
    });
    return res.json();
  },
}));

function Posts() {
  const [{ data: posts, isLoading }] = useAtom(postsAtom);
  const [{ mutate: createPost, isPending }] = useAtom(createPostAtom);

  if (isLoading) return <p>Loading...</p>;

  return (
    <div>
      {posts.map((post) => (
        <article key={post.id}>{post.title}</article>
      ))}
      <button onClick={() => createPost({ title: 'New', content: 'Content' })}>
        {isPending ? 'Creating...' : 'Add Post'}
      </button>
    </div>
  );
}
```

## TanStack Query (React Query)

### Basic Queries

```tsx
import { useQuery, useMutation, useQueryClient, QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Query client setup
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
      gcTime: 1000 * 60 * 30, // 30 minutes
      retry: 3,
      refetchOnWindowFocus: true,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Posts />
    </QueryClientProvider>
  );
}

// Fetching data
function Posts() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['posts'],
    queryFn: async () => {
      const res = await fetch('/api/posts');
      if (!res.ok) throw new Error('Failed to fetch');
      return res.json();
    },
  });

  if (isLoading) return <Spinner />;
  if (error) return <ErrorMessage error={error} />;

  return (
    <div>
      {data.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
      <button onClick={() => refetch()}>Refresh</button>
    </div>
  );
}
```

### Mutations with Optimistic Updates

```tsx
function useCreatePost() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (newPost: CreatePostInput) => {
      const res = await fetch('/api/posts', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(newPost),
      });
      if (!res.ok) throw new Error('Failed to create post');
      return res.json();
    },
    onMutate: async (newPost) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ['posts'] });

      // Snapshot previous value
      const previousPosts = queryClient.getQueryData(['posts']);

      // Optimistically update
      queryClient.setQueryData(['posts'], (old: Post[]) => [
        { ...newPost, id: 'temp-id', createdAt: new Date() },
        ...old,
      ]);

      return { previousPosts };
    },
    onError: (err, newPost, context) => {
      // Rollback on error
      queryClient.setQueryData(['posts'], context?.previousPosts);
    },
    onSettled: () => {
      // Refetch after mutation
      queryClient.invalidateQueries({ queryKey: ['posts'] });
    },
  });
}

function CreatePostForm() {
  const createPost = useCreatePost();

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const formData = new FormData(e.currentTarget);
    createPost.mutate({
      title: formData.get('title') as string,
      content: formData.get('content') as string,
    });
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="title" required />
      <textarea name="content" required />
      <button type="submit" disabled={createPost.isPending}>
        {createPost.isPending ? 'Creating...' : 'Create Post'}
      </button>
    </form>
  );
}
```

### Infinite Queries

```tsx
import { useInfiniteQuery } from '@tanstack/react-query';

function InfinitePosts() {
  const {
    data,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isLoading,
  } = useInfiniteQuery({
    queryKey: ['posts', 'infinite'],
    queryFn: async ({ pageParam = 0 }) => {
      const res = await fetch(`/api/posts?cursor=${pageParam}&limit=10`);
      return res.json();
    },
    getNextPageParam: (lastPage) => lastPage.nextCursor,
    initialPageParam: 0,
  });

  if (isLoading) return <Spinner />;

  return (
    <div>
      {data?.pages.map((page, i) => (
        <Fragment key={i}>
          {page.posts.map((post) => (
            <PostCard key={post.id} post={post} />
          ))}
        </Fragment>
      ))}

      <button
        onClick={() => fetchNextPage()}
        disabled={!hasNextPage || isFetchingNextPage}
      >
        {isFetchingNextPage
          ? 'Loading more...'
          : hasNextPage
          ? 'Load More'
          : 'No more posts'}
      </button>
    </div>
  );
}
```

