"""
run_perception_demo.py - One-command launcher for Offline Real-World Perception Chapter
Smart India Hackathon 2026 (SIH26037)

Usage:
  python run_perception_demo.py                # Launches live interactive window
  python run_perception_demo.py --snap 50      # Exports snapshot PNG
  python run_perception_demo.py --export       # Exports full 1080p presentation video
"""

import sys
from pathlib import Path

# Add python module directory to path
script_dir = Path(__file__).resolve().parent / "python"
sys.path.insert(0, str(script_dir))

from render_perception import run_interactive, run_snapshot, run_export

if __name__ == "__main__":
    if "--snap" in sys.argv:
        frame_idx = 50
        try:
            pos = sys.argv.index("--snap") + 1
            if pos < len(sys.argv):
                frame_idx = int(sys.argv[pos])
        except Exception:
            pass
        run_snapshot(frame_idx, "submission/step_perception_shell.png")
    elif "--export" in sys.argv:
        run_export("submission/perception_chapter.mp4", max_seconds=12.0)
    else:
        # Default: run interactive preview
        run_interactive()
