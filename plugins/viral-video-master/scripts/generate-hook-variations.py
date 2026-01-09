#!/usr/bin/env python3
"""
Generate viral hook variations using psychological triggers.

Usage:
    python generate-hook-variations.py --topic "morning routine" --platform tiktok
    python generate-hook-variations.py --topic "cooking pasta" --style educational
    python generate-hook-variations.py --topic "productivity tips" --triggers curiosity,fomo
"""

import argparse
import json
import random
from typing import List, Dict, Any

# Psychological trigger templates based on 2025-2026 research
HOOK_TEMPLATES = {
    "curiosity": {
        "name": "Curiosity Gap",
        "description": "Creates information gap that must be filled",
        "weight": "Very High",
        "templates": [
            "Here's why {topic} is completely wrong...",
            "The secret about {topic} no one talks about...",
            "I discovered something that changed how I think about {topic}...",
            "Most people don't know this about {topic}...",
            "The {industry} doesn't want you to know this about {topic}...",
            "What they don't teach you about {topic}...",
            "Everything you know about {topic} is backwards...",
            "The hidden truth about {topic}...",
            "Why {topic} isn't what you think it is...",
        ],
    },
    "pattern_interrupt": {
        "name": "Pattern Interrupt",
        "description": "Breaks expected patterns (triggers orienting response)",
        "weight": "High",
        "templates": [
            "...and that's why I stopped {topic}",
            "I quit {topic} and here's what happened",
            "Wait, {topic} actually works like this?",
            "[Mid-sentence start] ...the real way to {topic}",
            "This {topic} hack broke my brain",
            "Forget everything about {topic}",
            "Plot twist: {topic} isn't real",
        ],
    },
    "open_loop": {
        "name": "Open Loop (Zeigarnik Effect)",
        "description": "Incomplete stories demand completion",
        "weight": "Very High",
        "templates": [
            "By the end of this, you'll understand {topic} completely...",
            "What happened next with {topic} shocked everyone...",
            "The third tip about {topic} is the one that actually works...",
            "Wait until you see what happens with {topic}...",
            "I didn't believe {topic} until I tried it myself...",
            "The last one changed everything about {topic}...",
            "Watch until the end to see {topic} in action...",
        ],
    },
    "fomo": {
        "name": "FOMO / Loss Aversion",
        "description": "Humans feel losses 2x more than gains",
        "weight": "High",
        "templates": [
            "If you're not doing {topic}, you're losing out...",
            "This {topic} trend is about to explode...",
            "Before everyone figures out {topic}...",
            "Stop scrolling if you want to master {topic}...",
            "This {topic} method is going away soon...",
            "You're missing this about {topic}...",
            "The {topic} window is closing fast...",
        ],
    },
    "self_id": {
        "name": "Self-Identification",
        "description": "Immediate relevance to viewer",
        "weight": "High",
        "templates": [
            "If you struggle with {topic}, this is for you...",
            "POV: You're someone who needs {topic}...",
            "Only {audience} people will understand this {topic}...",
            "This is for my {audience} who want {topic}...",
            "Tag someone who needs this {topic}...",
            "If you've ever failed at {topic}...",
        ],
    },
    "controversy": {
        "name": "Controversy",
        "description": "Challenges beliefs to drive engagement",
        "weight": "Medium-High",
        "templates": [
            "{topic} is a scam and here's why...",
            "I'm sorry but {topic} doesn't work...",
            "Hot take: {topic} is overrated...",
            "Why everyone is wrong about {topic}...",
            "The {topic} industry is lying to you...",
            "Unpopular opinion: {topic} is...",
        ],
    },
    "specificity": {
        "name": "Specificity",
        "description": "Numbers create credibility",
        "weight": "High",
        "templates": [
            "3 exact steps to master {topic}...",
            "The 5-second {topic} trick that works...",
            "How I {topic} in just 7 days...",
            "The 80/20 rule of {topic}...",
            "{topic} in under 60 seconds...",
            "1 simple change that fixed my {topic}...",
        ],
    },
    "story": {
        "name": "Story Hook",
        "description": "Personal narrative drives connection",
        "weight": "High",
        "templates": [
            "I was about to give up on {topic} when...",
            "Nobody believed my {topic} story until...",
            "This one decision changed my {topic}...",
            "The moment I realized {topic}...",
            "A year ago, I couldn't {topic}. Now...",
            "My {topic} journey started with...",
        ],
    },
    "educational": {
        "name": "Educational",
        "description": "Direct value proposition",
        "weight": "High",
        "templates": [
            "Here's exactly how to {topic} in 2025...",
            "5 things I wish I knew before {topic}...",
            "The simple trick that changed my {topic}...",
            "Why the typical {topic} approach doesn't work...",
            "Master {topic} with this one technique...",
            "The beginner's guide to {topic}...",
        ],
    },
}

