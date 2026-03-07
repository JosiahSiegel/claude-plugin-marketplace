---
name: react-performance
description: Complete React performance optimization system. PROACTIVELY activate for: (1) React.memo and memoization, (2) useMemo and useCallback usage, (3) Code splitting with React.lazy, (4) List virtualization (react-window, react-virtuoso), (5) Avoiding unnecessary re-renders, (6) useTransition and useDeferredValue, (7) Bundle optimization, (8) Web Vitals and profiling. Provides: Profiler setup, memoization patterns, lazy loading, virtualization config, state colocation. Ensures optimal React performance with measurable improvements.
---

## Quick Reference

| Issue | Solution |
|-------|----------|
| Unnecessary re-renders | `React.memo`, `useMemo`, `useCallback` |
| Expensive computations | `useMemo` |
| Large bundles | Code splitting, `React.lazy` |
| Long lists | Virtualization (`react-window`) |
| Slow state updates | `useTransition`, `useDeferredValue` |
| State too high | State colocation |

| Tool | Purpose |
|------|---------|
| React DevTools Profiler | Component render timing |
| `web-vitals` | CLS, INP, LCP, FCP, TTFB |
| Bundle analyzer | Identify large dependencies |

## When to Use This Skill

Use for **React performance optimization**:
- Diagnosing slow rendering issues
- Implementing memoization correctly
- Setting up code splitting and lazy loading
- Virtualizing long lists for smooth scrolling
- Using concurrent features for responsiveness
- Measuring and improving Web Vitals

**For general hooks**: see `react-hooks-complete`

---

# React Performance Optimization

## Measuring Performance

### React DevTools Profiler

```tsx
// Wrap components with Profiler for measurement
import { Profiler, ProfilerOnRenderCallback } from 'react';

const onRenderCallback: ProfilerOnRenderCallback = (
  id,
  phase,
  actualDuration,
  baseDuration,
  startTime,
  commitTime
) => {
  console.log({
    id,
    phase,
    actualDuration, // Time spent rendering
    baseDuration,   // Estimated time without memoization
    startTime,
    commitTime,
  });
};

function App() {
  return (
    <Profiler id="App" onRender={onRenderCallback}>
      <MainContent />
    </Profiler>
  );
}
```

### Web Vitals

```tsx
import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals';

function reportWebVitals(metric: Metric) {
  console.log(metric);
  // Send to analytics
  fetch('/api/analytics', {
    method: 'POST',
    body: JSON.stringify(metric),
  });
}

onCLS(reportWebVitals);  // Cumulative Layout Shift
onINP(reportWebVitals);  // Interaction to Next Paint
onLCP(reportWebVitals);  // Largest Contentful Paint
onFCP(reportWebVitals);  // First Contentful Paint
onTTFB(reportWebVitals); // Time to First Byte
```

## Memoization

### React.memo

```tsx
import { memo, useState } from 'react';

// Memoized component - only re-renders when props change
const ExpensiveList = memo(function ExpensiveList({
  items,
  onItemClick,
}: {
  items: Item[];
  onItemClick: (id: string) => void;
}) {
  console.log('ExpensiveList rendered');

  return (
    <ul>
      {items.map((item) => (
        <li key={item.id} onClick={() => onItemClick(item.id)}>
          {item.name}
        </li>
      ))}
    </ul>
  );
});

// With custom comparison
const DeepCompareList = memo(
  function DeepCompareList({ data }: { data: ComplexData }) {
    return <div>{/* render */}</div>;
  },
  (prevProps, nextProps) => {
    // Return true if props are equal (skip re-render)
    return JSON.stringify(prevProps.data) === JSON.stringify(nextProps.data);
  }
);
```

### useMemo for Expensive Computations

```tsx
import { useMemo, useState } from 'react';

function DataTable({ data, filters, sortConfig }: Props) {
  // Memoize filtered data
  const filteredData = useMemo(() => {
    console.log('Filtering data...');
    return data.filter((item) => {
      return Object.entries(filters).every(([key, value]) => {
        if (!value) return true;
        return item[key]?.toLowerCase().includes(value.toLowerCase());
      });
    });
  }, [data, filters]);

  // Memoize sorted data
  const sortedData = useMemo(() => {
    console.log('Sorting data...');
    if (!sortConfig.key) return filteredData;

    return [...filteredData].sort((a, b) => {
      const aVal = a[sortConfig.key];
      const bVal = b[sortConfig.key];

      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
  }, [filteredData, sortConfig]);

  // Memoize statistics
  const stats = useMemo(() => ({
    total: sortedData.length,
    average: sortedData.reduce((sum, item) => sum + item.value, 0) / sortedData.length,
    max: Math.max(...sortedData.map((item) => item.value)),
  }), [sortedData]);

  return (
    <div>
      <Stats data={stats} />
      <Table data={sortedData} />
    </div>
  );
}
```

