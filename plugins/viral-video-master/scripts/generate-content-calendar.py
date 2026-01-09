#!/usr/bin/env python3
"""
Generate a viral video content calendar with optimal posting times.

Usage:
    python generate-content-calendar.py --platform tiktok --weeks 4 --posts-per-day 2
    python generate-content-calendar.py --platform youtube --weeks 2 --output calendar.csv
    python generate-content-calendar.py --platform instagram --weeks 1 --format json
"""

import argparse
import json
import csv
import sys
from datetime import datetime, timedelta
from typing import List, Dict, Any

# Platform-specific optimal posting times (2025-2026 research)
PLATFORM_SCHEDULES = {
    "tiktok": {
        "best_times": [
            {"day": "Monday", "times": ["7:00 AM", "12:00 PM", "7:00 PM"]},
            {"day": "Tuesday", "times": ["9:00 AM", "2:00 PM", "8:00 PM"]},
            {"day": "Wednesday", "times": ["7:00 AM", "11:00 AM", "8:00 PM"]},
            {"day": "Thursday", "times": ["9:00 AM", "12:00 PM", "7:00 PM"]},
            {"day": "Friday", "times": ["5:00 AM", "1:00 PM", "3:00 PM"]},
            {"day": "Saturday", "times": ["11:00 AM", "7:00 PM", "8:00 PM"]},
            {"day": "Sunday", "times": ["8:00 AM", "4:00 PM", "7:00 PM"]},
        ],
        "recommended_daily": "1-4",
        "note": "68% of views happen in first 24 hours. 2-4x daily = 2.5x follower growth.",
    },
    "youtube-shorts": {
        "best_times": [
            {"day": "Monday", "times": ["2:00 PM", "4:00 PM"]},
            {"day": "Tuesday", "times": ["2:00 PM", "4:00 PM", "6:00 PM"]},
            {"day": "Wednesday", "times": ["2:00 PM", "4:00 PM", "6:00 PM"]},
            {"day": "Thursday", "times": ["12:00 PM", "3:00 PM", "6:00 PM"]},
            {"day": "Friday", "times": ["3:00 PM", "5:00 PM"]},
            {"day": "Saturday", "times": ["9:00 AM", "11:00 AM", "3:00 PM"]},
            {"day": "Sunday", "times": ["9:00 AM", "12:00 PM"]},
        ],
        "recommended_daily": "1-3",
        "note": "Freshness factor: content older than 30 days rarely pushed. 55-second = 3x more views.",
    },
    "youtube-long": {
        "best_times": [
            {"day": "Monday", "times": ["2:00 PM"]},
            {"day": "Tuesday", "times": ["6:00 PM", "9:00 PM"]},
            {"day": "Wednesday", "times": ["6:00 PM", "9:00 PM"]},
            {"day": "Thursday", "times": ["12:00 PM", "3:00 PM"]},
            {"day": "Friday", "times": ["3:00 PM", "5:00 PM"]},
            {"day": "Saturday", "times": ["9:00 AM", "11:00 AM"]},
            {"day": "Sunday", "times": ["9:00 AM", "12:00 PM"]},
        ],
        "recommended_daily": "1-2 per week",
        "note": "8-15 minutes optimal. Test up to 3 thumbnails with Test & Compare.",
    },
    "instagram": {
        "best_times": [
            {"day": "Monday", "times": ["11:00 AM", "2:00 PM"]},
            {"day": "Tuesday", "times": ["11:00 AM", "2:00 PM", "6:00 PM"]},
            {"day": "Wednesday", "times": ["11:00 AM", "2:00 PM", "6:00 PM"]},
            {"day": "Thursday", "times": ["11:00 AM", "2:00 PM", "6:00 PM"]},
            {"day": "Friday", "times": ["11:00 AM", "2:00 PM"]},
            {"day": "Saturday", "times": ["10:00 AM", "1:00 PM"]},
            {"day": "Sunday", "times": ["10:00 AM", "1:00 PM"]},
        ],
        "recommended_daily": "1-2",
        "note": "Best days: Tuesday-Thursday. Sends Per Reach is most powerful signal.",
    },
    "facebook": {
        "best_times": [
            {"day": "Monday", "times": ["9:00 AM", "1:00 PM"]},
            {"day": "Tuesday", "times": ["9:00 AM", "1:00 PM"]},
            {"day": "Wednesday", "times": ["9:00 AM", "1:00 PM"]},
            {"day": "Thursday", "times": ["9:00 AM", "1:00 PM"]},
            {"day": "Friday", "times": ["9:00 AM", "11:00 PM"]},
            {"day": "Saturday", "times": ["12:00 AM", "10:00 AM"]},
            {"day": "Sunday", "times": ["10:00 AM", "1:00 PM"]},
        ],
        "recommended_daily": "1-2",
        "note": "Late Friday night/midnight Saturday = highest views. First 1-2 hours critical.",
    },
}

