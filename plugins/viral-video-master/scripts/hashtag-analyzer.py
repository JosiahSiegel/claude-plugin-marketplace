#!/usr/bin/env python3
"""
Analyze and generate optimized hashtag strategies for viral video content.

Usage:
    python hashtag-analyzer.py --platform tiktok --niche "fitness" --topic "home workout"
    python hashtag-analyzer.py --platform instagram --niche "cooking" --count 10
    python hashtag-analyzer.py --platform youtube --analyze "#shorts #fitness #workout"
"""

import argparse
import json
import random
from typing import List, Dict, Any

# Platform-specific hashtag strategies (2025-2026 research)
PLATFORM_STRATEGIES = {
    "tiktok": {
        "optimal_count": "3-5",
        "max_count": 5,
        "strategy": "Quality over quantity - mix niche + category",
        "effectiveness": {
            "trending": "23% more engagement",
            "niche": "2.5x better distribution",
            "broad": "Debated effectiveness (#fyp, #foryou)",
        },
        "tips": [
            "Algorithm reads hashtags for content categorization",
            "Niche hashtags outperform broad hashtags",
            "Check TikTok Creative Center for trending",
            "Avoid banned or shadowbanned hashtags",
        ],
    },
    "instagram": {
        "optimal_count": "3-5",
        "max_count": 30,
        "strategy": "Keyword SEO shifting from pure hashtags",
        "effectiveness": {
            "with_hashtags": "12.6% more engagement",
            "keyword_focus": "Growing importance in 2025",
        },
        "tips": [
            "Instagram shifting to keyword-based SEO",
            "Include keywords naturally in caption",
            "Can place hashtags in comments",
            "Test 3-5 vs more hashtags for your niche",
        ],
    },
    "youtube": {
        "optimal_count": "3-5",
        "max_count": 15,
        "strategy": "Keywords > Hashtags for discovery",
        "effectiveness": {
            "shorts": "#Shorts in title/description recommended",
            "long_form": "Tags and description keywords more important",
        },
        "tips": [
            "#Shorts helps Shorts algorithm discovery",
            "Focus on title and description SEO",
            "Use tags for related topics",
            "Keywords in first 25 words of description",
        ],
    },
    "facebook": {
        "optimal_count": "1-3",
        "max_count": 5,
        "strategy": "Minimal hashtags - focus on shares",
        "effectiveness": {
            "general": "Less important than other platforms",
            "shares": "Content quality drives reach, not hashtags",
        },
        "tips": [
            "Facebook prioritizes shares over hashtags",
            "Use hashtags sparingly if at all",
            "Focus on share-worthy content",
            "Cross-posting: adjust from Instagram strategy",
        ],
    },
}

# Niche hashtag databases (examples for common niches)
NICHE_HASHTAGS = {
    "fitness": {
        "broad": ["fitness", "workout", "gym", "health", "exercise"],
        "niche": ["homeworkout", "bodyweightworkout", "fitnessmotivation", "workoutathome", "fitnesstips"],
        "micro": ["beginnerfitness", "quickworkout", "noequipmentworkout", "5minuteworkout", "fitnessforbeginners"],
        "trending": ["fitcheck", "gymmotivation", "fitnesstransformation"],
    },
    "cooking": {
        "broad": ["cooking", "food", "recipe", "homemade", "foodie"],
        "niche": ["easyrecipes", "quickmeals", "healthyrecipes", "mealprep", "cookingtips"],
        "micro": ["15minutemeals", "onepotmeal", "budgetmeals", "studentcooking", "beginnerrecipes"],
        "trending": ["foodtok", "recipeideas", "cooktok"],
    },
    "beauty": {
        "broad": ["beauty", "makeup", "skincare", "cosmetics", "beautytips"],
        "niche": ["makeuptutorial", "skincareroutine", "makeuphacks", "skincareproducts", "beautyhacks"],
        "micro": ["drugstorebeauty", "affordablemakeup", "skincaretips", "beginnermakeup", "cleanbeauty"],
        "trending": ["grwm", "beautytok", "skintok"],
    },
    "tech": {
        "broad": ["tech", "technology", "gadgets", "innovation", "digital"],
        "niche": ["techtips", "techreview", "appreview", "productivityapps", "techtok"],
        "micro": ["iphonehacks", "androidtips", "techhacks", "appstouse", "hiddenfeatures"],
        "trending": ["techtok", "gadgetreview", "techlife"],
    },
    "business": {
        "broad": ["business", "entrepreneur", "startup", "success", "money"],
        "niche": ["businesstips", "entrepreneurlife", "sidehustle", "passiveincome", "businessadvice"],
        "micro": ["smallbusinessowner", "onlinebusiness", "makemoneyonline", "businessgrowth", "entrepreneurmindset"],
        "trending": ["moneytok", "sidehustleideas", "financetok"],
    },
    "lifestyle": {
        "broad": ["lifestyle", "life", "daily", "routine", "living"],
        "niche": ["morningroutine", "nightroutine", "productivitytips", "selfcare", "lifehacks"],
        "micro": ["minimalistlifestyle", "cleanwithme", "dayinmylife", "organizationtips", "adulting"],
        "trending": ["lifestyletok", "aestheticlifestyle", "thatgirl"],
    },
    "education": {
        "broad": ["education", "learning", "knowledge", "study", "tips"],
        "niche": ["learntok", "studytips", "studywithme", "educationaltiktok", "didyouknow"],
        "micro": ["studyhacks", "learnontiktok", "quickfacts", "interestingfacts", "studentlife"],
        "trending": ["booktok", "learnsomething", "edutok"],
    },
    "travel": {
        "broad": ["travel", "wanderlust", "adventure", "explore", "vacation"],
        "niche": ["traveltips", "travelguide", "travelhacks", "budgettravel", "travelgram"],
        "micro": ["solotravel", "hiddenspots", "travelsecrets", "affordabletravel", "travelblogger"],
        "trending": ["traveltok", "travelwithme", "wheretonext"],
    },
}


