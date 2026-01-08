# React Virtualization Guide

Complete guide to virtualized lists for handling large datasets efficiently.

## Why Virtualization?

| Items | Without Virtualization | With Virtualization |
|-------|----------------------|---------------------|
| 100 | ~20ms | ~5ms |
| 1,000 | ~200ms | ~10ms |
| 10,000 | ~2000ms (unusable) | ~15ms |
| 100,000 | Crash | ~20ms |

Virtualization only renders visible items + buffer, making performance constant regardless of list size.

## Libraries Comparison

| Library | Size | Features | Best For |
|---------|------|----------|----------|
| react-window | 6kb | Fixed/Variable size lists | Simple lists |
| react-virtuoso | 15kb | Auto-sizing, grouping, tables | Complex lists |
| @tanstack/react-virtual | 5kb | Headless, flexible | Custom implementations |

## react-window Implementation

### Installation

```bash
npm install react-window
npm install -D @types/react-window
```

### FixedSizeList - Basic Usage

```tsx
import { FixedSizeList, ListChildComponentProps } from 'react-window';
import { memo } from 'react';

interface Item {
  id: string;
  name: string;
  email: string;
}

interface RowProps extends ListChildComponentProps<Item[]> {}

// IMPORTANT: Memoize row component
const Row = memo(function Row({ index, style, data }: RowProps) {
  const item = data[index];

  return (
    <div style={style} className="flex items-center px-4 border-b">
      <span className="flex-1">{item.name}</span>
      <span className="text-gray-500">{item.email}</span>
    </div>
  );
});

function UserList({ users }: { users: Item[] }) {
  return (
    <FixedSizeList
      height={600}        // Container height
      width="100%"        // Container width
      itemCount={users.length}
      itemSize={50}       // Row height in pixels
      itemData={users}    // Data passed to Row
    >
      {Row}
    </FixedSizeList>
  );
}
```

### FixedSizeList - With Interaction

```tsx
import { FixedSizeList, ListChildComponentProps } from 'react-window';
import { memo, useCallback } from 'react';

interface Item {
  id: string;
  name: string;
  status: 'active' | 'inactive';
}

interface RowData {
  items: Item[];
  onSelect: (item: Item) => void;
  onDelete: (id: string) => void;
  selectedId: string | null;
}

const Row = memo(function Row({
  index,
  style,
  data,
}: ListChildComponentProps<RowData>) {
  const { items, onSelect, onDelete, selectedId } = data;
  const item = items[index];
  const isSelected = item.id === selectedId;

  return (
    <div
      style={style}
      className={`flex items-center px-4 border-b cursor-pointer ${
        isSelected ? 'bg-blue-100' : 'hover:bg-gray-50'
      }`}
      onClick={() => onSelect(item)}
    >
      <span className="flex-1 font-medium">{item.name}</span>
      <span
        className={`px-2 py-1 rounded text-sm ${
          item.status === 'active'
            ? 'bg-green-100 text-green-800'
            : 'bg-gray-100 text-gray-600'
        }`}
      >
        {item.status}
      </span>
      <button
        className="ml-2 p-1 text-red-500 hover:text-red-700"
        onClick={(e) => {
          e.stopPropagation();
          onDelete(item.id);
        }}
      >
        Delete
      </button>
    </div>
  );
});

function InteractiveList({ items }: { items: Item[] }) {
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const handleSelect = useCallback((item: Item) => {
    setSelectedId(item.id);
  }, []);

  const handleDelete = useCallback((id: string) => {
    // Handle deletion
  }, []);

  // IMPORTANT: Memoize itemData to prevent unnecessary re-renders
  const itemData = useMemo(
    () => ({
      items,
      onSelect: handleSelect,
      onDelete: handleDelete,
      selectedId,
    }),
    [items, handleSelect, handleDelete, selectedId]
  );

  return (
    <FixedSizeList
      height={400}
      width="100%"
      itemCount={items.length}
      itemSize={56}
      itemData={itemData}
    >
      {Row}
    </FixedSizeList>
  );
}
```

### VariableSizeList - Dynamic Heights

