#!/usr/bin/env python3
"""
Analyze Next.js project structure and provide optimization suggestions.

Usage:
    python nextjs-analyzer.py --path ./my-nextjs-app
    python nextjs-analyzer.py --path ./my-nextjs-app --report json
    python nextjs-analyzer.py --path ./my-nextjs-app --check-version
"""

import argparse
import json
import os
import re
from pathlib import Path
from typing import Dict, List, Any, Optional

# File patterns to analyze
PATTERNS = {
    "pages": ["page.tsx", "page.ts", "page.jsx", "page.js"],
    "layouts": ["layout.tsx", "layout.ts", "layout.jsx", "layout.js"],
    "loading": ["loading.tsx", "loading.ts", "loading.jsx", "loading.js"],
    "error": ["error.tsx", "error.ts", "error.jsx", "error.js"],
    "route": ["route.tsx", "route.ts", "route.jsx", "route.js"],
    "middleware": ["middleware.ts", "middleware.js"],
    "proxy": ["proxy.ts", "proxy.js"],
}


def find_next_config(project_path: Path) -> Optional[Path]:
    """Find Next.js config file."""
    config_names = [
        "next.config.ts",
        "next.config.mjs",
        "next.config.js",
        "next.config.cjs",
    ]
    for name in config_names:
        config_path = project_path / name
        if config_path.exists():
            return config_path
    return None


def get_next_version(project_path: Path) -> Optional[str]:
    """Get Next.js version from package.json."""
    package_json = project_path / "package.json"
    if not package_json.exists():
        return None

    try:
        with open(package_json, "r", encoding="utf-8") as f:
            data = json.load(f)
            deps = data.get("dependencies", {})
            dev_deps = data.get("devDependencies", {})
            return deps.get("next") or dev_deps.get("next")
    except (json.JSONDecodeError, IOError):
        return None


def analyze_file_patterns(project_path: Path) -> Dict[str, List[str]]:
    """Analyze App Router file patterns."""
    app_dir = project_path / "app"
    if not app_dir.exists():
        return {"error": "No app directory found - not an App Router project"}

    results = {
        "pages": [],
        "layouts": [],
        "loading_states": [],
        "error_boundaries": [],
        "api_routes": [],
        "dynamic_routes": [],
        "parallel_routes": [],
        "intercepting_routes": [],
        "route_groups": [],
    }

    for root, dirs, files in os.walk(app_dir):
        rel_path = Path(root).relative_to(app_dir)
        path_str = str(rel_path) if str(rel_path) != "." else ""

        # Check for special route patterns
        dir_name = Path(root).name

        # Parallel routes (@folder)
        if dir_name.startswith("@"):
            results["parallel_routes"].append(path_str)

        # Intercepting routes
        if dir_name.startswith("(.)") or dir_name.startswith("(..)"):
            results["intercepting_routes"].append(path_str)

        # Route groups
        if dir_name.startswith("(") and not dir_name.startswith("(."):
            results["route_groups"].append(path_str)

        # Dynamic routes
        if "[" in dir_name:
            results["dynamic_routes"].append(path_str)

        for file in files:
            file_path = f"{path_str}/{file}" if path_str else file

            if file in PATTERNS["pages"]:
                results["pages"].append(file_path)
            elif file in PATTERNS["layouts"]:
                results["layouts"].append(file_path)
            elif file in PATTERNS["loading"]:
                results["loading_states"].append(file_path)
            elif file in PATTERNS["error"]:
                results["error_boundaries"].append(file_path)
            elif file in PATTERNS["route"]:
                if "api" in path_str.lower():
                    results["api_routes"].append(file_path)

    return results


def check_client_components(project_path: Path) -> Dict[str, Any]:
    """Analyze 'use client' directive usage."""
    app_dir = project_path / "app"
    if not app_dir.exists():
        return {"error": "No app directory found"}

    client_components = []
    server_components = []

    tsx_files = list(app_dir.rglob("*.tsx")) + list(app_dir.rglob("*.jsx"))

    for file_path in tsx_files:
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read(500)  # Read first 500 chars
                rel_path = str(file_path.relative_to(project_path))

                if "'use client'" in content or '"use client"' in content:
                    client_components.append(rel_path)
                else:
                    server_components.append(rel_path)
        except IOError:
            continue

    return {
        "client_components": client_components,
        "server_components": server_components,
        "client_ratio": len(client_components) / max(len(tsx_files), 1) * 100,
    }