def analyze_hashtags(hashtags: str, platform: str) -> Dict[str, Any]:
    """Analyze a set of hashtags."""
    tags = [h.strip().lstrip("#") for h in hashtags.replace(",", " ").split()]

    strategy = PLATFORM_STRATEGIES[platform]
    optimal_min, optimal_max = map(int, strategy["optimal_count"].split("-"))

    analysis = {
        "platform": platform,
        "hashtags": tags,
        "count": len(tags),
        "optimal_count": strategy["optimal_count"],
        "count_status": "optimal" if optimal_min <= len(tags) <= optimal_max else (
            "too_few" if len(tags) < optimal_min else "too_many"
        ),
        "issues": [],
        "suggestions": [],
    }

    # Check for common issues
    broad_tags = ["fyp", "foryou", "viral", "trending", "explore"]
    broad_count = sum(1 for t in tags if t.lower() in broad_tags)

    if broad_count > 2:
        analysis["issues"].append(f"Too many broad hashtags ({broad_count}). These have debated effectiveness.")

    if len(tags) > strategy["max_count"]:
        analysis["issues"].append(f"Exceeds platform max of {strategy['max_count']} hashtags")

    if len(tags) < optimal_min:
        analysis["suggestions"].append(f"Add {optimal_min - len(tags)} more relevant hashtags")

    if not any(t.lower() in ["shorts"] for t in tags) and platform == "youtube":
        analysis["suggestions"].append("Consider adding #Shorts for YouTube Shorts discovery")

    return analysis


def generate_hashtags(
    platform: str,
    niche: str,
    topic: str = None,
    count: int = 5,
) -> Dict[str, Any]:
    """Generate optimized hashtag set for a platform and niche."""
    strategy = PLATFORM_STRATEGIES[platform]
    optimal_count = min(count, strategy["max_count"])

    # Get niche hashtags or use generic
    niche_lower = niche.lower()
    niche_data = NICHE_HASHTAGS.get(niche_lower, {
        "broad": [niche_lower],
        "niche": [f"{niche_lower}tips", f"{niche_lower}content"],
        "micro": [f"beginner{niche_lower}"],
        "trending": [f"{niche_lower}tok"],
    })

    # Build hashtag mix
    hashtags = []

    # Add 1-2 niche/micro hashtags (highest value)
    micro_count = min(2, optimal_count)
    hashtags.extend(random.sample(niche_data.get("micro", niche_data["niche"]),
                                   min(micro_count, len(niche_data.get("micro", niche_data["niche"])))))

    # Add 1-2 category hashtags
    remaining = optimal_count - len(hashtags)
    if remaining > 0:
        category_count = min(2, remaining)
        available = [h for h in niche_data["niche"] if h not in hashtags]
        hashtags.extend(random.sample(available, min(category_count, len(available))))

    # Add 1 trending if available
    remaining = optimal_count - len(hashtags)
    if remaining > 0 and niche_data.get("trending"):
        hashtags.append(random.choice(niche_data["trending"]))

    # Add topic-specific if provided
    if topic and len(hashtags) < optimal_count:
        topic_tag = topic.replace(" ", "").lower()
        if topic_tag not in hashtags:
            hashtags.append(topic_tag)

    # Platform-specific additions
    if platform == "youtube" and "shorts" not in [h.lower() for h in hashtags]:
        hashtags.insert(0, "Shorts")

    result = {
        "platform": platform,
        "niche": niche,
        "topic": topic,
        "hashtags": hashtags[:optimal_count],
        "formatted": " ".join(f"#{h}" for h in hashtags[:optimal_count]),
        "strategy": strategy["strategy"],
        "tips": strategy["tips"],
        "breakdown": {
            "micro_niche": [h for h in hashtags if h in niche_data.get("micro", [])],
            "category": [h for h in hashtags if h in niche_data.get("niche", [])],
            "trending": [h for h in hashtags if h in niche_data.get("trending", [])],
        },
    }

    return result


