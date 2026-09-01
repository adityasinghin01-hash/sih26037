# Check 6 — the DGX A100

Rewritten 31 Aug 2026. **Most of this no longer needs to be asked.** A DGX A100 is a fixed
appliance with a published specification, so the hardware answers are known before anyone
replies. What is left is the site policy, and `check06_dgx_probe.sh` collects all of that in
one paste.

```bash
bash derisk/check06_dgx_probe.sh 2>&1 | tee dgx_probe.txt
```

Run it **on a compute node**, not the login node. Paste `dgx_probe.txt` back raw.

---

## Part 1 — Already answered, from the NVIDIA specification

A DGX A100 is one 6U box. It ships in exactly two configurations. The PRD says ours is
**8 × 40 GB**, which makes it the **320 GB** configuration:

| | DGX A100 **320 GB** (ours) | DGX A100 640 GB |
|---|---|---|
| GPUs | 8 × A100 **40 GB SXM4** | 8 × A100 80 GB SXM4 |
| GPU memory | 320 GB total | 640 GB total |
| System memory | **1 TB** | 2 TB |
| CPU | **2 × AMD EPYC 7742 — 128 cores total**, 2.25 GHz base / 3.4 GHz boost | same |
| GPU interconnect | 6 × NVSwitch, **NVLink 3.0, 600 GB/s GPU-to-GPU** | same |
| OS disk | 2 × 1.92 TB NVMe M.2, **RAID 1** | same |
| Data disk | **15 TB (4 × 3.84 TB) U.2 NVMe, RAID 0, mounted `/raid`** | 30 TB (8 × 3.84 TB) |
| Network | up to 8 × ConnectX-6 200 Gb/s HDR InfiniBand | + ConnectX-7 option |
| Power / size | 6.5 kW max, 6U, 123 kg | same |
| OS | DGX OS (Ubuntu). DGX OS 5 = 20.04 · 6 = 22.04 · 7 = 24.04 | same |

Per-GPU: **6912 CUDA cores, 432 Tensor cores, 1,555 GB/s HBM2e, compute capability 8.0**,
400 W. Ampere, so **TF32 and bfloat16 both work** — use bf16, not fp16, and no loss scaling.

**`/raid` is 15 TB and that is where our data goes.** NVIDIA's own words: the U.2 array is
"intended for application caching", ships as **RAID 0**, and *"if one SSD in the array fails,
all data stored on the array is lost."* So:

- **Disk is a solved problem if we can write to `/raid`.** 295 GB of 15 TB.
- **`/raid` is not backed up and may be wiped between users.** Never leave the only copy of
  anything there. Home directories are usually a small NFS quota — that is the real risk, and
  it is question 3 below.

**MIG:** each A100 splits into up to **7 instances** (`1g.5gb`), so 8 GPUs → up to 56.
Tempting for our 40-experiment sweep — but **enabling MIG needs root and a GPU reset**, so it
is the admin's call, not ours. Ask; do not plan on it.

---

## Part 2 — What the probe answers by itself

Questions 1, 2, 4, 5, 6, 7, 8, 9, 12, 13, 14 of the old list are all in `dgx_probe.txt`:
free disk per mount, quota, writability, whether **this** node reaches HuggingFace, proxy
variables, whether Slurm exists and with what partitions and wall-clock limits, Docker /
Singularity / Apptainer / enroot, Python version, module system, and whether
`pip install --user` is permitted.

## Part 3 — What only a human can answer

1. **Where should large datasets live** — `/raid`, a scratch mount, or somewhere else? The probe
   shows what is writable; it cannot show what is *allowed*.
2. **Is scratch wiped, and how often?**
3. **Who approves accounts and how long does it take?**
4. **Any GPU-hour budget or fair-share policy?**
5. **Is MIG available to us?** (see above)

---

## Part 4 — Corrections to instructions already sent out

**`huggingface-cli download` is deprecated and removed.** The command in the PRD and in
`Stream-C-prediction.pdf` will fail on a current `huggingface_hub`. The CLI was renamed to
**`hf`** in v0.34 and `huggingface-cli` no longer works in v1.0.

```bash
pip install --user -U "huggingface_hub[hf_transfer]"
export HF_HUB_ENABLE_HF_TRANSFER=1          # much faster on a 200 Gb/s link
hf download XijunWang/METEOR --repo-type dataset --local-dir ./meteor
```

**Verified live 31 Aug 2026** at `huggingface.co/datasets/XijunWang/METEOR` — public, **not
gated**, no login, last modified 2 Dec 2024, 226 downloads. Exact contents:

