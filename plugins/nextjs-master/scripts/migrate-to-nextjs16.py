#!/usr/bin/env python3
"""
Migration helper for Next.js 16 breaking changes.

Focuses on the async params migration which is the primary breaking change.

Usage:
    python migrate-to-nextjs16.py --path ./my-nextjs-app --dry-run
    python migrate-to-nextjs16.py --path ./my-nextjs-app --apply
    python migrate-to-nextjs16.py --path ./my-nextjs-app --check
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import json


# Patterns to detect and migrate
LEGACY_PARAMS_PATTERNS = [
    # page.tsx: params: { slug: string }
    (
        r'params:\s*\{\s*(\w+):\s*string\s*\}',
        r'params: Promise<{ \1: string }>',
        'params type'
    ),
    # Multiple params: { slug: string; id: string }
    (
        r'params:\s*\{\s*(\w+):\s*string;\s*(\w+):\s*string\s*\}',
        r'params: Promise<{ \1: string; \2: string }>',
        'params type (multiple)'
    ),
    # searchParams: { [key: string]: string | string[] | undefined }
    (
        r'searchParams:\s*\{\s*\[key:\s*string\]:\s*string\s*\|\s*string\[\]\s*\|\s*undefined\s*\}',
        r'searchParams: Promise<{ [key: string]: string | string[] | undefined }>',
        'searchParams type'
    ),
]

# Files to analyze
TARGET_FILES = ['page.tsx', 'page.ts', 'layout.tsx', 'layout.ts', 'route.ts', 'route.tsx']


class MigrationFile:
    """Represents a file that needs migration."""

    def __init__(self, path: Path, original: str, migrated: str, changes: List[str]):
        self.path = path
        self.original = original
        self.migrated = migrated
        self.changes = changes


def detect_params_pattern(content: str) -> List[Tuple[str, str, str]]:
    """Detect legacy params patterns that need migration."""
    issues = []

    # Check for synchronous params access
    if 'params.' in content and 'await params' not in content:
        # Look for direct destructuring or access
        if re.search(r'const\s*\{\s*\w+\s*\}\s*=\s*params', content):
            issues.append((
                'synchronous_destructure',
                'Direct params destructuring without await',
                'Add await: const { slug } = await params'
            ))
        elif re.search(r'params\.\w+', content):
            issues.append((
                'synchronous_access',
                'Direct params property access without await',
                'First await params: const { prop } = await params'
            ))

    # Check for synchronous searchParams access
    if 'searchParams.' in content and 'await searchParams' not in content:
        if re.search(r'searchParams\.\w+', content) or re.search(r'searchParams\.get', content):
            issues.append((
                'synchronous_searchParams',
                'Direct searchParams access without await',
                'First await searchParams: const params = await searchParams'
            ))

    # Check type definitions
    for pattern, _, desc in LEGACY_PARAMS_PATTERNS:
        if re.search(pattern, content):
            issues.append((
                'type_definition',
                f'Legacy {desc} definition',
                f'Update type to use Promise<...>'
            ))

    return issues


def migrate_file_content(content: str) -> Tuple[str, List[str]]:
    """Migrate file content to Next.js 16 patterns."""
    changes = []
    migrated = content

    # Migrate type definitions
    for pattern, replacement, desc in LEGACY_PARAMS_PATTERNS:
        if re.search(pattern, migrated):
            migrated = re.sub(pattern, replacement, migrated)
            changes.append(f"Updated {desc} to Promise pattern")

    # Migrate synchronous params destructuring to await
    # Pattern: const { slug } = params;
    params_destruct = re.search(
        r'(const\s*\{[^}]+\}\s*=\s*)params(\s*[;\n])',
        migrated
    )
    if params_destruct and 'await params' not in migrated:
        migrated = re.sub(
            r'(const\s*\{[^}]+\}\s*=\s*)params(\s*[;\n])',
            r'\1await params\2',
            migrated
        )
        changes.append("Added await to params destructuring")

    # Migrate synchronous searchParams destructuring
    searchParams_destruct = re.search(
        r'(const\s*\{[^}]+\}\s*=\s*)searchParams(\s*[;\n])',
        migrated
    )
    if searchParams_destruct and 'await searchParams' not in migrated:
        migrated = re.sub(
            r'(const\s*\{[^}]+\}\s*=\s*)searchParams(\s*[;\n])',
            r'\1await searchParams\2',
            migrated
        )
        changes.append("Added await to searchParams destructuring")

    # Ensure async function if we added await
    if 'await params' in migrated or 'await searchParams' in migrated:
        # Check for non-async function declarations
        if re.search(r'export\s+default\s+function\s+\w+', migrated) and \
           not re.search(r'export\s+default\s+async\s+function', migrated):
            migrated = re.sub(
                r'export\s+default\s+function\s+(\w+)',
                r'export default async function \1',
                migrated
            )
            changes.append("Made default export function async")

        # Check generateMetadata
        if re.search(r'export\s+function\s+generateMetadata', migrated) and \
           not re.search(r'export\s+async\s+function\s+generateMetadata', migrated):
            migrated = re.sub(
                r'export\s+function\s+generateMetadata',
                r'export async function generateMetadata',
                migrated
            )
            changes.append("Made generateMetadata async")

    return migrated, changes


def analyze_project(project_path: Path) -> List[MigrationFile]:
    """Analyze project for files needing migration."""
    app_dir = project_path / 'app'
    if not app_dir.exists():
        print(f"No app directory found at {project_path}")
        return []

    files_to_migrate = []

    for file_path in app_dir.rglob('*'):
        if file_path.name not in TARGET_FILES:
            continue

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
        except IOError as e:
            print(f"Warning: Could not read {file_path}: {e}")
            continue

        issues = detect_params_pattern(content)
        if not issues:
            continue

        migrated, changes = migrate_file_content(content)

        if changes:
            files_to_migrate.append(MigrationFile(
                path=file_path,
                original=content,
                migrated=migrated,
                changes=changes
            ))

    return files_to_migrate


def print_check_report(files: List[MigrationFile], project_path: Path):
    """Print check report without making changes."""
    print("\n" + "=" * 70)
    print("NEXT.JS 16 MIGRATION CHECK")
    print("=" * 70)

    if not files:
        print("\nNo files need migration. Your project is ready for Next.js 16!")
        return

    print(f"\nFound {len(files)} file(s) that need migration:\n")

    for i, file in enumerate(files, 1):
        rel_path = file.path.relative_to(project_path)
        print(f"{i}. {rel_path}")
        for change in file.changes:
            print(f"   - {change}")
        print()

    print("-" * 70)
    print("Run with --dry-run to see proposed changes")
    print("Run with --apply to apply migrations")
    print("=" * 70 + "\n")


def print_dry_run_report(files: List[MigrationFile], project_path: Path):
    """Print detailed dry run report with diffs."""
    print("\n" + "=" * 70)
    print("NEXT.JS 16 MIGRATION - DRY RUN")
    print("=" * 70)

    if not files:
        print("\nNo files need migration.")
        return

    for file in files:
        rel_path = file.path.relative_to(project_path)
        print(f"\n{'─' * 70}")
        print(f"File: {rel_path}")
        print(f"Changes: {', '.join(file.changes)}")
        print("─" * 70)

        # Show simple diff
        original_lines = file.original.split('\n')
        migrated_lines = file.migrated.split('\n')

        for i, (orig, new) in enumerate(zip(original_lines, migrated_lines), 1):
            if orig != new:
                print(f"Line {i}:")
                print(f"  - {orig.strip()}")
                print(f"  + {new.strip()}")

    print("\n" + "=" * 70)
    print(f"Total files to migrate: {len(files)}")
    print("Run with --apply to apply these changes")
    print("=" * 70 + "\n")


def apply_migrations(files: List[MigrationFile], project_path: Path) -> int:
    """Apply migrations to files."""
    applied = 0
    errors = []

    for file in files:
        try:
            with open(file.path, 'w', encoding='utf-8') as f:
                f.write(file.migrated)
            applied += 1
            rel_path = file.path.relative_to(project_path)
            print(f"✓ Migrated: {rel_path}")
            for change in file.changes:
                print(f"  - {change}")
        except IOError as e:
            rel_path = file.path.relative_to(project_path)
            errors.append(f"{rel_path}: {e}")

    print(f"\nMigrated {applied}/{len(files)} file(s)")

    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"  ✗ {error}")

    return applied


def generate_codemod_command(project_path: Path) -> str:
    """Generate the official codemod command."""
    return f"npx @next/codemod@canary next-async-request-api {project_path}"


def main():
    parser = argparse.ArgumentParser(
        description="Migration helper for Next.js 16 async params breaking change."
    )
    parser.add_argument(
        "--path",
        "-p",
        default=".",
        help="Path to Next.js project (default: current directory)",
    )
    parser.add_argument(
        "--check",
        "-c",
        action="store_true",
        help="Check which files need migration (no changes)",
    )
    parser.add_argument(
        "--dry-run",
        "-d",
        action="store_true",
        help="Show proposed changes without applying them",
    )
    parser.add_argument(
        "--apply",
        "-a",
        action="store_true",
        help="Apply migrations to files",
    )
    parser.add_argument(
        "--json",
        "-j",
        action="store_true",
        help="Output results as JSON",
    )

    args = parser.parse_args()
    project_path = Path(args.path).resolve()

    if not project_path.exists():
        print(f"Error: Path does not exist: {project_path}")
        return 1

    # Check for package.json
    if not (project_path / "package.json").exists():
        print(f"Warning: No package.json found at {project_path}")

    print(f"Analyzing project at: {project_path}")

    files = analyze_project(project_path)

    if args.json:
        result = {
            "project_path": str(project_path),
            "files_to_migrate": len(files),
            "files": [
                {
                    "path": str(f.path.relative_to(project_path)),
                    "changes": f.changes
                }
                for f in files
            ],
            "codemod_command": generate_codemod_command(project_path)
        }
        print(json.dumps(result, indent=2))
        return 0

    if args.apply:
        if not files:
            print("No files need migration.")
            return 0
        print(f"\nApplying migrations to {len(files)} file(s)...\n")
        apply_migrations(files, project_path)
    elif args.dry_run:
        print_dry_run_report(files, project_path)
    else:  # --check or default
        print_check_report(files, project_path)

    # Always show the official codemod option
    if files:
        print("\nAlternatively, use the official codemod:")
        print(f"  {generate_codemod_command(project_path)}")
        print()

    return 0


if __name__ == "__main__":
    exit(main())
