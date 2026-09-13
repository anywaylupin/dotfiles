#!/usr/bin/env python3
"""The date, with one calendar carrying both reckonings.

Like the Windows calendar: each cell shows the Gregorian day with the lunar day
underneath, so 初一 marks where a lunar month turns over. Waybar's own clock
calendar cannot do this - it renders through glibc locale data, and no zh_CN
locale is generated here anyway.

Lunar conversion is in lunar.py, verified against known Chinese New Years.
"""

import calendar
import json
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from lunar import to_lunar, day_name, month_name, short   # noqa: E402

WEEKDAY = "一二三四五六日"                    # Monday-first, matching weekday()
HEADERS = ["日", "一", "二", "三", "四", "五", "六"]


def grid(today: date) -> str:
    """A month where every cell is two lines: Gregorian over lunar."""
    cal = calendar.Calendar(firstweekday=6)
    rows = ["  ".join(f"{h:^4}" for h in HEADERS)]

    for week in cal.monthdatescalendar(today.year, today.month):
        top, bottom = [], []
        for day in week:
            if day.month != today.month:
                top.append("    ")
                bottom.append("    ")
                continue
            label = f"{day.day:2}"
            lunar = short(day)
            if day == today:
                top.append(f"<b>[{label}]</b>".rjust(4))
                bottom.append(f"<b>{lunar:^4}</b>")
            else:
                top.append(f"{label:^4}")
                bottom.append(f"<span alpha='60%'>{lunar:^4}</span>")
        rows.append("  ".join(top))
        rows.append("  ".join(bottom))
        rows.append("")
    return "\n".join(rows).rstrip()


def main() -> None:
    today = date.today()
    _, month, day, leap = to_lunar(today)
    lunar_full = f"{month_name(month, leap)}{day_name(day)}"

    text = f"{today.month}月{today.day}日 星期{WEEKDAY[today.weekday()]}"

    tooltip = "\n".join([
        f"<b>{today.year}年{text}</b>",
        f"农历 {lunar_full}",
        "",
        f"<tt>{grid(today)}</tt>",
    ])

    print(json.dumps({"text": text, "tooltip": tooltip, "class": "date"}))


if __name__ == "__main__":
    main()