def check_caching_patterns(project_path: Path) -> Dict[str, Any]:
    """Check for caching patterns and directives."""
    results = {
        "use_cache_files": [],
        "unstable_cache_files": [],
        "revalidate_calls": [],
        "cache_tags": [],
        "issues": [],
    }

    app_dir = project_path / "app"
    lib_dir = project_path / "lib"
    src_dir = project_path / "src"

    search_dirs = [d for d in [app_dir, lib_dir, src_dir] if d.exists()]

    for search_dir in search_dirs:
        for ext in ["*.ts", "*.tsx", "*.js", "*.jsx"]:
            for file_path in search_dir.rglob(ext):
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()
                        rel_path = str(file_path.relative_to(project_path))

                        # Check for 'use cache' directive (Next.js 16)
                        if "'use cache'" in content or '"use cache"' in content:
                            results["use_cache_files"].append(rel_path)

                        # Check for deprecated unstable_cache
                        if "unstable_cache" in content:
                            results["unstable_cache_files"].append(rel_path)
                            results["issues"].append(
                                f"{rel_path}: Uses deprecated unstable_cache - migrate to 'use cache'"
                            )

                        # Check for revalidation
                        if "revalidatePath" in content or "revalidateTag" in content:
                            results["revalidate_calls"].append(rel_path)

                        # Check for cache tags
                        cache_tag_matches = re.findall(r"cacheTag\(['\"]([^'\"]+)['\"]\)", content)
                        results["cache_tags"].extend(cache_tag_matches)

                except IOError:
                    continue

    results["cache_tags"] = list(set(results["cache_tags"]))
    return results


def check_async_params(project_path: Path) -> Dict[str, Any]:
    """Check for async params pattern (Next.js 16 requirement)."""
    results = {
        "correct_pattern": [],
        "legacy_pattern": [],
        "needs_migration": [],
    }

    app_dir = project_path / "app"
    if not app_dir.exists():
        return results

    for file_path in app_dir.rglob("*.tsx"):
        if not any(p in str(file_path) for p in ["page.tsx", "layout.tsx", "route.ts"]):
            continue

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                rel_path = str(file_path.relative_to(project_path))

                # Check for Promise<{ params pattern (correct)
                if "params: Promise<" in content:
                    results["correct_pattern"].append(rel_path)
                # Check for legacy { params } pattern
                elif re.search(r"params:\s*\{\s*\w+:", content):
                    results["legacy_pattern"].append(rel_path)
                    results["needs_migration"].append(rel_path)

        except IOError:
            continue

    return results


def check_server_actions(project_path: Path) -> Dict[str, Any]:
    """Analyze Server Actions usage."""
    results = {
        "action_files": [],
        "inline_actions": [],
        "uses_zod": False,
        "uses_safe_action": False,
        "issues": [],
    }

    app_dir = project_path / "app"
    lib_dir = project_path / "lib"
    search_dirs = [d for d in [app_dir, lib_dir] if d.exists()]

    for search_dir in search_dirs:
        for ext in ["*.ts", "*.tsx"]:
            for file_path in search_dir.rglob(ext):
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        content = f.read()
                        rel_path = str(file_path.relative_to(project_path))

                        if "'use server'" in content or '"use server"' in content:
                            if "actions" in rel_path.lower():
                                results["action_files"].append(rel_path)
                            else:
                                results["inline_actions"].append(rel_path)

                        if "from 'zod'" in content or 'from "zod"' in content:
                            results["uses_zod"] = True

                        if "next-safe-action" in content:
                            results["uses_safe_action"] = True

                except IOError:
                    continue

    if not results["uses_zod"] and results["action_files"]:
        results["issues"].append(
            "Consider adding Zod for Server Action validation"
        )

    if not results["uses_safe_action"] and len(results["action_files"]) > 3:
        results["issues"].append(
            "Consider using next-safe-action for type-safe Server Actions"
        )

    return results


def generate_suggestions(analysis: Dict[str, Any]) -> List[str]:
    """Generate optimization suggestions based on analysis."""
    suggestions = []

    # Check loading states coverage
    pages_count = len(analysis.get("file_patterns", {}).get("pages", []))
    loading_count = len(analysis.get("file_patterns", {}).get("loading_states", []))

    if pages_count > 0 and loading_count / pages_count < 0.5:
        suggestions.append(
            f"Add loading.tsx files - only {loading_count}/{pages_count} pages have loading states"
        )

    # Check error boundaries coverage
    error_count = len(analysis.get("file_patterns", {}).get("error_boundaries", []))
    if pages_count > 0 and error_count / pages_count < 0.3:
        suggestions.append(
            f"Add error.tsx boundaries - only {error_count}/{pages_count} pages have error handling"
        )

    # Check client component ratio
    client_ratio = analysis.get("client_components", {}).get("client_ratio", 0)
    if client_ratio > 50:
        suggestions.append(
            f"High client component ratio ({client_ratio:.1f}%) - consider moving logic to Server Components"
        )

    # Check caching
    caching = analysis.get("caching", {})
    if caching.get("unstable_cache_files"):
        suggestions.append(
            "Migrate unstable_cache to 'use cache' directive (Next.js 16+)"
        )

    # Check async params migration
    async_params = analysis.get("async_params", {})
    if async_params.get("needs_migration"):
        migration_count = len(async_params["needs_migration"])
        suggestions.append(
            f"Migrate {migration_count} file(s) to async params pattern (Next.js 16 requirement)"
        )

    # Version-specific suggestions
    version = analysis.get("version", "")
    if version:
        major_version = int(re.match(r"(\d+)", version.lstrip("^~")).group(1)) if re.match(r"(\d+)", version.lstrip("^~")) else 0
        if major_version < 15:
            suggestions.append(
                f"Consider upgrading from Next.js {version} to 16.x for Turbopack and Cache Components"
            )

    return suggestions


