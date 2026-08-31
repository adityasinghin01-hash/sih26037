#!/usr/bin/env bash
# CHECK 6 — one-shot DGX probe. Answers every site question in derisk/check06-dgx-questions.md.
#
#   bash derisk/check06_dgx_probe.sh 2>&1 | tee dgx_probe.txt
#
# Read-only. Writes nothing except one small temp file in each candidate data
# directory, which it deletes again. Safe to run on a shared machine.
# Paste dgx_probe.txt back verbatim. Do not summarise it.

s() { printf '\n\n===== %s =====\n' "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }
try() { if have "${1%% *}"; then eval "timeout 20 $*" 2>&1 || echo "(command failed, exit $?)"; else echo "(no ${1%% *})"; fi; }

echo "CHECK 6 — DGX probe"
echo "run at : $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "by     : $(whoami)@$(hostname -f 2>/dev/null || hostname)"

s "0 · WHICH MACHINE AM I ON"
echo "-- is this a login node or a compute node? compare hostname above with sinfo below"
try "cat /etc/dgx-release"
try "cat /etc/os-release"
uname -a
try "id"
echo "-- uptime / load:"; try "uptime"

s "1 · GPUs"
if have nvidia-smi; then
  nvidia-smi --query-gpu=index,name,memory.total,driver_version,compute_cap,mig.mode.current --format=csv
  echo; echo "-- who is using them right now:"; nvidia-smi
  echo; echo "-- NVLink / NVSwitch topology:"; nvidia-smi topo -m 2>&1 | head -30
else
  echo "(no nvidia-smi — THIS IS NOT A GPU NODE. Find the compute node and rerun.)"
fi

s "2 · CPU AND RAM"
try "lscpu | grep -E 'Model name|Socket|Core\(s\)|Thread|NUMA node\(s\)|CPU\(s\):'"
try "free -h"

s "3 · DISK — the question that can kill the plan"
echo "-- all filesystems:"; df -hT 2>/dev/null || df -h
echo
echo "-- the directories that matter:"
for d in "$HOME" /raid /scratch /data /mnt /lustre /work /tmp; do
  [ -d "$d" ] && printf '%-12s ' "$d" && df -h "$d" 2>/dev/null | tail -1
done
echo
echo "-- can I actually WRITE there, and is it big enough?"
for d in "$HOME" /raid /scratch /data /work; do
  [ -d "$d" ] || continue
  avail=$(df -BG --output=avail "$d" 2>/dev/null | tail -1 | tr -dc '0-9')
  t="$d/.sih_write_test.$$"
  if touch "$t" 2>/dev/null; then rm -f "$t"; w=WRITABLE; else w="NOT writable"; fi
  printf '%-12s %-14s %s GB free  %s\n' "$d" "$w" "${avail:-?}" \
    "$([ -n "$avail" ] && [ "$avail" -ge 200 ] && echo '<-- METEOR fits here' || echo '')"
done
echo
echo "-- per-user quota (blank output usually means no quota):"
try "quota -s"
have lfs && lfs quota -h -u "$(whoami)" "$HOME" 2>&1 | head
echo "-- block devices:"; try "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT"

s "4 · INTERNET FROM *THIS* NODE"
echo "-- proxy environment:"; env | grep -i -E 'proxy|no_proxy' || echo "(no proxy variables set)"
echo "-- DNS:"; try "getent hosts huggingface.co"
echo "-- HTTPS to huggingface.co:"
try "curl -sS -I --max-time 15 https://huggingface.co | head -5"
echo "-- HTTPS to the actual CDN the download comes from:"
try "curl -sS -I --max-time 15 https://cdn-lfs.huggingface.co | head -5"
echo "-- pypi (needed for pip install):"
try "curl -sS -I --max-time 15 https://pypi.org/simple/ | head -3"
echo "-- github:"; try "curl -sS -I --max-time 15 https://github.com | head -3"

s "5 · SCHEDULER — how we book GPU time"
for c in sbatch squeue sinfo srun bsub qsub pbsnodes; do
  printf '%-10s %s\n' "$c" "$(command -v $c 2>/dev/null || echo '-')"
done
echo; echo "-- partitions, limits and node state:"
try "sinfo -o '%20P %5D %14F %8G %10l %10L %N'"
echo "-- my accounts / QOS / limits:"
try "sacctmgr -n show assoc user=$(whoami) format=account,partition,qos,maxjobs,grptres,maxwall"
echo "-- what is queued right now:"; try "squeue -o '%.10i %.9P %.20j %.8u %.2t %.10M %.6D %R'"

s "6 · CONTAINERS"
for c in docker podman singularity apptainer enroot; do
  printf '%-12s %s\n' "$c" "$(command -v $c 2>/dev/null || echo '-')"
done
echo "-- am I in the docker group? (if not, docker will refuse)"
groups | tr ' ' '\n' | grep -x -E 'docker|sudo|admin' || echo "(not in docker/sudo)"
try "docker info --format '{{.ServerVersion}} runtimes={{.Runtimes}}' "

s "7 · PYTHON AND PACKAGES"
for c in python3 python pip3 pip conda mamba uv module; do
  printf '%-10s %s\n' "$c" "$(command -v $c 2>/dev/null || echo '-')"
done
try "python3 -V"
try "pip3 --version"
echo "-- can I install my own packages?"
try "pip3 install --user --dry-run --no-input huggingface_hub 2>&1 | tail -5"
echo "-- environment modules on offer:"
try "module avail 2>&1 | head -40"
echo "-- is torch already there, and does it see the GPUs?"
try "python3 -c \"import torch;print('torch',torch.__version__,'cuda',torch.version.cuda,'gpus',torch.cuda.device_count())\""

s "8 · SESSION SURVIVAL (the 93 GB download must outlive your ssh)"
for c in tmux screen nohup; do printf '%-8s %s\n' "$c" "$(command -v $c 2>/dev/null || echo '-')"; done

s "9 · SUMMARY LINE"
echo "host=$(hostname -s) gpus=$(nvidia-smi -L 2>/dev/null | wc -l | tr -d ' ') \
sched=$(command -v sbatch >/dev/null && echo slurm || echo none) \
docker=$(command -v docker >/dev/null && echo yes || echo no) \
net=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 https://huggingface.co 2>/dev/null || echo fail)"
echo
echo "DONE. Paste this whole file back. Raw. Do not summarise."
