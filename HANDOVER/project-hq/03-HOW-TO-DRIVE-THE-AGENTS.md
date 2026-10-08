# How to drive Codex and Antigravity — the exact commands

## Codex — the MATLAB executor

```bash
codex exec -C ~/dev/sih2026 -s workspace-write --color never \
  -o ~/dev/sih2026-hq/REPORTS/<name>-report.md \
  "$(cat ~/dev/sih2026-hq/04-JOBS/<brief>.md)" \
  < /dev/null > ~/codex-live.log 2>&1
```

**The `< /dev/null` is not optional.** Without it, when stdout is piped Codex waits forever
on stdin — it prints *"Reading additional input from stdin…"* and then does nothing at all.
This cost 15 minutes today and looked exactly like a hung MATLAB. It was not.

**Codex cannot write to `.git`.** The `workspace-write` sandbox denies it, and `git fetch`
fails with `cannot open '.git/FETCH_HEAD': Operation not permitted`. So:
- **Claude does all git operations** (they take seconds).
- Codex gets a repo that is already on the right branch, and is told read-only git is fine.

Codex will not assert a fact it cannot verify. Give it repo-checkable instructions, not
narrative. Budget ~11–20k tokens even for a small job, so send it substantial work.

## Antigravity — currently blocked

```bash
agy -p "$(cat ~/dev/sih2026-hq/04-JOBS/<brief>.md)" --effort high \
  --add-dir ~/dev/sih2026 --print-timeout 20m
```

This runs, but **every file read is auto-denied** in headless mode:

> *a tool required the "read_file" permission that headless mode cannot prompt for, so it
> was auto-denied.*

**To unblock it, you must add the permission yourself.** Open
`~/Library/Application Support/Antigravity/User/settings.json` and add:

```json
"permissions": {
  "allow": [
    "read_file(https://github.com/adityasinghin01-hash/sih26037/blob/main/**)",
    "read_file(https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/**)",
    "read_file(<team-archive>/**)",
    "write_file(https://github.com/adityasinghin01-hash/sih26037/blob/main/HANDOVER/project-hq/**)",
    "list_dir(<legacy-dev-root>/**)",
    "grep(<legacy-dev-root>/**)"
  ]
}
```

That grant is **scoped** — it can read the three project folders and write only into the HQ
folder. The alternative flag, `--dangerously-skip-permissions`, auto-approves *everything*
anywhere on the machine. Don't use it.

## The rule that keeps them from fighting

| Agent | Owns | Never touches |
|---|---|---|
| Claude | `sih2026-hq/`, all git operations | any code |
| Codex | `matlab/` | `ml/`, `plan/`, `matlab/baseline/`, `AGENTS.md` |
| Antigravity | `ml/`, `plan/` | `matlab/` |

**Never run two MATLAB sessions at once.** 8 GB of RAM, and the demo's own frame timing
degrades 20× under background load.

---

## CONFIRMED 16 Sep: Codex cannot run MATLAB. At all.

Tried twice, failed identically both times:

```
Incompatible processor. This Qt build requires the following features:
    neon
MATLAB is exiting because of fatal error          exit 137
```

It is not about figures or `demo_play` — even a plain headless `-batch` call dies. The
sandbox masks a CPU feature MATLAB's Qt build requires, and MATLAB refuses to start.

**So the division of labour is fixed:**

| | Does |
|---|---|
| **Codex** | writes MATLAB code, reads, greps, reasons about the repo |
| **Claude** | runs every MATLAB command, all git writes, reports results back to Codex |

When briefing Codex for MATLAB work, tell it explicitly: **write the file, do not execute it**,
and ask it to state which parts it is guessing at — that is the list to check first when the
run fails.

## Codex failure mode 2: it hangs AFTER finishing the work

16 Sep, Phase 1. Codex wrote `densityPlannerRun.m` correctly at 15:58, dumped the diff to
its log at 16:00, and then **sat there until 18:05** — 2 h 10 m elapsed, **2.78 seconds of
CPU**. It never wrote its report and never exited. The work was done; the process just
never let go.

**A hung job and a slow job look identical from the outside.** So don't trust the process,
watch the log. `tools/codex-run.sh` now runs Codex in the background and kills it if its
log stops growing for 8 minutes (`CODEX_STALL_MIN` to change it).

**Two hours were lost to this.** Check `tools/codex-status.sh` if a job feels slow — if it
shows a job "running" but its log timestamp is old, it is dead, not thinking.
