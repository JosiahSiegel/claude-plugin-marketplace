#!/usr/bin/env python3
"""
Generate Next.js components with proper structure and patterns.

Usage:
    python generate-nextjs-component.py page --path app/dashboard --name DashboardPage
    python generate-nextjs-component.py layout --path app/dashboard
    python generate-nextjs-component.py action --path app/actions --name createPost
    python generate-nextjs-component.py route --path app/api/posts --methods GET,POST
"""

import argparse
from pathlib import Path
from datetime import datetime


# Templates for different component types
TEMPLATES = {
    "page_static": '''import type {{ Metadata }} from 'next';

export const metadata: Metadata = {{
  title: '{title}',
  description: '{description}',
}};

export default function {name}() {{
  return (
    <div>
      <h1>{title}</h1>
      <p>Content here...</p>
    </div>
  );
}}
''',

    "page_dynamic": '''import {{ notFound }} from 'next/navigation';
import type {{ Metadata }} from 'next';

interface PageProps {{
  params: Promise<{{ {param}: string }}>;
  searchParams: Promise<{{ [key: string]: string | string[] | undefined }}>;
}}

export async function generateMetadata({{ params }}: PageProps): Promise<Metadata> {{
  const {{ {param} }} = await params;
  // Fetch data for metadata
  // const data = await getData({param});

  return {{
    title: `${{ {param} }}`,
    description: `Page for ${{ {param} }}`,
  }};
}}

export async function generateStaticParams() {{
  // Return array of params for static generation
  // const items = await getItems();
  // return items.map((item) => ({{ {param}: item.{param} }}));
  return [];
}}

export default async function {name}({{ params, searchParams }}: PageProps) {{
  const {{ {param} }} = await params;
  const query = await searchParams;

  // Fetch data
  // const data = await getData({param});

  // if (!data) {{
  //   notFound();
  // }}

  return (
    <div>
      <h1>Page: {{{param}}}</h1>
      <p>Dynamic route content</p>
    </div>
  );
}}
''',

    "page_cached": ''''use cache'

import {{ cacheLife, cacheTag }} from 'next/cache';
import type {{ Metadata }} from 'next';

export const metadata: Metadata = {{
  title: '{title}',
  description: '{description}',
}};

export default async function {name}() {{
  cacheLife('hours');
  cacheTag('{cache_tag}');

  // Fetch data (will be cached)
  // const data = await fetchData();

  return (
    <div>
      <h1>{title}</h1>
      <p>Cached content here...</p>
    </div>
  );
}}
''',

    "loading": '''export default function Loading() {{
  return (
    <div className="animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-3/4 mb-4" />
      <div className="h-4 bg-gray-200 rounded w-full mb-2" />
      <div className="h-4 bg-gray-200 rounded w-5/6 mb-2" />
      <div className="h-4 bg-gray-200 rounded w-4/5" />
    </div>
  );
}}
''',

    "error": ''''use client';

export default function Error({{
  error,
  reset,
}}: {{
  error: Error & {{ digest?: string }};
  reset: () => void;
}}) {{
  return (
    <div className="flex flex-col items-center justify-center min-h-[400px]">
      <h2 className="text-xl font-semibold mb-4">Something went wrong!</h2>
      <p className="text-gray-600 mb-4">{{error.message}}</p>
      <button
        onClick={{() => reset()}}
        className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600"
      >
        Try again
      </button>
    </div>
  );
}}
''',

    "layout": '''import type {{ Metadata }} from 'next';

export const metadata: Metadata = {{
  title: {{
    template: '%s | {title}',
    default: '{title}',
  }},
  description: '{description}',
}};

export default function {name}({{
  children,
}}: {{
  children: React.ReactNode;
}}) {{
  return (
    <div className="min-h-screen">
      {{/* Add layout-specific UI here */}}
      {{children}}
    </div>
  );
}}
''',

    "action_basic": ''''use server';

import {{ revalidatePath }} from 'next/cache';
import {{ redirect }} from 'next/navigation';
import {{ z }} from 'zod';

const {schema_name} = z.object({{
  // Define your schema
  name: z.string().min(1, 'Name is required'),
}});

export type {state_type} = {{
  errors?: {{
    name?: string[];
  }};
  message?: string;
  success?: boolean;
}};

export async function {name}(
  prevState: {state_type},
  formData: FormData
): Promise<{state_type}> {{
  // Validate input
  const validatedFields = {schema_name}.safeParse({{
    name: formData.get('name'),
  }});

  if (!validatedFields.success) {{
    return {{
      errors: validatedFields.error.flatten().fieldErrors,
      message: 'Validation failed',
    }};
  }}

  try {{
    // Perform action
    // await db.items.create({{ data: validatedFields.data }});

    console.log('Action executed:', validatedFields.data);
  }} catch (error) {{
    return {{
      message: 'Failed to execute action',
    }};
  }}

  // Revalidate and redirect
  revalidatePath('/');
  // redirect('/success');

  return {{ success: true, message: 'Action completed successfully' }};
}}
''',

    "action_safe": ''''use server';

import {{ z }} from 'zod';
import {{ actionClient }} from '@/lib/safe-action';
import {{ revalidatePath }} from 'next/cache';

const {schema_name} = z.object({{
  name: z.string().min(1, 'Name is required'),
}});

export const {name} = actionClient
  .schema({schema_name})
  .action(async ({{ parsedInput }}) => {{
    const {{ name }} = parsedInput;

    try {{
      // Perform action
      // const result = await db.items.create({{ data: {{ name }} }});

      revalidatePath('/');
      return {{ success: true, message: 'Action completed' }};
    }} catch (error) {{
      throw new Error('Failed to execute action');
    }}
  }});
''',

    "route_handler": '''import {{ NextResponse }} from 'next/server';
{auth_import}
{zod_import}

{schema}

{get_handler}
{post_handler}
{put_handler}
{delete_handler}
''',

    "route_get": '''export async function GET(request: Request) {{
  try {{
    const {{ searchParams }} = new URL(request.url);
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
{auth_check}
    // Fetch data
    // const items = await db.items.findMany({{
    //   skip: (page - 1) * limit,
    //   take: limit,
    // }});

    const items = []; // Replace with actual data

    return NextResponse.json({{
      data: items,
      pagination: {{ page, limit }},
    }});
  }} catch (error) {{
    console.error('GET error:', error);
    return NextResponse.json(
      {{ error: 'Failed to fetch data' }},
      {{ status: 500 }}
    );
  }}
}}
''',

    "route_post": '''export async function POST(request: Request) {{
  try {{
{auth_check}
    const body = await request.json();
{validation}
    // Create item
    // const item = await db.items.create({{ data: validatedData }});

    return NextResponse.json({{ success: true }}, {{ status: 201 }});
  }} catch (error) {{
    if (error instanceof z.ZodError) {{
      return NextResponse.json(
        {{ error: 'Validation failed', details: error.errors }},
        {{ status: 400 }}
      );
    }}
    console.error('POST error:', error);
    return NextResponse.json(
      {{ error: 'Failed to create item' }},
      {{ status: 500 }}
    );
  }}
}}
''',

    "route_put": '''export async function PUT(request: Request) {{
  try {{
{auth_check}
    const body = await request.json();
    const {{ id, ...data }} = body;

    if (!id) {{
      return NextResponse.json(
        {{ error: 'ID is required' }},
        {{ status: 400 }}
      );
    }}

    // Update item
    // const item = await db.items.update({{
    //   where: {{ id }},
    //   data,
    // }});

    return NextResponse.json({{ success: true }});
  }} catch (error) {{
    console.error('PUT error:', error);
    return NextResponse.json(
      {{ error: 'Failed to update item' }},
      {{ status: 500 }}
    );
  }}
}}
''',

    "route_delete": '''export async function DELETE(request: Request) {{
  try {{
{auth_check}
    const {{ searchParams }} = new URL(request.url);
    const id = searchParams.get('id');

    if (!id) {{
      return NextResponse.json(
        {{ error: 'ID is required' }},
        {{ status: 400 }}
      );
    }}

    // Delete item
    // await db.items.delete({{ where: {{ id }} }});

    return new NextResponse(null, {{ status: 204 }});
  }} catch (error) {{
    console.error('DELETE error:', error);
    return NextResponse.json(
      {{ error: 'Failed to delete item' }},
      {{ status: 500 }}
    );
  }}
}}
''',

    "middleware": '''import {{ NextResponse }} from 'next/server';
import type {{ NextRequest }} from 'next/server';

export function middleware(request: NextRequest) {{
  const {{ pathname }} = request.nextUrl;

  // Add your middleware logic here

  return NextResponse.next();
}}

export const config = {{
  matcher: [
    // Match all paths except static files
    '/((?!_next/static|_next/image|favicon.ico).*)',
  ],
}};
''',

    "client_component": ''''use client';

import {{ useState }} from 'react';

interface {name}Props {{
  // Define props
}}

export function {name}({{ }}: {name}Props) {{
  const [state, setState] = useState<string>('');

  return (
    <div>
      <h2>{title}</h2>
      {{/* Component content */}}
    </div>
  );
}}
''',
}


