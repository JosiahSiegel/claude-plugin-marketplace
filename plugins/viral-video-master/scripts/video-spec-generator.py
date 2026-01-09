#!/usr/bin/env python3
"""
Generate platform-specific video specifications and technical requirements.

Usage:
    python video-spec-generator.py --platform tiktok
    python video-spec-generator.py --platform youtube-long --export json
    python video-spec-generator.py --all --export markdown
"""

import argparse
import json
from typing import Dict, Any

# Platform specifications (2025-2026)
VIDEO_SPECS = {
    "tiktok": {
        "name": "TikTok",
        "type": "Short-form",
        "video": {
            "aspect_ratio": "9:16",
            "resolution": "1080x1920",
            "max_resolution": "4K (2160x3840)",
            "file_formats": ["MP4", "MOV", "WebM"],
            "codec": "H.264",
            "max_file_size": "287.6 MB (iOS) / 72 MB (Android)",
            "max_length": "10 minutes",
            "optimal_length": "15-30 seconds (peak), under 60 seconds",
            "frame_rate": "30fps (standard), 60fps (supported)",
            "bitrate": "516 kbps - 20 Mbps",
        },
        "audio": {
            "format": "AAC",
            "sample_rate": "44.1 kHz",
            "bitrate": "128-320 kbps",
            "importance": "88% say sound is essential",
        },
        "captions": {
            "recommended": "Yes - algorithm reads captions",
            "format": "Built-in editor or SRT",
            "style": "Animated, bouncing, highlighted keywords",
        },
        "algorithm_preferences": {
            "optimal_length": "15-30 seconds",
            "hook_window": "1.3 seconds",
            "completion_target": "80%+ for viral",
            "hashtags": "3-5 relevant",
        },
        "tips": [
            "Film in app for best quality optimization",
            "Use trending sounds from Creative Center",
            "Seamless loops boost replay rate",
            "Text overlays help categorization",
        ],
    },
    "youtube-shorts": {
        "name": "YouTube Shorts",
        "type": "Short-form",
        "video": {
            "aspect_ratio": "9:16",
            "resolution": "1080x1920",
            "max_resolution": "4K (2160x3840)",
            "file_formats": ["MP4", "MOV", "AVI", "WMV"],
            "codec": "H.264, H.265",
            "max_file_size": "256 GB (or 12 hours)",
            "max_length": "3 minutes",
            "optimal_length": "50-60 seconds (3x more views than 15-second)",
            "frame_rate": "24-60fps",
            "bitrate": "Variable (YouTube re-encodes)",
        },
        "audio": {
            "format": "AAC, MP3",
            "sample_rate": "48 kHz (recommended)",
            "bitrate": "384 kbps (stereo)",
            "importance": "Sound adds engagement but less critical than TikTok",
        },
        "captions": {
            "recommended": "Yes - improves accessibility and SEO",
            "format": "Auto-generated or SRT/VTT upload",
            "style": "94% of top videos have closed captions",
        },
        "algorithm_preferences": {
            "optimal_length": "50-60 seconds",
            "hook_window": "3 seconds",
            "completion_target": "80-90% for top performers",
            "freshness": "Content older than 30 days rarely pushed",
        },
        "tips": [
            "Include #Shorts in title or description",
            "Thumbnail matters for browse features",
            "CTA increases engagement by 22%",
            "Tease long-form content for growth",
        ],
    },
    "youtube-long": {
        "name": "YouTube Long-form",
        "type": "Long-form",
        "video": {
            "aspect_ratio": "16:9",
            "resolution": "1920x1080 (HD) or 3840x2160 (4K)",
            "max_resolution": "8K (7680x4320)",
            "file_formats": ["MP4", "MOV", "AVI", "WMV", "MKV"],
            "codec": "H.264, H.265, VP9, AV1",
            "max_file_size": "256 GB (or 12 hours)",
            "max_length": "12 hours (verified) / 15 minutes (unverified)",
            "optimal_length": "8-15 minutes (sweet spot for ads)",
            "frame_rate": "24-60fps",
            "bitrate": "8 Mbps (1080p30), 12 Mbps (1080p60)",
        },
        "audio": {
            "format": "AAC-LC, FLAC",
            "sample_rate": "48 kHz (required for 5.1 surround)",
            "bitrate": "384 kbps (stereo)",
            "importance": "Voice clarity critical for educational content",
        },
        "captions": {
            "recommended": "Yes - major SEO factor",
            "format": "SRT, VTT, SBV",
            "style": "94% of top videos have closed captions",
        },
        "thumbnail": {
            "resolution": "1280x720 (minimum)",
            "aspect_ratio": "16:9",
            "file_size": "Under 2 MB",
            "format": "JPG, PNG",
            "best_practices": [
                "Faces with emotion = 20-30% higher CTR",
                "Less than 5 words of text",
                "High contrast for mobile",
                "Test up to 3 variants",
            ],
        },
        "algorithm_preferences": {
            "optimal_length": "8-15 minutes",
            "hook_window": "5-10 seconds",
            "retention_target": "70%+ in first 30 seconds",
            "ctr_target": "4-10%+",
        },
        "tips": [
            "8+ minutes enables more ad placements",
            "Chapters/timestamps improve UX and SEO",
            "End screens and cards for session time",
            "Connected TV optimization growing",
        ],
    },
    "instagram-reels": {
        "name": "Instagram Reels",
        "type": "Short-form",
        "video": {
            "aspect_ratio": "9:16",
            "resolution": "1080x1920",
            "max_resolution": "1080x1920 (Instagram compresses higher)",
            "file_formats": ["MP4", "MOV"],
            "codec": "H.264",
            "max_file_size": "4 GB",
            "max_length": "90 seconds",
            "optimal_length": "7-30 seconds (viral), 30-90 seconds (engagement)",
            "frame_rate": "30fps",
            "bitrate": "3,500 kbps",
        },
        "audio": {
            "format": "AAC",
            "sample_rate": "44.1 kHz",
            "bitrate": "128 kbps",
            "importance": "50% watch without sound - captions essential",
        },
        "captions": {
            "recommended": "Essential - 50% watch without sound",
            "format": "Built-in editor or burned in",
            "style": "Clean, readable, centered away from UI",
        },
        "algorithm_preferences": {
            "optimal_length": "7-30 seconds",
            "hook_window": "3 seconds (3/8/12 rule)",
            "completion_target": "80%+ for viral",
            "top_signal": "Sends Per Reach",
        },
        "tips": [
            "Trial Reels for risk-free testing",
            "Keyword SEO in captions growing",
            "3-5 relevant hashtags",
            "Best times: Tuesday-Thursday, 11 AM - 6 PM",
        ],
    },
    "facebook-reels": {
        "name": "Facebook Reels",
        "type": "Short-form",
        "video": {
            "aspect_ratio": "9:16",
            "resolution": "1080x1920",
            "max_resolution": "1080x1920",
            "file_formats": ["MP4", "MOV"],
            "codec": "H.264",
            "max_file_size": "4 GB",
            "max_length": "90 seconds",
            "optimal_length": "15-30 seconds",
            "frame_rate": "30fps",
            "bitrate": "Variable",
        },
        "audio": {
            "format": "AAC, MP3",
            "sample_rate": "44.1 kHz",
            "bitrate": "128 kbps",
            "importance": "Sound adds value but captions needed",
        },
        "captions": {
            "recommended": "Yes - many watch without sound",
            "format": "Auto-generated or burned in",
            "style": "Clear, readable",
        },
        "algorithm_preferences": {
            "optimal_length": "15-30 seconds",
            "hook_window": "3 seconds",
            "top_signal": "Shares (Facebook's core mechanic)",
            "timing": "First 1-2 hours critical",
        },
        "tips": [
            "Vertical video: 70% brand lift vs square",
            "Native upload preferred over cross-post link",
            "Best time: Late Friday night/midnight Saturday",
            "Focus on share-worthy content",
        ],
    },
}