```tsx
import { VariableSizeList, ListChildComponentProps } from 'react-window';
import { memo, useCallback, useRef } from 'react';

interface Message {
  id: string;
  text: string;
  sender: string;
  timestamp: Date;
}

const Row = memo(function Row({
  index,
  style,
  data,
}: ListChildComponentProps<Message[]>) {
  const message = data[index];

  return (
    <div style={style} className="px-4 py-2">
      <div className="flex justify-between">
        <span className="font-medium">{message.sender}</span>
        <span className="text-gray-400 text-sm">
          {message.timestamp.toLocaleTimeString()}
        </span>
      </div>
      <p className="text-gray-700">{message.text}</p>
    </div>
  );
});

function ChatMessages({ messages }: { messages: Message[] }) {
  const listRef = useRef<VariableSizeList>(null);

  // Calculate height based on content
  const getItemSize = useCallback(
    (index: number) => {
      const message = messages[index];
      // Base height + lines of text
      const lineHeight = 24;
      const lines = Math.ceil(message.text.length / 60);
      return 40 + lines * lineHeight;
    },
    [messages]
  );

  // Reset cache when messages change
  useEffect(() => {
    listRef.current?.resetAfterIndex(0);
  }, [messages]);

  return (
    <VariableSizeList
      ref={listRef}
      height={500}
      width="100%"
      itemCount={messages.length}
      itemSize={getItemSize}
      itemData={messages}
    >
      {Row}
    </VariableSizeList>
  );
}
```

### FixedSizeGrid - 2D Virtualization

```tsx
import { FixedSizeGrid, GridChildComponentProps } from 'react-window';
import { memo } from 'react';

interface Product {
  id: string;
  name: string;
  price: number;
  image: string;
}

const Cell = memo(function Cell({
  columnIndex,
  rowIndex,
  style,
  data,
}: GridChildComponentProps<{ products: Product[]; columns: number }>) {
  const { products, columns } = data;
  const index = rowIndex * columns + columnIndex;
  const product = products[index];

  if (!product) return <div style={style} />;

  return (
    <div style={style} className="p-2">
      <div className="border rounded-lg p-4 h-full">
        <img
          src={product.image}
          alt={product.name}
          className="w-full h-32 object-cover rounded"
        />
        <h3 className="mt-2 font-medium">{product.name}</h3>
        <p className="text-green-600">${product.price}</p>
      </div>
    </div>
  );
});

function ProductGrid({ products }: { products: Product[] }) {
  const columns = 4;
  const rows = Math.ceil(products.length / columns);

  return (
    <FixedSizeGrid
      height={600}
      width={800}
      columnCount={columns}
      columnWidth={200}
      rowCount={rows}
      rowHeight={250}
      itemData={{ products, columns }}
    >
      {Cell}
    </FixedSizeGrid>
  );
}
```

## react-virtuoso Implementation

### Installation

```bash
npm install react-virtuoso
```

### Basic List - Auto Height

```tsx
import { Virtuoso } from 'react-virtuoso';

interface Item {
  id: string;
  title: string;
  description: string;
}

function AutoSizeList({ items }: { items: Item[] }) {
  return (
    <Virtuoso
      style={{ height: 600 }}
      data={items}
      itemContent={(index, item) => (
        <div className="p-4 border-b">
          <h3 className="font-medium">{item.title}</h3>
          <p className="text-gray-600">{item.description}</p>
        </div>
      )}
    />
  );
}
```

### Infinite Scroll

```tsx
import { Virtuoso } from 'react-virtuoso';
import { useState, useCallback } from 'react';

interface Item {
  id: string;
  name: string;
}

function InfiniteList() {
  const [items, setItems] = useState<Item[]>([]);
  const [hasMore, setHasMore] = useState(true);

  const loadMore = useCallback(async () => {
    const newItems = await fetchItems(items.length, 20);

    if (newItems.length === 0) {
      setHasMore(false);
      return;
    }

    setItems((prev) => [...prev, ...newItems]);
  }, [items.length]);

  return (
    <Virtuoso
      style={{ height: 600 }}
      data={items}
      endReached={hasMore ? loadMore : undefined}
      itemContent={(index, item) => (
        <div className="p-4 border-b">{item.name}</div>
      )}
      components={{
        Footer: () =>
          hasMore ? (
            <div className="p-4 text-center">Loading more...</div>
          ) : (
            <div className="p-4 text-center text-gray-500">No more items</div>
          ),
      }}
    />
  );
}
```

### Grouped List

```tsx
import { GroupedVirtuoso } from 'react-virtuoso';

interface Contact {
  name: string;
  email: string;
}

interface ContactGroup {
  letter: string;
  contacts: Contact[];
}

function GroupedContactList({ groups }: { groups: ContactGroup[] }) {
  const groupCounts = groups.map((g) => g.contacts.length);
  const allContacts = groups.flatMap((g) => g.contacts);

  return (
    <GroupedVirtuoso
      style={{ height: 600 }}
      groupCounts={groupCounts}
      groupContent={(index) => (
        <div className="bg-gray-100 px-4 py-2 font-bold sticky top-0">
          {groups[index].letter}
        </div>
      )}
      itemContent={(index) => (
        <div className="px-4 py-3 border-b">
          <div className="font-medium">{allContacts[index].name}</div>
          <div className="text-gray-500 text-sm">{allContacts[index].email}</div>
        </div>
      )}
    />
  );
}
```