def to_pascal_case(s: str) -> str:
    """Convert string to PascalCase."""
    return ''.join(word.capitalize() for word in s.replace('-', '_').split('_'))


def to_camel_case(s: str) -> str:
    """Convert string to camelCase."""
    pascal = to_pascal_case(s)
    return pascal[0].lower() + pascal[1:] if pascal else ''


def generate_page(args):
    """Generate a page component."""
    path = Path(args.path)
    name = args.name or to_pascal_case(path.name) + 'Page'
    title = args.title or path.name.replace('-', ' ').title()
    description = args.description or f'{title} page'

    # Determine if dynamic route
    is_dynamic = '[' in str(path)
    param = None
    if is_dynamic:
        # Extract param name from path like [slug] or [id]
        import re
        match = re.search(r'\[(\w+)\]', str(path))
        param = match.group(1) if match else 'id'

    if args.cached:
        template = TEMPLATES['page_cached']
        content = template.format(
            name=name,
            title=title,
            description=description,
            cache_tag=path.name.replace('-', '_')
        )
    elif is_dynamic:
        template = TEMPLATES['page_dynamic']
        content = template.format(
            name=name,
            param=param
        )
    else:
        template = TEMPLATES['page_static']
        content = template.format(
            name=name,
            title=title,
            description=description
        )

    # Write files
    path.mkdir(parents=True, exist_ok=True)

    page_file = path / 'page.tsx'
    page_file.write_text(content, encoding='utf-8')
    print(f"Created: {page_file}")

    if args.with_loading:
        loading_file = path / 'loading.tsx'
        loading_file.write_text(TEMPLATES['loading'], encoding='utf-8')
        print(f"Created: {loading_file}")

    if args.with_error:
        error_file = path / 'error.tsx'
        error_file.write_text(TEMPLATES['error'], encoding='utf-8')
        print(f"Created: {error_file}")


