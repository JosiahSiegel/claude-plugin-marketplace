#!/usr/bin/env python3
"""
Analyze video metrics against viral benchmarks.

Usage:
    python analyze-video-metrics.py --platform tiktok --views 5000 --completion 45 --likes 200
    python analyze-video-metrics.py --platform youtube-shorts --views 10000 --retention 65 --ctr 8
    python analyze-video-metrics.py --platform instagram --views 2000 --saves 50 --shares 30
"""

import argparse
import json
import sys
from typing import Dict, Any, List, Tuple

# Platform benchmarks based on 2025-2026 research
BENCHMARKS = {
    "tiktok": {
        "completion_rate": {
            "poor": 30,
            "average": 50,
            "good": 60,
            "viral": 80,
            "unit": "%",
            "description": "Percentage of viewers who watch to the end",
        },
        "engagement_rate": {
            "poor": 2,
            "average": 5,
            "good": 10,
            "viral": 15,
            "unit": "%",
            "description": "(Likes + Comments + Shares) / Views * 100",
        },
        "share_rate": {
            "poor": 0.5,
            "average": 1,
            "good": 3,
            "viral": 5,
            "unit": "%",
            "description": "Shares / Views * 100",
        },
        "replay_rate": {
            "poor": 2,
            "average": 5,
            "good": 10,
            "viral": 15,
            "unit": "%",
            "description": "Replays / Views * 100 (10% = boost)",
        },
    },
    "youtube-shorts": {
        "retention_30s": {
            "poor": 40,
            "average": 50,
            "good": 70,
            "viral": 85,
            "unit": "%",
            "description": "Retention at 30 seconds (70%+ = much higher ranking)",
        },
        "completion_rate": {
            "poor": 40,
            "average": 60,
            "good": 80,
            "viral": 90,
            "unit": "%",
            "description": "Below 50% = skippable content",
        },
        "ctr": {
            "poor": 2,
            "average": 4,
            "good": 8,
            "viral": 12,
            "unit": "%",
            "description": "Click-through rate from impressions",
        },
        "engagement_rate": {
            "poor": 2,
            "average": 4,
            "good": 8,
            "viral": 12,
            "unit": "%",
            "description": "(Likes + Comments) / Views * 100",
        },
    },
    "youtube-long": {
        "avg_view_duration": {
            "poor": 20,
            "average": 30,
            "good": 50,
            "viral": 70,
            "unit": "%",
            "description": "Average percentage of video watched (23.7% is platform average)",
        },
        "retention_30s": {
            "poor": 50,
            "average": 60,
            "good": 70,
            "viral": 85,
            "unit": "%",
            "description": "10% improvement = 25%+ impressions",
        },
        "ctr": {
            "poor": 2,
            "average": 4,
            "good": 6,
            "viral": 10,
            "unit": "%",
            "description": "Thumbnail CTR (faces with emotion = 20-30% higher)",
        },
        "engagement_rate": {
            "poor": 1,
            "average": 3,
            "good": 5,
            "viral": 8,
            "unit": "%",
            "description": "(Likes + Comments) / Views * 100",
        },
    },
    "instagram": {
        "completion_rate": {
            "poor": 30,
            "average": 50,
            "good": 70,
            "viral": 80,
            "unit": "%",
            "description": "80%+ for viral distribution",
        },
        "save_rate": {
            "poor": 0.5,
            "average": 1,
            "good": 3,
            "viral": 5,
            "unit": "%",
            "description": "Saves / Reach * 100 (high value signal)",
        },
        "share_rate": {
            "poor": 0.5,
            "average": 1,
            "good": 2,
            "viral": 4,
            "unit": "%",
            "description": "Sends Per Reach - most powerful signal",
        },
        "engagement_rate": {
            "poor": 2,
            "average": 4,
            "good": 6,
            "viral": 10,
            "unit": "%",
            "description": "(Likes + Comments + Saves + Shares) / Reach * 100",
        },
    },
    "facebook": {
        "share_rate": {
            "poor": 0.5,
            "average": 1,
            "good": 3,
            "viral": 5,
            "unit": "%",
            "description": "Shares / Reach * 100 (Facebook's core mechanic)",
        },
        "engagement_rate": {
            "poor": 2,
            "average": 4,
            "good": 6,
            "viral": 10,
            "unit": "%",
            "description": "(Reactions + Comments + Shares) / Reach * 100",
        },
        "completion_rate": {
            "poor": 30,
            "average": 45,
            "good": 60,
            "viral": 75,
            "unit": "%",
            "description": "Percentage watching to completion",
        },
    },
}


def rate_metric(value: float, benchmark: Dict[str, Any]) -> Tuple[str, str]:
    """Rate a metric value against benchmarks."""
    if value >= benchmark["viral"]:
        return "viral", "🔥"
    elif value >= benchmark["good"]:
        return "good", "✅"
    elif value >= benchmark["average"]:
        return "average", "➖"
    else:
        return "poor", "⚠️"


