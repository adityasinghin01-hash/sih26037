#!/bin/zsh
# overnight.sh - the queue that runs while Aditya sleeps. One MATLAB at a time,
# each job time-boxed so a single hang cannot eat the whole night.
# Log: ~/sih-overnight.log
REPO=~/dev/sih2026
MAT=/Applications/MATLAB_R2026a.app/bin/matlab
LOG=~/sih-overnight.log
cd $REPO

say() { print -P "\n%F{cyan}[$(date '+%H:%M:%S')] $1%f" | tee -a $LOG }

# run <name> <minutes> <matlab-statement>
run() {
  local name=$1 cap=$2 stmt=$3
  say "START $name (cap ${cap}m)"
  $MAT -batch "addpath(genpath('matlab')); $stmt" >> $LOG 2>&1 &
  local pid=$!
  local waited=0
  while kill -0 $pid 2>/dev/null; do
    sleep 30; waited=$((waited+30))
    if (( waited > cap*60 )); then
      say "TIMEBOX HIT on $name after ${cap}m - killing, moving on"
      pkill -9 -P $pid 2>/dev/null; kill -9 $pid 2>/dev/null
      break
    fi
  done
  say "END $name"
}

say "=== OVERNIGHT QUEUE START ==="

# wait for whatever is already running to clear
while pgrep -f "MacOS/MATLAB_maca64" >/dev/null 2>&1; do sleep 20; done

# 1. S3 with pruning in place - the Phase 2 unknown. Timeboxed hard: the
#    unpruned attempt ran 3h48m and never finished.
run "PHASE2-S3" 50 "densityPlannerRunS3();"

# 2. PHASE 6 - the confidence-interval bench on S1. This is the phase that turns
#    a demo into a test, and it is exactly the job to do while nobody is waiting.
run "PHASE6-BENCH-S1" 240 "R = benchRuns('s1', 12); save('~/bench_s1.mat','R');"

# 3. the full test suite, so a night of edits cannot silently break the baseline
run "REGRESSION-SUITE" 15 "addpath(genpath('OpenTrafficLab')); r = runtests('matlab/tests','IncludeSubfolders',true); fprintf('TOTAL=%d PASS=%d FAIL=%d INCOMPLETE=%d\n', numel(r), sum([r.Passed]), sum([r.Failed]), sum([r.Incomplete]));"

say "=== OVERNIGHT QUEUE DONE ==="
