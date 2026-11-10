import unittest
from datetime import datetime

from logtool.parser import parse_line


class ParseLineTest(unittest.TestCase):
    def test_parses_a_normal_line(self):
        entry = parse_line("2026-11-10T09:15:02 ERROR [db] connection refused")
        self.assertEqual(entry["time"], datetime(2026, 11, 10, 9, 15, 2))
        self.assertEqual(entry["level"], "ERROR")
        self.assertEqual(entry["component"], "db")
        self.assertEqual(entry["message"], "connection refused")


if __name__ == "__main__":
    unittest.main()