def generate_layout(args):
    """Generate a layout component."""
    path = Path(args.path)
    name = args.name or to_pascal_case(path.name) + 'Layout'
    title = args.title or path.name.replace('-', ' ').title()
    description = args.description or f'{title} section'

    content = TEMPLATES['layout'].format(
        name=name,
        title=title,
        description=description
    )

    path.mkdir(parents=True, exist_ok=True)
    layout_file = path / 'layout.tsx'
    layout_file.write_text(content, encoding='utf-8')
    print(f"Created: {layout_file}")


def generate_action(args):
    """Generate a Server Action."""
    path = Path(args.path)
    name = args.name or 'performAction'
    schema_name = to_pascal_case(name) + 'Schema'
    state_type = to_pascal_case(name) + 'State'

    if args.safe_action:
        content = TEMPLATES['action_safe'].format(
            name=name,
            schema_name=schema_name
        )
    else:
        content = TEMPLATES['action_basic'].format(
            name=name,
            schema_name=schema_name,
            state_type=state_type
        )

    path.mkdir(parents=True, exist_ok=True)

    # Determine filename
    if 'actions' in str(path).lower():
        action_file = path / f'{to_camel_case(name)}.ts'
    else:
        action_file = path / 'actions.ts'

    action_file.write_text(content, encoding='utf-8')
    print(f"Created: {action_file}")


