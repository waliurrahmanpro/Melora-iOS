#!/usr/bin/env python3
"""
Melora Audio Engine & Playback Coordinator Test Suite
Validates queue sequencing, shuffle/repeat state machines, interruption handling,
route change logic, and listening session history accumulation without iOS SDK dependencies.
"""

import random
import time
import unittest


class SimulatedQueueManager:
    """Python simulation of QueueManager.swift logic."""

    def __init__(self):
        self.original_tracks = []
        self.active_queue = []
        self.active_index = 0
        self.repeat_mode = "off"  # "off", "all", "one"
        self.shuffle_mode = "off"  # "off", "on"

    @property
    def current_track(self):
        if 0 <= self.active_index < len(self.active_queue):
            return self.active_queue[self.active_index]
        return None

    def set_queue(self, tracks, start_index=0):
        self.original_tracks = list(tracks)
        safe_index = min(max(start_index, 0), max(0, len(tracks) - 1))

        if self.shuffle_mode == "on" and tracks:
            selected = self.original_tracks[safe_index]
            remaining = [t for t in self.original_tracks if t["id"] != selected["id"]]
            random.shuffle(remaining)
            self.active_queue = [selected] + remaining
            self.active_index = 0
        else:
            self.active_queue = list(tracks)
            self.active_index = safe_index

    def set_shuffle_mode(self, mode):
        if mode == self.shuffle_mode or not self.active_queue:
            self.shuffle_mode = mode
            return

        self.shuffle_mode = mode
        current = self.current_track

        if mode == "on":
            remaining = [t for t in self.original_tracks if t["id"] != current["id"]]
            random.shuffle(remaining)
            self.active_queue = [current] + remaining
            self.active_index = 0
        else:
            self.active_queue = list(self.original_tracks)
            for i, t in enumerate(self.original_tracks):
                if t["id"] == current["id"]:
                    self.active_index = i
                    break

    def next_track(self):
        if not self.active_queue:
            return None

        if self.repeat_mode == "one":
            return self.active_queue[self.active_index]

        if self.active_index + 1 < len(self.active_queue):
            self.active_index += 1
            return self.active_queue[self.active_index]
        elif self.repeat_mode == "all":
            self.active_index = 0
            return self.active_queue[0]

        return None

    def previous_track(self, current_position_seconds):
        if not self.active_queue:
            return None, False

        # If played > 3.0 seconds, restart current track
        if current_position_seconds > 3.0:
            return self.active_queue[self.active_index], True

        if self.active_index > 0:
            self.active_index -= 1
            return self.active_queue[self.active_index], False
        elif self.repeat_mode == "all":
            self.active_index = len(self.active_queue) - 1
            return self.active_queue[self.active_index], False

        return self.active_queue[self.active_index], True


class SimulatedAudioPlaybackCoordinator:
    """Python simulation of AudioPlaybackCoordinator.swift history & interruption logic."""

    def __init__(self, pause_on_headphone_disconnect=True, min_seconds=30, completion_threshold=0.70):
        self.is_playing = False
        self.current_track = None
        self.accumulated_seconds = 0.0
        self.last_play_timestamp = None
        self.was_playing_before_interruption = False
        self.history_records = []
        self.pause_on_headphone_disconnect = pause_on_headphone_disconnect
        self.min_seconds = min_seconds
        self.completion_threshold = completion_threshold

    def play(self, track=None):
        if track:
            if self.current_track and self.current_track["id"] != track["id"]:
                self.finalize_history()
            self.current_track = track

        self.is_playing = True
        self.last_play_timestamp = time.time()

    def pause(self):
        if self.is_playing:
            self.is_playing = False
            if self.last_play_timestamp:
                self.accumulated_seconds += time.time() - self.last_play_timestamp
                self.last_play_timestamp = None

    def add_simulated_playtime(self, seconds):
        self.accumulated_seconds += seconds

    def finalize_history(self, completed=False):
        if self.last_play_timestamp:
            self.accumulated_seconds += time.time() - self.last_play_timestamp
            self.last_play_timestamp = None

        total_played = self.accumulated_seconds
        self.accumulated_seconds = 0.0

        if not self.current_track:
            return

        duration = self.current_track.get("duration_seconds", 0)
        completion = min(total_played / duration, 1.0) if duration > 0 else 0.0

        if completed or total_played >= self.min_seconds or completion >= self.completion_threshold:
            self.history_records.append({
                "track_id": self.current_track["id"],
                "total_played_seconds": total_played,
                "completion": completion
            })

    def handle_interruption_began(self):
        self.was_playing_before_interruption = self.is_playing
        self.pause()

    def handle_interruption_ended(self, should_resume):
        if self.was_playing_before_interruption and should_resume:
            self.play()
        self.was_playing_before_interruption = False

    def handle_headphones_disconnected(self):
        if self.pause_on_headphone_disconnect and self.is_playing:
            self.pause()


