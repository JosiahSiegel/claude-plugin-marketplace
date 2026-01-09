---
name: nextjs-middleware
description: Complete Next.js Middleware system (Next.js 15.5/16). PROACTIVELY activate for: (1) Creating middleware.ts (Edge) or proxy.ts (Node.js), (2) Matcher configuration, (3) Authentication protection, (4) Role-based access control, (5) Redirects and rewrites, (6) Internationalization (i18n), (7) Security headers (CSP, CORS), (8) Geolocation routing, (9) Bot detection, (10) Rate limiting patterns, (11) Node.js Middleware with proxy.ts (Next.js 16). Provides: Edge middleware patterns, Node.js proxy patterns, matcher syntax, auth guards, header manipulation, cookie handling, database access in proxy.ts. Ensures optimized request handling with proper security.
---

## Quick Reference

| Response Type | Code | Purpose |
|---------------|------|---------|
| Continue | `NextResponse.next()` | Pass through |
| Redirect | `NextResponse.redirect(url)` | 307/308 redirect |
| Rewrite | `NextResponse.rewrite(url)` | URL rewrite (no redirect) |
| JSON | `NextResponse.json(data)` | Return JSON response |

| Matcher Pattern | Matches |
|-----------------|---------|
| `'/about'` | Exact path |
| `'/dashboard/:path*'` | Dashboard and all sub-paths |
| `'/((?!api\|_next).*)` | All except api and _next |

| Request Data | Access |
|--------------|--------|
| Path | `request.nextUrl.pathname` |
| Search params | `request.nextUrl.searchParams` |
| Cookies | `request.cookies.get('name')` |
| Headers | `request.headers.get('name')` |
| Geo | `request.geo?.country` |
| IP | `request.ip` |

## When to Use This Skill

Use for **Edge request handling**:
- Protecting routes with authentication
- Implementing role-based access control
- Setting security headers (CSP, CORS)
- Internationalization and locale detection
- A/B testing with rewrites
- Geolocation-based routing

**Related skills:**
- For authentication: see `nextjs-authentication`
- For routing: see `nextjs-routing-advanced`
- For deployment: see `nextjs-deployment`

---

# Next.js Middleware

## Basic Middleware

### Creating Middleware

```tsx
// middleware.ts (in project root)
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // Add custom header
  const response = NextResponse.next();
  response.headers.set('x-custom-header', 'my-value');
  return response;
}

// Configure which paths middleware runs on
export const config = {
  matcher: '/api/:path*',
};
```

### Matcher Configuration

```tsx
// Single path
export const config = {
  matcher: '/about',
};

// Multiple paths
export const config = {
  matcher: ['/about', '/dashboard/:path*'],
};

// Regex pattern
export const config = {
  matcher: [
    // Match all paths except static files and images
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
};

// All paths except API and static
export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

## Authentication

### Protecting Routes

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

export async function middleware(request: NextRequest) {
  const token = await getToken({
    req: request,
    secret: process.env.NEXTAUTH_SECRET,
  });

  const isAuthPage =
    request.nextUrl.pathname.startsWith('/login') ||
    request.nextUrl.pathname.startsWith('/register');

  if (isAuthPage) {
    if (token) {
      // Redirect to dashboard if already logged in
      return NextResponse.redirect(new URL('/dashboard', request.url));
    }
    return NextResponse.next();
  }

  if (!token) {
    // Redirect to login if not authenticated
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('callbackUrl', request.nextUrl.pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/settings/:path*', '/login', '/register'],
};
```

### Role-Based Access

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

const roleBasedRoutes: Record<string, string[]> = {
  '/admin': ['admin'],
  '/dashboard': ['admin', 'user'],
  '/settings': ['admin', 'user'],
};

export async function middleware(request: NextRequest) {
  const token = await getToken({ req: request });
  const { pathname } = request.nextUrl;

  // Check role-based access
  for (const [route, allowedRoles] of Object.entries(roleBasedRoutes)) {
    if (pathname.startsWith(route)) {
      if (!token) {
        return NextResponse.redirect(new URL('/login', request.url));
      }

      const userRole = token.role as string;
      if (!allowedRoles.includes(userRole)) {
        return NextResponse.redirect(new URL('/unauthorized', request.url));
      }
    }
  }

  return NextResponse.next();
}
```

## Redirects

### Simple Redirects

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const redirects: Record<string, string> = {
  '/old-page': '/new-page',
  '/blog/old-post': '/articles/new-post',
  '/legacy': 'https://legacy.example.com',
};

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (redirects[pathname]) {
    const destination = redirects[pathname];

    // External redirect
    if (destination.startsWith('http')) {
      return NextResponse.redirect(destination);
    }

    // Internal redirect
    return NextResponse.redirect(new URL(destination, request.url));
  }

  return NextResponse.next();
}
```

### Conditional Redirects

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname, searchParams } = request.nextUrl;

  // Redirect old search format
  if (pathname === '/search' && searchParams.has('query')) {
    const query = searchParams.get('query');
    return NextResponse.redirect(new URL(`/search/${query}`, request.url));
  }

  // Redirect trailing slashes
  if (pathname !== '/' && pathname.endsWith('/')) {
    return NextResponse.redirect(
      new URL(pathname.slice(0, -1), request.url)
    );
  }

  return NextResponse.next();
}
```

## Rewrites

### URL Rewrites

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Rewrite /api to external API
  if (pathname.startsWith('/api/external')) {
    return NextResponse.rewrite(
      new URL(pathname.replace('/api/external', ''), 'https://api.example.com')
    );
  }

  // A/B testing rewrite
  const bucket = request.cookies.get('bucket')?.value || 'a';
  if (pathname === '/landing') {
    return NextResponse.rewrite(
      new URL(`/landing-${bucket}`, request.url)
    );
  }

  return NextResponse.next();
}
```