### useCallback for Stable Function References

```tsx
import { useCallback, useState, memo } from 'react';

// Child component that should not re-render unnecessarily
const SearchInput = memo(function SearchInput({
  onSearch,
}: {
  onSearch: (query: string) => void;
}) {
  console.log('SearchInput rendered');
  return <input onChange={(e) => onSearch(e.target.value)} />;
});

function SearchPage() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<Result[]>([]);

  // Stable callback reference
  const handleSearch = useCallback((searchQuery: string) => {
    setQuery(searchQuery);
    // Perform search...
  }, []);

  // Without useCallback, SearchInput would re-render on every parent render
  return (
    <div>
      <SearchInput onSearch={handleSearch} />
      <ResultsList results={results} />
    </div>
  );
}
```

## Code Splitting

### React.lazy and Suspense

```tsx
import { lazy, Suspense } from 'react';

// Lazy load components
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));
const Analytics = lazy(() => import('./pages/Analytics'));

// With named exports
const Chart = lazy(() =>
  import('./components/Charts').then((module) => ({
    default: module.PieChart,
  }))
);

function App() {
  return (
    <Suspense fallback={<LoadingSpinner />}>
      <Routes>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
        <Route path="/analytics" element={<Analytics />} />
      </Routes>
    </Suspense>
  );
}
```

### Route-Based Splitting

```tsx
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

// Preload on hover
const DashboardPage = lazy(() => import('./pages/Dashboard'));

function NavLink({ to, children }: { to: string; children: React.ReactNode }) {
  const handleMouseEnter = () => {
    // Preload component on hover
    if (to === '/dashboard') {
      import('./pages/Dashboard');
    }
  };

  return (
    <Link to={to} onMouseEnter={handleMouseEnter}>
      {children}
    </Link>
  );
}
```

### Component-Level Splitting

```tsx
import { lazy, Suspense, useState } from 'react';

// Heavy component loaded only when needed
const RichTextEditor = lazy(() => import('./components/RichTextEditor'));
const ImageEditor = lazy(() => import('./components/ImageEditor'));

function CreatePost() {
  const [showEditor, setShowEditor] = useState(false);
  const [showImageEditor, setShowImageEditor] = useState(false);

  return (
    <div>
      <button onClick={() => setShowEditor(true)}>Open Editor</button>

      {showEditor && (
        <Suspense fallback={<EditorSkeleton />}>
          <RichTextEditor />
        </Suspense>
      )}

      <button onClick={() => setShowImageEditor(true)}>Edit Image</button>

      {showImageEditor && (
        <Suspense fallback={<ImageEditorSkeleton />}>
          <ImageEditor />
        </Suspense>
      )}
    </div>
  );
}
```

## List Virtualization

### react-window

```tsx
import { FixedSizeList, VariableSizeList } from 'react-window';

// Fixed size items
function VirtualizedList({ items }: { items: Item[] }) {
  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      {items[index].name}
    </div>
  );

  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {Row}
    </FixedSizeList>
  );
}

// Variable size items
function VirtualizedVariableList({ items }: { items: Item[] }) {
  const getItemSize = (index: number) => {
    return items[index].content.length > 100 ? 100 : 50;
  };

  const Row = ({ index, style }: { index: number; style: React.CSSProperties }) => (
    <div style={style}>
      <h3>{items[index].title}</h3>
      <p>{items[index].content}</p>
    </div>
  );

  return (
    <VariableSizeList
      height={600}
      itemCount={items.length}
      itemSize={getItemSize}
      width="100%"
    >
      {Row}
    </VariableSizeList>
  );
}
```

### react-virtuoso