def analyze_project(project_path: str) -> Dict[str, Any]:
    """Run full analysis on a Next.js project."""
    path = Path(project_path)

    if not path.exists():
        return {"error": f"Path does not exist: {project_path}"}

    analysis = {
        "project_path": str(path.absolute()),
        "version": get_next_version(path),
        "config_file": str(find_next_config(path)) if find_next_config(path) else None,
        "file_patterns": analyze_file_patterns(path),
        "client_components": check_client_components(path),
        "caching": check_caching_patterns(path),
        "async_params": check_async_params(path),
        "server_actions": check_server_actions(path),
    }

    analysis["suggestions"] = generate_suggestions(analysis)

    return analysis


def print_text_report(analysis: Dict[str, Any]):
    """Print human-readable analysis report."""
    print("\n" + "=" * 70)
    print("NEXT.JS PROJECT ANALYSIS")
    print("=" * 70)

    print(f"\nProject: {analysis['project_path']}")
    print(f"Next.js Version: {analysis['version'] or 'Unknown'}")
    print(f"Config File: {analysis['config_file'] or 'Not found'}")

    # File patterns
    print("\n" + "-" * 70)
    print("FILE STRUCTURE")
    print("-" * 70)
    patterns = analysis.get("file_patterns", {})
    if isinstance(patterns, dict) and "error" not in patterns:
        print(f"  Pages: {len(patterns.get('pages', []))}")
        print(f"  Layouts: {len(patterns.get('layouts', []))}")
        print(f"  Loading States: {len(patterns.get('loading_states', []))}")
        print(f"  Error Boundaries: {len(patterns.get('error_boundaries', []))}")
        print(f"  API Routes: {len(patterns.get('api_routes', []))}")
        print(f"  Dynamic Routes: {len(patterns.get('dynamic_routes', []))}")
        print(f"  Parallel Routes: {len(patterns.get('parallel_routes', []))}")
        print(f"  Route Groups: {len(patterns.get('route_groups', []))}")

    # Component analysis
    print("\n" + "-" * 70)
    print("COMPONENT ANALYSIS")
    print("-" * 70)
    components = analysis.get("client_components", {})
    if "error" not in components:
        print(f"  Server Components: {len(components.get('server_components', []))}")
        print(f"  Client Components: {len(components.get('client_components', []))}")
        print(f"  Client Ratio: {components.get('client_ratio', 0):.1f}%")

    # Caching
    print("\n" + "-" * 70)
    print("CACHING")
    print("-" * 70)
    caching = analysis.get("caching", {})
    print(f"  'use cache' Files: {len(caching.get('use_cache_files', []))}")
    print(f"  unstable_cache (deprecated): {len(caching.get('unstable_cache_files', []))}")
    print(f"  Revalidation Calls: {len(caching.get('revalidate_calls', []))}")
    print(f"  Cache Tags: {len(caching.get('cache_tags', []))}")

    # Server Actions
    print("\n" + "-" * 70)
    print("SERVER ACTIONS")
    print("-" * 70)
    actions = analysis.get("server_actions", {})
    print(f"  Action Files: {len(actions.get('action_files', []))}")
    print(f"  Inline Actions: {len(actions.get('inline_actions', []))}")
    print(f"  Uses Zod: {'Yes' if actions.get('uses_zod') else 'No'}")
    print(f"  Uses next-safe-action: {'Yes' if actions.get('uses_safe_action') else 'No'}")

    # Async Params Check
    print("\n" + "-" * 70)
    print("ASYNC PARAMS (Next.js 16)")
    print("-" * 70)
    async_params = analysis.get("async_params", {})
    print(f"  Correct Pattern: {len(async_params.get('correct_pattern', []))}")
    print(f"  Legacy Pattern (needs migration): {len(async_params.get('legacy_pattern', []))}")

    # Suggestions
    print("\n" + "-" * 70)
    print("SUGGESTIONS")
    print("-" * 70)
    suggestions = analysis.get("suggestions", [])
    if suggestions:
        for i, suggestion in enumerate(suggestions, 1):
            print(f"  {i}. {suggestion}")
    else:
        print("  No suggestions - project looks good!")

    print("\n" + "=" * 70 + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze Next.js project structure and provide optimization suggestions."
    )
    parser.add_argument(
        "--path",
        "-p",
        default=".",
        help="Path to Next.js project (default: current directory)",
    )
    parser.add_argument(
        "--report",
        "-r",
        choices=["text", "json"],
        default="text",
        help="Output format (default: text)",
    )
    parser.add_argument(
        "--check-version",
        action="store_true",
        help="Only check Next.js version",
    )

    args = parser.parse_args()

    if args.check_version:
        version = get_next_version(Path(args.path))
        if version:
            print(f"Next.js version: {version}")
        else:
            print("Could not determine Next.js version")
        return

    analysis = analyze_project(args.path)

    if args.report == "json":
        print(json.dumps(analysis, indent=2))
    else:
        print_text_report(analysis)


if __name__ == "__main__":
    main()
