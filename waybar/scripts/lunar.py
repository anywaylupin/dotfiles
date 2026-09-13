"""Chinese lunar date conversion.

No lunar calendar library exists in the Arch repos, so this is the standard
packed-table algorithm. Each year from 1900 is one integer:

    bits 16..4   month lengths, 1 = 30 days, 0 = 29, from month 1
    bits 3..0    which month is doubled as the leap month, 0 = none
    bit  16      length of that leap month

Verified against known Chinese New Year dates - see the self-test at the bottom.
"""

from datetime import date, timedelta

# 1900-2100.
LUNAR_INFO = [
    0x04BD8, 0x04AE0, 0x0A570, 0x054D5, 0x0D260, 0x0D950, 0x16554, 0x056A0, 0x09AD0, 0x055D2,
    0x04AE0, 0x0A5B6, 0x0A4D0, 0x0D250, 0x1D255, 0x0B540, 0x0D6A0, 0x0ADA2, 0x095B0, 0x14977,
    0x04970, 0x0A4B0, 0x0B4B5, 0x06A50, 0x06D40, 0x1AB54, 0x02B60, 0x09570, 0x052F2, 0x04970,
    0x06566, 0x0D4A0, 0x0EA50, 0x06E95, 0x05AD0, 0x02B60, 0x186E3, 0x092E0, 0x1C8D7, 0x0C950,
    0x0D4A0, 0x1D8A6, 0x0B550, 0x056A0, 0x1A5B4, 0x025D0, 0x092D0, 0x0D2B2, 0x0A950, 0x0B557,
    0x06CA0, 0x0B550, 0x15355, 0x04DA0, 0x0A5B0, 0x14573, 0x052B0, 0x0A9A8, 0x0E950, 0x06AA0,
    0x0AEA6, 0x0AB50, 0x04B60, 0x0AAE4, 0x0A570, 0x05260, 0x0F263, 0x0D950, 0x05B57, 0x056A0,
    0x096D0, 0x04DD5, 0x04AD0, 0x0A4D0, 0x0D4D4, 0x0D250, 0x0D558, 0x0B540, 0x0B6A0, 0x195A6,
    0x095B0, 0x049B0, 0x0A974, 0x0A4B0, 0x0B27A, 0x06A50, 0x06D40, 0x0AF46, 0x0AB60, 0x09570,
    0x04AF5, 0x04970, 0x064B0, 0x074A3, 0x0EA50, 0x06B58, 0x055C0, 0x0AB60, 0x096D5, 0x092E0,
    0x0C960, 0x0D954, 0x0D4A0, 0x0DA50, 0x07552, 0x056A0, 0x0ABB7, 0x025D0, 0x092D0, 0x0CAB5,
    0x0A950, 0x0B4A0, 0x0BAA4, 0x0AD50, 0x055D9, 0x04BA0, 0x0A5B0, 0x15176, 0x052B0, 0x0A930,
    0x07954, 0x06AA0, 0x0AD50, 0x05B52, 0x04B60, 0x0A6E6, 0x0A4E0, 0x0D260, 0x0EA65, 0x0D530,
    0x05AA0, 0x076A3, 0x096D0, 0x04AFB, 0x04AD0, 0x0A4D0, 0x1D0B6, 0x0D250, 0x0D520, 0x0DD45,
    0x0B5A0, 0x056D0, 0x055B2, 0x049B0, 0x0A577, 0x0A4B0, 0x0AA50, 0x1B255, 0x06D20, 0x0ADA0,
    0x14B63, 0x09370, 0x049F8, 0x04970, 0x064B0, 0x168A6, 0x0EA50, 0x06B20, 0x1A6C4, 0x0AAE0,
    0x0A2E0, 0x0D2E3, 0x0C960, 0x0D557, 0x0D4A0, 0x0DA50, 0x05D55, 0x056A0, 0x0A6D0, 0x055D4,
    0x052D0, 0x0A9B8, 0x0A950, 0x0B4A0, 0x0B6A6, 0x0AD50, 0x055A0, 0x0ABA4, 0x0A5B0, 0x052B0,
    0x0B273, 0x06930, 0x07337, 0x06AA0, 0x0AD50, 0x14B55, 0x04B60, 0x0A570, 0x054E4, 0x0D160,
    0x0E968, 0x0D520, 0x0DAA0, 0x16AA6, 0x056D0, 0x04AE0, 0x0A9D4, 0x0A2D0, 0x0D150, 0x0F252,
    0x0D520,
]

BASE = date(1900, 1, 31)                    # lunar 1900-01-01
CN_NUM = "〇一二三四五六七八九"
MONTHS = ["正", "二", "三", "四", "五", "六", "七", "八", "九", "十", "冬", "腊"]


def _leap_month(year):
    return LUNAR_INFO[year - 1900] & 0xF


def _leap_days(year):
    if not _leap_month(year):
        return 0
    return 30 if LUNAR_INFO[year - 1900] & 0x10000 else 29


def _month_days(year, month):
    return 30 if LUNAR_INFO[year - 1900] & (0x10000 >> month) else 29


def _year_days(year):
    total = 348                              # 12 * 29
    for i in range(1, 13):
        total += 1 if LUNAR_INFO[year - 1900] & (0x10000 >> i) else 0
    return total + _leap_days(year)


def to_lunar(gregorian):
    """(year, month, day, is_leap) for a Gregorian date."""
    offset = (gregorian - BASE).days
    if offset < 0:
        return None

    year = 1900
    while year < 2101:
        days = _year_days(year)
        if offset < days:
            break
        offset -= days
        year += 1

    leap = _leap_month(year)
    is_leap = False
    month = 1
    while month < 13:
        if leap and month == leap + 1 and not is_leap:
            is_leap = True
            days = _leap_days(year)
        else:
            is_leap = False
            days = _month_days(year, month)
        if offset < days:
            break
        offset -= days
        if not (leap and month == leap + 1 and is_leap):
            month += 1
    return year, month, offset + 1, is_leap


def day_name(day):
    """初一 ... 三十, the way lunar days are written."""
    if day <= 10:
        return "初" + (CN_NUM[day] if day < 10 else "十")
    if day < 20:
        return "十" + CN_NUM[day - 10]
    if day == 20:
        return "二十"
    if day < 30:
        return "廿" + CN_NUM[day - 20]
    return "三十"


def month_name(month, is_leap=False):
    return ("闰" if is_leap else "") + MONTHS[month - 1] + "月"


def short(gregorian):
    """What goes under a calendar cell: the day, or the month if it is the 1st."""
    result = to_lunar(gregorian)
    if not result:
        return ""
    _, month, day, is_leap = result
    return month_name(month, is_leap) if day == 1 else day_name(day)


if __name__ == "__main__":
    # Chinese New Year is lunar 1/1. If these land, the table is being read right.
    CHECKS = [
        (date(2024, 2, 10), "2024 CNY"),
        (date(2025, 1, 29), "2025 CNY"),
        (date(2026, 2, 17), "2026 CNY"),
        (date(2023, 1, 22), "2023 CNY"),
    ]
    for d, label in CHECKS:
        y, m, day, leap = to_lunar(d)
        status = "ok" if (m, day) == (1, 1) else "MISMATCH"
        print(f"  {label} {d}  ->  lunar {y}-{m}-{day}  {status}")
    today = date.today()
    y, m, day, leap = to_lunar(today)
    print(f"  today {today} -> {month_name(m, leap)}{day_name(day)}")