DAY_MAP = {
    "Monday": 0,
    "Tuesday": 1,
    "Wednesday": 2,
    "Thursday": 3,
    "Friday": 4,
    "Saturday": 5,
    "Sunday": 6,
}


def get_next_weekday(start_date: datetime, target_weekday: int) -> datetime:
    """Get the next occurrence of a weekday from a start date."""
    days_ahead = target_weekday - start_date.weekday()
    if days_ahead < 0:
        days_ahead += 7
    return start_date + timedelta(days=days_ahead)


def generate_calendar(
    platform: str, weeks: int, posts_per_day: int, start_date: datetime = None
) -> List[Dict[str, Any]]:
    """Generate a content calendar for the specified platform."""
    if platform not in PLATFORM_SCHEDULES:
        raise ValueError(f"Unknown platform: {platform}. Choose from: {list(PLATFORM_SCHEDULES.keys())}")

    schedule = PLATFORM_SCHEDULES[platform]
    start = start_date or datetime.now()
    calendar = []

    for week in range(weeks):
        week_start = start + timedelta(weeks=week)

        for day_info in schedule["best_times"]:
            day_name = day_info["day"]
            target_date = get_next_weekday(week_start, DAY_MAP[day_name])

            # Skip dates in the past
            if target_date < start:
                continue

            times = day_info["times"][:posts_per_day]

            for i, time_str in enumerate(times):
                calendar.append({
                    "date": target_date.strftime("%Y-%m-%d"),
                    "day": day_name,
                    "time": time_str,
                    "platform": platform,
                    "slot": i + 1,
                    "content_type": "",
                    "topic": "",
                    "hook_idea": "",
                    "status": "planned",
                })

    # Sort by date and time
    calendar.sort(key=lambda x: (x["date"], x["time"]))
    return calendar


