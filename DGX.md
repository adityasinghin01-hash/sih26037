# DGX.md — the supercomputer

Read this before running anything on the DGX. Facts below are from the NVIDIA specification for
this machine, not guesses. Anything marked **UNCONFIRMED** must be measured on the machine and
reported — do not assume it.

---

## What the machine is

A DGX A100 is a single 6U appliance. Ours is the **320 GB** configuration.

| | |
|---|---|
| GPUs | **8 × A100 40 GB SXM4** — 6912 CUDA cores, 432 Tensor cores, 1,555 GB/s each |
| Compute capability | **8.0 (Ampere)** |
| GPU interconnect | 6 × NVSwitch, NVLink 3.0, **600 GB/s GPU-to-GPU** |
| CPU | 2 × AMD EPYC 7742 — **128 cores total**, 2.25 GHz |
| System memory | **1 TB** |
| OS disk | 2 × 1.92 TB NVMe M.2, RAID 1 |
| **Data disk** | **15 TB (4 × 3.84 TB) U.2 NVMe, RAID 0, normally mounted `/raid`** |
| Network | up to 8 × ConnectX-6, 200 Gb/s InfiniBand |
| OS | DGX OS, an Ubuntu derivative (5 → 20.04 · 6 → 22.04 · 7 → 24.04) |

---

## Rules for using it

**Put data on `/raid`, never in your home directory.** Home is usually a small networked disk with
a quota. `/raid` is local NVMe and fast.

**`/raid` is RAID 0 and is NOT backed up.** NVIDIA's own words: *"if one SSD in the array fails,
all data stored on the array is lost."* It is a working area. **Never keep the only copy of
anything there.** Our datasets can be re-downloaded; a trained model cannot.

**Ampere means bfloat16, not float16.** Use `bf16` for mixed precision. It has the same exponent
range as fp32, so no loss scaling is needed. TF32 is on by default and needs no code change.

**Run long jobs inside `tmux`.** An ssh drop kills anything not detached:
```bash
tmux new -s training
# ... start the job ...
# Ctrl+B then D to detach; tmux attach -t training to return
```

**Many small runs, not one long one.** The yield predictor is small — it trains in minutes, not
days. Eight GPUs is for running **20-40 short experiments** and keeping the best, not for one huge
model. Say that honestly in any report: *forty small experiments, not one giant model.*

**Download data directly onto the machine.** It has a far faster line than a laptop. Do not copy
10 GB over ssh.

**Code travels through GitHub only.** Laptop → push → pull on the DGX. Never scp source files.

---

## Before the first run, measure the machine

```bash
bash derisk/check06_dgx_probe.sh 2>&1 | tee dgx_probe.txt
```
Run it **on a compute node, not the login node** — the answers differ. Send the whole file back
unedited.

Then confirm the GPUs are actually visible to PyTorch:
```bash
nvidia-smi
python3 -c "import torch; print(torch.cuda.device_count(), torch.cuda.get_device_name(0))"
```
**Expect 8.** If it prints 0, PyTorch was installed without CUDA support — say so rather than
training on CPU by accident.

---

## UNCONFIRMED — measure and report, do not assume

- **Is `/raid` present and writable by us?** The mount point is conventional, not guaranteed.
- **Free disk, and whether a per-user quota applies.**
- **Does the compute node reach the internet?** Some clusters give the login node internet and the
  compute nodes none. This decides whether data can be downloaded where it is needed.
- **Is there a job queue (Slurm) or do we run directly?** Changes how every job is launched.
- **Maximum job length and GPUs per user.**
- **Is MATLAB installed?** Another stream needs this answer.
- **Is MIG enabled?** Each A100 can be split into up to 7 instances, which would suit a 40-run
  sweep — but enabling it needs root, so it is the administrator's decision, not ours.

`check06_dgx_probe.sh` answers all but the last two.

---

## What we actually need it for

Be accurate about this when writing it up. The predictor trains on **1.81 GB** and would run on a
laptop. The machine buys us two things:

1. **Throughput for the sweep** — many settings at once instead of one after another.
2. **Disk and bandwidth** for the larger datasets, if we train the detector or the lidar model.

It is a **schedule convenience, not a requirement**. If it is unavailable, the core model still
trains — more slowly. Do not describe it as a blocker.
