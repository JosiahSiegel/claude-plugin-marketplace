# React Hooks: Performance Hooks and React 19 Hooks

Detailed coverage of `useMemo`, `useCallback`, `useTransition`, `useDeferredValue`, and React 19-era hooks such as `useActionState`, `useOptimistic`, `useFormStatus`, and `use`. SKILL.md keeps state, effect, context, ref, custom-hook, and Rules of Hooks essentials.

## Performance Hooks

### useMemo

```tsx
import { useMemo, useState } from 'react';

function ProductList({ products, filter }: Props) {
  // Memoize expensive computation
  const filteredProducts = useMemo(() => {
    console.log('Filtering products...');
    return products.filter((product) => {
      if (filter.category && product.category !== filter.category) {
        return false;
      }
      if (filter.minPrice && product.price < filter.minPrice) {
        return false;
      }
      if (filter.maxPrice && product.price > filter.maxPrice) {
        return false;
      }
      return true;
    });
  }, [products, filter]);

  // Memoize derived data
  const stats = useMemo(
    () => ({
      total: filteredProducts.length,
      avgPrice:
        filteredProducts.reduce((sum, p) => sum + p.price, 0) /
        filteredProducts.length,
    }),
    [filteredProducts]
  );

  return (
    <div>
      <p>
        Showing {stats.total} products (avg: ${stats.avgPrice.toFixed(2)})
      </p>
      {filteredProducts.map((product) => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
}
```

### useCallback

```tsx
import { useCallback, useState, memo } from 'react';

// Memoized child component
const TodoItem = memo(function TodoItem({
  todo,
  onToggle,
  onDelete,
}: {
  todo: Todo;
  onToggle: (id: number) => void;
  onDelete: (id: number) => void;
}) {
  console.log('Rendering todo:', todo.id);
  return (
    <li>
      <input
        type="checkbox"
        checked={todo.completed}
        onChange={() => onToggle(todo.id)}
      />
      <span>{todo.text}</span>
      <button onClick={() => onDelete(todo.id)}>Delete</button>
    </li>
  );
});

function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);

  // Stable callback reference
  const handleToggle = useCallback((id: number) => {
    setTodos((prev) =>
      prev.map((todo) =>
        todo.id === id ? { ...todo, completed: !todo.completed } : todo
      )
    );
  }, []);

  const handleDelete = useCallback((id: number) => {
    setTodos((prev) => prev.filter((todo) => todo.id !== id));
  }, []);

  return (
    <ul>
      {todos.map((todo) => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onToggle={handleToggle}
          onDelete={handleDelete}
        />
      ))}
    </ul>
  );
}
```

## React 19 Hooks

### useTransition

```tsx
import { useState, useTransition } from 'react';

function TabContainer() {
  const [tab, setTab] = useState('about');
  const [isPending, startTransition] = useTransition();

  function selectTab(nextTab: string) {
    // Mark state update as non-urgent
    startTransition(() => {
      setTab(nextTab);
    });
  }

  return (
    <div>
      <nav>
        {['about', 'posts', 'contact'].map((t) => (
          <button
            key={t}
            onClick={() => selectTab(t)}
            className={tab === t ? 'active' : ''}
          >
            {t}
          </button>
        ))}
      </nav>

      <div className={isPending ? 'pending' : ''}>
        {tab === 'about' && <AboutTab />}
        {tab === 'posts' && <PostsTab />}
        {tab === 'contact' && <ContactTab />}
      </div>
    </div>
  );
}
```

### useDeferredValue

```tsx
import { useState, useDeferredValue, memo } from 'react';

const SlowList = memo(function SlowList({ text }: { text: string }) {
  // Expensive rendering
  const items = [];
  for (let i = 0; i < 20000; i++) {
    items.push(<li key={i}>{text}</li>);
  }
  return <ul>{items}</ul>;
});

function App() {
  const [text, setText] = useState('');
  const deferredText = useDeferredValue(text);

  return (
    <div>
      <input
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Type here..."
      />
      {/* Input stays responsive while list updates are deferred */}
      <SlowList text={deferredText} />
    </div>
  );
}
```

### useActionState

```tsx
'use client';

import { useActionState } from 'react';

async function submitForm(
  prevState: { message: string } | null,
  formData: FormData
) {
  'use server';

  const email = formData.get('email') as string;

  if (!email.includes('@')) {
    return { message: 'Invalid email address' };
  }

  await subscribeToNewsletter(email);
  return { message: 'Subscribed successfully!' };
}

function NewsletterForm() {
  const [state, formAction, isPending] = useActionState(submitForm, null);

  return (
    <form action={formAction}>
      <input type="email" name="email" placeholder="Enter email" required />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Subscribing...' : 'Subscribe'}
      </button>
      {state?.message && <p>{state.message}</p>}
    </form>
  );
}
```

### useOptimistic

```tsx
'use client';

import { useOptimistic, useState } from 'react';
import { likePost } from './actions';

function LikeButton({ postId, initialLikes }: Props) {
  const [likes, setLikes] = useState(initialLikes);
  const [optimisticLikes, addOptimisticLike] = useOptimistic(
    likes,
    (state, _) => state + 1
  );

  async function handleLike() {
    addOptimisticLike(null); // Optimistically update
    const newLikes = await likePost(postId); // Server action
    setLikes(newLikes); // Update with actual value
  }

  return (
    <button onClick={handleLike}>
      Like ({optimisticLikes})
    </button>
  );
}
```

### useFormStatus

```tsx
'use client';

import { useFormStatus } from 'react-dom';

function SubmitButton() {
  const { pending, data, method, action } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Submitting...' : 'Submit'}
    </button>
  );
}

function Form() {
  return (
    <form action={submitAction}>
      <input type="text" name="name" />
      <SubmitButton />
    </form>
  );
}
```

