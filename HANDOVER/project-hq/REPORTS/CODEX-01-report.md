MATLAB verification could not proceed because the environment prevents writing Git metadata.

- Before: branch `planner-ml-sidebuild`, HEAD `1b010a0`
- After: branch `planner-ml-sidebuild`, HEAD `1b010a0`
- `main`: `2f59687`
- locally recorded `origin/main`: `f4d1f79`
- Fetch error, verbatim:

```text
error: cannot open '.git/FETCH_HEAD': Operation not permitted
```

Because `git fetch` failed, I did not switch branches, fast-forward, or run the MATLAB suite.

```text
TOTAL=TODO(unverified) PASS=TODO(unverified) FAIL=TODO(unverified) INCOMPLETE=TODO(unverified)
```

No failing-test output exists because tests were not run.

Read-only checks:

- `OpenTrafficLab/`: present
- `git status --short matlab/baseline/`: no output
- `S1_cattle_crossing.mp4`: present
- `S2_the_chowk.mp4`: present
- Demo caches present:
  - `demo_demo1-cowblocking.mat`
  - `demo_demo1-cownone.mat`
  - `demo_demo1.mat`
  - `demo_demo2-cowblocking.mat`
  - `demo_demo2.mat`
- Pre-existing untracked path: `.claude/worktrees/`

No files were edited, committed, or pushed.