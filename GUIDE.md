# SIH26037 - The AI Training Guide

> **AI / ML Stream Master Workflow & Visual Progress Dashboard**  
> **Active Branch:** stream-ml | **Workstation:** NVIDIA RTX A1000 (8 GB VRAM) | **Lead:** Aditya  
> **Status As Of:** Post-Tasks 1–5 Sync (September 5, 2026)

### Summary Metric Snapshot

| Metric | Value | Breakdown / Notes |
|---|:---:|---|
| **Overall Pipeline Progress** | **100% (core) + Part 16 in progress** | Core complete (68); Part 16 Steps 84–85 complete, Step 86 actively training on A100 |
| **Completed Steps** | **70** | `[🟢COMPLETED]` — Core pipeline (68) + Steps 84 & 85 (Model 4 dataset & script verified) |
| **Partially Done** | **1** | `[🟡PARTIALLY DONE]` — Step 86 (Model 4 DeepLab v3+ training on A100, Epoch 1 Drivable IoU = 0.9429) |
| **Active Planned Steps** | **3** | `[🔵TO DO]` — Part 16 Steps 87–89 (Evaluation, ONNX export, and MATLAB verification) |
| **Deferred / Bypassed** | **14** | `[⚪DEFERRED / BYPASSED]` — 8 supercomputer steps bypassed by local GPU; 6 post-S7 |

### Visual Pipeline Status Overview

| Phase / Master Track | Steps | Status | Verified Milestone / Deliverable |
|---|:---:|:---:|---|
| **Part 1: Setup & Python Environment** | 1–7 | 🟢 7/7 COMPLETE | Repo cloned, Python 3.10/3.14 verified, AGENTS.md S2 contract passed |
| **Part 3: METEOR Data Acquisition & Prep** | 8–17 | 🟢 10/10 COMPLETE | 2,502 XMLs fetched, 3.73M sequences extracted (10 Hz, 31 features, 0 leakage) |
| **Part 4: Model 1 Laptop Sanity Run** | 18–20 | 🟢 3/3 COMPLETE | 2-epoch sanity training completed on laptop |
| **Part 5: GPU Compute Migration** | 21–29 | 🟢 2/2 ON LOCAL GPU | Bypassed supercomputer; trained directly on local RTX A1000 GPU (15 epochs) |
| **Part 6: Model 2 (Group Attention)** | 30–32 | 🟢 3/3 COMPLETE | 15 epochs on GPU (loss 0.2089, -44.9%), AP 0.3691, comparison table generated |
| **Part 7: 8-Check Metric Evaluation** | 33–36 | 🟢 4/4 COMPLETE | evaluate.py full suite run on all 249 val clips (772k samples) |
| **Part 8: ONNX Export & Archival** | 37–40 | 🟢 4/4 COMPLETE | All 6 production ONNX files exported (opsets 17, 18, 20), bitwise verified |
| **Part 9: Models 3, 4, 5 (Perception Suite)** | 41–44 | 🟡 1 COMPLETE, 3 POST-S7 | Model 3 dataset curated, trained & saved (33.5 MB); Models 4 & 5 post-Sept 7 demo |
| **Part 11: Model 3 Local Setup & Audit** | 45–58 | 🟢 10 PREP, 4 DEFERRED | MATLAB R2024b, toolboxes, YOLOX add-on, GPU & 46k images ready; pipeline verified |
| **Part 12: Aditya's Directives** | 59–64 | 🟢 6/6 COMPLETE | check04 Opset 18 passed in MATLAB; Model 2 dangerous rate measured; scores exported |
| **Part 13: Calibration Exploration** | 65–70 | 🟢 6/6 COMPLETE | Ensemble of Models 1 & 2 + Temp Scaling (Option B verdict logged) |
| **Part 14: Fast-Track Model 3 (YOLOX)** | 71–76 | 🟢 6/6 COMPLETE | Dual bug fixed (H7/H9), 3.7k curated, Stage 1 trained & spotter_yolox.mat saved |
| **Part 15: A100 YOLOX Continuation Training** | 77–83 | 🟢 7/7 COMPLETE | Supercomputer pipeline complete: 15 epochs trained, ONNX exported & imported in MATLAB |
| **Part 16: Model 4 Road-Finder (A100)** | 84–89 | 🟡 2 DONE, 1 RUNNING | Step 84/85 complete; Step 86 training on A100 (Epoch 1 Drivable IoU = 0.9429) |

### Status Tag Legend:
- [🟢COMPLETED] : Step successfully executed, verified against code/data, and logged.
- [🟡PARTIALLY DONE] : Work actively initiated / environment prepared; execution pending.
- [🔵TO DO] : Active planned step awaiting execution in current phase.
- [⚪DEFERRED / BYPASSED] : Postponed to post-Sept 7 internal round or bypassed by local GPU training.

---
For whoever takes the AI work. Everything from an empty laptop to trained models handed over to the simulation team. [cite: 1]

You do not have to write the model code. Aditya writes and supplies all of it through GitHub. Your job is to run it, train it, check it honestly, and report the numbers. If something is missing or broken, ask him do not rewrite it yourself, because other people's code depends on its exact shape. [cite: 1]

Every step is marked [HIGH] or [LOW]. Do every [HIGH] step first. [LOW] steps are real work we intend to do, just not before the high ones are done. [cite: 1]

If a step fails, send the WHOLE error. Never a summary. A trimmed error costs a day. [cite: 1]

---

## The models [cite: 1]
### what we are training and why [cite: 1]

Five models. Two of them are essential; the rest are evidence. [cite: 1]

| # | NAME | WHAT IT DOES, IN ONE LINE | DATA IT LEARNS FROM | PRIORITY |
|---|------|---------------------------|---------------------|----------|
| 1 | The predictor | Says whether a vehicle beside us will let us in | METEOR markings, 1.8 GB | HIGH |
| 2 | The predictor, group version | Same job, but looks at all nearby vehicles together instead of one at a time | the same 1.8 GB | HIGH |
| 3 | The spotter | Looks at a photo and says that is a cow / auto-rickshaw/pushcart | IDD Detection + FGVD + animal photos, ~25 GB | HIGH |
| 4 | The road-finder | Marks which part of a photo is drivable road | IDD Segmentation, 24 GB | LOW |
| 5 | The laser spotter | Finds vehicles in laser scans instead of photos | IDD-3D, 236 GB | LOW |

Models 1 and 2 do the same job in two different ways. We train both, compare them, and report both results. [cite: 1]
That comparison is itself something worth reporting it is not indecision. [cite: 1]

Only model 1 or 2 goes inside the car. Models 3, 4 and 5 run on files and produce numbers that prove things. [cite: 1]
They never touch the simulation, so they cannot break it. [cite: 1]

---

## Read this before anything else [cite: 1]

To the two of you taking the Al work. [cite: 1]

You are not writing the model code. It is already written and on GitHub. Every script in this guide exists, and the ones that could be tested on real data have been. Your job is to run them, check the results honestly, and report the numbers. [cite: 1]

If something is missing or broken, tell Aditya. Do not rewrite it yourself other people's code depends on its exact shape, and a helpful rewrite is how five people's work quietly stops fitting together. [cite: 1]

How to split it between two people. In week one, both of you do everything together you will both need to understand the data. After that, one takes the data side (Parts 3 and 4) and one takes the training side (Parts 5 to 8). The handover between you is the file of numbers produced by Part 4. [cite: 1]

---

## What is on GitHub [cite: 1]

Repository: github.com/adityasinghin01-hash/sih26037 [cite: 1]

| FILE | WHAT IT IS |
|---|---|
| AGENTS.md | The project rules and the frozen contract. Section 3 is the exact shape of everything passed between people. Read it. Never change it without asking |
| ML.md | Instructions for your Al, not for you. It carries the verified facts about the dataset its real specification, and the rules for using it |
| DGX.md | The supercomputer |
| .agents/rules/ | Rules your Al loads by itself |
| python/meteor/fetch_annotations.py | Downloads the data 1.8 GB, not 93 GB |
| python/meteor/parse_xml.py | Reads METEOR's annotation files |
| python/meteor/check_balance.py | The gate. Run before training. It measures how rare the answer is |
| python/meteor/build_dataset.py | Turns annotations into numbers the model reads |
| python/meteor/split.py | Splits the data for testing by clip, never by frame |
| python/model/yield_lstm.py | Model 1 |
| python/model/yield_attention.py | Model 2 |
| python/model/train.py | Trains either one and reports the honest numbers |
| python/export/to_onnx.py | Converts a trained model into a file MATLAB can read |
| python/tests/test_contract.py | Checks nothing has broken. Run this first, and after any change |
| derisk/check06_dgx_probe.sh | Measures the supercomputer in one command |

---

## Using Antigravity on this project [cite: 1]

Open the whole repository, not a subfolder. The rules load from the repository root. Open a subfolder and your Al starts blind wrong function names, invented code, edits that break other people. [cite: 1]

Three things load by themselves once you open it: [cite: 1]
* AGENTS.md the project rules, always [cite: 1]
* .agents/rules/no-unrequested-actions.md always [cite: 1]
* .agents/rules/ml-pipeline.md when you are doing AI work, and it tells your Al to read ML.md [cite: 1]

So you do not have to explain the project to it. It already knows our units, our naming, and what the data contains. [cite: 1]

Four habits that make the difference: [cite: 1]
* Paste the whole error. Every line, plus the command you ran. "It didn't work" wastes a round trip; the full text usually contains the answer. [cite: 1]
* Ask it to check, not just to write. Say: "before using a function, confirm it exists." Both MATLAB and Python have functions that sound right and do not exist. We have lost time to this already. [cite: 1]
* One file at a time. Ask for one script, run it, confirm, move on. Five files at once means five files nobody has run. [cite: 1]
* Delete any number it did not measure. If it writes an accuracy or a timing it did not produce by running something, that number is fiction. A plausible wrong number is worse than a blank. [cite: 1]

---

## Before you download three things to know [cite: 1]

1. It is 1.8 GB, not 93 GB. We take only the markings, not the video. Everything the model reads comes from the markings. [cite: 1]
2. Put it outside the repository. Data must never be committed. ~/meteor-data is fine. [cite: 1]
3. The download is resumable. Stop it, rerun it, it skips what it already has and checks every file. A dropped connection costs nothing. [cite: 1]

---

## Before you train five things to know [cite: 1]

These were measured on real data, not assumed. They will decide how you spend your first week. [cite: 1]

1. The answer we want is very rare. Across 25,000 vehicles, "this one yielded" was ticked about 20 times roughly 1 in 1,262. A model can answer "no" every single time and be right 99.9% of the time. This is why accuracy is banned in this guide. [cite: 1]
2. Two other labels are far more common. "Overtaking" was ticked 1 in 25, "changing lane" 1 in 1. Two labels "zigzagging" and "speeding" were never ticked at all, in 25,000 vehicles. [cite: 1]
3. So the question may need to change. Predicting "will this vehicle assert itself" instead of "will it yield" gives roughly 70 times more examples, and tells our car nearly the same thing. That is Aditya's decision. Measure it, report it, wait. [cite: 1]
4. Four of the 31 numbers are empty. METEOR records the car's own position once per clip, not as it moves, so we cannot compute our own speed, turning or acceleration from it. The model is effectively working with 27 numbers. build_dataset.py warns you about this do not ignore the warning. [cite: 1]
5. There are almost no animals. Five, in 24 clips. This data cannot teach us how animals behave, which is why our cow is simulated rather than learned. Do not try to train an animal model on it. [cite: 1]

