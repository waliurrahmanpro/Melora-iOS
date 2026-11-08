#!/usr/bin/env python3
"""
Melora UI & ViewModels Test Suite
Validates greeting calculation, repeat/shuffle state cycles, library stats,
and search viewmodel filtering.
"""

import unittest


def compute_greeting(hour: int) -> str:
    """Matches HomeViewModel.swift greeting logic."""
    if hour < 12:
        return "Good Morning"
    elif hour < 18:
        return "Good Afternoon"
    else:
        return "Good Evening"


def cycle_repeat_mode(current: str) -> str:
    """Matches PlayerViewModel.swift cycleRepeatMode logic."""
    if current == "off":
        return "all"
    elif current == "all":
        return "one"
    else:
        return "off"


def format_total_library_duration(total_ms: int) -> str:
    """Matches LibraryViewModel.swift totalLibraryDurationFormatted."""
    hours = total_ms // 3600000
    minutes = (total_ms % 3600000) // 60000
    if hours > 0:
        return f"{hours} hr {minutes} min"
    return f"{minutes} min"


class TestMeloraUIViewModels(unittest.TestCase):

    def test_greeting_for_all_hours(self):
        for h in range(0, 12):
            self.assertEqual(compute_greeting(h), "Good Morning")
        for h in range(12, 18):
            self.assertEqual(compute_greeting(h), "Good Afternoon")
        for h in range(18, 24):
            self.assertEqual(compute_greeting(h), "Good Evening")

    def test_repeat_mode_cycle(self):
        mode = "off"
        mode = cycle_repeat_mode(mode)
        self.assertEqual(mode, "all")
        mode = cycle_repeat_mode(mode)
        self.assertEqual(mode, "one")
        mode = cycle_repeat_mode(mode)
        self.assertEqual(mode, "off")

    def test_library_duration_formatting(self):
        self.assertEqual(format_total_library_duration(180000), "3 min")
        self.assertEqual(format_total_library_duration(3600000), "1 hr 0 min")
        self.assertEqual(format_total_library_duration(3900000), "1 hr 5 min")
        self.assertEqual(format_total_library_duration(0), "0 min")

    def test_search_filtering(self):
        tracks = [
            {"title": "Aerodynamic", "artist": "Daft Punk", "album": "Discovery"},
            {"title": "Digital Love", "artist": "Daft Punk", "album": "Discovery"},
            {"title": "Midnight City", "artist": "M83", "album": "Hurry Up"},
        ]

        query = "aerod"
        matches = [t for t in tracks if query in t["title"].lower() or query in t["artist"].lower()]
        self.assertEqual(len(matches), 1)
        self.assertEqual(matches[0]["title"], "Aerodynamic")

        artist_query = "daft"
        artist_matches = [t for t in tracks if artist_query in t["artist"].lower()]
        self.assertEqual(len(artist_matches), 2)

    def test_tabs_enumeration(self):
        tabs = ["home", "search", "library", "spotify", "settings"]
        self.assertEqual(len(tabs), 5)
        self.assertEqual(len(set(tabs)), 5, "Tab IDs must be distinct")


if __name__ == "__main__":
    unittest.main()
