#!/bin/zsh
# codex-run.sh — run a brief through Codex, survive a rate limit, resume automatically.
#
# usage:  ~/dev/sih2026-hq/tools/codex-run.sh <brief.md> <report.md> [max-retries]
# e.g.    ~/dev/sih2026-hq/tools/codex-run.sh \
#           ~/dev/sih2026-hq/04-JOBS/CODEX-06-phase2.md \
#           ~/dev/sih2026-hq/REPORTS/CODEX-06-report.md
#
# Why this exists: Codex reveals a limit only by failing. This runs the job, reads the
# tail of its own log, and if it was limited it waits and goes again instead of the
# work silently stopping.

BRIEF=${1:?need a brief path}
REPORT=${2:?need a report path}
MAXTRY=${3:-6}
REPO=~/dev/sih2026
LOG=~/codex-$(basename ${BRIEF:r}).log

for try in {1..$MAXTRY}; do
  print -P "%F{cyan}[$(date '+%H:%M:%S')] attempt $try/$MAXTRY — ${BRIEF:t}%f"

  # < /dev/null is MANDATORY. Without it Codex blocks forever reading stdin.
  # --- run with a STALL WATCHDOG -------------------------------------------
  # Codex hung for 2h10m on 16 Sep: it finished the work, wrote nothing more to
  # its log, and never exited (2.78s CPU total). A dead job looks identical to a
  # slow one, so watch the log instead of trusting the process.
  STALL=${CODEX_STALL_MIN:-8}          # kill if the log stops growing for this long
  codex exec -C "$REPO" -s workspace-write --color never -o "$REPORT" \
       "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1 &
  CPID=$!
  LASTSIZE=0; IDLE=0
  while kill -0 $CPID 2>/dev/null; do
    sleep 30
    SIZE=$(stat -f%z "$LOG" 2>/dev/null || echo 0)
    if [[ "$SIZE" == "$LASTSIZE" ]]; then
      IDLE=$((IDLE+30))
      if (( IDLE >= STALL*60 )); then
        print -P "%F{red}[$(date '+%H:%M:%S')] STALLED — no log growth for ${STALL} min, killing%f"
        pkill -9 -P $CPID 2>/dev/null; kill -9 $CPID 2>/dev/null
        break
      fi
    else
      LASTSIZE=$SIZE; IDLE=0
    fi
  done
  wait $CPID 2>/dev/null
  RC=$?

  TAIL=$(tail -200 "$LOG" | awk 'length($0) < 200')
  HIT=$(print "$TAIL" | grep -iE "rate.?limit|usage limit|quota exceeded|too many requests|HTTP 429|upgrade to continue")

  if [[ -z "$HIT" ]]; then
    print -P "%F{green}[$(date '+%H:%M:%S')] done (exit $RC) → ${REPORT:t}%f"
    tail -25 "$REPORT" 2>/dev/null
    exit $RC
  fi

  print -P "%F{red}[$(date '+%H:%M:%S')] RATE LIMITED%f"
  print "$HIT" | tail -2 | sed 's/^/    /'

  # Use the reset time Codex gives us if it gives one; otherwise back off.
  MINS=$(print "$TAIL" | grep -oiE "try again in ([0-9]+) ?(minute|min)" | grep -oE "[0-9]+" | head -1)
  SECS=$(print "$TAIL" | grep -oiE "try again in ([0-9]+) ?(second|sec)" | grep -oE "[0-9]+" | head -1)
  if   [[ -n "$MINS" ]]; then WAIT=$((MINS*60 + 30))
  elif [[ -n "$SECS" ]]; then WAIT=$((SECS + 30))
  else WAIT=$(( (try < 4 ? 600 : 1800) ))   # 10 min, then 30 min
  fi

  print -P "%F{yellow}    waiting ${WAIT}s — back at $(date -v+${WAIT}S '+%H:%M:%S')%f"
  sleep $WAIT
done

print -P "%F{red}gave up after $MAXTRY attempts — still limited%f"; exit 1
