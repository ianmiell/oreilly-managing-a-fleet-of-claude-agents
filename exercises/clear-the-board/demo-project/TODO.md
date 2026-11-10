# TODO

Work through these in order. Each one is small; run the tests and commit after each.

1. Add type hints to `parse_level` in `logtool/parser.py`
2. Add type hints to `parse_line`
3. Add type hints to `parse_duration`
4. Add type hints to `is_error` and `read_log`
5. Make `parse_level` accept `fatal` as another name for `CRITICAL`
6. Make `parse_duration` accept `d` for days (`2d4h`)
7. Make `parse_line` accept timestamps ending in `Z` (UTC)
8. Add `count_by_component(entries)` to `parser.py`, returning a dict of component to count, with a test
9. Add an optional `since` argument to `read_log` (a datetime: only yield entries at or after it), with a test
10. Make `read_log` read standard input when the path is `-`, with a test
11. Add a `components` command that lists each component and how many entries it has
12. Add a `--since` option to `errors` that takes a duration such as `1h`, counted back from the last entry in the log
13. Make every command print a clear message and exit with status 2 if the log file doesn't exist
14. Add a `--json` option to `stats` that prints the counts as a JSON object
15. Add `__version__ = "0.2.0"` to `logtool/__init__.py` and a `--version` option
16. Add type hints to every function in `logtool/cli.py`
17. Write a test for the `stats` command using `sample.log`
18. Write a test for the `errors` command using `sample.log`
19. Write a test for the `top` command using `sample.log`, including `--limit`
20. Write a test for the `components` command using `sample.log`
21. Add a `Makefile` with `test` and `lint` targets
22. Add a GitHub Actions workflow that runs the tests on every push
23. Add a `CHANGELOG.md` that lists every change made from this file