---

## The order to work in [cite: 1]

1. Run python3 python/tests/test_contract.py proves your setup is sound before you touch data [cite: 1]
2. Download (Part 3) [cite: 1]
3. Run the gate (Step 13) and send Aditya the ratio. Stop there and wait [cite: 1]
4. While waiting: get supercomputer accounts and run the probe (Part 6) [cite: 1]
5. Then Parts 4 to 10 in order [cite: 1]

---

## Part 1 Set up [cite: 1]

### Step 1 Any laptop will do [🟢COMPLETED] [HIGH]
Mac, Windows or Linux. Nothing in Parts 1 to 5 needs MATLAB. You only need MATLAB much later, at Part 8, and someone else can run that part for you. [cite: 1]

### Step 2 Check Python [🟢COMPLETED] [HIGH]
```bash
python3 --version
```
Done when: it prints 3.11 or higher. If it errors, install Python from python.org, close the terminal, reopen it, try again. [cite: 1]

### Step 3 Get the project [🟢COMPLETED] [HIGH]
```bash
cd ~
git clone https://github.com/adityasinghin01-hash/sih26037.git
cd sih26037
```
Done when: you see folders named python, matlab, derisk, teammates. [cite: 1]

### Step 4 Make your own branch [🟢COMPLETED] [HIGH]
Never work on main several people would overwrite each other. [cite: 1]
```bash
git checkout -b stream-ml
```
Done when: git branch shows * stream-ml. Once only. From now on you cannot break anyone. [cite: 1]

### Step 5 Read AGENTS.md [🟢COMPLETED] [HIGH]
This file is the rules of the project. Two reasons it matters. [cite: 1]

One: section 3 is the frozen contract. It is the exact shape of everything handed between people the list of detected objects, the 31 numbers, the prediction output. If it changes quietly, other people break and only find out days later. [cite: 1]

Two: the Al reads it by itself. Antigravity and Claude Code both load AGENTS.md from the project folder automatically. That is why the Al already knows our function names and units without being told. [cite: 1]

Done when: you have read section 3 and can point to the parts your work produces S2 (the 31 numbers) and S3 (the prediction). [cite: 1]

### Step 6 Install what Python needs [🟢COMPLETED] [HIGH]
```bash
pip3 install --user torch numpy onnx
python3 -c "import torch; print(torch.__version__)"
```
Done when: a version prints with no red errors. [cite: 1]

---

## Part 2 - Working with Antigravity [cite: 1]

### Step 7 How to get good code out of the Al [🟢COMPLETED] [HIGH]
You will use Antigravity constantly. These are the habits that make the difference. [cite: 1]

It already knows the project. It reads AGENTS.md on its own, so you do not need to explain our units, our naming, or the contract. Just say what you want. [cite: 1]

Always give it the whole error. Paste every line, from the first to the last, plus the command you ran. A summary like "it didn't work" wastes a round trip. The full text usually contains the exact answer. [cite: 1]

Ask it to check, not just to write. MATLAB and Python both have functions that sound right but do not exist. A useful instruction: "before you use a function, confirm it exists and check the argument order." We have already lost time to a made-up function name once. [cite: 1]

One file at a time. Ask for one script, run it, confirm it works, then move on. Asking for five files at once produces five files that have never been run. [cite: 1]

Never let it invent a number. If it writes an accuracy or a timing you did not produce by running something, delete it. A plausible-sounding number that turns out false is worse than a blank. [cite: 1]

When you get stuck, say what you expected. "I expected the loss to go down and it stayed flat" is far more useful than "this is broken." [cite: 1]

---

## Part 3 - Get the data [cite: 1]

### Step 8 Choose where the data lives [🟢COMPLETED] [HIGH]
Not inside the project folder. Data must never be committed. [cite: 1]
```bash
mkdir -p ~/meteor-data
df -h ~ | tail -1
```
Done when: you have 15 GB free. If not, use an external drive and use that path everywhere below. [cite: 1]

### Step 9 Download the markings [🟢COMPLETED] [HIGH]
1.8 GB, not 93 GB. We take only the markings, not the video every number our model reads comes from the markings. [cite: 1]
```bash
python3 python/meteor/fetch_annotations.py --out ~/meteor-data
```
20-40 minutes. Safe to stop and rerun it skips what is already there. Done when: it prints fetched=2502 skipped = 0 failed = 0. [cite: 1]

### Step 10 Confirm it arrived [🟢COMPLETED] [HIGH]
```bash
du -sh ~/meteor-data
ls ~/meteor-data/METEOR_Dataset/
```
Done when: about 10 GB, showing Frame XML Annotations and Video XML Annotations. [cite: 1]

---

## Part 4 - Preparing the data (preprocessing) [cite: 1]

This part turns raw markings into something a model can read. Aditya supplies the scripts you run them and check the output at each stage. [cite: 1]

### Step 11 Unpack the clips [🟢COMPLETED] [HIGH]
Each clip arrives as a zip containing one marking file per frame. [cite: 1]
```bash
python3 python/meteor/unpack.py --data ~/meteor-data
```
Done when: you have folders of frame_000000.xml files. A full clip has 1,800 one minute at 30 frames per second. [cite: 1]

### Step 12 Look inside one file, once [🟢COMPLETED] [HIGH]
```bash
head -60 ~/meteor-data/unpacked/*/Annotations/frame_000045.xml
```
For every vehicle you should see: its type, its box on the screen, and attributes including Yield, Cutting and track_id. [cite: 1]

Three things already checked, so you do not have to: [cite: 1]
* Every non-ego vehicle carries these labels. [cite: 1]
* track_id means we do not write our own tracking. A vehicle keeps its number across frames. [cite: 1]
* The x-axis / y-axis / z-axis values are the ego car's own GPS repeated, not each vehicle's position. There is no 3-D per vehicle. Do not try to build any. [cite: 1]

### Step 13 THE CHECK THAT DECIDES EVERYTHING [🟢COMPLETED] [HIGH]
Do this before any model is trained. If yielding is rare, a model can answer "no" every time, score 99%, and be useless. [cite: 1]
```bash
python3 python/meteor/check_balance.py --data ~/meteor-data
```
It prints how many vehicles were seen and how many yielded. [cite: 1]

Send that ratio to Aditya immediately. It decides what happens next: [cite: 1]

| RATIO | MEANING | WHAT WE DO |
|---|---|---|
| Better than 1 in 20 | healthy | train normally |
| 1 in 20 to 1 in 200 | imbalanced | weight the rare answer during training |
| Worse than 1 in 200 | severe | change the question itself |

### Step 14 Reduce 30 frames a second to 10 [🟢COMPLETED] [HIGH]
The data is recorded 30 times a second. Our model uses 10. Take every third frame. Two seconds of history then becomes 20 steps, which is what the contract expects. [cite: 1]
```bash
python3 python/meteor/build_dataset.py --data ~/meteor-data --out ~/meteor-data/features
```

### Step 15 What this script is actually doing [🟢COMPLETED] [HIGH]
For every vehicle in every frame it produces 31 numbers: where its box is, how big, how fast the box is growing, what type of vehicle, and what our own car was doing. [cite: 1]

Why "how fast the box grows" instead of distance: measuring distance from one camera is unreliable one degree of camera tilt makes distance at 30 metres wrong by about a third, and every pothole tilts a dashcam. Things coming closer look bigger, and that we can measure exactly. None of the 31 numbers is a distance. [cite: 1]

The exact list is in AGENTS.md under S2. The order never changes other people's code reads them by position. [cite: 1]

### Step 16 Check the shape [🟢COMPLETED] [HIGH]
```bash
python3 -c "
import numpy as np, glob
d = np.load(sorted(glob.glob('$HOME/meteor-data/features/*.npz'))[0])
print(d['x'].shape, d['y'].shape, d['adj'].shape)"
```
Done when: the last number is 31. If it is not, stop and tell Aditya the contract is broken and the planner team's code will read the wrong values. [cite: 1]

### Step 17 Split the data the RIGHT way [🟢COMPLETED] [HIGH]
This one mistake silently ruins results, so it is worth understanding. [cite: 1]

Split by clip, never by frame. Frames next to each other are nearly identical. If some frames from a clip go into training and others into testing, the model has effectively seen the test answers, and your scores will look great and mean nothing. [cite: 1]
```bash
python3 python/meteor/split.py --features ~/meteor-data/features --by clip
```
Done when: it reports how many clips went to training and how many to testing not how many frames. [cite: 1]

---

## Part 5 - Model 1, and proving it runs [cite: 1]

### Step 18 What model 1 does [🟢COMPLETED] [HIGH]
It reads 20 steps of those 31 numbers two seconds of one vehicle's history and answers one question: will this vehicle let us in? It outputs a number between 0 and 1. [cite: 1]

It reads events in order and remembers what came before, the way you read a sentence. [cite: 1]

It does not drive the car. It answers one question. Everything that keeps the car safe is geometry, not learning. [cite: 1]

### Step 19 Train it small, on your laptop [🟢COMPLETED] [HIGH]
Do not go near the supercomputer yet. Prove it runs first. [cite: 1]
```bash
python3 python/model/train.py --features ~/meteor-data/features --model lstm --epochs 2 --limit 5000
```
Done when: the loss goes down between the two rounds and a model file is saved. If the loss does not move: send the whole output. That is a data problem, not a model problem. [cite: 1]

### Step 20 Look at the numbers that matter [🟢COMPLETED] [HIGH]
Accuracy alone is a lie when one answer is rare. You need both: [cite: 1]
* Precision when it says "they will yield", how often is that true? [cite: 1]
* Recall of all the vehicles that did yield, how many did it catch? [cite: 1]

Done when: both are reported separately for yield and no-yield. [cite: 1]

---

## Part 6 The supercomputer [cite: 1]

### Step 21 Get an account [⚪DISCARDED / BYPASSED] [HIGH]
Ask whoever runs the DGX A100. Ask at the same time: is MATLAB installed on it? Another part of the team needs that answer. [cite: 1]

### Step 22 Log in [⚪DISCARDED / BYPASSED] [HIGH]
```bash
ssh yourusername@the-machine-address
```

### Step 23 Run the probe before anything else [⚪DISCARDED / BYPASSED] [HIGH]
One script answers every question about the machine free disk, what you can write to, whether it reaches the internet, whether there is a job queue, what Python it has. [cite: 1]
```bash
git clone https://github.com/adityasinghin01-hash/sih26037.git
cd sih26037
bash derisk/check06_dgx_probe.sh 2>&1 | tee dgx_probe.txt
```
Run it on a compute node, not the login node the answers differ. Done when: send the whole dgx_probe.txt to Aditya, unedited. [cite: 1]

### Step 24 Find the right disk [⚪DISCARDED / BYPASSED] [HIGH]
```bash
df -h /raid $HOME
```
The big fast disk is usually /raid, around 15 TB. Warning: /raid is fast but not backed up. Never keep the only copy of anything there. [cite: 1]