# Platform-specific modifications
PLATFORM_MODS = {
    "tiktok": {
        "max_length": 80,
        "style": "punchy",
        "notes": [
            "Pair with trending sound",
            "Use text overlay for first frame",
            "Add visual hook (movement, surprise)",
        ],
    },
    "youtube-shorts": {
        "max_length": 100,
        "style": "slightly_longer",
        "notes": [
            "Thumbnail preview matters",
            "Can tease longer content",
            "Add end CTA for engagement",
        ],
    },
    "youtube-long": {
        "max_length": 150,
        "style": "detailed",
        "notes": [
            "Can be 5-10 seconds spoken",
            "Preview the payoff",
            "Hook + roadmap works well",
        ],
    },
    "instagram": {
        "max_length": 90,
        "style": "visual_first",
        "notes": [
            "3/8/12 rule applies",
            "Text overlay hooks popular",
            "Aesthetic matters more",
        ],
    },
    "facebook": {
        "max_length": 90,
        "style": "share_worthy",
        "notes": [
            "Optimize for shares",
            "Conversation starters",
            "Broader audience appeal",
        ],
    },
}

# Audience/niche suggestions
AUDIENCES = [
    "busy professionals",
    "beginners",
    "entrepreneurs",
    "students",
    "parents",
    "creators",
    "health-conscious",
    "tech-savvy",
    "budget-minded",
    "ambitious",
]


def generate_hooks(
    topic: str,
    platform: str = "tiktok",
    triggers: List[str] = None,
    count: int = 10,
    audience: str = None,
) -> List[Dict[str, Any]]:
    """Generate hook variations for a topic."""
    hooks = []

    # Use specified triggers or all
    if triggers:
        template_keys = [t for t in triggers if t in HOOK_TEMPLATES]
    else:
        template_keys = list(HOOK_TEMPLATES.keys())

    platform_config = PLATFORM_MODS.get(platform, PLATFORM_MODS["tiktok"])

    # Select random audience if not specified
    aud = audience or random.choice(AUDIENCES)

    for _ in range(count):
        trigger_key = random.choice(template_keys)
        trigger = HOOK_TEMPLATES[trigger_key]
        template = random.choice(trigger["templates"])

        # Generate hook
        hook_text = template.format(
            topic=topic,
            industry=topic.split()[0] if " " in topic else topic,
            audience=aud,
        )

        # Trim to platform max length
        if len(hook_text) > platform_config["max_length"]:
            hook_text = hook_text[: platform_config["max_length"] - 3] + "..."

        hooks.append({
            "hook": hook_text,
            "trigger": trigger_key,
            "trigger_name": trigger["name"],
            "weight": trigger["weight"],
            "platform": platform,
            "length": len(hook_text),
        })

    # Remove duplicates and sort by trigger diversity
    seen = set()
    unique_hooks = []
    for h in hooks:
        if h["hook"] not in seen:
            seen.add(h["hook"])
            unique_hooks.append(h)

    return unique_hooks[:count]


def generate_visual_hooks(topic: str) -> List[Dict[str, str]]:
    """Generate visual hook suggestions."""
    return [
        {
            "type": "Result First",
            "description": f"Show the end result of {topic} immediately",
            "example": "Before → After transformation in first frame",
        },
        {
            "type": "Unexpected Element",
            "description": "Start with something visually surprising",
            "example": "Unusual angle, unexpected prop, or dramatic movement",
        },
        {
            "type": "Face + Emotion",
            "description": "Lead with expressive reaction",
            "example": "Shocked, excited, or confused expression",
        },
        {
            "type": "Text Overlay",
            "description": f"Bold text stating the {topic} hook",
            "example": "Large, animated text matching the verbal hook",
        },
        {
            "type": "Movement",
            "description": "Physical action in first frame",
            "example": "Walking in, jumping, or dynamic camera movement",
        },
    ]


def generate_audio_suggestions(platform: str) -> List[Dict[str, str]]:
    """Generate audio/sound suggestions."""
    suggestions = [
        {
            "type": "Trending Sound",
            "description": "Use current trending audio from platform",
            "where_to_find": f"Check {platform}'s Creative Center or trending tab",
        },
        {
            "type": "Original Voiceover",
            "description": "Clear, energetic voiceover (not AI)",
            "note": "35% drop-off with AI narration",
        },
        {
            "type": "Sound Effect Accent",
            "description": "Dramatic sound effect to punctuate hook",
            "examples": "Whoosh, ding, record scratch, boom",
        },
    ]

    if platform == "tiktok":
        suggestions.append({
            "type": "Viral Sound Remix",
            "description": "Put your spin on trending audio",
            "note": "88% of TikTok users say sound is essential",
        })

    return suggestions