| file | bytes | GB |
|---|---|---|
| `chunk_aa` | 20,401,094,656 | 20.40 |
| `chunk_ab` | 20,401,094,656 | 20.40 |
| `chunk_ac` | 20,401,094,656 | 20.40 |
| `chunk_ad` | 20,401,094,656 | 20.40 |
| `chunk_ae` | 11,777,868,276 | 11.78 |
| | **93,382,246,900** | **93.38 GB (86.97 GiB)** |

The HF page states **licence `mit`**. Our notes say CC BY-NC-SA from the paper. **Cite the
paper's terms, not the mirror's tag** — the stricter one, and say where each came from.

### You probably do not need to download 93 GB at all

Measured 31 Aug 2026 by reading the zip's Zip64 central directory over HTTP range requests
(2 MB of transfer, no download). **The archive is ordered by category**, so the annotations are
contiguous at the two ends of the file:

| section | files | download | extracted | byte span |
|---|---|---|---|---|
| **Frame XML Annotations** | 1,251 | **1.55 GB** | 2.04 GB | 0 → 1.55 G — start of `chunk_aa` |
| Raw Videos | 1,250 | 91.57 GB | 104.86 GB | 1.55 G → 93.12 G |
| **Video XML Annotations** | 1,251 | **0.27 GB** | 8.25 GB | 93.12 G → 93.38 G — end of `chunk_ae` |
| | **3,752** | **93.38 GB** | **115.14 GB** | |

**Every S2 feature comes from boxes and classes, which live in the XML. The 91.57 GB of MP4 is
needed only to look at.** So the training download is **1.81 GB**, expanding to 10.28 GB — and a
clip's video can be range-fetched later, ~84 MB each, when we want one for a slide.

Verified while doing this: annotation is a full **30 Hz** (1,800 frames per one-minute clip,
numbered 0..1799), non-ego objects **do** carry `Yield`/`Cutting` labels, and each carries a
`track_id`. Details in the `sih26037-datasets` memory.

**Gotcha for whoever writes the fetcher:** the local file headers use **data descriptors**, so
their compressed/uncompressed size fields are `0`. Take sizes from the central directory.

### Storing it on an external drive

A 1 TB drive (~931 GiB usable) holds all of it several times over — worst case, keeping chunks,
joined zip and extracted tree at once, is **301.9 GB**. Three real constraints:

- **Filesystem.** FAT32 caps a single file at 4 GB and the chunks are 20.4 GB, so it fails
  mid-copy. Use **exFAT**, which Windows, macOS and Linux all read and write. (Irrelevant if you
  take annotations only: the largest file there is 76 MB.)
- **A USB drive cannot be plugged into a machine you SSH to.** A drive is an offline copy and
  insurance against the HuggingFace mirror disappearing — not a way to get data onto the DGX.
  For that, download on the DGX itself, straight to `/raid`.
- Training off a spinning USB HDD is slow (random reads). Fine for archival, poor as a working
  directory. `/raid` is NVMe and is the right working location.

### Reassembly: 114 GB peak instead of 187 GB

The documented `cat chunk_* > METEOR_Dataset.zip` holds the chunks **and** the joined zip at
once — 187 GB before extraction even starts. Deleting each chunk as it is appended caps the
peak at 93.4 + 20.4 ≈ **114 GB**:

```bash
for f in chunk_aa chunk_ab chunk_ac chunk_ad chunk_ae; do
  cat "$f" >> METEOR_Dataset.zip && rm -f "$f" || { echo "FAILED at $f"; break; }
done
unzip -t METEOR_Dataset.zip | tail -3      # verify BEFORE trusting it
unzip METEOR_Dataset.zip
```

**The trade:** if the zip turns out corrupt you re-download 93 GB. On `/raid` there is no
reason to bother — do it the safe way. Use it only if we end up on a quota'd home directory.
Extracted size is **115.14 GB**, measured from the central directory (see above).
Run all of it inside `tmux`.

---

## Part 5 — How much do we actually need this machine?

Worth saying plainly, because it changes how hard we chase it. Our model is an LSTM over
**20 timesteps × 31 features**. That is small enough to train on a laptop. The DGX buys us
exactly two things:

1. **Disk and bandwidth** for a 93 GB download — the real dependency.
2. **Throughput for the sweep** — 40 experiments, and the LSTM-vs-GNN ablation, in parallel
   rather than in series.

Neither is on the critical path for a *working* system. So the DGX is a **schedule risk, not
an existence risk** — and if it never materialises, an external SSD and any CUDA GPU still
produce the result, more slowly. Say it that way to the mentor; do not present it as a blocker
that kills the project, because it is not one.

## Answer format
Paste raw command output. Do not summarise. A trimmed error costs a day.