```tsx
import { Virtuoso, VirtuosoGrid } from 'react-virtuoso';

// Simple virtualized list
function VirtuosoList({ items }: { items: Item[] }) {
  return (
    <Virtuoso
      style={{ height: '600px' }}
      totalCount={items.length}
      itemContent={(index) => (
        <div className="item">
          <h3>{items[index].title}</h3>
          <p>{items[index].description}</p>
        </div>
      )}
    />
  );
}

// With grouping
function GroupedList({ groups }: { groups: Group[] }) {
  const groupCounts = groups.map((g) => g.items.length);
  const allItems = groups.flatMap((g) => g.items);

  return (
    <Virtuoso
      style={{ height: '600px' }}
      groupCounts={groupCounts}
      groupContent={(index) => (
        <div className="group-header">{groups[index].name}</div>
      )}
      itemContent={(index) => (
        <div className="item">{allItems[index].name}</div>
      )}
    />
  );
}
```

## Avoiding Unnecessary Renders

### State Colocation

```tsx
// Bad - state too high in tree
function App() {
  const [searchQuery, setSearchQuery] = useState('');

  return (
    <div>
      <Header /> {/* Re-renders when searchQuery changes */}
      <SearchSection query={searchQuery} setQuery={setSearchQuery} />
      <Footer /> {/* Re-renders when searchQuery changes */}
    </div>
  );
}

// Good - state colocated with usage
function App() {
  return (
    <div>
      <Header />
      <SearchSection /> {/* Manages its own state */}
      <Footer />
    </div>
  );
}

function SearchSection() {
  const [searchQuery, setSearchQuery] = useState('');
  return (
    <div>
      <input value={searchQuery} onChange={(e) => setSearchQuery(e.target.value)} />
      <SearchResults query={searchQuery} />
    </div>
  );
}
```

### Children as Props

```tsx
// Bad - re-renders children on state change
function Modal({ isOpen, children }: Props) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  return isOpen ? (
    <div style={{ left: position.x, top: position.y }}>
      {children} {/* Re-renders when position changes */}
    </div>
  ) : null;
}

// Good - children are stable
function Modal({ isOpen, children }: Props) {
  const [position, setPosition] = useState({ x: 0, y: 0 });

  // children is a prop, not re-created on render
  return isOpen ? (
    <div style={{ left: position.x, top: position.y }}>
      {children}
    </div>
  ) : null;
}
```

### Composition Pattern

```tsx
// Bad - entire tree re-renders
function SlowComponent({ isOpen }: { isOpen: boolean }) {
  const [count, setCount] = useState(0);
  const [items] = useState(generateLargeList());

  return (
    <div>
      <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>
      <ExpensiveTree items={items} /> {/* Re-renders on count change */}
    </div>
  );
}

// Good - expensive component isolated
function FastComponent() {
  return (
    <div>
      <Counter />
      <ExpensiveTreeWrapper />
    </div>
  );
}

function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>Count: {count}</button>;
}

function ExpensiveTreeWrapper() {
  const [items] = useState(generateLargeList());
  return <ExpensiveTree items={items} />;
}
```

## Concurrent Features

### useTransition for Non-Blocking Updates

```tsx
import { useState, useTransition, memo } from 'react';

const SlowList = memo(function SlowList({ text }: { text: string }) {
  const items = [];
  for (let i = 0; i < 10000; i++) {
    items.push(<li key={i}>{text}</li>);
  }
  return <ul>{items}</ul>;
});

function SearchWithTransition() {
  const [query, setQuery] = useState('');
  const [isPending, startTransition] = useTransition();

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;

    // Urgent update - keep input responsive
    setQuery(value);

    // Non-urgent update - can be interrupted
    startTransition(() => {
      setQuery(value);
    });
  };

  return (
    <div>
      <input value={query} onChange={handleChange} />
      <div style={{ opacity: isPending ? 0.7 : 1 }}>
        <SlowList text={query} />
      </div>
    </div>
  );
}
```

### useDeferredValue for Deferred Rendering

```tsx
import { useState, useDeferredValue, memo } from 'react';

const SearchResults = memo(function SearchResults({ query }: { query: string }) {
  // Expensive search/filter operation
  const results = expensiveSearch(query);
  return (
    <ul>
      {results.map((result) => (
        <li key={result.id}>{result.name}</li>
      ))}
    </ul>
  );
});

function SearchWithDeferredValue() {
  const [query, setQuery] = useState('');
  const deferredQuery = useDeferredValue(query);

  // Show stale indicator
  const isStale = query !== deferredQuery;

  return (
    <div>
      <input
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search..."
      />
      <div style={{ opacity: isStale ? 0.7 : 1 }}>
        <SearchResults query={deferredQuery} />
      </div>
    </div>
  );
}
```

