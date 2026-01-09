---
description: Create Next.js middleware or proxy for authentication, redirects, or headers
argument-hint: "Middleware purpose (e.g., 'auth for dashboard', 'i18n', 'rate-limiting')"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Generate Next.js Middleware

Create middleware with common patterns for authentication, redirects, or headers.

## Arguments
- `$ARGUMENTS` - Middleware purpose (e.g., "authentication for dashboard routes" or "internationalization")

## Instructions

Create middleware based on the provided purpose:

1. **Analyze Requirements**
   - Parse middleware purpose from `$ARGUMENTS`
   - Identify routes to protect/modify
   - Determine required logic

2. **Implementation**
   - Create middleware.ts (Edge) or proxy.ts (Node.js - Next.js 16)
   - Configure matcher for target routes
   - Implement required logic

3. **Common Patterns**
   - Authentication protection
   - Internationalization
   - Redirects/rewrites
   - Custom headers
   - Rate limiting

## Middleware vs Proxy (Next.js 16)

| Use Case | File | Runtime |
|----------|------|---------|
| Simple redirects/rewrites | middleware.ts | Edge |
| Basic auth checks | middleware.ts | Edge |
| Database queries | proxy.ts | Node.js |
| Full JWT verification | proxy.ts | Node.js |
| Complex business logic | proxy.ts | Node.js |

## Example Output

### Authentication Middleware (Edge)
```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getToken } from 'next-auth/jwt';

const publicPaths = [
  '/',
  '/login',
  '/register',
  '/forgot-password',
  '/api/auth',
];

const adminPaths = ['/admin'];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Check if path is public
  const isPublicPath = publicPaths.some(
    (path) => pathname === path || pathname.startsWith(`${path}/`)
  );

  if (isPublicPath) {
    return NextResponse.next();
  }

  // Get session token
  const token = await getToken({
    req: request,
    secret: process.env.NEXTAUTH_SECRET,
  });

  // Redirect to login if not authenticated
  if (!token) {
    const loginUrl = new URL('/login', request.url);
    loginUrl.searchParams.set('callbackUrl', pathname);
    return NextResponse.redirect(loginUrl);
  }

  // Check admin access
  const isAdminPath = adminPaths.some((path) => pathname.startsWith(path));
  if (isAdminPath && token.role !== 'admin') {
    return NextResponse.redirect(new URL('/unauthorized', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico|public).*)'],
};
```

### Node.js Proxy with Database Access (Next.js 16)
```tsx
// proxy.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { verify } from 'jsonwebtoken';
import { db } from './lib/db';

export async function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Skip public paths
  if (pathname.startsWith('/api/public') || pathname === '/login') {
    return NextResponse.next();
  }

  const token = request.cookies.get('auth-token')?.value;

  if (!token) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  try {
    const decoded = verify(token, process.env.JWT_SECRET!) as { userId: string };

    // Query database for user (only possible in proxy.ts, not middleware.ts)
    const user = await db.user.findUnique({
      where: { id: decoded.userId },
      select: { id: true, role: true, isActive: true },
    });

    if (!user || !user.isActive) {
      return NextResponse.redirect(new URL('/login', request.url));
    }

    // Admin routes check
    if (pathname.startsWith('/admin') && user.role !== 'admin') {
      return NextResponse.redirect(new URL('/unauthorized', request.url));
    }

    // Add user context to headers
    const response = NextResponse.next();
    response.headers.set('x-user-id', user.id);
    response.headers.set('x-user-role', user.role);
    return response;

  } catch (error) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
```

### Internationalization Middleware
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
    const preferred = acceptLanguage
      .split(',')
      .map((lang) => lang.split(';')[0].trim().split('-')[0])
      .find((lang) => locales.includes(lang));

    if (preferred) return preferred;
  }

  return defaultLocale;
}

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Check if pathname has locale
  const pathnameHasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );

  if (pathnameHasLocale) {
    return NextResponse.next();
  }

  // Redirect to localized path
  const locale = getLocale(request);
  const url = new URL(`/${locale}${pathname}`, request.url);

  return NextResponse.redirect(url);
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### Security Headers Middleware
```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const response = NextResponse.next();

  // Security headers
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('X-XSS-Protection', '1; mode=block');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set(
    'Permissions-Policy',
    'camera=(), microphone=(), geolocation=()'
  );

  // CSP
  const csp = [
    "default-src 'self'",
    "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: https:",
    "font-src 'self'",
    "connect-src 'self'",
  ].join('; ');

  response.headers.set('Content-Security-Policy', csp);

  return response;
}

export const config = {
  matcher: ['/((?!api|_next/static|_next/image|favicon.ico).*)'],
};
```

### Rate Limiting Middleware
```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const rateLimit = new Map<string, { count: number; resetTime: number }>();

const WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS = 100;

export function middleware(request: NextRequest) {
  // Only rate limit API routes
  if (!request.nextUrl.pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  const ip = request.ip || request.headers.get('x-forwarded-for') || 'unknown';
  const now = Date.now();

  const record = rateLimit.get(ip);

  if (!record || now > record.resetTime) {
    rateLimit.set(ip, { count: 1, resetTime: now + WINDOW_MS });
    return NextResponse.next();
  }

  if (record.count >= MAX_REQUESTS) {
    return NextResponse.json(
      { error: 'Too many requests' },
      {
        status: 429,
        headers: {
          'Retry-After': String(Math.ceil((record.resetTime - now) / 1000)),
        },
      }
    );
  }

  record.count++;
  return NextResponse.next();
}

export const config = {
  matcher: '/api/:path*',
};
```

### Geolocation-Based Routing
```tsx
// middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const EU_COUNTRIES = ['DE', 'FR', 'IT', 'ES', 'NL', 'BE', 'AT', 'PL'];

export function middleware(request: NextRequest) {
  const country = request.geo?.country || 'US';

  // Redirect EU users to EU-specific pages
  if (EU_COUNTRIES.includes(country)) {
    if (request.nextUrl.pathname === '/pricing') {
      return NextResponse.rewrite(new URL('/pricing/eu', request.url));
    }

    if (request.nextUrl.pathname === '/privacy') {
      return NextResponse.rewrite(new URL('/privacy/gdpr', request.url));
    }
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/pricing', '/privacy'],
};
```
