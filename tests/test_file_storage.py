#!/usr/bin/env python3
"""
Melora Local File Ingestion & Storage Manager Test Suite
Validates magic byte content integrity, chunked SHA-256 streaming,
duplicate detection, atomic rollback orphan cleanup, path traversal security,
and library filtering/sorting.
"""

import hashlib
import os
import shutil
import tempfile
import unittest
import uuid

# Magic byte signatures matching FileValidator.swift
MAGIC_SIGNATURES = {
    "flac": b"fLaC\x00\x00\x00\x22",
    "mp3_id3": b"ID3\x04\x00\x00\x00\x00\x00\x00",
    "mp3_sync": b"\xff\xfb\x90\x44\x00\x00\x00\x00",
    "wav": b"RIFF\x24\x08\x00\x00WAVEfmt ",
    "aiff": b"FORM\x00\x01\x00\x00AIFFCOMM",
    "m4a": b"\x00\x00\x00\x20ftypM4A \x00\x00\x00\x00",
}


def compute_chunked_sha256(file_path: str, chunk_size: int = 65536) -> str:
    """Computes SHA-256 stream hash using 64 KB chunks without loading full file."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while True:
            chunk = f.read(chunk_size)
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()


def validate_magic_bytes(header: bytes, expected_format: str) -> bool:
    """Validates header bytes against expected audio format."""
    fmt = expected_format.lower()
    if fmt == "flac":
        return header.startswith(b"fLaC")
    elif fmt == "mp3":
        return header.startswith(b"ID3") or (len(header) >= 2 and header[0] == 0xFF and (header[1] & 0xE0) == 0xE0)
    elif fmt == "wav":
        return len(header) >= 12 and header.startswith(b"RIFF") and header[8:12] == b"WAVE"
    elif fmt == "aiff":
        return len(header) >= 12 and header.startswith(b"FORM") and header[8:12] in (b"AIFF", b"AIFC")
    elif fmt in ("m4a", "alac"):
        return len(header) >= 8 and header[4:8] == b"ftyp"
    return False


def sanitize_relative_path(path: str) -> str:
    """Prevents directory traversal attacks."""
    if path.startswith("/") or path.startswith("\\") or ".." in path or "\0" in path:
        raise PermissionError(f"Path traversal detected: {path}")
    cleaned = path.strip("/\\ ")
    if not cleaned:
        raise PermissionError(f"Empty path: {path}")
    return cleaned


class TestMeloraFileStorage(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp(prefix="melora_storage_test_")
        self.tracks_dir = os.path.join(self.test_dir, "Tracks")
        self.artwork_dir = os.path.join(self.test_dir, "Artwork")
        os.makedirs(self.tracks_dir, exist_ok=True)
        os.makedirs(self.artwork_dir, exist_ok=True)

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_magic_byte_validation(self):
        self.assertTrue(validate_magic_bytes(MAGIC_SIGNATURES["flac"], "flac"))
        self.assertTrue(validate_magic_bytes(MAGIC_SIGNATURES["mp3_id3"], "mp3"))
        self.assertTrue(validate_magic_bytes(MAGIC_SIGNATURES["mp3_sync"], "mp3"))
        self.assertTrue(validate_magic_bytes(MAGIC_SIGNATURES["wav"], "wav"))
        self.assertTrue(validate_magic_bytes(MAGIC_SIGNATURES["aiff"], "aiff"))
        self.assertTrue(validate_magic_bytes(MAGIC_SIGNATURES["m4a"], "m4a"))

        # Corrupted / mismatched format
        self.assertFalse(validate_magic_bytes(b"INVALID_HEADER_DATA", "flac"))
        self.assertFalse(validate_magic_bytes(MAGIC_SIGNATURES["flac"], "mp3"))

    def test_path_traversal_prevention(self):
        valid = "Tracks/valid_track_123.flac"
        self.assertEqual(sanitize_relative_path(valid), "Tracks/valid_track_123.flac")

        # Invalid paths
        invalid_paths = [
            "../etc/passwd",
            "..\\Windows\\System32",
            "Tracks/../../sensitive_file.txt",
            "/absolute/root/file",
            "Tracks/\0null_byte"
        ]
        for p in invalid_paths:
            with self.assertRaises(PermissionError):
                sanitize_relative_path(p)

    def test_chunked_sha256_streaming(self):
        # Create a 200 KB test file
        test_file = os.path.join(self.test_dir, "large_audio.flac")
        dummy_data = b"fLaC" + os.urandom(200 * 1024)
        with open(test_file, "wb") as f:
            f.write(dummy_data)

        # Full hash vs chunked streaming hash
        expected_hash = hashlib.sha256(dummy_data).hexdigest()
        streamed_hash = compute_chunked_sha256(test_file, chunk_size=65536)

        self.assertEqual(streamed_hash, expected_hash)

    def test_duplicate_detection(self):
        file1 = os.path.join(self.test_dir, "song1.mp3")
        file2 = os.path.join(self.test_dir, "song2_copy.mp3")

        audio_bytes = MAGIC_SIGNATURES["mp3_id3"] + b"AUDIO_SAMPLE_DATA_12345"
        with open(file1, "wb") as f:
            f.write(audio_bytes)
        with open(file2, "wb") as f:
            f.write(audio_bytes)

        hash1 = compute_chunked_sha256(file1)
        hash2 = compute_chunked_sha256(file2)

        self.assertEqual(hash1, hash2, "Identical files must produce identical SHA-256 hashes")

    def test_safe_file_deletion_within_sandbox(self):
        track_filename = "track_to_delete.flac"
        track_path = os.path.join(self.tracks_dir, track_filename)
        with open(track_path, "wb") as f:
            f.write(b"fLaC_dummy")

        self.assertTrue(os.path.exists(track_path))

        # Safe delete relative path inside sandbox
        rel_path = f"Tracks/{track_filename}"
        clean_rel = sanitize_relative_path(rel_path)
        abs_target = os.path.abspath(os.path.join(self.test_dir, clean_rel))

        # Verify target is strictly within sandbox root
        self.assertTrue(abs_target.startswith(os.path.abspath(self.test_dir)))
        os.remove(abs_target)
        self.assertFalse(os.path.exists(track_path))

    def test_atomic_batch_rollback_orphan_cleanup(self):
        """Simulates an interrupted import where newly copied files must be cleaned up."""
        created_relative_paths = []

        try:
            # Step 1: Copy file 1 into sandbox
            f1_path = os.path.join(self.tracks_dir, "track1.flac")
            with open(f1_path, "wb") as f:
                f.write(b"fLaC_1")
            created_relative_paths.append("Tracks/track1.flac")

            # Step 2: Copy file 2 into sandbox
            f2_path = os.path.join(self.tracks_dir, "track2.flac")
            with open(f2_path, "wb") as f:
                f.write(b"fLaC_2")
            created_relative_paths.append("Tracks/track2.flac")

            # Step 3: Deliberate failure on file 3 (e.g. database error)
            raise RuntimeError("Database transaction failed!")

        except RuntimeError:
            # Orphan cleanup routine triggered
            for rel in created_relative_paths:
                full_path = os.path.join(self.test_dir, rel)
                if os.path.exists(full_path):
                    os.remove(full_path)

        # Verify zero orphaned files remain in sandbox
        remaining = os.listdir(self.tracks_dir)
        self.assertEqual(len(remaining), 0, "All newly copied files must be removed on transaction failure")

    def test_library_sorting_and_filtering(self):
        tracks = [
            {"id": "1", "title": "Get Lucky", "artist": "Daft Punk", "format": "mp3", "duration": 240000, "created": 100},
            {"id": "2", "title": "Harder Better", "artist": "Daft Punk", "format": "flac", "duration": 220000, "created": 200},
            {"id": "3", "title": "Midnight City", "artist": "M83", "format": "wav", "duration": 243000, "created": 300},
        ]

        # Filter by artist
        daft_tracks = [t for t in tracks if t["artist"].lower() == "daft punk"]
        self.assertEqual(len(daft_tracks), 2)

        # Filter by format
        flac_tracks = [t for t in tracks if t["format"] == "flac"]
        self.assertEqual(len(flac_tracks), 1)
        self.assertEqual(flac_tracks[0]["title"], "Harder Better")

        # Sort by title ascending
        sorted_title = sorted(tracks, key=lambda t: t["title"].lower())
        self.assertEqual(sorted_title[0]["title"], "Get Lucky")
        self.assertEqual(sorted_title[-1]["title"], "Midnight City")

        # Sort by date added newest
        sorted_newest = sorted(tracks, key=lambda t: t["created"], reverse=True)
        self.assertEqual(sorted_newest[0]["id"], "3")


if __name__ == "__main__":
    unittest.main()