## Image Optimization

### Lazy Loading Images

```tsx
function LazyImage({ src, alt, ...props }: React.ImgHTMLAttributes<HTMLImageElement>) {
  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      decoding="async"
      {...props}
    />
  );
}

// With placeholder
function OptimizedImage({ src, alt, width, height }: Props) {
  const [isLoaded, setIsLoaded] = useState(false);

  return (
    <div style={{ position: 'relative', width, height }}>
      {!isLoaded && <div className="placeholder skeleton" />}
      <img
        src={src}
        alt={alt}
        loading="lazy"
        onLoad={() => setIsLoaded(true)}
        style={{ opacity: isLoaded ? 1 : 0 }}
      />
    </div>
  );
}
```

### Responsive Images

```tsx
function ResponsiveImage({ src, alt }: { src: string; alt: string }) {
  return (
    <picture>
      <source
        media="(max-width: 640px)"
        srcSet={`${src}?w=640 1x, ${src}?w=1280 2x`}
      />
      <source
        media="(max-width: 1024px)"
        srcSet={`${src}?w=1024 1x, ${src}?w=2048 2x`}
      />
      <img
        src={`${src}?w=1920`}
        alt={alt}
        loading="lazy"
        decoding="async"
      />
    </picture>
  );
}
```

## Bundle Optimization

### Analyzing Bundle

```bash
# With webpack
npx webpack-bundle-analyzer stats.json

# With Vite
npx vite-bundle-analyzer
```

### Tree Shaking

```tsx
// Bad - imports entire library
import _ from 'lodash';
const sorted = _.sortBy(items, 'name');

// Good - import only what you need
import sortBy from 'lodash/sortBy';
const sorted = sortBy(items, 'name');

// Best - use native methods when possible
const sorted = [...items].sort((a, b) => a.name.localeCompare(b.name));
```

### Dynamic Imports

```tsx
// Load heavy libraries on demand
async function handleExport() {
  const { jsPDF } = await import('jspdf');
  const doc = new jsPDF();
  doc.text('Hello world!', 10, 10);
  doc.save('document.pdf');
}

async function handleChart() {
  const { Chart } = await import('chart.js/auto');
  new Chart(ctx, config);
}
```

## Best Practices Summary

| Issue | Solution |
|-------|----------|
| Unnecessary re-renders | React.memo, useMemo, useCallback |
| Expensive computations | useMemo |
| Large bundles | Code splitting, lazy loading |
| Long lists | Virtualization |
| Slow state updates | useTransition, useDeferredValue |
| Image performance | Lazy loading, responsive images |
| State too high | State colocation |

## Media Element Performance

Video and audio elements require special attention in React because the browser's media pipeline is **stateful and expensive to initialize**. Unlike most DOM elements, a `<video>` element manages hardware decoder instances, buffered data, and playback state. When React unmounts and remounts a video element, the browser must tear down the entire decoder pipeline and restart it from scratch --- a process called **decoder churn**.

### Why Video Re-renders Are Costly

On mobile devices, decoder churn is especially destructive:

| Impact | Desktop | Mobile |
|--------|---------|--------|
| Decoder initialization | ~50ms | ~200-500ms |
| Simultaneous decoders | 8-16 | 3-4 (hardware limited) |
| Battery drain per restart | Negligible | Measurable |
| Visual glitch | Brief flash | Black frame + delay |

When a parent component re-renders and causes a `<video>` element to remount, the browser:
1. Destroys the existing hardware decoder instance
2. Releases all buffered video data
3. Allocates a new decoder (may fail if device limit reached)
4. Re-fetches and re-buffers the video stream
5. Restarts playback from the beginning (or seeks back)

### Preventing Video Remounting with Stable Keys

The most common cause of video remounting is **unstable keys** or **conditional rendering** that changes the component tree structure:

```tsx
// BAD - video remounts every time filter changes
function VideoFeed({ videos, filter }: Props) {
  const filtered = videos.filter(v => v.category === filter);

  return (
    <div>
      {filtered.map((video, index) => (
        // Using index as key means elements shift and remount
        <video key={index} src={video.src} />
      ))}
    </div>
  );
}

// GOOD - stable keys prevent remounting
function VideoFeed({ videos, filter }: Props) {
  const filtered = videos.filter(v => v.category === filter);

  return (
    <div>
      {filtered.map((video) => (
        // Stable ID keeps the same DOM element across re-renders
        <video key={video.id} src={video.src} />
      ))}
    </div>
  );
}
```