def print_report(
    topic: str,
    hooks: List[Dict[str, Any]],
    platform: str,
    visual_hooks: List[Dict[str, str]],
    audio_suggestions: List[Dict[str, str]],
):
    """Print formatted hook report."""
    platform_config = PLATFORM_MODS.get(platform, PLATFORM_MODS["tiktok"])

    print(f"\n{'='*70}")
    print(f"🎬 VIRAL HOOK GENERATOR")
    print(f"{'='*70}")
    print(f"\n📌 Topic: {topic}")
    print(f"📱 Platform: {platform}")
    print(f"📏 Max Hook Length: {platform_config['max_length']} characters")

    print(f"\n{'─'*70}")
    print("🎯 HOOK VARIATIONS")
    print(f"{'─'*70}")

    for i, hook in enumerate(hooks, 1):
        print(f"\n{i}. \"{hook['hook']}\"")
        print(f"   Trigger: {hook['trigger_name']} ({hook['weight']} weight)")
        print(f"   Length: {hook['length']} chars")

    print(f"\n{'─'*70}")
    print("👁️ VISUAL HOOK SUGGESTIONS")
    print(f"{'─'*70}")

    for vh in visual_hooks:
        print(f"\n• {vh['type']}")
        print(f"  {vh['description']}")
        print(f"  Example: {vh['example']}")

    print(f"\n{'─'*70}")
    print("🔊 AUDIO SUGGESTIONS")
    print(f"{'─'*70}")

    for audio in audio_suggestions:
        print(f"\n• {audio['type']}")
        print(f"  {audio['description']}")
        if "note" in audio:
            print(f"  Note: {audio['note']}")

    print(f"\n{'─'*70}")
    print(f"💡 PLATFORM TIPS ({platform.upper()})")
    print(f"{'─'*70}")

    for note in platform_config["notes"]:
        print(f"• {note}")

    print(f"\n{'─'*70}")
    print("🧪 A/B TESTING SUGGESTIONS")
    print(f"{'─'*70}")

    if len(hooks) >= 3:
        print("\nTest these hooks against each other:")
        # Group by trigger type
        triggers_used = set(h["trigger"] for h in hooks)
        if len(triggers_used) >= 2:
            trigger_list = list(triggers_used)[:3]
            print(f"• Curiosity-based vs Story-based vs FOMO-based hooks")
            for i, trigger in enumerate(trigger_list):
                example = next(h for h in hooks if h["trigger"] == trigger)
                print(f"  {i+1}. {HOOK_TEMPLATES[trigger]['name']}: \"{example['hook'][:50]}...\"")

    print(f"\n{'='*70}\n")


def main():
    parser = argparse.ArgumentParser(
        description="Generate viral hook variations using psychological triggers."
    )
    parser.add_argument(
        "--topic",
        "-t",
        required=True,
        help="Video topic or subject",
    )
    parser.add_argument(
        "--platform",
        "-p",
        choices=list(PLATFORM_MODS.keys()),
        default="tiktok",
        help="Target platform (default: tiktok)",
    )
    parser.add_argument(
        "--triggers",
        help="Comma-separated triggers: curiosity,fomo,story,etc.",
    )
    parser.add_argument(
        "--count",
        "-n",
        type=int,
        default=10,
        help="Number of hooks to generate (default: 10)",
    )
    parser.add_argument(
        "--audience",
        "-a",
        help="Target audience (e.g., 'busy professionals')",
    )
    parser.add_argument(
        "--format",
        "-f",
        choices=["text", "json"],
        default="text",
        help="Output format",
    )
    parser.add_argument(
        "--list-triggers",
        action="store_true",
        help="List available psychological triggers",
    )

    args = parser.parse_args()

    if args.list_triggers:
        print("\nAvailable Psychological Triggers:")
        print("=" * 50)
        for key, trigger in HOOK_TEMPLATES.items():
            print(f"\n{key}:")
            print(f"  Name: {trigger['name']}")
            print(f"  Weight: {trigger['weight']}")
            print(f"  Description: {trigger['description']}")
        return

    triggers = args.triggers.split(",") if args.triggers else None

    hooks = generate_hooks(
        topic=args.topic,
        platform=args.platform,
        triggers=triggers,
        count=args.count,
        audience=args.audience,
    )

    visual_hooks = generate_visual_hooks(args.topic)
    audio_suggestions = generate_audio_suggestions(args.platform)

    if args.format == "json":
        output = {
            "topic": args.topic,
            "platform": args.platform,
            "hooks": hooks,
            "visual_suggestions": visual_hooks,
            "audio_suggestions": audio_suggestions,
            "platform_tips": PLATFORM_MODS[args.platform]["notes"],
        }
        print(json.dumps(output, indent=2))
    else:
        print_report(
            args.topic,
            hooks,
            args.platform,
            visual_hooks,
            audio_suggestions,
        )


if __name__ == "__main__":
    main()
