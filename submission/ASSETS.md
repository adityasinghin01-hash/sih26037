# External submission assets

Large videos and generated evidence are deliberately excluded from Git history. The
submission scripts remain versioned; restore the input clips locally before running them.

## Expected local layout

```text
submission/assets/footage/
  drive_04 - Trim.mp4
  drive_07 - Trim.mp4
  drive_08 - Trim.mp4
  drive_09 - Trim.mp4
  drive_10 - Trim.mp4

submission/assets/perception demo/
  demo_04.mp4
  demo_07.mp4
  demo_08.mp4
  demo_09.mp4
  demo_10.mp4
```

The `footage` files are source clips. The `perception demo` files and
`submission/perception_chapter.mp4` are generated outputs and can be recreated by the
versioned scripts after the source clips and required Python packages are available.

For recovery, use the team's shared Drive archive referenced in `SETUP.md`. The untouched
`codex/submission-guide` branch also preserves the original snapshot; do not merge that
branch directly because its history contains the large media files.

Do not commit restored clips, generated videos, screenshots, local test transcripts, model
weights, datasets, or `results/`. Record reproducible evidence in the appropriate Markdown
progress report and keep the actual binaries in the shared Drive.