def calculate_engagement_rate(
    views: int, likes: int = 0, comments: int = 0, shares: int = 0, saves: int = 0
) -> float:
    """Calculate engagement rate."""
    if views == 0:
        return 0
    total_engagement = likes + comments + shares + saves
    return (total_engagement / views) * 100


def analyze_metrics(platform: str, metrics: Dict[str, float]) -> Dict[str, Any]:
    """Analyze metrics against platform benchmarks."""
    if platform not in BENCHMARKS:
        raise ValueError(f"Unknown platform: {platform}")

    benchmarks = BENCHMARKS[platform]
    results = {
        "platform": platform,
        "metrics": {},
        "overall_score": 0,
        "recommendations": [],
    }

    scores = []

    for metric_name, value in metrics.items():
        if metric_name in benchmarks:
            benchmark = benchmarks[metric_name]
            rating, emoji = rate_metric(value, benchmark)

            # Calculate score (0-100)
            if value >= benchmark["viral"]:
                score = 100
            elif value >= benchmark["good"]:
                score = 75 + 25 * (value - benchmark["good"]) / (benchmark["viral"] - benchmark["good"])
            elif value >= benchmark["average"]:
                score = 50 + 25 * (value - benchmark["average"]) / (benchmark["good"] - benchmark["average"])
            elif value >= benchmark["poor"]:
                score = 25 + 25 * (value - benchmark["poor"]) / (benchmark["average"] - benchmark["poor"])
            else:
                score = max(0, 25 * value / benchmark["poor"])

            scores.append(score)

            results["metrics"][metric_name] = {
                "value": value,
                "unit": benchmark["unit"],
                "rating": rating,
                "emoji": emoji,
                "score": round(score, 1),
                "benchmarks": {
                    "poor": benchmark["poor"],
                    "average": benchmark["average"],
                    "good": benchmark["good"],
                    "viral": benchmark["viral"],
                },
                "description": benchmark["description"],
            }

            # Generate recommendations
            if rating in ["poor", "average"]:
                results["recommendations"].append(
                    generate_recommendation(platform, metric_name, value, benchmark)
                )

    if scores:
        results["overall_score"] = round(sum(scores) / len(scores), 1)

    return results


def generate_recommendation(
    platform: str, metric_name: str, value: float, benchmark: Dict[str, Any]
) -> str:
    """Generate actionable recommendation for a metric."""
    recommendations = {
        "completion_rate": [
            "Optimize your hook in the first 1.3 seconds",
            "Eliminate filler content - every second must add value",
            "Add pattern interrupts (visual/audio changes) to maintain attention",
            "Consider shortening video length",
            "Use text overlays to reinforce key points",
        ],
        "engagement_rate": [
            "Add a clear call-to-action (22% engagement boost)",
            "Include conversation starters in captions",
            "Ask questions to encourage comments",
            "Create share-worthy moments",
            "Use trending sounds/audio (23% more engagement)",
        ],
        "share_rate": [
            "Create content with 'send to friend' moments",
            "Add relatable or surprising elements",
            "Include valuable information worth sharing",
            "Use the 'tag someone who needs this' approach",
        ],
        "replay_rate": [
            "Create seamless loops (last frame → first frame)",
            "Add details that reward rewatching",
            "Use satisfying/ASMR-style content",
            "End with a reveal that makes viewers want to see context",
        ],
        "retention_30s": [
            "Front-load value - don't save the best for last",
            "Use pattern interrupts every 15-30 seconds",
            "Add visual variety (cuts, zooms, graphics)",
            "Remove slow intros - get to the point immediately",
        ],
        "ctr": [
            "Test multiple thumbnails (use Test & Compare)",
            "Add faces with emotion (20-30% higher CTR)",
            "Use less than 5 words on thumbnail",
            "Create high contrast, mobile-friendly designs",
            "A/B test titles - curiosity without clickbait",
        ],
        "save_rate": [
            "Create reference-worthy content (guides, tips, tutorials)",
            "Add text overlays with key takeaways",
            "Make content 'bookmark for later' worthy",
            "Include actionable steps or lists",
        ],
        "avg_view_duration": [
            "Use the Promise → Tease → Deliver structure",
            "Add chapters/timestamps for longer videos",
            "Eliminate unnecessary sections",
            "Use storytelling to maintain interest",
        ],
    }

    tips = recommendations.get(metric_name, ["Improve this metric to boost performance"])
    target = benchmark["good"]

    return {
        "metric": metric_name,
        "current": f"{value}{benchmark['unit']}",
        "target": f"{target}{benchmark['unit']}",
        "gap": f"{target - value:.1f}{benchmark['unit']}",
        "tips": tips[:3],
    }


