"""Command-line interface: python3 -m logtool COMMAND LOGFILE"""

import argparse
from collections import Counter

from . import parser as logparser


def cmd_stats(args):
    counts = Counter(entry["level"] for entry in logparser.read_log(args.logfile))
    for level in logparser.LEVELS:
        print(f"{level:<9} {counts.get(level, 0)}")


def cmd_errors(args):
    for entry in logparser.read_log(args.logfile):
        if logparser.is_error(entry):
            print(f"{entry['time'].isoformat()} {entry['component']}: {entry['message']}")


def cmd_top(args):
    """Print the most common messages."""
    counts = Counter(entry["message"] for entry in logparser.read_log(args.logfile))
    for message, count in counts.most_common(args.limit):
        print(f"{count:>5}  {message}")


def main(argv=None):
    """Run the command named on the command line."""
    parser = argparse.ArgumentParser(prog="logtool", description="Summarise application logs.")
    commands = parser.add_subparsers(dest="command", required=True)

    stats = commands.add_parser("stats", help="count entries by level")
    stats.add_argument("logfile")
    stats.set_defaults(func=cmd_stats)

    errors = commands.add_parser("errors", help="print ERROR and CRITICAL entries")
    errors.add_argument("logfile")
    errors.set_defaults(func=cmd_errors)

    top = commands.add_parser("top", help="print the most common messages")
    top.add_argument("logfile")
    top.add_argument("-n", "--limit", type=int, default=5, help="how many messages to show (default: 5)")
    top.set_defaults(func=cmd_top)

    args = parser.parse_args(argv)
    args.func(args)  
    return 0
