# The supercomputer — NVIDIA DGX A100

8 × A100, 40 GB each. Used for exactly two things: **downloading METEOR** and **training the yield
predictor**. Nothing else in this project needs it.

## Before anything — six questions to answer

Ask whoever administers the machine. **Paste raw command output; do not summarise.**

| # | Question | How to check |
|---|---|---|
| 1 | How much free disk? | `df -h` |
| 2 | Is there a per-user quota? | `quota -s` |
| 3 | Does the **compute node** have internet, or only the login node? | `curl -I https://huggingface.co` **from a compute node** |
| 4 | How do we book GPU time? Slurm, calendar, ad hoc? | ask |
| 5 | Who approves accounts, and how long does it take? | ask |
| 6 | Can we `pip install --user`? Is conda or module-load available? | `pip install --user --dry-run numpy` |

**The disk answer is the one that can kill the plan.** METEOR needs **~190 GB free at peak** —
93 GB of chunks plus a 93 GB reassembled zip, before extraction. Total dataset budget is ~295 GB.

## Step 1 — download METEOR

**The official page `gamma.umd.edu/meteor` is dead.** The HuggingFace mirror is the only live
route. **If that mirror disappears, the yield-predictor plan dies with it — download early.**

```bash
pip install --user huggingface_hub
huggingface-cli download XijunWang/METEOR --repo-type dataset --local-dir ./meteor

cd meteor
cat chunk_* > METEOR_Dataset.zip     # ~93 GB, needs the chunks still present -> ~190 GB peak
unzip METEOR_Dataset.zip
rm chunk_*                            # only after unzip succeeds
```

Run it inside `tmux` or `screen` so a dropped connection does not kill it.

## Step 2 — THE CHECK THAT DECIDES WHAT OUR MODEL MEANS

The moment it extracts, open **one dynamic XML** and answer one question:

> Does a **non-ego** object carry an `<attributes>` block containing `Yield` or `Cutting`?

Both of the dataset authors' own parsers read behaviour labels **only** from the object named
`EgoVehicle`. Their paper implies the opposite. Nobody outside the dataset can settle it.

```bash
find . -name "*.xml" | head -1 | xargs head -100
```

**Report the answer before designing anything.** Full reasoning in research section 11 and
`docs/CLAIM-LEDGER.md` section F.

## Step 3 — train

**Eight GPUs, forty small experiments — not one big model.** Say that honestly; it is the truthful
description of what we do and it is more defensible than implying a large training run.

```bash
python python/model/train.py --config configs/train_base.json
```

Two runs matter:
1. **The LSTM** — the shipped model. Class-balanced, held-out clips, precision and recall reported
   separately for yield and no-yield.
2. **The GNN ablation** — same data, using the adjacency matrix the loader already emits. Reported
   as a comparison. This is why the adjacency matrix exists from day one.

## Step 4 — export and hand over

```bash
python python/export/to_onnx.py
```

Tell Stream D **which opset MATLAB accepts**. That number gates the whole in-loop integration.
See `docs/MODEL-PIPELINE.md`.

## Rules

- **Never commit the dataset.** `.gitignore` already excludes `meteor/`, `chunk_*`, `*.onnx`.
- Long jobs go in `tmux`. Always.
- Every training run writes its config next to its results. A number without its config is not a result.