class TestMeloraAudioEngine(unittest.TestCase):

    def setUp(self):
        self.tracks = [
            {"id": f"trk_{i}", "title": f"Song {i}", "duration_seconds": 180.0}
            for i in range(1, 6)
        ]

    def test_queue_sequential_navigation(self):
        q = SimulatedQueueManager()
        q.set_queue(self.tracks, start_index=0)
        self.assertEqual(q.current_track["id"], "trk_1")

        self.assertEqual(q.next_track()["id"], "trk_2")
        self.assertEqual(q.next_track()["id"], "trk_3")
        self.assertEqual(q.next_track()["id"], "trk_4")
        self.assertEqual(q.next_track()["id"], "trk_5")
        self.assertIsNone(q.next_track(), "Should stop at end with repeat off")

    def test_repeat_all_and_repeat_one(self):
        q = SimulatedQueueManager()
        q.set_queue(self.tracks, start_index=4)  # Start at last track (trk_5)

        # Repeat All: wraps to trk_1
        q.repeat_mode = "all"
        self.assertEqual(q.next_track()["id"], "trk_1")

        # Repeat One: repeats trk_1 indefinitely
        q.repeat_mode = "one"
        self.assertEqual(q.next_track()["id"], "trk_1")
        self.assertEqual(q.next_track()["id"], "trk_1")

    def test_shuffle_preserves_current_track_and_restores_order(self):
        q = SimulatedQueueManager()
        q.set_queue(self.tracks, start_index=2)  # Active: trk_3
        self.assertEqual(q.current_track["id"], "trk_3")

        # Turn shuffle on
        q.set_shuffle_mode("on")
        self.assertEqual(q.shuffle_mode, "on")
        self.assertEqual(q.current_track["id"], "trk_3")
        self.assertEqual(q.active_index, 0)
        self.assertEqual(len(q.active_queue), 5)

        # Turn shuffle off: original order must be intact, active track preserved
        q.set_shuffle_mode("off")
        self.assertEqual(q.shuffle_mode, "off")
        self.assertEqual(q.current_track["id"], "trk_3")
        self.assertEqual(q.active_index, 2)
        self.assertEqual([t["id"] for t in q.active_queue], ["trk_1", "trk_2", "trk_3", "trk_4", "trk_5"])

    def test_previous_track_threshold(self):
        q = SimulatedQueueManager()
        q.set_queue(self.tracks, start_index=2)  # trk_3

        # If played > 3.0s, restart current track
        track, should_restart = q.previous_track(current_position_seconds=12.0)
        self.assertEqual(track["id"], "trk_3")
        self.assertTrue(should_restart)

        # If played <= 3.0s, retreat to previous track
        track, should_restart = q.previous_track(current_position_seconds=1.0)
        self.assertEqual(track["id"], "trk_2")
        self.assertFalse(should_restart)

    def test_history_logging_accumulation_and_no_duplicate_on_pause(self):
        coordinator = SimulatedAudioPlaybackCoordinator(min_seconds=30, completion_threshold=0.70)
        track = {"id": "trk_100", "title": "Discovery", "duration_seconds": 200.0}

        coordinator.play(track)
        coordinator.add_simulated_playtime(15.0)

        # Pause and resume multiple times
        coordinator.pause()
        self.assertEqual(len(coordinator.history_records), 0, "Pausing must not log history")

        coordinator.play()
        coordinator.add_simulated_playtime(20.0)  # Total 35 seconds (> 30s threshold)
        coordinator.pause()
        self.assertEqual(len(coordinator.history_records), 0, "Pausing must not log history")

        # Track completes
        coordinator.finalize_history(completed=True)
        self.assertEqual(len(coordinator.history_records), 1)
        self.assertEqual(coordinator.history_records[0]["track_id"], "trk_100")
        self.assertGreaterEqual(coordinator.history_records[0]["total_played_seconds"], 35.0)

    def test_interruption_phone_call(self):
        coordinator = SimulatedAudioPlaybackCoordinator()
        track = {"id": "trk_1", "duration_seconds": 180.0}
        coordinator.play(track)
        self.assertTrue(coordinator.is_playing)

        # Incoming phone call begins
        coordinator.handle_interruption_began()
        self.assertFalse(coordinator.is_playing)
        self.assertTrue(coordinator.was_playing_before_interruption)

        # Phone call ends with should_resume = True
        coordinator.handle_interruption_ended(should_resume=True)
        self.assertTrue(coordinator.is_playing)

    def test_headphone_disconnect_pauses_playback(self):
        coordinator = SimulatedAudioPlaybackCoordinator(pause_on_headphone_disconnect=True)
        track = {"id": "trk_1", "duration_seconds": 180.0}
        coordinator.play(track)
        self.assertTrue(coordinator.is_playing)

        # Headphone unplugged
        coordinator.handle_headphones_disconnected()
        self.assertFalse(coordinator.is_playing, "Headphone disconnect must pause playback")


if __name__ == "__main__":
    unittest.main()
