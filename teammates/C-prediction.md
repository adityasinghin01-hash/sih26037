# Stream C · Prediction

**You own the model that answers: will that agent yield to us?**

This is the stream with the most machine time and the least MATLAB. If you like training models
and wrangling data, take this one.

## What is already written for you
| File | State |
|---|---|
| `python/meteor/features.py` | **Working.** The 31-dim feature builder, tested |
| `python/model/yield_lstm.py` | **Working.** The LSTM. Run it to see shapes |
| `python/export/to_onnx.py` | **Working.** Exports at four opsets |

## Your job, in order

### C1 — Download METEOR. Start this first; it is the long pole.
93.4 GB in five chunks. **The official page is dead — the HuggingFace mirror is the only route.**
```
huggingface-cli download XijunWang/METEOR --repo-type dataset --local-dir ./meteor
cat chunk_* > METEOR_Dataset.zip
```
Needs **~190 GB free at peak** (93 GB of chunks + 93 GB zip before extraction). Check disk first.
Do this on the DGX, not a laptop.

### C2 — THE CHECK THAT DECIDES WHAT OUR MODEL MEANS
The moment it extracts, open **one dynamic XML** and answer one question:

> Does a **non-ego** object carry an `<attributes>` block containing `Yield` or `Cutting`?

Both of the authors' own parsers read behaviour labels **only** from the object named
`EgoVehicle`. The paper says the opposite. Nobody outside the dataset can settle it.
**Report the answer before designing anything.** Full detail in research section 11.

Either answer works — the feature vector was built to survive both — but they mean different things.

### C3 — Write the loader
`python/meteor/loader.py`. Parse the XMLs into per-agent tracks, feed `frame_features()`,
emit `[T, 31]` sequences plus labels. Ask your agent to write it; you verify the output shapes
and spot-check ten samples against the video by eye.

### C4 — Train
Baseline first: class-balanced, held-out clips, report precision and recall separately for
yield and no-yield. **Then train the ablation** — same data, GNN variant using the adjacency
matrix the loader already emits. Eight GPUs, many small experiments, not one big model.

### C5 — Export and hand over
Run `python/export/to_onnx.py`, then tell Stream D **which opset MATLAB actually accepts**.
That number gates the whole in-loop integration.

## Do not
- Do not lift METEOR into 3-D. Ever. See research section 11.
- Do not swap the LSTM for a transformer or GNN in the shipped path. ONNX import will fail.
- Do not change `docs/INTERFACES.md` S2. Stream D is building against those 31 columns.


## Done when

| Task | Done means |
|---|---|
| C1 | METEOR extracted, `df -h` output reported before and after |
| C2 | **The ego-vs-agent question answered from a real XML**, with the snippet pasted |
| C3 | Loader emits `[T,31]` sequences **and** the `[N,N]` adjacency, shapes verified |
| C4 | Precision and recall reported **separately** for yield and no-yield, on held-out clips |
| C5 | At least one `.onnx` file that MATLAB imports without error |

**Four conditions apply to every task** (`docs/WORKFLOW.md`): it runs from a clean clone, a test
covers it, it matches `docs/INTERFACES.md` exactly, and someone else could run it without asking
you a question.

## Your handoff

**H3 → D:** report the working opset number as soon as you have it. It is one number and it gates all in-loop integration. Do not wait until training finishes.

**Read `docs/WORKFLOW.md` before your first commit** — branch naming, commit format, how to report
a blocker, and what to do when the contract is not enough.

---

## What you use

| | |
|---|---|
| **Stack** | Python 3.11 + PyTorch + ONNX, then MATLAB at the end |
| **Machine** | Any machine + the DGX |
| **IDE / agent** | Antigravity |
| **Key functions & tools** | `huggingface-cli` · `xmltodict` · PyTorch · `torch.onnx.export` · the DGX A100 |

**Setup:** `docs/SETUP.md` — 20 minutes.
**Before you write any code:** read `docs/INTERFACES.md`. It is frozen; five other people build
against it. If your agent proposes editing it, the answer is no.

**Reference docs you will need:**
`docs/PRD.md` (the whole idea) · `docs/ROADMAP.md` (phases and gates) ·
`docs/metrics.md` (M1–M10) · `docs/CLAIM-LEDGER.md` (never state a number that is not in it)
