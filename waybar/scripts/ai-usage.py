#!/usr/bin/env python3
"""Claude Code usage for the waybar bot module.

Claude's limits are two rolling windows - a 5-hour one and a weekly one - so
this reports both and lets the tighter of the two decide the bot's mood:

    idle     plenty left, the bot pootles along
    tired    one window past the warning mark
    sleeping one window nearly spent

Token counts come from Claude Code's own transcripts under ~/.claude/projects.
Assistant records carry `message.usage`, so the numbers are exact, local, and
cost no API call.

The ceilings below are approximations. Anthropic publishes limits as usage
allowances rather than token counts, so these are tuned to be useful rather than
authoritative - override them with ARCHCONFIG_AI_5H and ARCHCONFIG_AI_WEEK.

Output is waybar `custom` JSON. The icon is set from CSS by class, not from
here, because librsvg ignores animation inside an SVG: the widget animates, the
artwork stays still.
"""

import json
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

PROJECTS = Path.home() / ".claude" / "projects"

# Billable tokens per window before the bot starts to flag.
CEILING_5H   = int(os.environ.get("ARCHCONFIG_AI_5H",   3_000_000))
CEILING_WEEK = int(os.environ.get("ARCHCONFIG_AI_WEEK", 40_000_000))

WARN, SPENT = 0.55, 0.85     # tired above WARN, sleeping above SPENT


def parse_stamp(value):
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None


def collect():
    """Billable tokens in the last 5 hours and the last 7 days."""
    now = datetime.now(timezone.utc)
    since_5h, since_week = now - timedelta(hours=5), now - timedelta(days=7)

    window = {"h5": 0, "week": 0, "turns_5h": 0, "turns_week": 0,
              "cache": 0, "models": set(), "last": None}

    if not PROJECTS.is_dir():
        return window

    for path in PROJECTS.rglob("*.jsonl"):
        try:
            if datetime.fromtimestamp(path.stat().st_mtime, timezone.utc) < since_week:
                continue                      # whole file predates the widest window
        except OSError:
            continue

        try:
            with path.open("r", errors="replace") as handle:
                for line in handle:
                    if '"usage"' not in line:
                        continue
                    try:
                        record = json.loads(line)
                    except ValueError:
                        continue

                    stamp = parse_stamp(record.get("timestamp"))
                    if not stamp or stamp < since_week:
                        continue

                    message = record.get("message")
                    if not isinstance(message, dict):
                        continue
                    usage = message.get("usage")
                    if not isinstance(usage, dict):
                        continue

                    billable = (usage.get("input_tokens") or 0) + (usage.get("output_tokens") or 0)
                    cached = (usage.get("cache_read_input_tokens") or 0)

                    window["week"] += billable
                    window["turns_week"] += 1
                    window["cache"] += cached
                    if message.get("model"):
                        window["models"].add(message["model"])
                    if not window["last"] or stamp > window["last"]:
                        window["last"] = stamp

                    if stamp >= since_5h:
                        window["h5"] += billable
                        window["turns_5h"] += 1
        except OSError:
            continue

    return window


def compact(n):
    if n >= 1_000_000:
        return f"{n / 1_000_000:.1f}M"
    if n >= 1_000:
        return f"{n / 1_000:.0f}k"
    return str(n)


def bar(ratio, width=14):
    filled = min(width, int(ratio * width + 0.5))
    return "█" * filled + "░" * (width - filled)


def main():
    w = collect()

    r5 = w["h5"] / CEILING_5H if CEILING_5H else 0
    rw = w["week"] / CEILING_WEEK if CEILING_WEEK else 0
    worst = max(r5, rw)

    if w["turns_week"] == 0:
        state, mood = "idle", "nothing logged this week"
    elif worst >= SPENT:
        state, mood = "sleeping", "limit nearly spent, resting"
    elif worst >= WARN:
        state, mood = "tired", "past the warning mark"
    else:
        state, mood = "idle", "plenty of headroom"

    tight = "5 hour" if r5 >= rw else "week"
    last = "never"
    if w["last"]:
        mins = int((datetime.now(timezone.utc) - w["last"]).total_seconds() // 60)
        last = "just now" if mins < 1 else (f"{mins}m ago" if mins < 90 else f"{mins // 60}h ago")

    tooltip = "\n".join([
        f"<b>Claude Code</b>  <i>{mood}</i>",
        "",
        f"5 hour   {bar(r5)}  {int(r5 * 100):>3}%   {compact(w['h5'])} / {compact(CEILING_5H)}",
        f"week     {bar(rw)}  {int(rw * 100):>3}%   {compact(w['week'])} / {compact(CEILING_WEEK)}",
        "",
        f"tighter window   {tight}",
        f"turns            {w['turns_5h']} in 5h, {w['turns_week']} this week",
        f"cache served     {compact(w['cache'])}",
        f"model            {', '.join(sorted(w['models'])) or 'none'}",
        f"last activity    {last}",
    ])

    print(json.dumps({
        "text": f"{int(worst * 100)}%",
        "alt": state,                    # CSS hooks on this for the artwork
        "tooltip": tooltip,
        "class": state,
        "percentage": min(100, int(worst * 100)),
    }))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(json.dumps({"text": "", "alt": "idle", "class": "error",
                          "tooltip": f"ai-usage error: {exc}"}))
