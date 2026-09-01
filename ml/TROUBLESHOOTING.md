# Errors we have already hit, and what they actually mean

Every entry here is a real failure that happened during development, with the real cause. If you
hit one of these, the answer is here — do not spend an afternoon on it, and do not let your AI
guess at it.

**The pattern worth noticing: almost none of these crash.** They produce a number and the number
is wrong. That is why this file exists.

---

## Export and ONNX

### `ModuleNotFoundError: No module named 'onnxscript'`
**Cause:** PyTorch 2.9 and later use a new ONNX exporter that needs it. It is not installed with
torch.
**Fix:** `pip install onnxscript`. It is a real dependency, not optional.

### The exported file says opset 9 but MATLAB reports 18
**Not a bug in MATLAB.** PyTorch **silently upgrades** any ONNX version below its minimum. Ask
for 9, 11 or 13 and you get a file that is really 18, under a filename that lies about it.
**Fix:** already handled — `to_onnx.py` writes only 17, 18 and 20 and reads the version back out
of each file. **Never report the number you asked for; report the one the file contains.** This
number goes to Stream D, and a wrong one costs them a day.

### `Gather` appears in the graph and MATLAB will not convert it
**Cause is almost never what people assume.** `Gather` comes from ordinary indexing, not only
from graph networks. `out[:, -1, :]` produces one. So does reading `x.shape` while the model
runs.
**Fix:** `torch.flatten(out[:, -1:, :], 1)` instead of the index, and compile-time constants
instead of shape reads. Both models are already written this way — if `Gather` comes back,
something was edited.

### `evaluate.py` says the exported file disagrees with the model by ~0.9
**Cause:** you exported from a checkpoint for the *other* model, so the one you are testing has
random starting weights.
**Fix:** run `to_onnx.py` once per checkpoint. The script now refuses to export a model whose
weights are not in the checkpoint and prints `SKIPPED`. **This one is nasty because the file
looks fine and the export prints OK** — it just predicts noise.

### `check04` finds no `.onnx` files
Run the export first, and run `check04` from the repository root. If you find files named
`opset9`, `opset11` or `opset13`, they are from the old script and every one of them is really
opset 18. Delete them.

---

## Training

### Loss goes down, recall stays 0.000
**This is the expected result when the label is too rare**, not a bug. At 1 in 581 the model
learns to always say no, which is correct-on-average and useless.
**Fix:** that is Decision 2 in `ReadThis.md`. Measure both labels and apply the rule.

### The numbers did not change after I edited `features.py`
**You forgot `--force`.** `build_dataset.py` skips clips that already have a `.npz`, so you
rebuilt nothing and measured the old code. There is no warning; the run just looks normal.
**Fix:** `--force`, always, after any change to the feature code or the label.

### `UserWarning: Converting a tensor with requires_grad=True to a scalar`
Harmless, and already fixed — it was `float(loss)` instead of `float(loss.detach())`. If you see
it again, someone reintroduced it.

### "samples" and "positives" do not add up
Not a bug for the attention model: it counts **frames**, each holding up to 16 agents, while the
positives count **agents**. The script now labels which unit each figure is in. If they still
look wrong, read the labels again before assuming.

### Every score is suspiciously good
Check the split. If someone changed it to split by frame instead of by clip, adjacent frames are
near-identical pictures and nearly every test frame has a twin in training. **A great score from
a frame split is worth nothing.**

---

## Features and data

### Ego speed shows something like 557 m/s
**The physical gate in `parse_xml.py` has been removed or widened.** METEOR stores the ego
position once per clip, so the rare frame where it changes produces an enormous fake velocity —
the guard used to check distance instead of speed, which at 1/30 s admits 3,000 m/s.
**This is not cosmetic:** that column sits in the same input layer as features whose values live
between 0 and 1, and it drowns them.
**Fix:** restore `MAX_SPEED_MPS` / `MAX_ACCEL_MPS2`. Stop and report it.

### The dead-feature list is not `[23, 24, 25, 27]`
Those four are the one-hot slots for dog, pushcart, animal-drawn cart and static obstacle, which
METEOR never contains. A **different** list is worth reporting — a **longer** list may mean the
check is sampling one clip instead of all of them, which it used to do.

### `parse_frame` gives 0 objects
Check you are reading **Frame XML Annotations**, not Video XML. Also remember `Behaviour` values
are dirty — `false`, `False`, `fasle` — and `Pedestrain` is misspelt in the source.

---

## MATLAB

### `Undefined function 'trainYOLOXObjectDetector'`
**The detector object exists but training does not.** You are missing the **Automated Visual
Inspection Library for Computer Vision Toolbox** — a free add-on the product installer does not
include. `Home → Add-Ons → Get Add-Ons`.
**This blocks model 3 only.** Everything else still runs.

### `Undefined function 'importNetworkFromONNX'`
Missing the **Deep Learning Toolbox Converter for ONNX Model Format**, also a free add-on, also
not in the installer. `check04` cannot run without it.

### `Undefined function 'deeplabv3plusLayers'`
**It was removed from MATLAB.** The replacement is `deeplabv3plus` plus `trainnet` — not
`trainNetwork`. If you found it in an example, the example is old.

### PointPillars fails on the training data
It needs **9-column** boxes: `[x y z length width height roll pitch yaw]`. A 4-column table is
an image box and will not work. Build the datastore with `lidarObjectDetectorTrainingData`.

### `testFeatureParity` fails on some feature number
The two feature builders have drifted. Feature numbers are `AGENTS.md` S2 positions: 10 is tau,
11 the lateral time-to-cross, 12–27 the class one-hot, 28–31 ego state.
**Do not "fix" one side to match the other.** Work out which is correct first. The two usual
causes are the `1e-9` threshold inside `_safe_div` / `iSafeDiv` changing on one side only, and a
one-hot landing at the wrong position — Python writes `row[11 + cid]` counting from 0, MATLAB
writes `data(i, 12 + cid)` counting from 1, and **those are the same position.**

### Something else in MATLAB fails
**Expected.** Most of the MATLAB here has never been executed. Send the whole error — the entire
message and stack, not a summary or a screenshot of part of it.

---

## When it is not on this list

1. **Send the whole output.** Every line.
2. **Say what you changed** since it last worked.
3. **Do not try three fixes and report the third.** Report the first failure.
4. If your AI proposes a fix, ask it: *did you run that, or is that what you expect?*
