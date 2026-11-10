"""Parse application log lines.

A line looks like:

    2026-11-10T09:15:02 ERROR [db] connection refused
"""

import re
from datetime import datetime

LEVELS = ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL")

_LINE = re.compile(r"^(\S+)\s+(\w+)\s+\[([^\]]+)\]\s+(.*)$")
_DURATION = re.compile(r"(\d+)([hms])")
_SECONDS = {"h": 3600, "m": 60, "s": 1}


def parse_level(text):
    """Normalise a level name, so 'warn' and 'Warning' both become 'WARNING'."""
    level = text.strip().upper()
    if level == "WARN":
        return "WARNING"
    if level not in LEVELS:
        raise ValueError(f"unknown level: {text!r}")
    return level


def parse_line(line):
    match = _LINE.match(line.strip())
    if not match:
        return None
    stamp, level, component, message = match.groups()
    return {
        "time": datetime.fromisoformat(stamp),
        "level": parse_level(level),
        "component": component,
        "message": message,
    }


def parse_duration(text):
    """Turn a duration like '1h30m' or '45s' into a number of seconds."""
    if not text:
        raise ValueError("empty duration")
    total = 0
    position = 0
    for match in _DURATION.finditer(text):
        if match.start() != position:
            raise ValueError(f"bad duration: {text!r}")
        total += int(match.group(1)) * _SECONDS[match.group(2)]
        position = match.end()
    if position != len(text):
        raise ValueError(f"bad duration: {text!r}")
    return total


def is_error(entry):
    return entry["level"] in ("ERROR", "CRITICAL")


def read_log(path):
    """Yield the parsed entries in a log file, skipping lines that don't parse."""
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            entry = parse_line(line)
            if entry is not None:
                yield entry