### Ref-Based Video Element Management

Use `useRef` to interact with video elements imperatively, avoiding state-driven patterns that trigger re-renders:

```tsx
import { useRef, useCallback, memo } from 'react';

const VideoPlayer = memo(function VideoPlayer({
  src,
  poster,
}: {
  src: string;
  poster?: string;
}) {
  const videoRef = useRef<HTMLVideoElement>(null);

  // Imperative control avoids re-renders
  const play = useCallback(() => {
    videoRef.current?.play();
  }, []);

  const pause = useCallback(() => {
    videoRef.current?.pause();
  }, []);

  const seek = useCallback((time: number) => {
    if (videoRef.current) {
      videoRef.current.currentTime = time;
    }
  }, []);

  return (
    <div>
      <video
        ref={videoRef}
        src={src}
        poster={poster}
        playsInline
        preload="metadata"
        onPlay={() => {/* update UI without re-rendering video */}}
        onPause={() => {/* update UI without re-rendering video */}}
      />
      <button onClick={play}>Play</button>
      <button onClick={pause}>Pause</button>
    </div>
  );
});
```

### Memoizing Video Components

Wrap video components with `React.memo` and memoize all non-primitive props to prevent unnecessary re-renders:

```tsx
import { memo, useMemo, useCallback } from 'react';

interface VideoCardProps {
  id: string;
  src: string;
  title: string;
  onPlay: (id: string) => void;
  onTimeUpdate: (id: string, time: number) => void;
}

const VideoCard = memo(function VideoCard({
  id,
  src,
  title,
  onPlay,
  onTimeUpdate,
}: VideoCardProps) {
  // Stable source object prevents <source> element remount
  const sourceProps = useMemo(
    () => ({ src, type: 'video/mp4' }),
    [src]
  );

  const handlePlay = useCallback(() => onPlay(id), [onPlay, id]);

  const handleTimeUpdate = useCallback(
    (e: React.SyntheticEvent<HTMLVideoElement>) => {
      onTimeUpdate(id, e.currentTarget.currentTime);
    },
    [onTimeUpdate, id]
  );

  return (
    <div>
      <h3>{title}</h3>
      <video
        playsInline
        preload="metadata"
        onPlay={handlePlay}
        onTimeUpdate={handleTimeUpdate}
      >
        <source src={sourceProps.src} type={sourceProps.type} />
      </video>
    </div>
  );
});

// Parent component with stable callbacks
function VideoList({ videos }: { videos: Video[] }) {
  const handlePlay = useCallback((id: string) => {
    console.log('Playing:', id);
  }, []);

  const handleTimeUpdate = useCallback((id: string, time: number) => {
    // Update progress without triggering re-render of video components
    progressRef.current.set(id, time);
  }, []);

  const progressRef = useRef(new Map<string, number>());

  return (
    <div>
      {videos.map((video) => (
        <VideoCard
          key={video.id}
          id={video.id}
          src={video.src}
          title={video.title}
          onPlay={handlePlay}
          onTimeUpdate={handleTimeUpdate}
        />
      ))}
    </div>
  );
}
```

### Portal Lifecycle and Video Elements

React portals can cause unexpected video remounting when the portal's parent moves in the DOM tree. The portal content unmounts and remounts, destroying the video decoder:

```tsx
import { useState, useRef, useEffect, createPortal } from 'react';

// BAD - video remounts when switching between inline and modal
function VideoWithModal({ src }: { src: string }) {
  const [isModal, setIsModal] = useState(false);

  if (isModal) {
    return createPortal(
      <div className="modal">
        {/* This creates a NEW video element, losing playback state */}
        <video src={src} playsInline />
        <button onClick={() => setIsModal(false)}>Close</button>
      </div>,
      document.body
    );
  }

  return (
    <div>
      <video src={src} playsInline />
      <button onClick={() => setIsModal(true)}>Expand</button>
    </div>
  );
}

// GOOD - move the DOM node instead of recreating it
function VideoWithModal({ src }: { src: string }) {
  const [isModal, setIsModal] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);
  const inlineContainerRef = useRef<HTMLDivElement>(null);
  const modalContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    // Move the existing video DOM node instead of recreating it
    const target = isModal
      ? modalContainerRef.current
      : inlineContainerRef.current;
    target?.appendChild(video);
  }, [isModal]);

  return (
    <>
      {/* Video element created once, moved between containers */}
      <video
        ref={videoRef}
        src={src}
        playsInline
        style={{ display: 'none' }}
      />

      <div ref={inlineContainerRef}>
        {!isModal && (
          <button onClick={() => setIsModal(true)}>Expand</button>
        )}
      </div>

      {isModal &&
        createPortal(
          <div className="modal">
            <div ref={modalContainerRef} />
            <button onClick={() => setIsModal(false)}>Close</button>
          </div>,
          document.body
        )}
    </>
  );
}
```