def generate_route(args):
    """Generate a Route Handler."""
    path = Path(args.path)
    methods = [m.strip().upper() for m in args.methods.split(',')]

    # Build components
    auth_import = "import { auth } from '@/auth';" if args.with_auth else ''
    zod_import = "import { z } from 'zod';" if 'POST' in methods or 'PUT' in methods else ''

    schema = '''const ItemSchema = z.object({
  name: z.string().min(1),
  // Add more fields
});
''' if zod_import else ''

    auth_check = '''
    const session = await auth();
    if (!session) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }
''' if args.with_auth else ''

    validation = '''    const validatedData = ItemSchema.parse(body);
''' if zod_import else ''

    # Build handlers
    get_handler = TEMPLATES['route_get'].format(auth_check=auth_check) if 'GET' in methods else ''
    post_handler = TEMPLATES['route_post'].format(
        auth_check=auth_check,
        validation=validation
    ) if 'POST' in methods else ''
    put_handler = TEMPLATES['route_put'].format(auth_check=auth_check) if 'PUT' in methods else ''
    delete_handler = TEMPLATES['route_delete'].format(auth_check=auth_check) if 'DELETE' in methods else ''

    content = TEMPLATES['route_handler'].format(
        auth_import=auth_import,
        zod_import=zod_import,
        schema=schema,
        get_handler=get_handler,
        post_handler=post_handler,
        put_handler=put_handler,
        delete_handler=delete_handler
    )

    path.mkdir(parents=True, exist_ok=True)
    route_file = path / 'route.ts'
    route_file.write_text(content, encoding='utf-8')
    print(f"Created: {route_file}")


def generate_middleware(args):
    """Generate middleware."""
    path = Path(args.path) if args.path != '.' else Path('.')

    content = TEMPLATES['middleware']

    middleware_file = path / 'middleware.ts'
    middleware_file.write_text(content, encoding='utf-8')
    print(f"Created: {middleware_file}")


def generate_component(args):
    """Generate a client component."""
    path = Path(args.path)
    name = args.name or to_pascal_case(path.name)
    title = args.title or name

    content = TEMPLATES['client_component'].format(
        name=name,
        title=title
    )

    path.mkdir(parents=True, exist_ok=True)
    component_file = path / f'{name}.tsx'
    component_file.write_text(content, encoding='utf-8')
    print(f"Created: {component_file}")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Next.js components with proper structure."
    )
    subparsers = parser.add_subparsers(dest='command', help='Component type to generate')

    # Page parser
    page_parser = subparsers.add_parser('page', help='Generate a page component')
    page_parser.add_argument('--path', '-p', required=True, help='Path to page directory')
    page_parser.add_argument('--name', '-n', help='Component name')
    page_parser.add_argument('--title', '-t', help='Page title')
    page_parser.add_argument('--description', '-d', help='Page description')
    page_parser.add_argument('--cached', action='store_true', help='Use cache directive')
    page_parser.add_argument('--with-loading', action='store_true', help='Include loading.tsx')
    page_parser.add_argument('--with-error', action='store_true', help='Include error.tsx')

    # Layout parser
    layout_parser = subparsers.add_parser('layout', help='Generate a layout component')
    layout_parser.add_argument('--path', '-p', required=True, help='Path to layout directory')
    layout_parser.add_argument('--name', '-n', help='Component name')
    layout_parser.add_argument('--title', '-t', help='Layout title')
    layout_parser.add_argument('--description', '-d', help='Layout description')

    # Action parser
    action_parser = subparsers.add_parser('action', help='Generate a Server Action')
    action_parser.add_argument('--path', '-p', required=True, help='Path to actions directory')
    action_parser.add_argument('--name', '-n', help='Action function name')
    action_parser.add_argument('--safe-action', action='store_true', help='Use next-safe-action pattern')

    # Route parser
    route_parser = subparsers.add_parser('route', help='Generate a Route Handler')
    route_parser.add_argument('--path', '-p', required=True, help='Path to route directory')
    route_parser.add_argument('--methods', '-m', default='GET', help='HTTP methods (comma-separated)')
    route_parser.add_argument('--with-auth', action='store_true', help='Include authentication')

    # Middleware parser
    middleware_parser = subparsers.add_parser('middleware', help='Generate middleware')
    middleware_parser.add_argument('--path', '-p', default='.', help='Path to project root')

    # Component parser
    component_parser = subparsers.add_parser('component', help='Generate a client component')
    component_parser.add_argument('--path', '-p', required=True, help='Path to component directory')
    component_parser.add_argument('--name', '-n', help='Component name')
    component_parser.add_argument('--title', '-t', help='Component title')

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return

    generators = {
        'page': generate_page,
        'layout': generate_layout,
        'action': generate_action,
        'route': generate_route,
        'middleware': generate_middleware,
        'component': generate_component,
    }

    generator = generators.get(args.command)
    if generator:
        generator(args)
    else:
        print(f"Unknown command: {args.command}")


if __name__ == '__main__':
    main()
