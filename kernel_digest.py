#!/usr/bin/env python3
"""
lkml-digest — print notable new LKML threads at shell startup.

Uses lore.kernel.org Atom feeds (no external deps, stdlib only).
Tracks seen Message-IDs in a state file to avoid reprinting.

Usage:
    python3 lkml-digest.py          # normal run
    python3 lkml-digest.py --reset  # clear seen-IDs and reprint everything

Add to ~/.bashrc or ~/.zshrc:
    python3 ~/bin/lkml-digest.py
"""

import sys
import os
import json
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from datetime import datetime, timezone, timedelta
from pathlib import Path

# ─── CONFIG ──────────────────────────────────────────────────────────────────

# Each entry: (label, lore_list, optional_search_query)
# query uses lore search syntax: s: = subject, f: = from, b: = body
# Leave query as None to get all recent threads from the list.
FEEDS = [
    # USB / xHCI
    ("USB",        "linux-usb",       "s:xhci OR s:usb3 OR s:hub"),
    # Memory management / allocators
    ("MM",         "linux-mm",        "s:buddy OR s:allocator OR s:PMM OR s:slab"),
    # Scheduler
    ("SCHED",      "linux-kernel",    "s:sched OR s:scheduler OR s:CFS OR s:EEVDF"),
    # Filesystems
    ("FS",         "linux-fsdevel",   "s:tmpfs OR s:vfs OR s:inode"),
    # Block layer
    ("BLOCK",      "linux-block",     "s:bio OR s:blk OR s:elevator"),
    # Driver core / PCI
    ("DRIVERS",    "linux-kernel",    "s:xhci OR s:driver OR s:pci"),
]

# How many threads to show per feed (0 = no limit)
MAX_PER_FEED = 5

# Only show threads newer than this many hours (0 = no filter)
MAX_AGE_HOURS = 48

# Where to persist seen Message-IDs
STATE_FILE = Path("~/.cache/lkml-digest-seen.json").expanduser()

# Request timeout in seconds
TIMEOUT = 8

# ─── ATOM NS ─────────────────────────────────────────────────────────────────

ATOM_NS = "http://www.w3.org/2005/Atom"

def _t(tag):
    return f"{{{ATOM_NS}}}{tag}"

# ─── ANSI COLORS (graceful fallback if not a tty) ────────────────────────────

USE_COLOR = sys.stdout.isatty()

def c(code, text):
    if not USE_COLOR:
        return text
    return f"\033[{code}m{text}\033[0m"

BOLD    = lambda t: c("1",    t)
DIM     = lambda t: c("2",    t)
CYAN    = lambda t: c("36",   t)
YELLOW  = lambda t: c("33",   t)
GREEN   = lambda t: c("32",   t)
RED     = lambda t: c("31",   t)
MAGENTA = lambda t: c("35",   t)

# ─── STATE ───────────────────────────────────────────────────────────────────

def load_seen():
    try:
        return set(json.loads(STATE_FILE.read_text()))
    except Exception:
        return set()

def save_seen(seen: set):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    # Keep a rolling window — cap at 4000 IDs to avoid unbounded growth
    ids = list(seen)[-4000:]
    STATE_FILE.write_text(json.dumps(ids))

# ─── FEED FETCH ──────────────────────────────────────────────────────────────

def build_url(lore_list: str, query: str | None) -> str:
    base = f"https://lore.kernel.org/{lore_list}/"
    if query:
        q = urllib.parse.quote(query)
        return f"{base}?q={q}&x=A"
    else:
        return f"{base}new.atom"

def fetch_atom(url: str) -> list[dict]:
    """Fetch and parse an Atom feed. Returns list of entry dicts."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "lkml-digest/1.0"})
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            data = resp.read()
    except urllib.error.URLError as e:
        print(DIM(f"  [fetch error: {e.reason}]"))
        return []
    except Exception as e:
        print(DIM(f"  [error: {e}]"))
        return []

    try:
        root = ET.fromstring(data)
    except ET.ParseError as e:
        print(DIM(f"  [XML parse error: {e}]"))
        return []

    entries = []
    for entry in root.findall(_t("entry")):
        mid_el  = entry.find(_t("id"))
        subj_el = entry.find(_t("title"))
        auth_el = entry.find(f"{_t('author')}/{_t('name')}")
        link_el = entry.find(_t("link"))
        date_el = entry.find(_t("updated"))

        mid    = mid_el.text.strip()  if mid_el  is not None else ""
        subj   = subj_el.text.strip() if subj_el is not None else "(no subject)"
        author = auth_el.text.strip() if auth_el is not None else "?"
        link   = link_el.get("href")  if link_el is not None else ""
        date   = date_el.text.strip() if date_el is not None else ""

        entries.append({"id": mid, "subject": subj, "author": author,
                        "link": link, "date": date})
    return entries

# ─── AGE FILTER ──────────────────────────────────────────────────────────────

def parse_iso(date_str: str) -> datetime | None:
    for fmt in ("%Y-%m-%dT%H:%M:%SZ", "%Y-%m-%dT%H:%M:%S+00:00",
                "%Y-%m-%dT%H:%M:%S%z"):
        try:
            dt = datetime.strptime(date_str, fmt)
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
        except ValueError:
            continue
    return None

def is_fresh(date_str: str, max_hours: int) -> bool:
    if max_hours == 0:
        return True
    dt = parse_iso(date_str)
    if dt is None:
        return True  # can't parse → show it
    cutoff = datetime.now(timezone.utc) - timedelta(hours=max_hours)
    return dt >= cutoff

# ─── DISPLAY ─────────────────────────────────────────────────────────────────

def shorten(text: str, width: int) -> str:
    return text if len(text) <= width else text[:width - 1] + "…"

def print_entry(label: str, entry: dict):
    subj   = shorten(entry["subject"], 72)
    author = shorten(entry["author"],  30)
    link   = entry["link"]
    print(f"  {GREEN(subj)}")
    print(f"  {DIM(author)}  {DIM(link)}")

# ─── MAIN ────────────────────────────────────────────────────────────────────

import urllib.parse  # needs to be here for build_url

def main():
    reset = "--reset" in sys.argv
    seen = set() if reset else load_seen()

    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    print(BOLD(CYAN(f"━━━ LKML digest  {now} ━━━")))

    new_seen = set(seen)
    any_new = False

    for (label, lore_list, query) in FEEDS:
        url = build_url(lore_list, query)
        entries = fetch_atom(url)

        fresh = [e for e in entries
                 if e["id"] not in seen
                 and is_fresh(e["date"], MAX_AGE_HOURS)]

        if MAX_PER_FEED:
            fresh = fresh[:MAX_PER_FEED]

        if not fresh:
            continue

        any_new = True
        count = len(fresh)
        print(f"\n{BOLD(YELLOW(f'[{label}]'))}  {DIM(f'{lore_list}')}"
              f"  {MAGENTA(f'+{count} thread(s)')}")
        for e in fresh:
            print_entry(label, e)
            new_seen.add(e["id"])

    if not any_new:
        print(DIM("  No new threads since last check."))

    print()  # trailing newline for shell prompt spacing
    save_seen(new_seen)

if __name__ == "__main__":
    main()