def get_spec(platform: str) -> Dict[str, Any]:
    """Get specifications for a platform."""
    if platform not in VIDEO_SPECS:
        raise ValueError(f"Unknown platform: {platform}")
    return VIDEO_SPECS[platform]


def format_as_text(spec: Dict[str, Any]) -> str:
    """Format spec as readable text."""
    lines = [
        f"\n{'='*70}",
        f"📹 {spec['name'].upper()} VIDEO SPECIFICATIONS",
        f"{'='*70}",
        f"\nType: {spec['type']}",
        f"\n{'─'*70}",
        "VIDEO REQUIREMENTS",
        f"{'─'*70}",
    ]

    for key, value in spec["video"].items():
        label = key.replace("_", " ").title()
        if isinstance(value, list):
            value = ", ".join(value)
        lines.append(f"  {label}: {value}")

    lines.extend([
        f"\n{'─'*70}",
        "AUDIO REQUIREMENTS",
        f"{'─'*70}",
    ])

    for key, value in spec["audio"].items():
        label = key.replace("_", " ").title()
        lines.append(f"  {label}: {value}")

    lines.extend([
        f"\n{'─'*70}",
        "CAPTIONS",
        f"{'─'*70}",
    ])

    for key, value in spec["captions"].items():
        label = key.replace("_", " ").title()
        lines.append(f"  {label}: {value}")

    if "thumbnail" in spec:
        lines.extend([
            f"\n{'─'*70}",
            "THUMBNAIL",
            f"{'─'*70}",
        ])
        for key, value in spec["thumbnail"].items():
            label = key.replace("_", " ").title()
            if isinstance(value, list):
                lines.append(f"  {label}:")
                for item in value:
                    lines.append(f"    • {item}")
            else:
                lines.append(f"  {label}: {value}")

    lines.extend([
        f"\n{'─'*70}",
        "ALGORITHM PREFERENCES",
        f"{'─'*70}",
    ])

    for key, value in spec["algorithm_preferences"].items():
        label = key.replace("_", " ").title()
        lines.append(f"  {label}: {value}")

    lines.extend([
        f"\n{'─'*70}",
        "TIPS",
        f"{'─'*70}",
    ])

    for tip in spec["tips"]:
        lines.append(f"  • {tip}")

    lines.append(f"\n{'='*70}\n")

    return "\n".join(lines)


