#!/usr/bin/env python3
"""
version_ops.py - Version tracking operations for Claude plugins
"""

import json
import sys
import os
import argparse
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
MARKETPLACE_JSON = REPO_ROOT / '.claude-plugin' / 'marketplace.json'
PLUGINS_DIR = REPO_ROOT / 'plugins'

class Colors:
    RED = '[0;31m'
    GREEN = '[0;32m'
    YELLOW = '[0;33m'
    BLUE = '[0;34m'
    BOLD = '[1m'
    NC = '[0m'
    
    @classmethod
    def disable(cls):
        cls.RED = cls.GREEN = cls.YELLOW = cls.BLUE = cls.BOLD = cls.NC = ''

def log_info(msg):
    print(f"{Colors.BLUE}[INFO]{Colors.NC} {msg}")

def log_success(msg):
    print(f"{Colors.GREEN}[OK]{Colors.NC} {msg}")

def log_warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}", file=sys.stderr)

def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}", file=sys.stderr)

def load_marketplace():
    with open(MARKETPLACE_JSON, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_marketplace(data):
    with open(MARKETPLACE_JSON, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write(chr(10))

def load_plugin_json(plugin_name):
    plugin_json = PLUGINS_DIR / plugin_name / '.claude-plugin' / 'plugin.json'
    if not plugin_json.exists():
        return None
    with open(plugin_json, 'r', encoding='utf-8') as f:
        return json.load(f)

def save_plugin_json(plugin_name, data):
    plugin_json = PLUGINS_DIR / plugin_name / '.claude-plugin' / 'plugin.json'
    with open(plugin_json, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write(chr(10))

def validate_versions(quiet=False, json_output=False):
    marketplace = load_marketplace()
    
    results = []
    match_count = 0
    mismatch_count = 0
    missing_count = 0
    
    for plugin in marketplace['plugins']:
        name = plugin['name']
        mp_version = plugin['version']
        
        plugin_data = load_plugin_json(name)
        if plugin_data is None:
            pj_version = 'NOT_FOUND'
            status = 'MISSING'
            missing_count += 1
        else:
            pj_version = plugin_data.get('version', 'NOT_FOUND')
            if mp_version == pj_version:
                status = 'MATCH'
                match_count += 1
            else:
                status = 'MISMATCH'
                mismatch_count += 1
        
        results.append({
            'plugin': name,
            'marketplace_version': mp_version,
            'plugin_json_version': pj_version,
            'status': status
        })
    
    if json_output:
        output = {
            'validation_results': results,
            'summary': {
                'total': len(results),
                'matching': match_count,
                'mismatched': mismatch_count,
                'missing': missing_count
            }
        }
        print(json.dumps(output, indent=2))
    else:
        log_info(f"Loaded {len(results)} plugins from marketplace.json")
        print()
        print(f"{Colors.BOLD}=== Plugin Version Validation ==={Colors.NC}")
        print()
        print(f"{'PLUGIN':<35} {'MARKETPLACE':<15} {'PLUGIN.JSON':<15} {'STATUS':<10}")
        print('-' * 80)
        
        for r in results:
            if quiet and r['status'] == 'MATCH':
                continue
            
            if r['status'] == 'MATCH':
                color = Colors.GREEN
            elif r['status'] == 'MISMATCH':
                color = Colors.RED
            else:
                color = Colors.YELLOW
            
            print(f"{r['plugin']:<35} {r['marketplace_version']:<15} {r['plugin_json_version']:<15} {color}{r['status']:<10}{Colors.NC}")
        
        print()
        print(f"{Colors.BOLD}=== Summary ==={Colors.NC}")
        print(f"Total plugins: {len(results)}")
        print(f"Matching:      {Colors.GREEN}{match_count}{Colors.NC}")
        print(f"Mismatched:    {Colors.RED}{mismatch_count}{Colors.NC}")
        print(f"Missing:       {Colors.YELLOW}{missing_count}{Colors.NC}")
        print()
    
    if mismatch_count > 0:
        return 1
    elif missing_count > 0:
        return 2
    return 0

def parse_version(version):
    """Parse version string into tuple for comparison."""
    if version.startswith('v'):
        version = version[1:]
    parts = version.split('.')
    return tuple(int(p) for p in parts[:3]) if parts else (0, 0, 0)

def compare_versions(v1, v2):
    """Compare two versions. Returns 1 if v1 > v2, -1 if v1 < v2, 0 if equal."""
    p1, p2 = parse_version(v1), parse_version(v2)
    if p1 > p2:
        return 1
    elif p1 < p2:
        return -1
    return 0

def sync_versions(dry_run=False):
    """Sync versions between marketplace.json and plugin.json files, using highest version."""
    marketplace = load_marketplace()

    print(f"{Colors.BOLD}=== Version Sync ==={Colors.NC}")
    print(f"{'PLUGIN':<35} {'MARKETPLACE':<12} {'PLUGIN.JSON':<12} {'ACTION':<30}")
    print('-' * 95)

    synced_count = 0

    for plugin in marketplace['plugins']:
        name = plugin['name']
        mp_version = plugin['version']

        plugin_data = load_plugin_json(name)
        if plugin_data is None:
            print(f"{name:<35} {mp_version:<12} {'NOT_FOUND':<12} {Colors.YELLOW}skipped (no plugin.json){Colors.NC}")
            continue

        pj_version = plugin_data.get('version', mp_version)

        if mp_version == pj_version:
            continue  # Already in sync

        # Use the higher version
        if compare_versions(mp_version, pj_version) > 0:
            highest = mp_version
            action = f"plugin.json -> {highest}"
        else:
            highest = pj_version
            action = f"marketplace -> {highest}"

        print(f"{name:<35} {mp_version:<12} {pj_version:<12} {Colors.GREEN}{action:<30}{Colors.NC}")

        if not dry_run:
            # Update both files with highest version
            plugin['version'] = highest
            plugin_data['version'] = highest
            save_plugin_json(name, plugin_data)

        synced_count += 1

    if not dry_run and synced_count > 0:
        save_marketplace(marketplace)

    print()
    if dry_run:
        log_info(f"[DRY-RUN] Would sync {synced_count} plugins")
    else:
        log_success(f"Synced {synced_count} plugins")

    return 0

def increment_version(version, bump_type):
    has_v = version.startswith('v')
    if has_v:
        version = version[1:]
    
    parts = version.split('.')
    major = int(parts[0]) if len(parts) > 0 else 0
    minor = int(parts[1]) if len(parts) > 1 else 0
    patch = int(parts[2]) if len(parts) > 2 else 0
    
    if bump_type == 'major':
        major += 1
        minor = 0
        patch = 0
    elif bump_type == 'minor':
        minor += 1
        patch = 0
    elif bump_type == 'patch':
        patch += 1
    
    new_version = f"{major}.{minor}.{patch}"
    if has_v:
        new_version = 'v' + new_version
    return new_version

def bump_version(plugin_name, bump_type, dry_run=False):
    marketplace = load_marketplace()
    
    plugin_entry = None
    for p in marketplace['plugins']:
        if p['name'] == plugin_name:
            plugin_entry = p
            break
    
    if plugin_entry is None:
        log_error(f"Plugin not found in marketplace: {plugin_name}")
        return 1
    
    current_version = plugin_entry['version']
    new_version = increment_version(current_version, bump_type)
    
    if dry_run:
        log_info(f"[DRY-RUN] Would bump {plugin_name}: {current_version} -> {new_version}")
        return 0
    
    log_info(f"Bumping {plugin_name}: {current_version} -> {new_version}")
    
    plugin_entry['version'] = new_version
    save_marketplace(marketplace)
    log_success("Updated marketplace.json")
    
    plugin_data = load_plugin_json(plugin_name)
    if plugin_data:
        plugin_data['version'] = new_version
        save_plugin_json(plugin_name, plugin_data)
        log_success(f"Updated {plugin_name}/.claude-plugin/plugin.json")
    else:
        log_warn("Plugin JSON not found, only marketplace.json was updated")
    
    print(f"{Colors.GREEN}Successfully bumped {plugin_name} to {new_version}{Colors.NC}")
    return 0

def bump_all(bump_type, dry_run=False):
    marketplace = load_marketplace()
    
    log_info(f"Bumping {bump_type} version for all {len(marketplace['plugins'])} plugins...")
    print()
    
    success_count = 0
    fail_count = 0
    
    for plugin in marketplace['plugins']:
        result = bump_version(plugin['name'], bump_type, dry_run)
        if result == 0:
            success_count += 1
        else:
            fail_count += 1
        print()
    
    print(f"{Colors.BOLD}=== Bump Summary ==={Colors.NC}")
    print(f"Successful: {Colors.GREEN}{success_count}{Colors.NC}")
    print(f"Failed:     {Colors.RED}{fail_count}{Colors.NC}")

def main():
    parser = argparse.ArgumentParser(
        description='Track and manage plugin versions in the marketplace'
    )
    parser.add_argument('-v', '--validate', action='store_true',
                        help='Validate all versions match (default action)')
    parser.add_argument('-s', '--sync', action='store_true',
                        help='Sync versions using highest version (never downgrades)')
    parser.add_argument('-b', '--bump', choices=['patch', 'minor', 'major'],
                        help='Bump version type')
    parser.add_argument('-i', '--increment', choices=['patch', 'minor', 'major'],
                        help='Same as --bump')
    parser.add_argument('-p', '--plugin', help='Plugin name to bump')
    parser.add_argument('-a', '--all', action='store_true',
                        help='Apply bump to all plugins')
    parser.add_argument('-d', '--dry-run', action='store_true',
                        help='Show what would change without making changes')
    parser.add_argument('-q', '--quiet', action='store_true',
                        help='Only output errors and mismatches')
    parser.add_argument('--json', action='store_true',
                        help='Output validation results as JSON')
    parser.add_argument('plugin_name', nargs='?',
                        help='Plugin name (positional argument)')
    
    args = parser.parse_args()
    
    if not sys.stdout.isatty():
        Colors.disable()
    
    bump_type = args.bump or args.increment
    
    if args.sync:
        sys.exit(sync_versions(args.dry_run))
    elif bump_type:
        target = args.plugin or args.plugin_name
        if args.all:
            bump_all(bump_type, args.dry_run)
        elif target:
            sys.exit(bump_version(target, bump_type, args.dry_run))
        else:
            log_error("Specify a plugin name (-p PLUGIN) or use --all to bump all plugins")
            sys.exit(1)
    else:
        result = validate_versions(args.quiet, args.json)
        if result != 0:
            if not args.json:
                log_error("Version validation failed!")
            sys.exit(result)
        if not args.json:
            log_success("All versions are in sync!")

if __name__ == '__main__':
    main()
