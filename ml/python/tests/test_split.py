"""Unit tests for Step 93: Deterministic 3-way session-grouped dataset partitioning."""
from __future__ import annotations

import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from meteor.split import (
    parse_clip_timestamp,
    group_clips_into_sessions,
    make_3way_split,
)


class TestSplit(unittest.TestCase):
    def test_parse_clip_timestamp(self):
        # Valid timestamp format
        dt = parse_clip_timestamp("REC_2020_10_29_04_38_55_F.npz")
        self.assertIsNotNone(dt)
        self.assertEqual(dt.year, 2020)
        self.assertEqual(dt.month, 10)
        self.assertEqual(dt.day, 29)
        self.assertEqual(dt.hour, 4)
        self.assertEqual(dt.minute, 38)
        self.assertEqual(dt.second, 55)

        # Case-insensitive format
        dt2 = parse_clip_timestamp("Rec_2020_10_11_04_35_02_F.npz")
        self.assertIsNotNone(dt2)
        self.assertEqual(dt2.year, 2020)

        # Non-matching filename
        dt_invalid = parse_clip_timestamp("some_random_clip.npz")
        self.assertIsNone(dt_invalid)

    def test_group_clips_into_sessions(self):
        clips = [
            "REC_2020_07_12_02_00_00_F.npz",
            "REC_2020_07_12_02_05_00_F.npz",  # 5 min later -> same session
            "REC_2020_07_12_03_00_00_F.npz",  # 55 min later -> new session
            "REC_2020_07_12_03_10_00_F.npz",  # 10 min later -> same session
            "unknown_timestamp.npz",          # singleton session
        ]
        sessions = group_clips_into_sessions(clips, gap_seconds=1800)
        self.assertEqual(len(sessions), 3)
        self.assertEqual(sessions[0], [
            "REC_2020_07_12_02_00_00_F.npz",
            "REC_2020_07_12_02_05_00_F.npz",
        ])
        self.assertEqual(sessions[1], [
            "REC_2020_07_12_03_00_00_F.npz",
            "REC_2020_07_12_03_10_00_F.npz",
        ])
        self.assertEqual(sessions[2], ["unknown_timestamp.npz"])

    def test_live_manifest_integrity(self):
        feat_dir = Path("C:/Users/admin/meteor-data/features")
        split_path = feat_dir / "split.json"
        if not split_path.exists():
            self.skipTest("features/split.json does not exist")

        manifest = json.loads(split_path.read_text())

        train = set(manifest["train"])
        cal = set(manifest["calibration"])
        test = set(manifest["test"])
        val = set(manifest["val"])

        # 1. Backwards compatibility alias
        self.assertEqual(cal, val, "'val' must match 'calibration' for backwards compatibility")

        # 2. Mutual exclusivity (0 leakage)
        self.assertEqual(len(train & cal), 0, "Train and Calibration must not overlap")
        self.assertEqual(len(cal & test), 0, "Calibration and Test must not overlap")
        self.assertEqual(len(train & test), 0, "Train and Test must not overlap")

        # 3. Completeness across all clips
        all_clips = sorted(p.name for p in feat_dir.glob("*.npz"))
        union = train | cal | test
        self.assertEqual(union, set(all_clips), "Partitions must cover exactly all .npz clips")
        self.assertEqual(len(union), len(all_clips))

        # 4. Session grouping integrity
        sessions = group_clips_into_sessions(all_clips, gap_seconds=1800)
        for s_idx, session_clips in enumerate(sessions):
            s_set = set(session_clips)
            in_train = bool(s_set & train)
            in_cal = bool(s_set & cal)
            in_test = bool(s_set & test)
            num_partitions = sum([in_train, in_cal, in_test])
            self.assertEqual(
                num_partitions, 1,
                f"Session {s_idx+1} ({len(session_clips)} clips) spans multiple partitions!"
            )

        # 5. Non-zero and sufficient assert positives in all partitions
        counts = manifest["counts"]
        for p_name in ["train", "calibration", "test"]:
            self.assertGreater(counts[p_name]["positives"], 1000,
                               f"Partition {p_name} has too few positive events")
            self.assertGreater(counts[p_name]["clips"], 50,
                               f"Partition {p_name} has too few clips")


if __name__ == "__main__":
    unittest.main()