def format_as_markdown(spec: Dict[str, Any]) -> str:
    """Format spec as markdown."""
    lines = [
        f"# {spec['name']} Video Specifications",
        "",
        f"**Type:** {spec['type']}",
        "",
        "## Video Requirements",
        "",
        "| Property | Value |",
        "|----------|-------|",
    ]

    for key, value in spec["video"].items():
        label = key.replace("_", " ").title()
        if isinstance(value, list):
            value = ", ".join(value)
        lines.append(f"| {label} | {value} |")

    lines.extend([
        "",
        "## Audio Requirements",
        "",
        "| Property | Value |",
        "|----------|-------|",
    ])

    for key, value in spec["audio"].items():
        label = key.replace("_", " ").title()
        lines.append(f"| {label} | {value} |")

    lines.extend([
        "",
        "## Captions",
        "",
    ])

    for key, value in spec["captions"].items():
        label = key.replace("_", " ").title()
        lines.append(f"- **{label}:** {value}")

    if "thumbnail" in spec:
        lines.extend([
            "",
            "## Thumbnail",
            "",
            "| Property | Value |",
            "|----------|-------|",
        ])
        for key, value in spec["thumbnail"].items():
            label = key.replace("_", " ").title()
            if not isinstance(value, list):
                lines.append(f"| {label} | {value} |")

        if "best_practices" in spec["thumbnail"]:
            lines.extend([
                "",
                "### Best Practices",
                "",
            ])
            for item in spec["thumbnail"]["best_practices"]:
                lines.append(f"- {item}")

    lines.extend([
        "",
        "## Algorithm Preferences",
        "",
        "| Signal | Target |",
        "|--------|--------|",
    ])

    for key, value in spec["algorithm_preferences"].items():
        label = key.replace("_", " ").title()
        lines.append(f"| {label} | {value} |")

    lines.extend([
        "",
        "## Tips",
        "",
    ])

    for tip in spec["tips"]:
        lines.append(f"- {tip}")

    return "\n".join(lines)


def export_all(format_type: str) -> str:
    """Export all platform specs."""
    if format_type == "json":
        return json.dumps(VIDEO_SPECS, indent=2)
    elif format_type == "markdown":
        parts = []
        for platform in VIDEO_SPECS:
            parts.append(format_as_markdown(VIDEO_SPECS[platform]))
        return "\n\n---\n\n".join(parts)
    else:
        parts = []
        for platform in VIDEO_SPECS:
            parts.append(format_as_text(VIDEO_SPECS[platform]))
        return "\n".join(parts)


def main():
    parser = argparse.ArgumentParser(
        description="Generate platform-specific video specifications."
    )
    parser.add_argument(
        "--platform",
        "-p",
        choices=list(VIDEO_SPECS.keys()),
        help="Target platform",
    )
    parser.add_argument(
        "--all",
        "-a",
        action="store_true",
        help="Show all platforms",
    )
    parser.add_argument(
        "--export",
        "-e",
        choices=["text", "json", "markdown"],
        default="text",
        help="Export format",
    )
    parser.add_argument(
        "--output",
        "-o",
        help="Output file",
    )
    parser.add_argument(
        "--quick",
        "-q",
        action="store_true",
        help="Quick reference (resolution, length, format only)",
    )

    args = parser.parse_args()

    if args.quick:
        print("\n📹 QUICK VIDEO SPECS REFERENCE")
        print("=" * 70)
        print(f"{'Platform':<18} {'Resolution':<14} {'Optimal Length':<25} {'Ratio'}")
        print("-" * 70)
        for key, spec in VIDEO_SPECS.items():
            print(f"{spec['name']:<18} {spec['video']['resolution']:<14} "
                  f"{spec['video']['optimal_length']:<25} {spec['video']['aspect_ratio']}")
        print()
        return

    if args.all:
        output = export_all(args.export)
    elif args.platform:
        spec = get_spec(args.platform)
        if args.export == "json":
            output = json.dumps(spec, indent=2)
        elif args.export == "markdown":
            output = format_as_markdown(spec)
        else:
            output = format_as_text(spec)
    else:
        parser.print_help()
        return

    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"Saved to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