def output_csv(calendar: List[Dict[str, Any]], output_file: str = None):
    """Output calendar as CSV."""
    if not calendar:
        print("No entries to output.", file=sys.stderr)
        return

    fieldnames = ["date", "day", "time", "platform", "slot", "content_type", "topic", "hook_idea", "status"]

    if output_file:
        with open(output_file, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(calendar)
        print(f"Calendar saved to {output_file}")
    else:
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(calendar)


def output_json(calendar: List[Dict[str, Any]], output_file: str = None):
    """Output calendar as JSON."""
    output = {
        "generated": datetime.now().isoformat(),
        "entries": calendar,
        "total_posts": len(calendar),
    }

    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(output, f, indent=2)
        print(f"Calendar saved to {output_file}")
    else:
        print(json.dumps(output, indent=2))


def output_markdown(calendar: List[Dict[str, Any]], platform: str, output_file: str = None):
    """Output calendar as Markdown."""
    schedule = PLATFORM_SCHEDULES[platform]

    lines = [
        f"# {platform.title()} Content Calendar",
        "",
        f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"**Platform Note:** {schedule['note']}",
        f"**Recommended Frequency:** {schedule['recommended_daily']} posts per day",
        "",
        "## Schedule",
        "",
        "| Date | Day | Time | Content Type | Topic | Hook Idea | Status |",
        "|------|-----|------|--------------|-------|-----------|--------|",
    ]

    for entry in calendar:
        lines.append(
            f"| {entry['date']} | {entry['day']} | {entry['time']} | "
            f"{entry['content_type']} | {entry['topic']} | {entry['hook_idea']} | {entry['status']} |"
        )

    lines.extend([
        "",
        "## Platform Tips",
        "",
    ])

    if platform == "tiktok":
        lines.extend([
            "- **Hook Window:** 1.3 seconds to capture attention",
            "- **Optimal Length:** 15-30 seconds (peak), under 60 seconds",
            "- **Hashtags:** 3-5 relevant, mix niche + category",
            "- **Sound:** 88% say sound is essential - use trending audio",
        ])
    elif platform == "youtube-shorts":
        lines.extend([
            "- **Optimal Length:** 50-60 seconds (3x more views than 15-second)",
            "- **Freshness:** Content older than 30 days rarely pushed",
            "- **CTA Impact:** 22% more engagement with strong CTA",
            "- **Retention Target:** 80-90% for top performers",
        ])
    elif platform == "instagram":
        lines.extend([
            "- **3/8/12 Rule:** Hook (3s), deepen (8s), deliver (12s+)",
            "- **Sound-Off:** 50% watch without sound - captions essential",
            "- **Sends Per Reach:** Most powerful signal for new audience reach",
            "- **Trial Reels:** Test content without risking engagement metrics",
        ])
    elif platform == "facebook":
        lines.extend([
            "- **Shares:** Most important signal for reach",
            "- **Vertical Video:** 70% brand lift vs square format",
            "- **First Hours:** 1-2 hours after posting are critical",
            "- **Best Time:** Late Friday night/midnight Saturday",
        ])

    content = "\n".join(lines)

    if output_file:
        with open(output_file, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Calendar saved to {output_file}")
    else:
        print(content)


def main():
    parser = argparse.ArgumentParser(
        description="Generate a viral video content calendar with optimal posting times."
    )
    parser.add_argument(
        "--platform",
        "-p",
        required=True,
        choices=list(PLATFORM_SCHEDULES.keys()),
        help="Target platform",
    )
    parser.add_argument(
        "--weeks",
        "-w",
        type=int,
        default=4,
        help="Number of weeks to plan (default: 4)",
    )
    parser.add_argument(
        "--posts-per-day",
        "-n",
        type=int,
        default=2,
        help="Maximum posts per day (default: 2)",
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["csv", "json", "markdown"],
        default="csv",
        help="Output format (default: csv)",
    )
    parser.add_argument(
        "--output",
        "-o",
        help="Output file (default: stdout)",
    )
    parser.add_argument(
        "--info",
        "-i",
        action="store_true",
        help="Show platform info and exit",
    )

    args = parser.parse_args()

    if args.info:
        schedule = PLATFORM_SCHEDULES[args.platform]
        print(f"\n{args.platform.upper()} Posting Guide")
        print("=" * 40)
        print(f"Recommended: {schedule['recommended_daily']} posts per day")
        print(f"Note: {schedule['note']}")
        print("\nBest Times:")
        for day_info in schedule["best_times"]:
            print(f"  {day_info['day']}: {', '.join(day_info['times'])}")
        return

    calendar = generate_calendar(
        platform=args.platform,
        weeks=args.weeks,
        posts_per_day=args.posts_per_day,
    )

    if args.format == "csv":
        output_csv(calendar, args.output)
    elif args.format == "json":
        output_json(calendar, args.output)
    elif args.format == "markdown":
        output_markdown(calendar, args.platform, args.output)


if __name__ == "__main__":
    main()
