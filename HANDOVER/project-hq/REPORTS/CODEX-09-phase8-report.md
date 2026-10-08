Root cause found: no `reactStep` guard rejects every actor. `opts.Reactive` was dropped at the top-level `loadRoute` call, so downstream builders defaulted to `reactive=false` and never called `reactStep`.

The propagation fix is present in [demo_play.m](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/demo_play.m:185). At `t=27 s`, the motorcycle has `ahead=18 m`, `reach=22.5 m`, and `lateral=1.9 m`, so every trigger guard passes.

Report: [CODEX-09-phase8-report.md](https://github.com/adityasinghin01-hash/sih26037/blob/main/REPORTS/CODEX-09-phase8-report.md:1)

The requested `sih2026-hq/REPORTS` directory is outside the writable workspace, so the report was placed in this checkout’s `REPORTS/`. `git diff --check` passes. MATLAB was not run; the post-fix reaction count remains `TODO(unverified)` for Claude.