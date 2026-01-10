#!/usr/bin/env bash
#
# version-tracker.sh - Track and manage plugin versions in the marketplace
#
# Usage:
#   ./version-tracker.sh [OPTIONS] [PLUGIN_NAME]
#
# Options:
#   -h, --help              Show this help message
#   -v, --validate          Validate all versions match (default action)
#   -b, --bump TYPE         Bump version (TYPE: patch, minor, major)
#   -i, --increment TYPE    Same as --bump
#   -p, --plugin NAME       Specify plugin to bump (required with --bump)
#   -a, --all               Apply bump to all plugins
#   -d, --dry-run           Show what would change without making changes
#   -q, --quiet             Only output errors and mismatches
#   --json                  Output validation results as JSON
#
# Examples:
#   ./version-tracker.sh                    # Validate all versions
#   ./version-tracker.sh --validate         # Same as above
#   ./version-tracker.sh -b patch -p bash-master    # Bump bash-master patch version
#   ./version-tracker.sh --bump minor --all         # Bump all plugins minor version
#   ./version-tracker.sh -b major -p ffmpeg-master --dry-run
#

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Show help if requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    head -25 "${BASH_SOURCE[0]}" | tail -24 | sed 's/^# \?//'
    exit 0
fi

# Run the Python implementation
python3 "${SCRIPT_DIR}/version_ops.py" "$@"
