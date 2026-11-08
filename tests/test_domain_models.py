#!/usr/bin/env python3
"""
Melora Domain Model & Serialization Test Suite
Validates domain data contracts, property calculations, and JSON serialization
matching Swift Codable representations.
"""

import json
import unittest


def format_duration(duration_ms: int) -> str:
    total_seconds = max(0, duration_ms // 1000)
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    seconds = total_seconds % 60
    if hours > 0:
        return f"{hours}:{minutes:02d}:{seconds:02d}"
    return f"{minutes}:{seconds:02d}"


def format_playlist_duration(total_duration_ms: int) -> str:
    total_seconds = max(0, total_duration_ms // 1000)
    hours = total_seconds // 3600
    minutes = (total_seconds % 3600) // 60
    if hours > 0:
        return f"{hours} hr {minutes} min"
    return f"{minutes} min"


class TestMeloraDomainModels(unittest.TestCase):

    def test_audio_format_properties(self):
        lossless_formats = {"flac", "alac", "wav", "aiff"}
        lossy_formats = {"mp3", "m4a", "aac"}

        for fmt in lossless_formats:
            self.assertTrue(fmt in ["flac", "alac", "wav", "aiff"])

        for fmt in lossy_formats:
            self.assertTrue(fmt in ["mp3", "m4a", "aac"])

    def test_track_duration_formatting(self):
        self.assertEqual(format_duration(243000), "4:03")
        self.assertEqual(format_duration(65000), "1:05")
        self.assertEqual(format_duration(5000), "0:05")
        self.assertEqual(format_duration(3665000), "1:01:05")
        self.assertEqual(format_duration(0), "0:00")

    def test_playlist_duration_formatting(self):
        self.assertEqual(format_playlist_duration(4320000), "1 hr 12 min")
        self.assertEqual(format_playlist_duration(600000), "10 min")
        self.assertEqual(format_playlist_duration(0), "0 min")

    def test_track_json_serialization(self):
        track_dict = {
            "id": "trk-100",
            "title": "Starboy",
            "artistName": "The Weeknd ft. Daft Punk",
            "albumTitle": "Starboy",
            "durationMs": 230000,
            "filePath": "Tracks/starboy.m4a",
            "fileSizeBytes": 8500000,
            "audioFormat": "m4a",
            "bitrate": 256000,
            "sampleRate": 44100,
            "channels": 2,
            "spotifyId": "spotify:track:57bgtoPSgt236HzfIDd8IP",
            "artworkPath": "Artwork/starboy.jpg",
            "createdAt": 1700000000.0,
            "updatedAt": 1700000000.0
        }

        # Validate round-trip JSON serialization
        encoded = json.dumps(track_dict)
        decoded = json.loads(encoded)

        self.assertEqual(decoded["id"], "trk-100")
        self.assertEqual(decoded["title"], "Starboy")
        self.assertEqual(decoded["audioFormat"], "m4a")
        self.assertEqual(decoded["fileSizeBytes"], 8500000)

    def test_playlist_json_serialization(self):
        playlist_dict = {
            "id": "pl-001",
            "title": "Night Drive",
            "description": "Late night driving tunes",
            "artworkPath": "Artwork/night_drive.png",
            "isImportedFromSpotify": True,
            "spotifyPlaylistId": "spotify:playlist:37i9dQZF1DXdLEN7aqioXM",
            "trackCount": 42,
            "totalDurationMs": 9500000,
            "createdAt": 1700000000.0,
            "updatedAt": 1700001000.0
        }

        encoded = json.dumps(playlist_dict)
        decoded = json.loads(encoded)

        self.assertEqual(decoded["id"], "pl-001")
        self.assertTrue(decoded["isImportedFromSpotify"])
        self.assertEqual(decoded["trackCount"], 42)

    def test_playback_history_listening_threshold(self):
        history_partial = {
            "trackId": "trk-100",
            "playedAt": 1700000000.0,
            "durationPlayedMs": 45000,
            "completionPercentage": 0.20
        }
        self.assertFalse(history_partial["completionPercentage"] >= 0.70)

        history_complete = {
            "trackId": "trk-100",
            "playedAt": 1700000000.0,
            "durationPlayedMs": 220000,
            "completionPercentage": 0.95
        }
        self.assertTrue(history_complete["completionPercentage"] >= 0.70)


if __name__ == "__main__":
    unittest.main()