### Step 25 Move code the right way [⚪DISCARDED / BYPASSED] [HIGH]
Code always travels through GitHub. Never copy files by hand. [cite: 1]

On your laptop: [cite: 1]
```bash
git add -A && git commit -m "what I changed" && git push -u origin stream-ml
```

On the supercomputer: [cite: 1]
```bash
cd sih26037 && git fetch && git checkout stream-ml && git pull
```
Laptop → GitHub → supercomputer. Every single time. [cite: 1]

### Step 26 Get the data there directly [⚪DISCARDED / BYPASSED] [HIGH]
Do not copy 10 GB from your laptop. The supercomputer has a much faster connection. [cite: 1]
```bash
pip install --user torch numpy onnx
python3 python/meteor/fetch_annotations.py --out /raid/yourname/meteor-data
```

### Step 27 Check the graphics cards [🟢COMPLETED] [HIGH]
```bash
nvidia-smi
python3 -c "import torch; print('GPUs:', torch.cuda.device_count())"
```
Done when: you see 8. If you see 0, PyTorch was installed without GPU support - say so. [cite: 1]

### Step 28 Train so it survives you logging out [⚪DISCARDED / BYPASSED] [HIGH]
If your connection drops, the job dies unless you do this. [cite: 1]
```bash
tmux new -s training
python3 python/model/train.py --features /raid/yourname/meteor-data/features --model lstm --epochs 50
# press Ctrl+B then D to leave it running
```
Return later with `tmux attach -t training`. [cite: 1]

### Step 29 Many small runs, not one long one [🟢COMPLETED] [HIGH]
Our model trains in minutes, not days. The supercomputer is not for one huge model it is for trying many settings at once and keeping the best. [cite: 1]

Run 20-40 short runs varying the settings. Done when: you have a table of settings and scores and know which won. Say this honestly in the report: eight graphics cards, forty small experiments not one giant model. [cite: 1]

---

## Part 7 - Model 2, the group version [cite: 1]

### Step 30 Why a second model [🟢COMPLETED] [HIGH]
Model 1 looks at each vehicle alone. But a scooter's behaviour depends on the bus beside it, not only on us. Model 2 looks at all nearby vehicles together. [cite: 1]

It is built using attention, not message-passing. Both would work, but attention is made of ordinary multiplication that MATLAB can import. Message-passing uses operations MATLAB does not support and would fail at the very last step. Aditya's code already uses the safe one. [cite: 1]

### Step 31 Same data, same test [🟢COMPLETED] [HIGH]
Identical features, labels and split. Only the model changes. Done when: both models' scores sit side by side. [cite: 1]

### Step 32 Report both [🟢COMPLETED] [HIGH]
Do not quietly keep the winner. Publish both. Comparing a sequence model with a group model on identical data is a result in itself. [cite: 1]

---

## Part 8 - Test it before it goes anywhere near MATLAB [cite: 1]

Do not export a model you have not tested. Once it is inside the simulation, a fault in the model looks like a fault in the car, and two people spend a day arguing about whose problem it is. [cite: 1]

### Step 33 Understand what "good" means here [🟢COMPLETED] [HIGH]
The model will never be perfect, and it does not need to be. [cite: 1]

It is predicting what a human will do next. The same scooter rider, in the same gap, on the same road, lets you in on Monday and pushes through on Tuesday. No model can be right every time, because the information is not there. [cite: 1]

Our car survives that, because the safety comes from the geometry underneath, which does not care what the model said. [cite: 1]

So the goal is not "never wrong". It is "wrong in the safe direction". There are two ways to be wrong and they are not equal: [cite: 1]

| THE MISTAKE | WHAT HAPPENS |
|---|---|
| Says "they will let me in" they do not | We pull out in front of someone. DANGEROUS |
| Says "they will not" they would have | We wait a few seconds longer. Harmless |

Make the first rare. Accept the second. [cite: 1]

### Step 34 Run the eight checks [🟢COMPLETED] [HIGH]
```bash
python3 python/model/evaluate.py --features ~/meteor-data/features --model <your-model.pt>
```
It checks, in order: [cite: 1]
1. The outputs are usable numbers finite, between 0 and 1, and not the same value every time [cite: 1]
2. There is something to measure the test set actually contains examples of yielding [cite: 1]
3. The operating point sweeps every threshold and picks the one where the dangerous mistake happens at most 1% of the time, while still letting the car go as often as possible [cite: 1]
4. Honesty when it says 80%, does it happen 80% of the time? An overconfident model is worse than a weak one, because the planner believes the number [cite: 1]
5. It actually reads its inputs scrambles the input and confirms the answer changes. A model that ignores its input can still score well and is worthless [cite: 1]
6. Degradation adds noise and shows how fast it falls apart. This is the perception curve [cite: 1]
7. Per class where it fails worst. It may be fine on cars and useless on scooters [cite: 1]
8. The exported file agrees with the model a conversion can silently change behaviour, and this is the last place to catch it [cite: 1]

It ends with READY FOR MATLAB or NOT READY, and a threshold number. [cite: 1]

### Step 35 Send three things, not one [🟢COMPLETED] [HIGH]
When it says ready, report: [cite: 1]
1. The threshold. Below it the planner treats the prediction as unusable and falls back to geometry alone. [cite: 1]
2. The dangerous error rate. This is the honest number and it goes on the slide. [cite: 1]
3. The degradation table from check 6. [cite: 1]

If it says NOT READY, do not export. Send the whole output and wait. [cite: 1]

### Step 36 How long to spend here [🟢COMPLETED] [HIGH]
As long as it takes. Training again is cheap minutes. Discovering a bad model after it is wired into the simulation costs days, and you will find it by watching a car behave strangely rather than by reading a number. [cite: 1]

---

## Part 9 - Handing it to the simulation [cite: 1]

### Step 37 Test the crossing FIRST, in week one [🟢COMPLETED] [HIGH]
This is the most likely thing in the whole project to break, and it blocks another person completely. Do it with a throwaway model before training the real one. [cite: 1]

On your machine: [cite: 1]
```bash
python3 derisk/check04_onnx_lstm.py
```
Then someone with MATLAB runs `derisk/check04_onnx_lstm.m`. Done when: you know which version number MATLAB accepts. [cite: 1]

### Step 38 Send that number immediately [🟢COMPLETED] [HIGH]
One number, sent the moment you have it. The planner team cannot connect anything without it. Do not wait for training to finish. [cite: 1]

### Step 39 Export the trained model [🟢COMPLETED] [HIGH]
```bash
python3 python/export/to_onnx.py --model <your-trained-file> --opset <the-number-that-worked>
```
Done when: the file exists and its shapes match AGENTS.md. [cite: 1]

### Step 40 Never commit models or data [🟢COMPLETED] [HIGH]
git status should never list a .onnx, .pt, or data file. Share those through Google Drive. [cite: 1]

---

## Part 10 The other three models [cite: 1]

These never enter the car. They run on files and produce numbers that prove things. [cite: 1]

### Step 41 The spotter [🟡PARTIALLY DONE] [HIGH]
What it does: looks at a photo and names what it sees cow, auto-rickshaw, pushcart, person. Why it matters: the task explicitly asks for camera perception and names these objects. That is currently a gap in our work, and this closes it with measured numbers. Which model: YOLOX. We checked the newer alternative, RTMDet - it cannot be trained on new classes, only run on its original ones. YOLOX trains, and is specifically better at small objects, which Indian traffic is full of. Data: IDD Detection 22.8 GB + FGVD 2.6 GB + DATS 2022 for animals. Done when: accuracy is reported per class, especially cow, auto-rickshaw and pushcart. [cite: 1]

### Step 42 The road-finder [🔵TO DO / DEFERRED] [LOW]
What it does: marks which part of a photo is drivable road. Why: our car has a rule about never leaving drivable ground. This shows the idea works on real Indian roads with no lane markings best shown on our own village footage. Model: DeepLab v3+. Data: IDD Segmentation, 24 GB. [cite: 1]

### Step 43 The laser spotter [🔵TO DO / DEFERRED] [LOW]
What it does: finds vehicles in laser scans instead of photos. Why: the car's main sensor is the laser and it currently uses a generic tool. This one is trained on real Indian laser data. Model: PointPillars. Data: IDD-3D, 236 GB. Note: MATLAB already includes this model, pretrained, so retraining it there takes a few lines. In Python it needs a large extra framework installed first. Since this model never enters the car, doing this one in MATLAB costs us nothing decide with Aditya before starting. [cite: 1]

### Step 44 Use IDD-3D with no training at all [🔵TO DO / DEFERRED] [HIGH]
Two of its best uses need no model: [cite: 1]
1. Replay real Indian traffic. Every object has an ID that follows it across frames, so real vehicles that drove on real roads can be replayed inside our simulation. Nobody can then say we arranged the traffic to flatter our car. [cite: 1]
2. Check our simulated laser is realistic. Compare our pretend scans with real ones density, range, points landing on a vehicle. This defends the claim that our simulation is a fair test. [cite: 1]

Done when: both are written up with numbers. [cite: 1]

---

## Done, and what to send [cite: 1]

| # | THIS COMPONENT IS FINISHED WHEN |
|---|----------------------------------|
| 1 | The yield ratio from Step 13 is reported |
| 2 | The split is by clip, and you can say how many clips are in each side |
| 3 | Both predictor models are trained and compared |
| 4 | Precision and recall are reported separately, not just accuracy |
| 5 | The working version number has been sent to the planner team |
| 6 | The exported file matches the shapes in AGENTS.md |
| 7 | The spotter's per-class accuracy is reported |
| 8 | One command regenerates every number above |

When something breaks, send: the whole error from first line to last the exact command you ran what you expected instead. [cite: 1]

Never: commit data or model files change section 3 of AGENTS.md without asking work on main report a number you did not produce by running something. [cite: 1]

SIH26037 ML Training Guide 01 Sep 2026 [cite: 1]


---

## Phase 2 Update: Critical Path for Internal Demo (Sept 7)

### 1. Model Matrix & Deployment Allocation

| Model | Architecture | Role & Dataset | Internal Demo (Sept 7) | Final Deployment |
|---|---|---|---|---|
| **Model 1 (Predictor)** | 1-Layer LSTM ($H=64$) | Single-vehicle intent (METEOR 1.8 GB) | **CRITICAL PATH:** Export to ONNX, run MATLAB check, send opset | Baseline in-car model |
| **Model 2 (Attention)** | Dense Attention ($H=64, A=16$) | Multi-vehicle spatial interaction (METEOR 1.8 GB) | **DONE / BENCHMARKED:** Slide owned ($AP=0.3691$, $ECE=0.1502$) | Primary in-car model (post-Sept 7) |
| **Model 3 (Spotter)** | YOLOX | Unstructured object detection (IDD 25 GB) | Parallel setup on KIET GPU cluster | Offline perception benchmark |
| **Model 4 (Road-Finder)** | DeepLab v3+ | Drivable area segmentation (IDD Seg 24 GB) | Staged for cluster execution | Offline safety boundary check |
| **Model 5 (Laser Spotter)**| PointPillars | 3D bounding box LiDAR detection (IDD-3D 236 GB) | Staged for cluster execution | Offline LiDAR validation |

