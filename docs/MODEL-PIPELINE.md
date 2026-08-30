# The model pipeline — from raw video to a decision inside Simulink

Six stages. Stream C owns 1–5, Stream D owns 6. The handover point is one number: **the ONNX
opset that MATLAB accepts.**

```
  METEOR video + XML          [DGX]
        │
        │  1. parse
        ▼
  per-agent box tracks
        │
        │  2. features   python/meteor/features.py
        ▼
  [T x 31] sequences  +  [N x N] adjacency
        │
        │  3. train      python/model/yield_lstm.py     [DGX, 8x A100]
        ▼
  yield_lstm.pt
        │
        │  4. export     python/export/to_onnx.py
        ▼
  yield_lstm_opset<N>.onnx
        │
        │  5. import     importNetworkFromONNX          [MATLAB]
        ▼
  dlnetwork
        │
        │  6. deploy     Simulink Predict block
        ▼
  P(yield) per agent, every step, inside the loop
```

## 1 · Parse

METEOR ships 1,250 one-minute clips. Each has a **static XML** (clip metadata) and a **dynamic
XML** (frame-level: bounding boxes, GPS, agent behaviours).

Structure, recovered from the authors' own parser code:

```xml
<annotation>
  <size><width/><height/></size>
  <object>
    <name>EgoVehicle | Car | Pedestrian | ...</name>   <!-- "Pedestrain" is misspelt in the data -->
    <bndbox><xmin/><ymin/><xmax/><ymax/></bndbox>
    <attributes>
      <attribute><name>Yield</name><value>True</value></attribute>
    </attributes>
  </object>
</annotation>
```

Attribute values: `RuleBreak` → {WrongLane, WrongTurn, TrafficLight};
`LaneChanging`, `LaneChanging(m)`, `OverTaking`, `Yield`, `Cutting` → {True}.

## 2 · Features — 31 dimensions, no depth anywhere

`python/meteor/features.py`, already written and tested.

**The rule that makes this work: project down, never lift up.** The instinct is to lift METEOR
into 3-D so it matches the simulator. That needs monocular depth, and **1 degree of camera pitch
error is ~31% depth error at 30 m**. So instead the simulator's exact 3-D is projected *into* the
image plane, where METEOR already lives:

```matlab
sensor   = monoCamera(cameraIntrinsics(f, pp, imgSize), height);
imagePts = vehicleToImage(sensor, [x y z]);
```

METEOR ships the camera intrinsic matrix, so the virtual camera matches the real dashcam.
**Both sources then produce the same 31 numbers.** Downward projection is arithmetic; upward
lifting is ill-posed.

The feature that makes image-plane learning legitimate is **#10, looming**: `tau = h / (dh/dt)` —
time-to-contact from pure 2-D expansion, no depth required.

Features **28–31 are the ego's own state and its candidate action**. That is what makes the model
answer *"if I go now, will they yield?"* rather than merely forecasting.

## 3 · Train — LSTM, and it is not a preference

`importNetworkFromONNX` **does not support Gather/Scatter**, which message-passing GNNs depend on.
LSTM and GRU import cleanly. Transformers import only partially, with manual surgery.

So the shipped model is an LSTM. The **adjacency matrix is emitted from day one anyway** — the
LSTM ignores it, but it makes the GNN ablation a ~60-line change instead of a rewrite. Train both,
report the comparison.

## 4 · Export

```bash
python python/export/to_onnx.py     # writes opsets 9, 11, 13, 17
```

| MATLAB release | Supported opsets |
|---|---|
| R2024b | 6 – 18 |
| R2025a+ | 6 – 20 |

## 5 · Import into MATLAB

```matlab
net = importNetworkFromONNX('yield_lstm_opset13.onnx');
x   = dlarray(randn(20,31,'single'),'TC');
y   = predict(net, x);
```

`derisk/check04_onnx_lstm.m` tries every exported opset and reports which succeed.
**The one that imports cleanly is the one we train and ship.** That number is the handover.

## 6 · Deploy in the loop

Use the **Predict block** (supports code generation). **Not** the ONNX Model Predict block — that
one is simulation-only.

Per step, per tracked agent:
1. Build the `[20 x 31]` sequence from the track history
2. `predict` → logits → softmax → `P(yield)`
3. Emit `YieldPrediction` (`docs/INTERFACES.md` S3)
4. Planner consumes it alongside the geometric role

**When `Valid(i)` is false** — the track is younger than 20 frames — **the planner falls back to
the geometric role alone.** It must never treat an invalid prediction as 0.5.

## Do not

- **Do not import YOLO from ONNX.** NMS is unsupported, dynamic shapes fail, opset-11 Resize
  `antialias` breaks it. Use MATLAB's built-in YOLOX.
- **Do not lift METEOR into 3-D.** Ever.
- **Do not swap in a transformer or GNN on the shipped path.** The import will fail.
