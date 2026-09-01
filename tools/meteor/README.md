# Pull single METEOR clips without downloading 93 GB

The dataset is one zip split across five chunks on HuggingFace. The Zip64 central
directory sits at the tail of `chunk_ae`, so any of the **1,250 videos** can be
range-fetched individually. One clip is ~84 MB and takes about two minutes.

```bash
python3 mzip.py                                   # index it: 3,752 entries, 1,250 videos
python3 fetch_clip.py "REC_2020_07_12_02_05_26_F.MP4" clip.mp4
```

Verified working 2 Sep 2026. Total archive 93,382,246,900 bytes across 5 chunks.

## What the videos turned out to contain
- **The dashcam burns its own speed into every frame** — bottom bar, e.g.
  `Thinkware F800  v1.01.01 13.6 V | 2020.07.12 02:05:28 | 90km/h`. Measured 90 -> 68 km/h
  across 18 s in one clip, 47 km/h in another. Live per-frame speed. See issue #1.
- **A 10 Hz three-axis g-sensor track** in a `mov_text` subtitle stream:
  `gsensori,4,512,-53,005,106;CAR,0,0,0,...`
- **The audio track is digitally silent** (mean and max both -91 dB). No horns from METEOR.
- Raw clips are ~22 s / 660 frames at 1920x1080 30 fps, not the one minute the
  annotation notes assume.

Ranking local annotation zips by agents-per-frame finds the congested clips worth
watching. Densest of 79: 11.2 agents/frame, buses + cars + motorbikes + pedestrians.