def print_report(results: Dict[str, Any]):
    """Print a formatted analysis report."""
    print(f"\n{'='*60}")
    print(f"📊 VIDEO METRICS ANALYSIS - {results['platform'].upper()}")
    print(f"{'='*60}")

    print(f"\n🎯 Overall Score: {results['overall_score']}/100")

    if results["overall_score"] >= 80:
        print("   Status: VIRAL POTENTIAL 🔥")
    elif results["overall_score"] >= 60:
        print("   Status: Good performance ✅")
    elif results["overall_score"] >= 40:
        print("   Status: Average - room for improvement ➖")
    else:
        print("   Status: Needs optimization ⚠️")

    print(f"\n{'─'*60}")
    print("METRIC BREAKDOWN")
    print(f"{'─'*60}")

    for name, data in results["metrics"].items():
        print(f"\n{data['emoji']} {name.replace('_', ' ').title()}")
        print(f"   Value: {data['value']}{data['unit']} ({data['rating'].upper()})")
        print(f"   Score: {data['score']}/100")
        print(f"   Benchmarks: Poor <{data['benchmarks']['poor']} | "
              f"Avg <{data['benchmarks']['average']} | "
              f"Good <{data['benchmarks']['good']} | "
              f"Viral ≥{data['benchmarks']['viral']}")

    if results["recommendations"]:
        print(f"\n{'─'*60}")
        print("💡 RECOMMENDATIONS")
        print(f"{'─'*60}")

        for rec in results["recommendations"]:
            print(f"\n📈 {rec['metric'].replace('_', ' ').title()}")
            print(f"   Current: {rec['current']} → Target: {rec['target']} (Gap: {rec['gap']})")
            print("   Actions:")
            for tip in rec["tips"]:
                print(f"      • {tip}")

    print(f"\n{'='*60}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze video metrics against viral benchmarks."
    )
    parser.add_argument(
        "--platform",
        "-p",
        required=True,
        choices=list(BENCHMARKS.keys()),
        help="Target platform",
    )
    parser.add_argument("--views", type=int, help="Total views")
    parser.add_argument("--likes", type=int, default=0, help="Total likes")
    parser.add_argument("--comments", type=int, default=0, help="Total comments")
    parser.add_argument("--shares", type=int, default=0, help="Total shares")
    parser.add_argument("--saves", type=int, default=0, help="Total saves (Instagram)")
    parser.add_argument("--completion", type=float, help="Completion rate (%)")
    parser.add_argument("--retention", type=float, help="Retention at 30s (%)")
    parser.add_argument("--ctr", type=float, help="Click-through rate (%)")
    parser.add_argument("--replay", type=float, help="Replay rate (%)")
    parser.add_argument("--avg-duration", type=float, help="Average view duration (%)")
    parser.add_argument(
        "--format",
        "-f",
        choices=["text", "json"],
        default="text",
        help="Output format",
    )
    parser.add_argument(
        "--benchmarks",
        "-b",
        action="store_true",
        help="Show platform benchmarks and exit",
    )

    args = parser.parse_args()

    if args.benchmarks:
        print(f"\n{args.platform.upper()} BENCHMARKS")
        print("=" * 50)
        for metric, data in BENCHMARKS[args.platform].items():
            print(f"\n{metric.replace('_', ' ').title()}:")
            print(f"  Poor: <{data['poor']}{data['unit']}")
            print(f"  Average: <{data['average']}{data['unit']}")
            print(f"  Good: <{data['good']}{data['unit']}")
            print(f"  Viral: ≥{data['viral']}{data['unit']}")
            print(f"  Note: {data['description']}")
        return

    # Collect provided metrics
    metrics = {}

    if args.completion is not None:
        metrics["completion_rate"] = args.completion

    if args.retention is not None:
        metrics["retention_30s"] = args.retention

    if args.ctr is not None:
        metrics["ctr"] = args.ctr

    if args.replay is not None:
        metrics["replay_rate"] = args.replay

    if args.avg_duration is not None:
        metrics["avg_view_duration"] = args.avg_duration

    # Calculate engagement rate if views provided
    if args.views and args.views > 0:
        engagement = calculate_engagement_rate(
            args.views, args.likes, args.comments, args.shares, args.saves
        )
        metrics["engagement_rate"] = engagement

        if args.shares:
            metrics["share_rate"] = (args.shares / args.views) * 100

        if args.saves:
            metrics["save_rate"] = (args.saves / args.views) * 100

    if not metrics:
        print("Error: No metrics provided. Use --help for usage.", file=sys.stderr)
        sys.exit(1)

    results = analyze_metrics(args.platform, metrics)

    if args.format == "json":
        print(json.dumps(results, indent=2))
    else:
        print_report(results)


if __name__ == "__main__":
    main()