### Intersection Observer for Lazy Video Loading

On mobile, loading all videos simultaneously wastes bandwidth, drains battery, and can exhaust the device's limited hardware decoder slots. Use Intersection Observer to load and play videos only when visible:

```tsx
import { useRef, useEffect, useState, memo } from 'react';

const LazyVideo = memo(function LazyVideo({
  src,
  poster,
  preloadMargin = '200px',
}: {
  src: string;
  poster?: string;
  preloadMargin?: string;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const videoRef = useRef<HTMLVideoElement>(null);
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsVisible(true);
          // Optionally auto-play when visible
          videoRef.current?.play().catch(() => {
            // Autoplay blocked by browser policy - this is expected
          });
        } else {
          // Pause when scrolled out of view to save resources
          videoRef.current?.pause();
        }
      },
      {
        rootMargin: preloadMargin, // Start loading before fully visible
        threshold: 0.25,
      }
    );

    observer.observe(container);

    return () => observer.disconnect();
  }, [preloadMargin]);

  return (
    <div ref={containerRef} style={{ aspectRatio: '16/9' }}>
      <video
        ref={videoRef}
        // Only set src when near viewport to prevent premature loading
        src={isVisible ? src : undefined}
        poster={poster}
        playsInline
        muted
        loop
        preload={isVisible ? 'auto' : 'none'}
        style={{ width: '100%', height: '100%', objectFit: 'cover' }}
      />
    </div>
  );
});

// Usage in a feed - only visible videos consume decoder slots
function VideoFeed({ videos }: { videos: VideoItem[] }) {
  return (
    <div>
      {videos.map((video) => (
        <LazyVideo
          key={video.id}
          src={video.src}
          poster={video.poster}
        />
      ))}
    </div>
  );
}
```

### Mobile-Specific Video Attributes

Always include these attributes for proper mobile video behavior:

```tsx
<video
  ref={videoRef}
  src={src}
  playsInline          // REQUIRED: prevents iOS Safari fullscreen takeover
  muted                // Required for autoplay on all mobile browsers
  preload="metadata"   // Load dimensions/duration only, not full video
  poster={posterUrl}   // Show image while video loads (saves bandwidth)
  disablePictureInPicture  // Prevent PiP on mobile if unwanted
  controlsList="nodownload nofullscreen noremoteplayback"
/>
```

### Multiple Simultaneous Video Decoders

Mobile devices typically support only 3-4 simultaneous hardware video decoders. Exceeding this limit causes videos to fall back to software decoding (slow, battery-draining) or fail entirely:

```tsx
import { useRef, useCallback } from 'react';

// Limit active video decoders across the application
const MAX_ACTIVE_VIDEOS = 3;

function useVideoDecoderPool() {
  const activeVideos = useRef<Set<HTMLVideoElement>>(new Set());

  const activate = useCallback((video: HTMLVideoElement) => {
    if (activeVideos.current.size >= MAX_ACTIVE_VIDEOS) {
      // Pause the oldest active video to free a decoder slot
      const oldest = activeVideos.current.values().next().value;
      if (oldest) {
        oldest.pause();
        oldest.removeAttribute('src');
        oldest.load(); // Release the decoder
        activeVideos.current.delete(oldest);
      }
    }
    activeVideos.current.add(video);
  }, []);

  const deactivate = useCallback((video: HTMLVideoElement) => {
    activeVideos.current.delete(video);
  }, []);

  return { activate, deactivate };
}
```

## Additional References

For comprehensive guides on specific optimization techniques, see:

- `references/virtualization-guide.md` - Complete guide to virtualized lists with react-window, react-virtuoso, and @tanstack/react-virtual