---

### 2. Immediate Technical Directives

**1. PyTorch Version & ONNX Export**
* Do not modify `ml/python/export/to_onnx.py` or the `FORBIDDEN` list under any circumstances.
* Check real PyTorch version: `python3 -c "import torch; print(torch.__version__)"`.
* Re-run `to_onnx.py` using Opset 20 on an environment running PyTorch 2.13+.
* Send `yield_lstm.onnx` to Aditya for macOS verification if local MATLAB add-on setup is delayed.

**2. Contract Logic & The Safety Gate**
* **The Target Flip:** The model was trained on `assert` ($P_{\text{assert}}$). The planner consumes $P_{\text{yield}}$. The conversion must occur exclusively on the MATLAB side:
  $$P_{\text{yield}} = 1 - P_{\text{assert}}$$
  Do not alter naming or inversion inside the `.onnx` model graph.
* **The Safety Gate:** With a measured dangerous error rate of 20.18% (target $\le 1.0\%$), set `Valid = false`[cite: 2]. The vehicle simulation falls back directly to deterministic geometry. Presenting an active safety fallback with honest validation metrics is our primary evaluation defense.

**3. Integration & Demo Backup Scenario**
* The full demo will execute on macOS. All modules integrate via GitHub commits on `stream-ml`.
* If the full rendered 3D city environment is not finished in time, simulation runs against two pre-built standalone backup driving scenarios.

**4. Parity Test Resolution (`testFeatureParity`)**
* **Discrepancy:** Case `"empty"` produces `[0 31]` in MATLAB and `[0 0]` in Python.
* **Verdict:** `[0 31]` is correct. Under `AGENTS.md` Section 3 (S2 Contract), an empty detection frame with zero vehicles still preserves a 31-dimensional feature schema. Returning `[0 0]` strips the feature dimension, causing downstream matrix multiplications expecting `array.shape[1] == 31` to raise runtime dimension errors. Python's empty extraction handler must be aligned to output `shape = (0, 31)`.

---

## Part 11 - Training Model 3 (The Spotter / YOLOX) on Local Workstation

Model 3 is an offline camera perception benchmark. It takes dashcam photos and detects unstructured Indian road actors (cow, auto-rickshaw, pushcart, bicycle, truck, etc.). It never enters the real-time simulation loop.

Because MATLAB's native YOLOX training is already written in `matlab/+sih/+models/trainSpotter.m`, you do NOT write any code. You simply install the exact required MATLAB toolboxes, download the IDD dataset, and run the training pipeline with VRAM adjustments for your local GPU.

---

### Phase A: Installing MATLAB with the Exact Required Toolboxes

Do NOT install all 110+ MATLAB toolboxes — that wastes 35-45 GB of disk space. A minimal installation tailored for Model 3 takes only ~4-6 GB.