### Internationalization

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const locales = ['en', 'es', 'fr', 'de'];
const defaultLocale = 'en';

function getLocale(request: NextRequest): string {
  // Check cookie
  const cookieLocale = request.cookies.get('NEXT_LOCALE')?.value;
  if (cookieLocale && locales.includes(cookieLocale)) {
    return cookieLocale;
  }

  // Check Accept-Language header
  const acceptLanguage = request.headers.get('accept-language');
  if (acceptLanguage) {
    const preferredLocale = acceptLanguage
      .split(',')
      .map((lang) => lang.split(';')[0].trim().split('-')[0])
      .find((lang) => locales.includes(lang));

    if (preferredLocale) {
      return preferredLocale;
    }
  }

  return defaultLocale;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Check if pathname has a locale
  const pathnameHasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );

  if (pathnameHasLocale) return NextResponse.next();

  // Redirect to localized path
  const locale = getLocale(request);
  return NextResponse.redirect(
    new URL(`/${locale}${pathname}`, request.url)
  );
}

export const config = {
  matcher: ['/((?!_next|api|favicon.ico).*)'],
};
```

## Headers

### Adding Headers

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Security headers
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=()'
  );

  // CSP header
  response.headers.set(
    'Content-Security-Policy',
    "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
  );

  return response;
}
```

### CORS Headers

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const allowedOrigins = ['https://example.com', 'https://app.example.com'];

export function middleware(request: NextRequest) {
  const origin = request.headers.get('origin');
  const isAllowedOrigin = origin && allowedOrigins.includes(origin);

  // Handle preflight requests
  if (request.method === 'OPTIONS') {
    const response = new NextResponse(null, { status: 204 });

    if (isAllowedOrigin) {
      response.headers.set('Access-Control-Allow-Origin', origin);
    }

    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    response.headers.set('Access-Control-Max-Age', '86400');

    return response;
  }

  const response = NextResponse.next();

  if (isAllowedOrigin) {
    response.headers.set('Access-Control-Allow-Origin', origin);
  }

  return response;
}

export const config = {
  matcher: '/api/:path*',
};
```

## Cookies

### Setting Cookies

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Set cookie if not exists
  if (!request.cookies.has('visitor_id')) {
    const visitorId = crypto.randomUUID();
    response.cookies.set('visitor_id', visitorId, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'lax',
      maxAge: 60 * 60 * 24 * 365, // 1 year
    });
  }

  return response;
}
```

### Reading Cookies

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth-token')?.value;
  const theme = request.cookies.get('theme')?.value || 'light';

  // Use cookie values
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  const response = NextResponse.next();
  response.headers.set('x-theme', theme);

  return response;
}
```

## Geolocation and IP

### Geolocation-Based Routing

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const country = request.geo?.country || 'US';
  const city = request.geo?.city || 'Unknown';
  const region = request.geo?.region || 'Unknown';

  // Block certain countries
  const blockedCountries = ['XX', 'YY'];
  if (blockedCountries.includes(country)) {
    return NextResponse.redirect(new URL('/blocked', request.url));
  }

  // Add geo info to headers
  const response = NextResponse.next();
  response.headers.set('x-user-country', country);
  response.headers.set('x-user-city', city);

  return response;
}
```

### IP-Based Rate Limiting

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const rateLimit = new Map<string, { count: number; resetTime: number }>();

export function middleware(request: NextRequest) {
  const ip = request.ip || request.headers.get('x-forwarded-for') || 'unknown';
  const now = Date.now();
  const windowMs = 60 * 1000; // 1 minute
  const maxRequests = 100;

  const record = rateLimit.get(ip);

  if (!record || now > record.resetTime) {
    rateLimit.set(ip, { count: 1, resetTime: now + windowMs });
    return NextResponse.next();
  }

  if (record.count >= maxRequests) {
    return NextResponse.json(
      { error: 'Too many requests' },
      { status: 429 }
    );
  }

  record.count++;
  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
```

## Bot Detection

```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const botPatterns = [
  /bot/i,
  /spider/i,
  /crawl/i,
  /slurp/i,
  /mediapartners/i,
];

export function middleware(request: NextRequest) {
  const userAgent = request.headers.get('user-agent') || '';
  const isBot = botPatterns.some((pattern) => pattern.test(userAgent));

  const response = NextResponse.next();
  response.headers.set('x-is-bot', isBot ? 'true' : 'false');

  // Optionally block certain bots
  if (isBot && request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  return response;
}
```

## Best Practices

| Practice | Description |
|----------|-------------|
| Keep middleware fast | Runs on every matched request |
| Use Edge Runtime | Middleware runs on Edge by default |
| Avoid heavy computation | No database queries in middleware |
| Use specific matchers | Don't run on static files |
| Handle errors gracefully | Always return a response |
| Cache when possible | Use cookies/headers for state |
