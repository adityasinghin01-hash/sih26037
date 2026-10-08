#!/bin/zsh
# codex-status.sh — is Codex alive, busy, or rate-limited?
# usage:  ~/dev/sih2026-hq/tools/codex-status.sh
print -P "%F{cyan}── CODEX STATUS ──%f"

print -n "auth      : "; codex login status 2>&1 | head -1

PIDS=$(pgrep -f "codex exec" 2>/dev/null)
if [[ -n "$PIDS" ]]; then
  for p in ${(f)PIDS}; do
    print "running   : pid $p, up $(ps -p $p -o etime= | tr -d ' ')"
  done
else
  print "running   : idle"
fi

LAST=$(ls -t ~/codex-*.log 2>/dev/null | head -1)
if [[ -z "$LAST" ]]; then print "last log  : none yet"; exit 0; fi
print "last log  : ${LAST:t}  ($(date -r "$LAST" '+%H:%M:%S'))"

# Only look at SHORT lines near the END of the log. Codex prints its own status
# there; long lines are repo file contents it read, which produce false hits.
TAIL=$(tail -200 "$LAST" | awk 'length($0) < 200')
HIT=$(print "$TAIL" | grep -iE "rate.?limit|usage limit|quota exceeded|too many requests|HTTP 429|try again in|resets? (at|in)|upgrade to continue" | tail -3)
if [[ -n "$HIT" ]]; then
  print -P "%F{red}limit     : HIT%f"
  print "$HIT" | sed 's/^/            /'
else
  print -P "%F{green}limit     : clear%f"
fi

TOK=$(grep -A1 -i "^tokens used" "$LAST" 2>/dev/null | tail -1 | tr -d ' ')
[[ -n "$TOK" ]] && print "last job  : $TOK tokens"
TOTAL=$(for f in ~/codex-*.log; do grep -A1 -i "^tokens used" "$f" 2>/dev/null | tail -1; done | tr -d ', ' | awk '{s+=$1} END {print s+0}')
print "today     : ~$TOTAL tokens across all runs"

print -n "verdict   : "
if [[ -n "$HIT" ]]; then print -P "%F{red}RATE LIMITED — wait for reset%f"
elif [[ -n "$PIDS" ]]; then print -P "%F{yellow}BUSY — a job is running%f"
else print -P "%F{green}READY%f"; fi