#### Step 45 Download the MATLAB Installer [🟢COMPLETED] [HIGH]
1. Go to [mathworks.com](https://www.mathworks.com/) and sign in using your institute academic email.
2. Navigate to your license and download the installer for **MATLAB R2024b** (or R2025a) for Windows.
3. Run the installer executable (`setup.exe`).

#### Step 46 Select ONLY the Essential Products [🟢COMPLETED] [HIGH]
When prompted to choose which products to install, check **ONLY** these three:
1. **MATLAB**
2. **Deep Learning Toolbox** (required for neural networks, `trainingOptions`, and `check04`)
3. **Computer Vision Toolbox** (required for bounding boxes, image datastores, and `yoloxObjectDetector`)

*(Optional: If you later decide to run Model 5 PointPillars locally, check **Lidar Toolbox**. Do NOT check Simulink, Stateflow, Automated Driving Toolbox, Navigation Toolbox, or ROS Toolbox — those belong to the simulation stream and waste tens of gigabytes).*

Done when: MATLAB installer completes and you can launch MATLAB from your Windows Start Menu.

#### Step 47 Install the Critical YOLOX Free Add-On [🟢COMPLETED] [HIGH]
The standard product installer does NOT include the YOLOX training backend. `yoloxObjectDetector` exists without it, but `trainYOLOXObjectDetector` will throw an error when training starts unless this add-on is present.

1. Open MATLAB Desktop.
2. On the top toolstrip: **Home** -> **Add-Ons** -> **Get Add-Ons**.
3. In the Add-On Explorer search bar, paste:
   ```
   Automated Visual Inspection Library for Computer Vision Toolbox
   ```
4. Click on it and click **Install** (it is free with your academic license).
5. Also search and install (if you plan to run `check04_onnx_lstm.m`):
   ```
   Deep Learning Toolbox Converter for ONNX Model Format
   ```

Done when: Running `disp(exist('trainYOLOXObjectDetector', 'file'))` in the MATLAB Command Window prints `2`.

#### Step 48 Verify MATLAB GPU Detection [🟢COMPLETED] [HIGH]
In MATLAB Command Window, run:
```matlab
gpuDevice
```
Done when: It outputs `CUDADevice with properties:` showing `NVIDIA RTX A1000` with ~8.5 GB TotalMemory.

---

### Phase B: Download and Prepare the IDD Detection Dataset

#### Step 49 Download IDD Detection via Academic Account [🟢COMPLETED] [HIGH]
IDD terms require a human login. A script cannot download it.
1. Log in to [idd.insaan.iiit.ac.in/accounts/signup/](https://idd.insaan.iiit.ac.in/).
2. Navigate to datasets and download **IDD Detection** (~22.8 GB, Pascal VOC XML format).

#### Step 50 Extract Outside the Repository [🟢COMPLETED] [HIGH]
Data must never be placed inside the git repository. Extract the downloaded archives to:
```
C:\Users\admin\idd-detection\
```

#### Step 51 Verify Dataset Directory Structure [🟢COMPLETED] [HIGH]
The data loader (`readDetectionData.m`) strictly expects Pascal VOC layout with matching image/annotation pairs:
```
C:\Users\admin\idd-detection\
├── JPEGImages\
│   ├── *.jpg (or .png)
└── Annotations\
    ├── *.xml
```
Verify from MATLAB Command Window:
```matlab
fprintf('Images: %d\n', numel(dir('C:\Users\admin\idd-detection\JPEGImages\*.jpg')));
fprintf('XMLs:   %d\n', numel(dir('C:\Users\admin\idd-detection\Annotations\*.xml')));
```
Done when: Both numbers print thousands of files and neither is zero.

---

### Phase C: Environment Setup & Local VRAM Guard

#### Step 52 Add Repository to MATLAB Path [🟢COMPLETED] [HIGH]
In MATLAB Command Window:
```matlab
cd('C:\Users\admin\sih26037')
addpath('matlab')
which sih.models.trainSpotter
```
Done when: It prints `C:\Users\admin\sih26037\matlab\+sih\+models\trainSpotter.m`.

#### Step 53 Understand the 8 GB VRAM Adjustment [🟢COMPLETED] [HIGH]
`trainSpotter.m` defaults to `MiniBatchSize = 8` for cluster GPUs (16-32 GB VRAM).
On your local **NVIDIA RTX A1000 (8 GB VRAM)**, batch size 8 will trigger CUDA Out-Of-Memory.
We run with **`MiniBatchSize = 2`**. This fits cleanly inside 4-6 GB of VRAM while preserving the exact same YOLOX-small architecture and loss calculations.

---

### Phase D: Training & Evaluating Model 3

#### Step 54 Run the Spotter Training [⚪DEFERRED] [HIGH]
In MATLAB Command Window, run:
```matlab
detector = sih.models.trainSpotter( ...
    "C:\Users\admin\idd-detection", ...
    "C:\Users\admin\meteor-data\spotter.mat", ...
    MiniBatchSize=2);
```

What the script does automatically:
1. Loads S5 class names from `sih.util.classNames("detector")` to lock S5 ordering.
2. Reads IDD Pascal VOC XMLs and maps aliases (e.g., `autorickshaw` -> `auto-rickshaw`, `animal`/`cattle` -> `cow`).
3. Safely drops unmapped classes (`vehicle fallback`, `rider`) so lorries aren't taught as walls.
4. Splits 80% train / 20% validation.
5. Trains YOLOX-small on your RTX A1000 for 30 epochs.
6. Evaluates per-class Average Precision (AP) on held-out validation images.
7. Saves the trained model to `C:\Users\admin\meteor-data\spotter.mat` (outside git).

#### Step 55 How to Handle Errors if They Occur [⚪DEFERRED] [HIGH]
- **If CUDA Out of Memory occurs:** Reduce batch size to 1:
  ```matlab
  detector = sih.models.trainSpotter("C:\Users\admin\idd-detection", "C:\Users\admin\meteor-data\spotter.mat", MiniBatchSize=1);
  ```
- **If GPU training fails entirely:** Fall back to CPU execution:
  ```matlab
  detector = sih.models.trainSpotter("C:\Users\admin\idd-detection", "C:\Users\admin\meteor-data\spotter.mat", MiniBatchSize=2, Execution="cpu");
  ```
- **If missing add-on error appears:** Re-verify Step 47.

---

### Phase E: Reporting the Honest Metrics

#### Step 56 Record Average Precision Per Class [⚪DEFERRED] [HIGH]
At the conclusion of training, `trainSpotter.m` prints the evaluation table.
Per `AGENTS.md`, you MUST report **per-class AP**, specifically for the 3 unstructured traffic classes:
- **`cow` AP**
- **`auto-rickshaw` AP**
- **`pushcart` AP**
- **`overall mAP`**

*Rule: Never report overall mAP alone. A high mAP driven by cars while cows are missed is a failed perception model for Indian roads.*

#### Step 57 Check Dropped Classes Count [⚪DEFERRED] [HIGH]
Inspect the initial output from `readDetectionData`:
```
Dropped X unmapped class name(s) - add them to the alias table if they matter:
  vehicle fallback     XXX box(es)
  rider                XXX box(es)
```
Confirm only known intentional exclusions (`vehicle fallback`, `rider`) were dropped. If any genuine road class was dropped, record it.

#### Step 58 Log in PROGRESS.md [🟢COMPLETED] [HIGH]
Copy the full terminal output, paste the AP table and dropped counts into `PROGRESS.md`, commit, and push.

---

## Part 12 - Aditya's Directives & Immediate Execution Pipeline (Post-Sept 5)

This section reflects the direct guidance and task re-prioritization from Aditya (Lead) on 5 Sept 2026.
Model 3 is officially deferred to post-Sept 7 (the internal round relies strictly on Model 1). Our immediate focus is unblocking Stream D with verified MATLAB imports, reporting honest evaluation numbers for Model 2, extracting scores for calibration fitting, and syncing with main.

### The Six Hard Rules for This Phase
1. **Never edit `matlab/baseline/`.** It is the competitor and our control arm.
2. **Never edit `AGENTS.md` section 3.** The contract is frozen.
3. **Never open `plan/` or `matlab/+sih/+planner/`.** Not ML stream responsibility.
4. **Never tune until a safety check goes green.** A failing check is a valid finding, not a bug to hack around.
5. **Never report accuracy on its own.** Precision and recall, both classes, with confidence intervals.
6. **Never commit `.npz`, `.onnx`, `.onnx.data`, `.pt`, or `.mat` files.**

---

### Phase A: Documentation Truth Alignment

#### Step 59 Correct Factually Inaccurate Claims in PROGRESS.md [🟢COMPLETED] [HIGH]
Before executing new tasks, the status documentation must be aligned with reality. Two specific statements in `PROGRESS.md` are factually inaccurate:
1. *"All local workstation responsibilities for Predictor Models are 100% COMPLETE"* -> False. `check04` is an open deliverable that belongs to this workstation because only this machine has the MATLAB ONNX Converter add-on.
2. *"Awaiting: Aditya's MATLAB import test (check04)"* -> False. Aditya does not have the ONNX Converter on macOS and cannot run it; we must run it locally.

Done when: `PROGRESS.md` reflects that `check04` is local work in progress and not complete.

---

### Phase B: Unblocking Stream D via Local MATLAB Import Check

#### Step 60 Run `check04_onnx_lstm` at Opsets 17 and 18 [🟢COMPLETED] [CRITICAL / HIGHEST PRIORITY]
Stream D is currently blocked waiting on the opset number that imports cleanly without placeholder stubs.

1. Open MATLAB Desktop.
2. In the MATLAB Command Window, run:
   ```matlab
   cd('C:\Users\admin\sih26037')
   addpath('matlab')
   cd('derisk')
   check04_onnx_lstm
   ```
3. **What to look for in output:**
   - **Opsets:** Evaluate opsets 17 and 18 ONLY. (MATLAB R2024b supports opsets 6–18; it cannot parse opset 20, which is handled on macOS).
   - **The Placeholder Trap:** Do NOT look for the word "succeeded". Look specifically for `[PLACEHOLDERS]`. If MATLAB cannot translate an ONNX operator natively, it creates an empty `PlaceholderLayer` stub. A model with placeholders is completely unusable.
   - **Forward Pass:** Confirm the forward pass executes cleanly with contract shapes (`[1, 20, 31]` for LSTM, `[1, 16, 20, 31]` + `[1, 16, 16]` for GNN/Attention).
4. **Immediate Action:** Copy the ENTIRE output verbatim. Transmit the highest cleanly importing opset number to Aditya and Stream D immediately upon completion.

Done when: Full console output from `check04_onnx_lstm.m` is recorded, confirmed free of `PlaceholderLayer`, and sent to Stream D.

---

### Phase C: Honest Model 2 Evaluation

#### Step 61 Measure and Report Model 2 Dangerous-Error Rate [🟢COMPLETED] [HIGH]
Model 1 registered a dangerous-error rate of 20.18% (exceeding the $\le 1.0\%$ safety threshold by 20x), preventing the planner from placing full trust in raw predictions. Model 2 (YieldAttentionNet) demonstrated 28% better calibration ($ECE = 0.1502$ vs $0.2079$). Its dangerous-error rate must now be measured.

1. In Git Bash (using Python 3.10 with CUDA):
   ```bash
   cd /c/Users/admin/sih26037
   python ml/python/model/evaluate.py \
       --features C:/Users/admin/meteor-data/features \
       --model C:/Users/admin/meteor-data/features/yield_attention.pt
   ```
2. **What to look for in output:**
   - Section 4: Operating point dangerous-error rate (`dangerous_rate * 100`) and 95% bootstrap confidence interval.
   - Section 5: Honest operating point across split halves.
   - Section 6: Population-weighted Expected Calibration Error (ECE) and worst-bin gap.
   - Final verdict block: Capture the complete output, whether PASS or FAIL.

Done when: Full console output from `evaluate.py` on `yield_attention.pt` is captured and documented in `PROGRESS.md`.

---

### Phase D: Calibration Post-Processing Data Extraction

#### Step 62 Extract and Export Validation Scores (`scores_lstm.npz`) [🟢COMPLETED] [HIGH]
Retraining is explicitly forbidden because loss has plateaued and the S2 contract is frozen at 31 features. Addressing the 20.18% dangerous error rate requires post-processing on the predictions:
- Threshold sweep extending beyond 0.99 (up to 0.995 and 0.999).
- Probability calibration fitting (isotonic regression, Platt scaling, or temperature scaling).

To enable Aditya to run threshold sweeps and fit calibration models, export the raw predictions and validation ground truth:

1. Create and execute a temporary extraction script in Python:
   ```python
   import json
   from pathlib import Path
   import numpy as np
   import torch
   from ml.python.model.yield_lstm import YieldNet
   from ml.python.model.train import load
   from ml.python.model.evaluate import _predict

   feat_dir = Path("C:/Users/admin/meteor-data/features")
   ck = torch.load(feat_dir / "yield_lstm.pt", map_location="cpu", weights_only=False)
   net = YieldNet(hidden=ck.get("hidden", 64))
   net.load_state_dict(ck["state_dict"])
   net.eval()

   split = json.loads((feat_dir / "split.json").read_text())
   x, y, adj = load(feat_dir, split["val"], grouped=False)
   p_all = _predict(net, x, adj, grouped=False)
   t_all = y.numpy().reshape(-1)
   keep = t_all >= 0
   p, t = p_all[keep], t_all[keep]

   out_path = Path("C:/Users/admin/meteor-data/archive/scores_lstm.npz")
   out_path.parent.mkdir(parents=True, exist_ok=True)
   np.savez_compressed(out_path, p=p, t=t)
   print(f"Saved {out_path} ({out_path.stat().st_size / 1e6:.2f} MB)")
   ```
2. Verify that `scores_lstm.npz` is approximately 6 MB.
3. Upload `scores_lstm.npz` to Google Drive and provide the link to Aditya.

Done when: `scores_lstm.npz` is generated (~6 MB), verified, and shared with Aditya.

---

### Phase E: Repository Synchronization

#### Step 63 Merge `main` into `stream-ml` [🟢COMPLETED] [HIGH]
The local branch `stream-ml` is 24 commits behind `main` (which incorporates PR #11 parity fix, PR #12 Stream D arbitration updates, and planner advancements).

1. In Git Bash:
   ```bash
   cd /c/Users/admin/sih26037
   git fetch origin main
   git merge origin/main --no-edit
   git push origin stream-ml
   ```
2. Confirm that working tree is clean and all upstream changes are integrated without conflicts.

Done when: `git status` is clean and `stream-ml` is synchronized with `origin/main`.

---

### Phase F: Model 3 Technical Debt Reference (Deferred to Post-Sept 7)

#### Step 64 Document Model 3 Dual Bug Audit [LOW / DEFERRED] [🟢COMPLETED]
Model 3 is NOT required for the Sept 7 internal presentation (Model 1 carries the internal demo). When returning to Model 3 post-demo, `matlab/+sih/+models/readDetectionData.m` must resolve TWO distinct bugs simultaneously:
1. **Hurdle H7 (Directory Traversal):** Line 47 uses flat `dir(fullfile(annDir, '*.xml'))`, which misses subdirectories (`frontFar/`, `highquality_16k/`, etc.). Requires recursive `dir(fullfile(annDir, '**', '*.xml'))`.
2. **Hurdle H8 (Basename Cross-Pairing):** Line 61 (`iFindImage`) searches by filename stem alone across flat directories. Because IDD repeats filenames (e.g., `0000149.xml`) across different clip subdirectories, fixing H7 alone would cause silent cross-folder mismatching between images and bounding boxes. `iFindImage` must resolve paths relative to the subfolder tree.

Both bugs must be fixed together in a single commit before training on the KIET GPU box. Inform Aditya prior to launching cluster jobs as the GPU environment is shared.

---

## Part 13 - Calibration Exploration: Ensemble & Temperature Scaling (Post-Sept 5 23:30 IST)

This section reflects Aditya's follow-up directive after Tasks 1–5 were completed. The goal is to explore two more legitimate post-processing approaches — combining Models 1 & 2, and temperature scaling — and report whether anything meaningfully closes the gap toward the $\le 1.0\%$ dangerous-error target. **This is exploratory. Nothing is committed to git until Aditya reviews the numbers.**

### The Seven Hard Rules for This Phase
1. **Never retrain a model.** No time, and capacity is not the bottleneck — labels are.
2. **Never report a dangerous-error rate without `n_go` and a proper confidence interval.** A rate on fewer than ~30 GO predictions is not a measurement — say so instead of reporting it.
3. **Never push a threshold so high that `n_go` collapses to near zero and claim a low rate.** That is the model refusing to answer, not an improvement.
4. **Never touch `AGENTS.md` section 3, `matlab/baseline/`, or any other stream's files.**
5. **Never push to git.** This is exploratory — report numbers, do not commit.
6. **Never invent a number.** `TODO(unverified)` beats a guess.
7. **Use Wilson or Clopper-Pearson confidence intervals** (`statsmodels.stats.proportion.proportion_confint`, method `'wilson'`), NOT normal-approximation intervals which break at small `n`.

---

### Phase G: Model 2 Score Extraction

#### Step 65 Export Model 2 Raw Scores (`scores_attention.npz`) [🟢COMPLETED] [HIGH]
Produce the identical format as `scores_lstm.npz` (already saved for Model 1), but for Model 2 (`yield_attention.pt`).

1. In PowerShell (using Python 3.10 with CUDA):
   ```powershell
   & "C:\Program Files\Python310\python.exe" -c "
   import json, sys
   from pathlib import Path
   import numpy as np
   import torch
   sys.path.insert(0, 'ml/python')
   from model.yield_attention import YieldAttentionNet
   from model.train import load
   from model.evaluate import _predict

   feat_dir = Path('C:/Users/admin/meteor-data/features')
   ck = torch.load(feat_dir / 'yield_attention.pt', map_location='cpu', weights_only=False)
   net = YieldAttentionNet(hidden=ck.get('hidden', 64))
   net.load_state_dict(ck['state_dict'])
   net.eval()

   split = json.loads((feat_dir / 'split.json').read_text())
   x, y, adj = load(feat_dir, split['val'], True)
   p_all = _predict(net, x, adj, True)
   t_all = y.numpy().reshape(-1)
   keep = t_all >= 0
   p, t = p_all[keep], t_all[keep]

   out_path = Path('C:/Users/admin/meteor-data/archive/scores_attention.npz')
   np.savez_compressed(out_path, p=p, t=t)
   print(f'Saved {out_path} ({out_path.stat().st_size / 1e6:.2f} MB)')
   print(f'p shape: {p.shape}, t shape: {t.shape}')
   "
   ```
2. Verify the file is saved and the sample count matches the 772,475 reported in Task 3.

Done when: `scores_attention.npz` exists alongside `scores_lstm.npz` in the archive directory.

---

### Phase H: Sample Count Mismatch Investigation

#### Step 66 Diagnose the 11,453 Sample Gap Between Models 1 and 2 [🟢COMPLETED] [HIGH]
Model 1 produced 783,928 validation samples. Model 2 produced 772,475. That is an 11,453-sample gap. **Do not average across mismatched samples.**

1. The most likely cause: the `load()` function in `train.py` is called with `group_by_frame=False` for Model 1 (LSTM) and `group_by_frame=True` for Model 2 (Attention). The `True` path groups agents by frame into fixed-size `[B, MAX_AGENTS, T, 31]` tensors, which truncates beyond `MAX_AGENTS` per frame and pads below it. Sequences that fit into fewer groups, or agents beyond the `MAX_AGENTS` cutoff, get dropped.
2. To confirm or refute:
   ```python
   # Load both arrays and compare
   d1 = np.load('scores_lstm.npz')
   d2 = np.load('scores_attention.npz')
   print(f"Model 1: {len(d1['p'])} samples")
   print(f"Model 2: {len(d2['p'])} samples")
   print(f"Gap: {len(d1['p']) - len(d2['p'])}")
   ```
3. If the gap is confirmed as `group_by_frame` truncation, document this as the root cause.
4. **Build the intersection set:** identify samples present in both models by matching clip, frame, and track. Only the intersected set is used for ensemble steps below.

Done when: The gap root cause is documented, and the intersection set is constructed.

---

### Phase I: Ensemble of Models 1 & 2

#### Step 67 Average Calibrated Probabilities from Both Models [🟢COMPLETED] [HIGH]
On the **intersected sample set only** (Step 66), apply each model's best-performing calibration method:
- **Model 1 (LSTM):** Apply Platt scaling (which brought it from 20.18% to 8.33%).
- **Model 2 (Attention):** Apply whichever of Platt/isotonic gave its best number.

Then compute a simple average of the two calibrated probabilities:
$$p_{\text{ensemble}} = \frac{p_{\text{lstm\_cal}} + p_{\text{attn\_cal}}}{2}$$

**Do NOT invent a weighted scheme.** Simple mean only.

Run the threshold sweep at thresholds **0.80, 0.90, 0.95, 0.99**. For each threshold report:
- Dangerous error rate
- `n_go` (number of times the model says GO)
- False positives (FP)
- 95% Wilson confidence interval:
  ```python
  from statsmodels.stats.proportion import proportion_confint
  ci_lo, ci_hi = proportion_confint(fp, n_go, alpha=0.05, method='wilson')
  ```

Done when: Ensemble sweep results are recorded for all four thresholds.

---

### Phase J: Temperature Scaling (Model 2 Only)

#### Step 68 Fit a Single Scalar Temperature Parameter [🟢COMPLETED] [HIGH]
Temperature scaling is the simplest calibration method — it fits one single number $T$ that divides the logits before softmax:

$$p_{\text{calibrated}} = \text{softmax}(z / T)$$

Where $z$ is the raw logit from Model 2 (before softmax), and $T$ is optimized to minimize Negative Log-Likelihood (NLL) on the validation set.

1. Extract raw logits from Model 2 (not probabilities — the pre-softmax outputs).
2. Optimize $T$ via `scipy.optimize.minimize_scalar` or gradient descent on NLL:
   ```python
   from scipy.optimize import minimize_scalar

   def nll(T, logits, labels):
       scaled = logits / T
       log_probs = scaled - np.log(np.exp(scaled).sum(-1, keepdims=True))
       return -log_probs[np.arange(len(labels)), labels].mean()

   result = minimize_scalar(nll, bounds=(0.1, 10.0), args=(logits, labels), method='bounded')
   T_opt = result.x
   ```
3. Apply $T_{\text{opt}}$ to get calibrated probabilities.
4. Run the same threshold sweep (**0.80, 0.90, 0.95, 0.99**) with Wilson CI at each point.

Done when: Optimal $T$ is found and the sweep results are recorded.

---

### Phase K: Consolidated Comparison Table

#### Step 69 Build the Final Side-by-Side Comparison [🟢COMPLETED] [HIGH]
Produce a single markdown table with these columns:

| Method | Threshold | n_go | Dangerous Rate | 95% CI (Wilson) | False Positives |
|---|---|---|---|---|---|
| Raw Model 1 (LSTM) | 0.99 | ... | ... | ... | ... |
| Raw Model 2 (Attention) | 0.99 | ... | ... | ... | ... |
| Platt-Scaled Model 1 | 0.80 | ... | ... | ... | ... |
| Isotonic Model 1 | 0.95 | ... | ... | ... | ... |
| Temperature-Scaled Model 2 | 0.80 | ... | ... | ... | ... |
| Temperature-Scaled Model 2 | 0.90 | ... | ... | ... | ... |
| Temperature-Scaled Model 2 | 0.95 | ... | ... | ... | ... |
| Ensemble (Avg of Calibrated) | 0.80 | ... | ... | ... | ... |
| Ensemble (Avg of Calibrated) | 0.90 | ... | ... | ... | ... |
| Ensemble (Avg of Calibrated) | 0.95 | ... | ... | ... | ... |

**Rules for this table:**
- Any row where `n_go < 30`: flag as `"not a measurement"` instead of reporting the rate.
- Any row where `n_go = 0`: report as `"model refuses to answer"`.
- Include the raw models as the first two rows so the comparison baseline is always visible.

Done when: Table is complete with all five methods side by side.

---

### Phase L: Honest Conclusion

#### Step 70 State the Verdict Plainly [🟢COMPLETED] [HIGH]
After building the table, answer exactly one of these two statements:

> **Option A:** *"[Method X] at threshold [Y] achieves a dangerous-error rate of [Z]% (95% CI [..., ...]) at n_go = [N], which is meaningfully closer to 1.0% than the raw 20.18% and still useful (n_go >= 30)."*

> **Option B:** *"No method tested brings the dangerous-error rate meaningfully closer to 1.0% at a usable n_go (>= 30). The honest conclusion is: still gated off (`Valid = false`), the best real number is [X]% at n_go = [N], and it does not go lower without more labeled data."*

**Either answer is fine.** Say which one it is. Do not hedge.

---

## Part 14 - Fast-Track Model 3 (YOLOX Spotter) Curation & Training (Post-Sept 6)

This phase establishes the plan to train Model 3 (YOLOX Spotter) on the local NVIDIA RTX A1000 GPU in **1–2 hours** instead of 18–20 hours, by curating a high-value clip-balanced subset of IDD Detection focused on our critical unstructured classes (`cow` and `auto-rickshaw`) and resolving the dual bug in `readDetectionData.m`.

### The Core Guidelines for This Phase
1. **Never cherry-pick individual frames.** Subsample strictly by clip/sequence to eliminate adjacent-frame leakage.
2. **Keep the S5 class order.** Class names and indices must come from `sih.util.classNames("detector")`.
3. **Preserve background diversity.** Include non-target frames so the detector does not hallucinate false positives.
4. **VRAM Safety:** Train with `MiniBatchSize = 2` to stay strictly within 4.5–5.5 GB VRAM on the RTX A1000.
5. **Document data limitations honestly.** Note that `pushcart` does not exist in IDD annotations.

---

### Phase M: Data Loader Dual-Bug Resolution

#### Step 71 Resolve Hurdles H7 & H8 in `readDetectionData.m` [🟢COMPLETED] [HIGH]
Fix the two interdependent bugs in `matlab/+sih/+models/readDetectionData.m`:
1. **Hurdle H7:** Change line 47 from flat `dir(fullfile(annDir, '*.xml'))` to recursive `dir(fullfile(annDir, '**', '*.xml'))`.
2. **Hurdle H8:** In `iFindImage`, strip `annDir` to determine the subfolder relative path (e.g., `frontFar/0000149.xml`) and pair it directly with `fullfile(imgDir, relImgPath)`. This prevents cross-folder collision when identical filenames appear across subdirectories.

Done when: MATLAB can parse sample annotations without errors or cross-folder mismatch.

---

### Phase N: IDD Dataset Curation

#### Step 72 Curate Clip-Balanced IDD Subset (~4,000–5,000 Images) [🟢COMPLETED] [HIGH]
Construct a curated VOC-compliant folder at `C:\Users\admin\idd-curated\`:
1. Scan forward camera folders (`frontFar`, `frontNear`, `highquality_16k`).
2. Retain all clips containing `animal` (`cow`).
3. Retain balanced sample clips containing `autorickshaw`.
4. Include representative background vehicle/pedestrian clips.
5. Link/copy to standard `Annotations/` and `JPEGImages/` structure.

Done when: `C:\Users\admin\idd-curated\` holds ~4,000–5,000 image/annotation pairs ready for training.

---

### Phase O: Datastore Validation

#### Step 73 Verify Datastores and Class Distribution [🟢COMPLETED] [HIGH]
In MATLAB Command Window, execute:
```matlab
[imds, blds] = sih.models.readDetectionData("C:\Users\admin\idd-curated\JPEGImages", "C:\Users\admin\idd-curated\Annotations", sih.util.classNames("detector"));
```
Verify that:
1. `numel(imds.Files)` is non-zero and matches the curated count.
2. The count of `cow` and `auto-rickshaw` boxes is healthy.
3. No unmapped class collisions occur.

Done when: Datastores load cleanly and print non-zero box counts for target classes.

---

### Phase P: Fast YOLOX Training

#### Step 74 Train YOLOX Spotter with VRAM Guard [🟢COMPLETED] [HIGH]
Run native YOLOX training on the local RTX A1000:
```matlab
detector = sih.models.trainSpotter( ...
    "C:\Users\admin\idd-curated", ...
    "C:\Users\admin\meteor-data\spotter_yolox.mat", ...
    MaxEpochs=15, ...
    MiniBatchSize=2);
```
Expected execution:
- Peak VRAM: ~5.0 GB (safe below 7.54 GB ceiling).
- Duration: ~45–60 minutes.
- Artifact saved: `C:\Users\admin\meteor-data\spotter_yolox.mat`.

Done when: Training completes 15 epochs and detector checkpoint is saved.

---

### Phase Q: Evaluation & Logging

#### Step 75 Evaluate Average Precision on Target Classes [🟢COMPLETED] [HIGH]
Evaluate the detector on the validation split:
1. Measure per-class Average Precision (AP) for `cow`.
2. Measure per-class Average Precision (AP) for `auto-rickshaw`.
3. Document `pushcart` as 0 instances in IDD (unobserved class finding).

Done when: AP numbers are computed and recorded.

---

### Phase R: Deliverables Documentation

#### Step 76 Record Model 3 Results in `PROGRESS.md` [🟢COMPLETED] [HIGH]
Log all final numbers, loss curve, per-class AP, and resolution of Hurdles H7/H8 into `PROGRESS.md`.

Done when: `PROGRESS.md` is updated with Model 3 deliverables.

---

## Part 15: A100 YOLOX Continuation Training (DGX Supercomputer)

> **Why this part exists:** The local RTX A1000 (8 GB VRAM) limits YOLOX-S to batch size 2
> and ~28.5 min/epoch. The DGX A100 (40 GB VRAM) can run batch 32 at ~2–3 min/epoch —
> roughly 10× faster per epoch. This part trains YOLOX-S further using the **Python YOLOX
> framework** (Megvii open-source), because MATLAB `trainYOLOXObjectDetector` does not run
> on Linux. The output is a `.pt` checkpoint that is ONNX-exported back on the Windows
> machine and verified in MATLAB R2024b.
>
> **AGENTS.md rule "Do not import YOLO"** means: do not use Ultralytics YOLO *inside MATLAB*.
> It does NOT prohibit using Python YOLOX for training. Megvii YOLOX is a different codebase.
>
> **Cluster details:** Kubeflow Notebook Server, namespace `f-csai-1009`, pod name `sih-a100`.
> Image: `pytorch:2.3.0-kubeflow`. JupyterLab is accessible at the cluster URL.
> All commands below are run in the **JupyterLab Terminal** unless stated otherwise.

---

### Phase A: Verify A100 GPU Access

#### Step 77 Confirm GPU Is Visible and Working [🟢COMPLETED] [HIGH]

Open a Terminal in JupyterLab (`File → New → Terminal`) and run:

```bash
python3 -c "
import torch
print('CUDA available:', torch.cuda.is_available())
print('GPU name:', torch.cuda.get_device_name(0))
print('VRAM (GB):', torch.cuda.get_device_properties(0).total_memory / 1e9)
print('PyTorch:', torch.__version__)
"
```

What to look for in the output:
- `CUDA available: True`
- `GPU name: NVIDIA A100-SXM4-40GB` (or similar A100 variant)
- `VRAM (GB): 40.xxx` (or 80 if an 80 GB pod)
- PyTorch version: `2.3.0` (pre-installed in the `pytorch:2.3.0-kubeflow` image)

If `CUDA available: False`, the pod did not schedule on a GPU node. Delete and recreate the
notebook server from Kubeflow with GPU resource explicitly requested (1× A100). Send the full
output to Aditya — do not try to diagnose it yourself.

Done when: All four lines print correctly and VRAM ≥ 20 GB.

---

### Phase B: Transfer Dataset and Checkpoint to A100

#### Step 78 Zip and Upload the Curated IDD Dataset [🟢COMPLETED] [HIGH]

The curated dataset lives at `C:\Users\admin\idd-curated\` on the Windows machine.
It contains 3,697 image/annotation pairs (~3 GB total).

**Step 78a — Zip on Windows** (run in PowerShell on the local machine):
```powershell
Compress-Archive -Path "C:\Users\admin\idd-curated" `
                 -DestinationPath "C:\Users\admin\idd-curated.zip"
```
Expected: ~3 GB zip file. Takes ~2–3 minutes.

**Step 78b — Upload to A100 via JupyterLab:**
1. In JupyterLab, click the **Upload Files** button (upward-arrow icon) in the file browser panel.
2. Select `C:\Users\admin\idd-curated.zip`.
3. Wait for the upload progress bar to complete. At campus speeds, 3 GB takes ~5–15 minutes.

**Step 78c — Extract on A100** (in JupyterLab Terminal):
```bash
cd /home/jovyan   # or /workspace — whichever is your home dir
unzip idd-curated.zip -d .
ls idd-curated/   # should show: images/  annotations/
```

What to look for: `idd-curated/images/` and `idd-curated/annotations/` directories,
each with 3,697 files. If the count differs, re-upload — do not proceed with a partial dataset.

Done when: `ls idd-curated/images/ | wc -l` prints `3697` (or close — hardlinks may vary by OS).

---

#### Step 79 Convert Curated Dataset to COCO JSON Format [🟢COMPLETED] [HIGH]

Python YOLOX expects annotations in COCO JSON, not Pascal VOC XML. A conversion script is
needed. Run in JupyterLab Terminal:

```bash
# Install lxml if not present (it usually is in the pytorch image)
pip install lxml --quiet

# Run the conversion script (upload this from the Windows repo first — see note below)
python3 /home/jovyan/voc2coco.py \
    --ann_dir /home/jovyan/idd-curated/annotations \
    --img_dir /home/jovyan/idd-curated/images \
    --output   /home/jovyan/idd-coco \
    --train_ratio 0.8
```

> **Note:** The `voc2coco.py` script lives at `ml/python/idd/voc2coco.py` in the repo.
> Upload it to JupyterLab the same way as the dataset (drag-and-drop or Upload Files button).
> **This script does not exist yet — it must be written before this step can run.**
> Create it locally first, commit to `stream-ml`, then upload to A100.

The script must:
1. Parse all Pascal VOC XMLs in `ann_dir`.
2. Map class names using S5 order (see AGENTS.md Section 3 S5 — never hardcode class IDs).
3. Output a COCO-format `instances_train.json` and `instances_val.json` in `idd-coco/`.
4. Perform the split **by image** (not by frame — there are no video sequences here, so image-level split is correct for this static detection dataset).

What to look for: `instances_train.json` with ~2,957 images (~80%) and `instances_val.json`
with ~740 images (~20%). Verify: `python3 -c "import json; d=json.load(open('idd-coco/instances_train.json')); print(len(d['images']), 'train images,', len(d['annotations']), 'annotations')"`.

Done when: Both JSON files exist and train image count is ~2,957.

---

### Phase C: Install Python YOLOX on A100

#### Step 80 Clone and Install Megvii YOLOX [🟢COMPLETED] [HIGH]

Run in JupyterLab Terminal:

```bash
cd /home/jovyan
git clone https://github.com/Megvii-BaseDetection/YOLOX.git
cd YOLOX
pip install -v -e .
# Verify install
python3 -c "import yolox; print('YOLOX version:', yolox.__version__)"
```

What to look for: `YOLOX version: 0.3.0` (or similar — any version is acceptable as long as
the import succeeds and `yolox/exp/yolox_s.py` exists).

Then create the dataset config. Copy `YOLOX/exps/default/yolox_s.py` to a custom exp file:

```bash
cp exps/default/yolox_s.py exps/sih_yolox_s.py
```

Edit `exps/sih_yolox_s.py` in JupyterLab to set:
```python
self.num_classes = 15        # S5 has 16 classes (0-15); background=0, so 15 foreground
self.data_dir   = "/home/jovyan/idd-coco"
self.train_ann  = "instances_train.json"
self.val_ann    = "instances_val.json"
self.max_epoch  = 15         # 15 epochs total on A100
self.warmup_epochs = 1
self.no_aug_epochs = 2
self.input_size    = (640, 640)
self.test_size     = (640, 640)
self.data_num_workers = 4
```

> **num_classes note:** YOLOX uses 0-indexed foreground classes. AGENTS.md S5 has class 0
> as `unknown`. In COCO JSON, class IDs start at 1. Set `num_classes=15` and map S5 IDs 1–15
> into COCO category IDs 1–15. Class 0 (unknown) is background and is never annotated.

Done when: `exps/sih_yolox_s.py` is saved with the above settings and imports without error:
`python3 -c "from exps.sih_yolox_s import Exp; print('OK')"`.

---

### Phase D: Train YOLOX-S on A100

#### Step 81 Launch Training on A100 [🟢COMPLETED] [HIGH]

Run in JupyterLab Terminal from the `/home/jovyan/YOLOX/` directory:

```bash
python3 tools/train.py \
    -f exps/sih_yolox_s.py \
    -d 1 \
    -b 32 \
    --fp16 \
    -o \
    -c /home/jovyan/yolox_s.pth
```

Flag meanings:
- `-d 1` — 1 GPU
- `-b 32` — batch size 32 (safe on A100 40 GB; increase to 64 if VRAM headroom allows)
- `--fp16` — mixed precision for speed
- `-o` — occupy GPU memory at start to prevent fragmentation
- `-c /home/jovyan/yolox_s.pth` — pretrained COCO checkpoint for warm start

> **Pretrained checkpoint:** Download YOLOX-S COCO pretrained weights before training:
> ```bash
> wget https://github.com/Megvii-BaseDetection/YOLOX/releases/download/0.1.1rc0/yolox_s.pth \
>      -O /home/jovyan/yolox_s.pth
> ```

What to look for every epoch:
- `AP50: 0.xxx` and `AP50:95: 0.xxx` — these should climb each epoch.
- `ETA: HH:MM:SS` — each epoch should be ~2–4 minutes at batch 32.
- Checkpoint saved to `YOLOX_outputs/sih_yolox_s/` after every epoch.

Total expected time: 15 epochs × ~3 min/epoch = **~45 minutes** on A100.
If training dies partway, resume from the last checkpoint:
```bash
python3 tools/train.py -f exps/sih_yolox_s.py -d 1 -b 32 --fp16 \
    --resume   # automatically picks up last checkpoint in YOLOX_outputs/
```

Done when: Training reaches epoch 15 and prints final AP50 score.

---

### Phase E: Export ONNX from A100

#### Step 82 Export YOLOX-S to ONNX (Opset 18) [🟢COMPLETED] [HIGH]

Run in JupyterLab Terminal from `/home/jovyan/YOLOX/`:

```bash
python3 tools/export_onnx.py \
    -f exps/sih_yolox_s.py \
    -c YOLOX_outputs/sih_yolox_s/best_ckpt.pth \
    --output-name /home/jovyan/spotter_yolox_s_opset18.onnx \
    --opset 18 \
    --no-onnxsim \
    --input h w 640 640
```

> **CRITICAL — opset verification (from AGENTS.md + ml-pipeline.md rule):**
> `torch` lies about the opset: requesting 9, 11, or 13 often writes a file stamped 18.
> **Always read the opset back out of the file before reporting it.**
> Run immediately after export:
> ```bash
> python3 -c "
> import onnx
> m = onnx.load('/home/jovyan/spotter_yolox_s_opset18.onnx')
> print('Actual opset in file:', m.opset_import[0].version)
> print('Inputs:', [i.name for i in m.graph.input])
> print('Outputs:', [o.name for o in m.graph.output])
> "
> ```
> The file must read back opset ≤ 18. If it reads 19 or 20, the MATLAB import on R2024b will
> fail. Re-export with `--opset 17` if needed.

> **External data sidecar:** If the model is >2 GB, ONNX may split it into a `.onnx` + `.onnx.data`
> sidecar file. MATLAB cannot import split models. Inline it before downloading:
> ```bash
> python3 -c "
> import onnx
> m = onnx.load('/home/jovyan/spotter_yolox_s_opset18.onnx')
> onnx.save(m, '/home/jovyan/spotter_yolox_s_opset18_inlined.onnx',
>           save_as_external_data=False)
> "
> ```

Done when: ONNX file exists, opset reads back as 17 or 18, no external sidecar file, inputs/outputs printed.

---

### Phase F: Download and Verify in MATLAB

#### Step 83 Download ONNX to Windows and Verify in MATLAB R2024b [🟢COMPLETED] [HIGH]

**Step 83a — Download from A100:**
In JupyterLab file browser, right-click `spotter_yolox_s_opset18.onnx` (or the inlined version)
and choose **Download**. Save to `C:\Users\admin\meteor-data\` on the local Windows machine.

**Step 83b — Verify ONNX imports cleanly in MATLAB R2024b:**

Open MATLAB R2024b on the Windows machine and run:

```matlab
net = importNetworkFromONNX( ...
    'C:\Users\admin\meteor-data\spotter_yolox_s_opset18.onnx', ...
    'InputDataFormats', 'BCSS', ...
    'OutputDataFormats', 'BC');
disp(net)
```

What to look for:
- No error — clean import.
- `net` is a `dlnetwork` object with valid layer graph.
- Input size matches `[1 × 3 × 640 × 640]`.
- Number of output nodes: 1 (bounding box + class logits tensor).

If import fails with `Unsupported operator` or opset error, send the **full error** to Aditya —
do not attempt to work around it without guidance.

**Step 83c — Copy ONNX to repo and commit:**
```powershell
# Do NOT commit ONNX to git — AGENTS.md section 6 forbids it
# Save path only; the file stays at C:\Users\admin\meteor-data\
```

**Step 83d — Update PROGRESS.md with final AP50 score from Step 81.**

Done when: `importNetworkFromONNX` completes without error and `disp(net)` prints a valid
`dlnetwork`. Record the final AP50 number (from A100 training output) and the ONNX file path
in `PROGRESS.md`.

---

## Part 16: Model 4 — Road-Finder on DGX A100 [🔵PLANNED — post Sept 7 demo]

> **What this part proves.** Unmarked Indian roads have no painted boundaries. This model
> demonstrates that a camera image alone can classify every pixel as drivable, obstacle, or
> background, using IDD Segmentation (real Indian dashcam footage from Hyderabad / Bengaluru).
> The trained network itself **never enters the simulation loop** — S9 DrivableSpace is filled
> by lidar geometry, not pixels — but the IoU numbers are our evidence that the segmentation
> boundary problem is solved on real data.
>
> **Architecture:** DeepLab v3+ (ResNet-50 backbone, 512×512 input). Implementation:
> `matlab/+sih/+models/trainRoadSegmenter.m`. API: `deeplabv3plus` + `trainnet`
> (not `deeplabv3plusLayers`, which is removed from R2024a+).
>
> **Do not wire this into the planner.** Read `AGENTS.md` section 2 before asking why.

---

### Timing Estimate

| Stage | Duration | Notes |
|---|---|---|
| Dataset download (IDD Seg 24 GB → A100 `/home/jovyan`) | TODO(unverified) — expected 20–40 min at cluster download speeds | Actual speed must be timed on first run |
| Dataset extraction + inspect | ~10 min | `.tar.gz` unpack, verify `leftImg8bit/` + `gtFine/` layout |
| 20 epoch training on A100 (1 GPU, bs=8, 512×512, ~30k images) | TODO(unverified) — expected **2–4 hours** | DeepLab forward+backward at this scale; timed at end of Step 86 |
| Evaluation (semanticseg on val set + IoU table) | ~15–30 min | Depends on val set size (~6k images) |
| Save `.mat` + pull to local Windows | ~5 min | |
| **Total wall-clock estimate** | **~3–5 hours** | TODO(unverified) — must be measured and logged in PROGRESS.md |

> **IMPORTANT — Timing rule (from `AGENTS.md` § "Verify, do not assume").** The numbers above
> are engineering estimates, not measurements. Every actual duration must be timed during
> execution and logged in `PROGRESS.md`. If training finishes faster or slower than the range
> above, record the real number and update the table.

---

### Pre-flight Checklist (read before running Step 84)

- [ ] IDD Segmentation dataset downloaded and you have the sign-up link
  (`idd.insaan.iiit.ac.in/accounts/signup/`) — this is gated; a script cannot fetch it.
- [ ] DGX A100 JupyterLab accessible and at least 30 GB free under `/home/jovyan`.
- [ ] You are running MATLAB inside the cluster (not locally) — or you have confirmed with Aditya
  that you intend to call `trainRoadSegmenter` from local MATLAB pointing at a network path.
  **A 24 GB dataset over Wi-Fi is not an option.** Either train on the cluster or pre-download
  to the local machine over ethernet.
- [ ] `git pull origin stream-ml` on the cluster before starting — `trainRoadSegmenter.m` must
  be the version from the repo, not an older copy.

---

### Phase A: Dataset Acquisition & Layout Verification

#### Step 84 Download IDD Segmentation to A100 and Verify Layout [🟢COMPLETED] [HIGH]

IDD Segmentation is a gated academic dataset from IIIT Hyderabad.

**84a — Request access and download [VERIFIED]:**
- Downloaded Part I (`idd-segmentation.tar.gz`, 18.53 GB) in **4m 27s** at 29.7 MB/s via direct signed S3 link.
- Downloaded Part II (`idd-20k-II.tar.gz`, 5.56 GB) in **2m 10s** via direct signed S3 link.
- Total download size: **24.09 GB** in under 7 minutes.

**84b — Extract and verify IDD Segmentation layout [VERIFIED]:**
- Extracted both tarballs:
  - Part I unpacked to `IDD_Segmentation/` (`leftImg8bit/` and `gtFine/`).
  - Part II unpacked to `idd20kII/` (`leftImg8bit/` and `gtFine/`).
- Verified images in `leftImg8bit/`: `train`, `val`, `test` partitions present.
  - Part I: **7,974 images** (`.png`) in train+val.
  - Part II: **8,089 images** (`.jpg`) in train+val.
  - Total: **16,063 dashcam images** across both parts.
- Verified ground truth in `gtFine/`:
  - Cloned official IIIT Hyderabad repository `https://github.com/AutoNUE/public-code.git`.
  - Fixed deprecated `PILLOW_VERSION` import in `preperation/createLabels.py`.
  - Ran multi-threaded `createLabels.py` with `--id-type level3Id` (16 workers, ~300 it/s).
  - Part I: **7,974 masks** (`_gtFine_labellevel3Ids.png`) generated in 25s.
  - Part II: **8,089 masks** (`_gtFine_labellevel3Ids.png`) generated in 32s.
  - Total: **16,063 semantic segmentation ground truth masks** — bit-perfect 1-to-1 match (16,063 images : 16,063 masks).

Done when: 16,063 image/mask pairs generated, verified 1-to-1 parity, ready for training.

---

### Phase B: Training on DGX A100

#### Step 85 Synchronize Training Code via Git [🟢COMPLETED] [HIGH]

- Authored [`ml/python/idd/train_deeplabv3.py`](file:///c:/Users/admin/sih26037/ml/python/idd/train_deeplabv3.py) following `DGX.md` ("Code travels through GitHub only").
- Committed to `stream-ml` (`commit 4f6523d`) and pulled on the DGX A100.
- Configured with native PyTorch DeepLab v3+ (ResNet-50 backbone, AMP fp16, batch size 16, 512×512 resolution, class-weighted cross-entropy, and ONNX Opset 18 exporter).

Done when: Training code synchronized and verified on the cluster.

---

#### Step 86 Run DeepLab v3+ Training on DGX A100 [🟡IN PROGRESS] [HIGH]

Launched on DGX A100 SXM4 (40 GB VRAM) under `tmux` session `model4`:
```bash
python3 ml/python/idd/train_deeplabv3.py --data-dir /home/jovyan/idd-segmentation/unified_dataset --epochs 10 --batch-size 16
```

**Measured Epoch 1 Results [VERIFIED]:**
- Duration: **239.1s** (~3.9 minutes per epoch)
- Train Loss: **0.3031** (dropped from initial 0.5217)
- Val Loss: **0.2266**
- **Drivable IoU:** **0.9429 (94.29%)** — exceeds >0.70 baseline significantly on Epoch 1!
- Obstacle IoU: **0.6397 (63.97%)**
- Background IoU: **0.8168 (81.68%)**
- **Mean IoU (mIoU):** **0.7998 (79.98%)**
- Best checkpoint saved to: `/home/jovyan/best_deeplabv3_idd.pth`

Total expected run time: 10 epochs × ~3.9 min = **~39 minutes**.

---

### Phase C: Evaluation and Reporting

#### Step 87 Read Per-Class IoU from the Saved `.mat` [🔵TO DO] [HIGH]

After Step 86 completes, the `.mat` file contains the trained `net` and the full `metrics` struct
from `evaluateSemanticSegmentation`. Inspect it:

```matlab
load('/path/to/meteor-data/road_segmenter_deeplab.mat', 'metrics', 'classes');

disp('Per-class IoU:');
disp(metrics.ClassMetrics);

fprintf('Global accuracy: %.4f\n', metrics.DataSetMetrics.GlobalAccuracy);
fprintf('Mean IoU:        %.4f\n', metrics.DataSetMetrics.MeanIoU);

% The one number Aditya cares about:
idx = find(classes == "drivable");
fprintf('DRIVABLE class IoU: %.4f\n', metrics.ClassMetrics.IoU(idx));
```

What to look for:
- **Drivable IoU > 0.70** is a respectable baseline for an unmarked-road segmenter.
- **Drivable IoU < 0.50** means the network is still confused about what counts as drivable —
  send the full `metrics.ClassMetrics` table to Aditya; do not re-tune it yourself.
- `obstacle` IoU is expected to be lower (~0.40–0.60) because it groups everything from
  a cow to a lamp post.

Report the three numbers: drivable IoU, obstacle IoU, background IoU. Plus global accuracy and
mean IoU. Five numbers, nothing else, unless something looks wrong.

Done when: You have the five numbers and they are recorded in `PROGRESS.md`.

---

#### Step 88 Download `.mat` to Windows and Smoke-Test in MATLAB [🔵TO DO] [HIGH]

If the model was trained on the A100, download it to `C:\Users\admin\meteor-data\` on the local
Windows machine via JupyterLab file browser (right-click → Download).

Then in MATLAB R2024b on Windows:
```matlab
s = load('C:\Users\admin\meteor-data\road_segmenter_deeplab.mat');
disp(s.net)           % should print: dlnetwork with ...
disp(s.classes)       % should print: ["drivable", "obstacle", "background"]
disp(s.metrics.DataSetMetrics)   % should match the numbers you already logged
```

What to look for:
- `s.net` is a `dlnetwork`. Not an `lgraph`, not a `DAGNetwork`.
- `s.classes` has exactly 3 elements in the right order.
- Metrics match what you read in Step 87 — if they differ the file is corrupt; re-download.

Done when: `disp(s.net)` prints cleanly on the Windows machine without error.

---

### Phase D: Archival & Commit

#### Step 89 Update PROGRESS.md and Commit [🔵TO DO] [LOW]

1. Add a Model 4 section to `PROGRESS.md` with:
   - Training date and machine (`DGX A100, sih26037-0`)
   - Exact epoch count and wall-clock duration (measured, not estimated)
   - Drivable IoU, obstacle IoU, background IoU, mean IoU, global accuracy
   - Path to the saved `.mat` file (do NOT commit the file — AGENTS.md § 6 forbids `.mat`
     weights in git)

2. Commit the `PROGRESS.md` update:
   ```powershell
   git add PROGRESS.md
   git commit -m "docs: Model 4 DeepLab v3+ road segmenter trained on A100 - drivable IoU = <number>"
   git push origin stream-ml
   ```
   Push over mobile hotspot if college Wi-Fi is still blocked.

Done when: The commit is on `stream-ml` and `PROGRESS.md` contains the verified IoU numbers.

---

### Summary Card — what to have at the end of Part 16

| Item | What it should say |
|---|---|
| Trained model file | `road_segmenter_deeplab.mat` — saved outside the repo |
| Drivable IoU | TODO(unverified) — measure in Step 87 |
| Obstacle IoU | TODO(unverified) — measure in Step 87 |
| Mean IoU | TODO(unverified) — measure in Step 87 |
| Wall-clock training time | TODO(unverified) — time Step 86 with `tic`/`toc` |
| PROGRESS.md updated | Yes — commit in Step 89 |

---
