# De-risk checks — how to run them

**Rule: send back the FULL output, never a summary. Errors especially.**
Every script writes a `checkNN_output.txt` next to itself. Send those files.

Do them in order. Stop and report if one fails.

---

## Step 0 + 1 — Environment (2 minutes)
1. Open MATLAB.
2. In the box at the top that shows the folder path, navigate to `sih2026/derisk`.
3. Type in the Command Window:
   ```
   check01_environment
   ```
4. Send back: `check01_output.txt`

**This decides everything.** If a product says MISSING, nothing else can run.

---

## Step 2 — THE CRITICAL ONE (5 minutes)
```
check02_lidar_cow
```
Send back: `check02_output.txt` **and** the image `check02_pointcloud.png`.

We are looking for one number: **points landing ON THE COW**.
- 10 or more → the whole perception design holds.
- 0 → we change the design. Not a disaster, but we must know.

---

## Step 3 — Real Meerut roads from OpenStreetMap (10 minutes)
First get the map file:
1. Go to **openstreetmap.org**
2. Search for a Meerut junction (e.g. *Begum Bridge Road, Meerut*)
3. Zoom in so one junction and its approach roads fill the screen
4. Click **Export** (top bar) → **Export** button
5. It downloads `map.osm` — rename it to **`meerut.osm`** and put it in the `derisk` folder

If the Export button is greyed out, click "Overpass API" underneath it instead.

Then in MATLAB:
```
check03_osm_import
```
Send back: `check03_output.txt` and `check03_osm_map.png`

---

## Step 4 — Can our REAL model get into MATLAB? (10 minutes)
In a **terminal** (not MATLAB):
```
pip install torch onnx onnxruntime onnxscript
python3 python/export/to_onnx.py --model <checkpoint.pt>
```
`onnxscript` is not optional — without it the export dies with
`ModuleNotFoundError: No module named 'onnxscript'`.

Then in MATLAB, from the repository root:
```
check04_onnx_lstm
```
Send back: `check04_output.txt`

**Two things changed on 1 Sep 2026 and both matter.**
`check04_onnx_lstm.py` is gone — it built a *toy* LSTM, and a toy importing tells you nothing
about our real model, which also carries LayerNorm, baked-in normalisation constants and a
Slice + Flatten. Those are the parts that fail.
It also swept opsets 13, 11 and 9, and torch **silently upconverts all three to 18** — three
files, one opset, three misleading names. We now write 17, 18 and 20 only.

**Read the output for PLACEHOLDER layers, not just for "succeeded".** An operator MATLAB cannot
convert does not throw; it arrives as a custom layer with a function a human must write.

**Send Stream D the opset number immediately.** It is the one thing blocking them.

---

## Step 5 — Does our foundation run? (10 minutes)
In a **terminal**:
```
cd ~/dev/sih2026
git clone https://github.com/mathworks/OpenTrafficLab.git
```
Then in MATLAB:
```
check05_opentrafficlab
```
It prints a list of example scripts. **Open one and run it without changing anything.**
Send back: `check05_output.txt`, whether the example ran, and any figure it produced.

---

## Step 6 — The supercomputer (ask, don't run)
Not a script. Get answers to `check06-dgx-questions.md` from whoever runs the DGX.

---

## Step 7 — Can the cuboid world hold a drop-off? (10 minutes)
In MATLAB:
```
check07_negative_obstacle
```
Send back `check07_output.txt` **and every figure**.

**This one decides whether the ghat scenario is buildable at all.** A khai returns no lidar
points, so it can never be an S1 track — it has to be S9 ground geometry instead. If the cuboid
world models nothing beside the road, a drop-off cannot be represented and we need a fallback.
Answer the questions the script prints; they are the point of it, not the numbers.