### Virtuoso Table

```tsx
import { TableVirtuoso } from 'react-virtuoso';

interface User {
  id: string;
  name: string;
  email: string;
  role: string;
  status: 'active' | 'inactive';
}

function VirtualTable({ users }: { users: User[] }) {
  return (
    <TableVirtuoso
      style={{ height: 500 }}
      data={users}
      fixedHeaderContent={() => (
        <tr className="bg-gray-100">
          <th className="px-4 py-2 text-left">Name</th>
          <th className="px-4 py-2 text-left">Email</th>
          <th className="px-4 py-2 text-left">Role</th>
          <th className="px-4 py-2 text-left">Status</th>
        </tr>
      )}
      itemContent={(index, user) => (
        <>
          <td className="px-4 py-2 border-b">{user.name}</td>
          <td className="px-4 py-2 border-b">{user.email}</td>
          <td className="px-4 py-2 border-b">{user.role}</td>
          <td className="px-4 py-2 border-b">
            <span
              className={`px-2 py-1 rounded text-sm ${
                user.status === 'active'
                  ? 'bg-green-100 text-green-800'
                  : 'bg-gray-100'
              }`}
            >
              {user.status}
            </span>
          </td>
        </>
      )}
    />
  );
}
```

## @tanstack/react-virtual (Headless)

### Installation

```bash
npm install @tanstack/react-virtual
```

### Custom Implementation

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';
import { useRef } from 'react';

interface Item {
  id: string;
  name: string;
  description: string;
}

function HeadlessList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80, // Estimated row height
    overscan: 5, // Buffer items
  });

  return (
    <div
      ref={parentRef}
      className="h-[600px] overflow-auto"
    >
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          width: '100%',
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => {
          const item = items[virtualRow.index];

          return (
            <div
              key={virtualRow.key}
              style={{
                position: 'absolute',
                top: 0,
                left: 0,
                width: '100%',
                height: `${virtualRow.size}px`,
                transform: `translateY(${virtualRow.start}px)`,
              }}
              className="p-4 border-b"
            >
              <h3 className="font-medium">{item.name}</h3>
              <p className="text-gray-600">{item.description}</p>
            </div>
          );
        })}
      </div>
    </div>
  );
}
```

### Dynamic Measurement

```tsx
import { useVirtualizer } from '@tanstack/react-virtual';

function DynamicHeightList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null);

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 50,
    measureElement: (element) => element.getBoundingClientRect().height,
  });

  return (
    <div ref={parentRef} className="h-[600px] overflow-auto">
      <div
        style={{
          height: `${virtualizer.getTotalSize()}px`,
          position: 'relative',
        }}
      >
        {virtualizer.getVirtualItems().map((virtualRow) => (
          <div
            key={virtualRow.key}
            data-index={virtualRow.index}
            ref={virtualizer.measureElement}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              transform: `translateY(${virtualRow.start}px)`,
            }}
          >
            {/* Content with dynamic height */}
          </div>
        ))}
      </div>
    </div>
  );
}
```

## Performance Tips

### 1. Memoize Row Components

```tsx
// ALWAYS use memo for row components
const Row = memo(function Row({ data, index, style }) {
  // ...
});
```

### 2. Memoize itemData

```tsx
// Prevent itemData recreation on every render
const itemData = useMemo(
  () => ({ items, onSelect, selectedId }),
  [items, onSelect, selectedId]
);
```

### 3. Avoid Inline Functions

```tsx
// BAD - new function every render
<FixedSizeList>
  {({ index, style }) => <Row index={index} style={style} onClick={() => select(index)} />}
</FixedSizeList>

// GOOD - stable reference
const Row = memo(function Row({ index, style, data }) {
  return <div onClick={() => data.onSelect(index)}>...</div>;
});
```

### 4. Use CSS for Styling

```tsx
// BAD - inline style object (creates new object)
<div style={{ color: 'red', padding: '10px' }}>

// GOOD - className or CSS modules
<div className="text-red-500 p-2">
```

### 5. Debounce Window Resize

```tsx
function ResponsiveList() {
  const [dimensions, setDimensions] = useState({ width: 0, height: 0 });

  useEffect(() => {
    const updateDimensions = debounce(() => {
      setDimensions({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    }, 100);

    window.addEventListener('resize', updateDimensions);
    return () => window.removeEventListener('resize', updateDimensions);
  }, []);

  return <FixedSizeList width={dimensions.width} height={dimensions.height} />;
}
```
