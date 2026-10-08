"""
batch_render_all.py - Batch render perception demo videos for all footage clips
Smart India Hackathon 2026 (SIH26037)
"""

import sys
from pathlib import Path

# Add python directory to path
script_dir = Path(__file__).resolve().parent
sys.path.insert(0, str(script_dir))

from render_perception import run_export, CLIPS

OUT_DIR = Path("submission/assets/perception demo")
OUT_DIR.mkdir(parents=True, exist_ok=True)

# Clips to render: 0, 1, 2, 3 (since 4 is demo_10.mp4 and is already rendered)
TARGETS = [
    (0, "demo_04.mp4", 15.0),
    (1, "demo_07.mp4", 15.0),
    (2, "demo_08.mp4", 15.5),
    (3, "demo_09.mp4", 10.0),
]

if __name__ == "__main__":
    print(f"[INFO] Starting batch render for {len(TARGETS)} clips into {OUT_DIR}...")
    for idx, out_name, max_sec in TARGETS:
        out_path = OUT_DIR / out_name
        print(f"\n{'='*60}")
        print(f"RENDERING [{idx+1}/4]: {CLIPS[idx]['name']} -> {out_name}")
        print(f"{'='*60}")
        run_export(output_path=str(out_path), max_seconds=max_sec, clip_idx=idx)
        print(f"[OK] Completed {out_name} ({out_path.stat().st_size} bytes)")
    
    print(f"\n[DONE] All batch renders successfully written to {OUT_DIR}!")