def print_analysis(analysis: Dict[str, Any]):
    """Print hashtag analysis report."""
    print(f"\n{'='*60}")
    print(f"🔍 HASHTAG ANALYSIS - {analysis['platform'].upper()}")
    print(f"{'='*60}")

    print(f"\nHashtags: {' '.join(f'#{h}' for h in analysis['hashtags'])}")
    print(f"Count: {analysis['count']} (Optimal: {analysis['optimal_count']})")

    status_emoji = {"optimal": "✅", "too_few": "⚠️", "too_many": "❌"}
    print(f"Status: {status_emoji.get(analysis['count_status'], '➖')} {analysis['count_status'].replace('_', ' ').title()}")

    if analysis["issues"]:
        print(f"\n⚠️ Issues:")
        for issue in analysis["issues"]:
            print(f"   • {issue}")

    if analysis["suggestions"]:
        print(f"\n💡 Suggestions:")
        for suggestion in analysis["suggestions"]:
            print(f"   • {suggestion}")


def print_generated(result: Dict[str, Any]):
    """Print generated hashtag report."""
    print(f"\n{'='*60}")
    print(f"#️⃣ GENERATED HASHTAGS - {result['platform'].upper()}")
    print(f"{'='*60}")

    print(f"\n📌 Niche: {result['niche']}")
    if result["topic"]:
        print(f"📝 Topic: {result['topic']}")

    print(f"\n🎯 Recommended Hashtags:")
    print(f"   {result['formatted']}")

    print(f"\n📊 Breakdown:")
    for category, tags in result["breakdown"].items():
        if tags:
            print(f"   {category.replace('_', ' ').title()}: {' '.join(f'#{t}' for t in tags)}")

    print(f"\n📖 Strategy: {result['strategy']}")

    print(f"\n💡 Platform Tips:")
    for tip in result["tips"]:
        print(f"   • {tip}")

    print(f"\n{'='*60}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Analyze and generate optimized hashtag strategies."
    )
    parser.add_argument(
        "--platform",
        "-p",
        required=True,
        choices=list(PLATFORM_STRATEGIES.keys()),
        help="Target platform",
    )
    parser.add_argument(
        "--niche",
        "-n",
        help="Content niche (fitness, cooking, beauty, tech, business, lifestyle, education, travel)",
    )
    parser.add_argument(
        "--topic",
        "-t",
        help="Specific video topic",
    )
    parser.add_argument(
        "--analyze",
        "-a",
        help="Analyze existing hashtags (space or comma separated)",
    )
    parser.add_argument(
        "--count",
        "-c",
        type=int,
        default=5,
        help="Number of hashtags to generate (default: 5)",
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["text", "json"],
        default="text",
        help="Output format",
    )
    parser.add_argument(
        "--strategy",
        "-s",
        action="store_true",
        help="Show platform hashtag strategy",
    )

    args = parser.parse_args()

    if args.strategy:
        strategy = PLATFORM_STRATEGIES[args.platform]
        print(f"\n{args.platform.upper()} HASHTAG STRATEGY")
        print("=" * 50)
        print(f"Optimal Count: {strategy['optimal_count']}")
        print(f"Max Count: {strategy['max_count']}")
        print(f"Strategy: {strategy['strategy']}")
        print("\nEffectiveness:")
        for key, value in strategy["effectiveness"].items():
            print(f"  {key}: {value}")
        print("\nTips:")
        for tip in strategy["tips"]:
            print(f"  • {tip}")
        return

    if args.analyze:
        result = analyze_hashtags(args.analyze, args.platform)
        if args.format == "json":
            print(json.dumps(result, indent=2))
        else:
            print_analysis(result)
    elif args.niche:
        result = generate_hashtags(
            platform=args.platform,
            niche=args.niche,
            topic=args.topic,
            count=args.count,
        )
        if args.format == "json":
            print(json.dumps(result, indent=2))
        else:
            print_generated(result)
    else:
        parser.print_help()
        print("\nError: Either --niche (to generate) or --analyze (to analyze) is required")


if __name__ == "__main__":
    main()
