"""Builds the 7 diagram PDFs. Each diagram is defined ONCE as data; the drawing (Mermaid),
the box list and the connection list are all generated from that same data, so they cannot disagree."""
import html, os, subprocess

OUT = os.path.expanduser("~/Desktop/SIH26037-PPT-Pack")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# ---------------------------------------------------------------- helpers
def mm_label(t):
    return t.replace('"', "'").replace("\n", "<br/>")

def flowchart(direction, groups, edges, core=(), dashed=(), classes=None):
    """groups: list of (group_id, group_title, [ (node_id, label), ... ] or nested groups)
    edges: list of (src, dst, label)"""
    lines = [f"flowchart {direction}"]
    def emit(g, ind="  "):
        gid, title, items = g
        lines.append(f'{ind}subgraph {gid}["{mm_label(title)}"]')
        for it in items:
            if len(it) == 3 and isinstance(it[2], list):
                emit(it, ind + "  ")
            else:
                nid, lab = it
                lines.append(f'{ind}  {nid}["{mm_label(lab)}"]')
        lines.append(f"{ind}end")
    for g in groups:
        emit(g)
    for i, (a, b, lab) in enumerate(edges):
        arrow = "-.->" if (a, b) in dashed else "-->"
        lines.append(f'  {a} {arrow}|"{mm_label(lab)}"| {b}' if lab else f"  {a} {arrow} {b}")
    if core:
        lines.append("  classDef core fill:#ffe9a8,stroke:#b8860b,stroke-width:2px")
        lines.append("  class " + ",".join(core) + " core")
    if classes:
        for cname, style, ids in classes:
            lines.append(f"  classDef {cname} {style}")
            lines.append(f"  class {','.join(ids)} {cname}")
    return "\n".join(lines)

def spec(groups, edges):
    names = {}
    out = ["BOXES (grouped exactly as drawn):"]
    def walk(g, depth=0):
        gid, title, items = g
        out.append("  " * depth + f"■ {title.replace(chr(10), ' ')}")
        for it in items:
            if len(it) == 3 and isinstance(it[2], list):
                walk(it, depth + 1)
            else:
                nid, lab = it
                names[nid] = lab.replace("\n", " ")
                out.append("  " * (depth + 1) + f"- [{nid}] {names[nid]}")
    for g in groups:
        walk(g)
    out.append("")
    out.append(f"CONNECTIONS ({len(edges)} arrows, from → to : what flows):")
    for a, b, lab in edges:
        out.append(f"  {names.get(a, a)}  →  {names.get(b, b)}" + (f"   : {lab.replace(chr(10), ' ')}" if lab else ""))
    return "\n".join(out)

def page(fname, title, subtitle, mermaid_code, spec_text, extra_html="", size="A2 landscape"):
    doc = f"""<!doctype html><html><head><meta charset="utf-8"><title>{html.escape(title)}</title>
<style>
@page {{ size: {size}; margin: 12mm; }}
body {{ font-family: Helvetica, Arial, sans-serif; color:#111; }}
h1 {{ font-size: 26px; margin: 0 0 4px; }} .sub {{ color:#444; margin-bottom: 10px; font-size: 14px; }}
.mermaid {{ text-align:center; }}
h2 {{ font-size: 18px; border-bottom: 2px solid #333; margin-top: 18px; page-break-before: always; }}
pre.spec, pre.code {{ font-size: 11.5px; white-space: pre-wrap; background:#f6f6f6; padding:10px; border:1px solid #ccc; }}
table {{ border-collapse: collapse; font-size: 13px; margin: 8px 0; }} td, th {{ border:1px solid #888; padding:4px 7px; vertical-align: top; }}
th {{ background:#eee; }} .note {{ font-size: 12px; color:#333; }}
</style></head><body>
<h1>{html.escape(title)}</h1><div class="sub">{html.escape(subtitle)}</div>
<pre class="mermaid">{html.escape(mermaid_code)}</pre>
{extra_html}
<h2>Exact spec for redrawing (give this page to Gemini / Nano Banana)</h2>
<p class="note">Redraw rule: keep every box, every group and every arrow below. Do not add, merge or drop any. Styling is free; structure is fixed.</p>
<pre class="spec">{html.escape(spec_text)}</pre>
<h2>Mermaid source (paste into mermaid.live to re-render)</h2>
<pre class="code">{html.escape(mermaid_code)}</pre>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
<script>mermaid.initialize({{startOnLoad:true, theme:'default', flowchart:{{useMaxWidth:true, htmlLabels:true, curve:'basis'}}, gantt:{{useMaxWidth:true}}}});</script>
</body></html>"""
    hp = os.path.join(OUT, "_build", fname + ".html")
    open(hp, "w").write(doc)
    pdf = os.path.join(OUT, fname + ".pdf")
    subprocess.run([CHROME, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                    "--virtual-time-budget=30000", f"--print-to-pdf={pdf}", hp],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    print("wrote", pdf)

# ================================================================ D1 FULL SYSTEM
D1_groups = [
 ("L5W", "LAYER 5 · PROVE — World (simulation)", [
   ("W_carla", "CARLA 0.9.15 scenes\n(unmarked village, unsignalled junction)\n— replaces RoadRunner, disclosed"),
   ("W_assets", "Indian 3D actors & props\ncattle · auto · e-rickshaw · tractor-trolley\npushcart · overloaded 2W · stalls · potholes"),
   ("W_sumo", "SUMO reactive traffic\n(official R2026a Simulink Client/Reader/Writer)\ncalibrated with Indian numbers (P16)"),
   ("W_agents", "Learned traffic agents\n(Indian-calibrated, react to our car)"),
   ("W_weather", "Weather & light\nrain · fog · night · glare"),
 ]),
 ("L1", "LAYER 1 · SENSE — Sensors (timestamped, CAN-style bus)", [
   ("S_cam", "Cameras\nfront · rear · left · right"),
   ("S_lidar", "LiDAR\n32 beams · 100 m · 10 Hz"),
   ("S_radar", "Radar\nfront 150 m + 2 corner · 20 Hz"),
   ("S_us", "Ultrasonic ×8\n0.2–5 m"),
   ("S_loc", "GNSS 10 Hz + IMU 100 Hz\n+ wheel speed + steering angle"),
   ("S_mic", "Microphone array\n(siren / horn events)"),
   ("S_dcam", "Driver camera"),
   ("S_env", "Rain & light sensors"),
 ]),
 ("L2", "LAYER 2 · UNDERSTAND — AI perception, hearing, tracking, prediction", [
   ("P", "Perception ML", [
     ("M_det", "Object detector (YOLOX)\nautos · pushcarts · people · cattle · 2W · buses"),
     ("M_road", "Road / edge / pothole mask\n(DeepLab v3+)"),
     ("M_lidar3d", "LiDAR 3D detector"),
     ("M_bev", "Bird's-eye free-space map\n(free / occupied / UNKNOWN)"),
     ("M_sign", "Sign & Indian-text reader\n(Hindi / regional)"),
     ("M_vis", "Visibility estimator\n(how far can we see)"),
   ]),
   ("H", "Hearing", [("M_audio", "Siren / horn recogniser\n+ direction")]),
   ("G", "Gesture reader", [("M_pose", "Pose model (pretrained)"), ("M_gest", "Hand-signal reader\nped stop · police stop/go · rider turn")]),
   ("T", "Tracker", [("T_fuse", "Sensor fusion + tracker\n(trackerGNN, EKF) → TrackList"), ("T_loc", "Localisation\nGNSS + IMU + wheels")]),
   ("PR", "Prediction ML", [
     ("M_pred", "Motion predictor\ntop-K paths, conditioned on OUR move\n(conformal safety margin)"),
     ("M_intent", "Crossing-intent model"),
     ("B_belief", "Cooperation belief\nintent × response (group / cover merge)\nBayes update from what they actually do"),
   ]),
 ]),
 ("L3", "LAYER 3 · DECIDE — Brain + independent safety", [
   ("D_plan", "Planner\nroute + rules → 8–16 candidate moves"),
   ("D_score", "Move scorer (small learned model)\nranks: progress · comfort · options"),
   ("D_rl", "RL policy\n(shadow only, never drives)"),
   ("D_check", "SAFETY CHECKER (no ML)\nswept footprint · stopping distance\nworst-case non-cooperation · uncertainty\n= the ONLY 'go' permission"),
   ("D_mon", "Safety monitor\nstale data · faults · deadline 100 ms\nsafe stop · BLOCKED state · takeover"),
 ]),
 ("L4", "LAYER 4 · ACT — Drive the car, talk to others", [
   ("A_ctrl", "Control\nlateral: Stanley / MPC · speed: PI\n50 Hz"),
   ("A_act", "Actuators\nsteer · throttle · brake · gear P/N/D/R"),
   ("A_veh", "Vehicle model\n3DOF (all runs) · 14DOF (potholes)"),
   ("A_sig", "Signals\nindicators · hazards · beams · brake light · horn"),
   ("A_hmi", "Driver screen + takeover\n+ driver watcher"),
 ]),
 ("L5T", "LAYER 5 · PROVE — Test & learn loop", [
   ("E_log", "Run recorder\nevery message + ground truth"),
   ("E_metrics", "PS metrics\nreplanning latency p50/p95/p99 · path smoothness (jerk, curvature)\nscenario completion rate · contacts · false stalls"),
   ("E_scen", "5 PS scenarios + 10 test families (F1–F10)\n90 Indian road difficulties"),
   ("E_mine", "Failure mining → replay by seed\n→ regression test → frozen holdout"),
   ("E_real", "Real Indian dashcam video replay\n(sim-vs-real accuracy gap)"),
   ("E_base", "Baselines\nMathWorks example · always-yield · rule planner"),
 ]),
]
D1_edges = [
 ("W_carla", "S_cam", "rendered pixels"), ("W_carla", "S_lidar", "ray-cast"), ("W_carla", "S_radar", "detections"),
 ("W_carla", "S_us", "near range"), ("W_carla", "S_loc", "ego motion"), ("W_sumo", "S_mic", "siren/horn events"),
 ("W_weather", "S_env", "rain/light"), ("W_assets", "W_carla", "spawned actors"), ("W_sumo", "W_carla", "actor states mirrored"),
 ("W_agents", "W_sumo", "behaviour"), ("W_weather", "W_carla", "conditions"),
 ("S_cam", "M_det", "front image"), ("S_cam", "M_road", "front image"), ("S_cam", "M_sign", ""), ("S_cam", "M_pose", ""),
 ("S_cam", "M_vis", ""), ("S_env", "M_vis", ""), ("S_lidar", "M_lidar3d", "point cloud"), ("S_lidar", "M_bev", ""),
 ("S_cam", "M_bev", ""), ("S_radar", "T_fuse", "range + speed"), ("S_us", "T_fuse", "near obstacles"),
 ("S_loc", "T_loc", ""), ("S_mic", "M_audio", ""), ("S_dcam", "A_hmi", "driver state"),
 ("M_det", "T_fuse", "2D boxes"), ("M_lidar3d", "T_fuse", "3D boxes"), ("M_road", "M_bev", "road / pothole pixels"),
 ("M_pose", "M_gest", "body keypoints"), ("T_loc", "T_fuse", "ego pose"),
 ("T_fuse", "M_pred", "TrackList 10 Hz"), ("T_fuse", "M_intent", "pedestrian tracks"), ("T_fuse", "B_belief", "observed motion"),
 ("M_intent", "B_belief", "cross?"), ("M_gest", "B_belief", "gesture (caution only)"), ("M_audio", "B_belief", "siren direction"),
 ("B_belief", "M_pred", "who yields / who asserts"),
 ("M_bev", "D_plan", "free space"), ("M_sign", "D_plan", "rules"), ("T_loc", "D_plan", "where we are"),
 ("D_plan", "D_score", "8–16 candidates"), ("M_pred", "D_score", "futures per candidate"), ("B_belief", "D_score", ""),
 ("D_rl", "D_score", "comparison only"), ("D_score", "D_check", "ranked moves"),
 ("M_pred", "D_check", "occupied regions"), ("M_bev", "D_check", "free / unknown space"), ("M_vis", "D_check", "sight distance"),
 ("D_check", "A_ctrl", "PASS: certificate"), ("D_check", "D_mon", "FAIL: no safe move"),
 ("D_mon", "A_ctrl", "veto / safe stop"), ("M_audio", "D_mon", "emergency vehicle"), ("A_hmi", "D_mon", "takeover ack"),
 ("A_ctrl", "A_act", "commands 50 Hz"), ("A_act", "A_veh", ""), ("A_veh", "S_loc", "wheel speed, steering feedback"),
 ("A_veh", "W_carla", "our car moves → world reacts"), ("A_veh", "W_sumo", "ego state (Writer block)"),
 ("D_check", "A_sig", "planned turn"), ("D_mon", "A_sig", "hazards"), ("D_mon", "A_hmi", "mode, fault, takeover request"),
 ("A_sig", "W_sumo", "others see our signals"),
 ("T_fuse", "E_log", ""), ("D_check", "E_log", ""), ("A_veh", "E_log", ""), ("W_carla", "E_log", "ground truth (tests only)"),
 ("E_log", "E_metrics", ""), ("E_log", "E_mine", "near-misses, disagreements"), ("E_mine", "E_scen", "new test cases"),
 ("E_scen", "W_carla", "scenario + seed"), ("E_scen", "W_sumo", "traffic setup"), ("E_real", "M_det", "real frames (open loop)"),
 ("E_base", "E_metrics", "same seeds"),
]
D1_dashed = {("D_rl", "D_score"), ("E_real", "M_det"), ("W_carla", "E_log")}
D1_classes = [("safety", "fill:#ffd6d6,stroke:#b00000,stroke-width:3px", ["D_check", "D_mon"])]

# ================================================================ D2 ONE DECISION
D2_groups = [
 ("T0", "EVERY 100 ms (10 Hz planning tick) — timing budget in brackets", [
   ("s1", "1 · Snapshot all sensors\n(sync + timestamps) [10 ms]"),
   ("s0", "Data fresh?\nego ≤50 ms · camera ≤150 ms · LiDAR/radar ≤200 ms"),
   ("s2", "2 · Perceive\nobjects · road/unknown · signs · gestures · sounds [30 ms]"),
   ("s3", "3 · Track + locate\nTrackList + ego pose [10 ms]"),
   ("s4", "4 · Update belief\nwho is cooperative? (from what they did after OUR last move)"),
   ("s5", "5 · Generate 8–16 short moves\nkeep · slow · creep · nudge left/right · stop · go-around [10 ms]"),
   ("s6", "6 · Predict others FOR EACH move\ntop-K paths + safety margin [15 ms incl. step 4]"),
   ("s7", "7 · Score moves\nprogress · comfort · keeps options"),
   ("s8", "8 · SAFETY CHECK best move first [15 ms]\nfits free space? can we still stop?\nsafe even if nobody yields?"),
   ("s9", "Any move passes?"),
   ("s10", "9 · Issue certificate\n(move ID + path hash + expiry)"),
   ("s11", "10 · Control → steer / throttle / brake / gear\n50 Hz [5 ms] + indicators"),
   ("s12", "SAFE STOP\nbrake within known free space · hazards\nstate = BLOCKED (reason + time logged)"),
   ("s13", "Re-check next tick\ncreep only if a new move passes\ntimeout never means 'go'"),
   ("s14", "Record everything\n(run log → metrics → failure replay)"),
 ]),
]
D2_edges = [
 ("s1", "s0", ""), ("s0", "s2", "yes"), ("s0", "s12", "no: stale / missing"), ("s2", "s3", ""), ("s3", "s4", ""),
 ("s4", "s5", ""), ("s5", "s6", ""), ("s6", "s7", ""), ("s7", "s8", "best first"), ("s8", "s9", ""),
 ("s9", "s10", "yes"), ("s9", "s12", "no"), ("s10", "s11", ""), ("s12", "s13", ""), ("s13", "s1", "next tick"),
 ("s11", "s14", ""), ("s12", "s14", ""), ("s11", "s1", "car moved → world changed → next tick"),
]
D2_classes = [("safety", "fill:#ffd6d6,stroke:#b00000,stroke-width:3px", ["s8", "s12"]), ("go", "fill:#d6f5d6,stroke:#1a7f1a,stroke-width:2px", ["s10", "s11"])]

# ================================================================ D3 AI STACK
D3_groups = [
 ("DATA", "TRAINING DATA (Indian + simulator)", [
   ("d_idd", "IDD · IDD-117K · FGVD · DriveIndia"), ("d_seg", "IDD segmentation · IDD-AW · IDD-X"),
   ("d_3d", "IDD-3D · TIAND"), ("d_ped", "IDD-PeD"), ("d_traj", "SPT Chennai · METEOR · IDD-X tracks"),
   ("d_text", "RoadText (English / Hindi / Telugu)"), ("d_gap", "GAPS: siren audio · driver monitoring\n· Indian police gestures (to collect)"),
   ("d_sim", "Our simulator runs\n(CARLA + SUMO, labelled automatically)"),
 ]),
 ("TRAIN", "TRAIN on KIET DGX A100 (+ cloud A100 backup ~$0.43–1.09/GPU-h) → export ONNX → MATLAB Deep Learning Toolbox", [
   ("SEE", "SEE (6)", [
     ("m1", "1 · Object detector (YOLOX)"), ("m2", "2 · Road / edge / pothole mask (DeepLab v3+)"),
     ("m3", "3 · LiDAR 3D detector"), ("m4", "4 · Bird's-eye free-space map"),
     ("m5", "5 · Hand-signal reader\n(on pretrained pose model)"), ("m6", "6 · Sign & Indian-text reader"),
   ]),
   ("HEAR", "HEAR & CONDITIONS (3)", [("m7", "7 · Siren / horn recogniser"), ("m8", "8 · Visibility estimator"), ("m9", "9 · Driver watcher")]),
   ("PRED", "PREDICT (2)", [("m10", "10 · Motion predictor\n(top-K, ego-conditioned, conformal)"), ("m11", "11 · Crossing-intent model")]),
   ("DEC", "DECIDE (2)", [("m12", "12 · Move scorer"), ("m13", "13 · RL policy (comparison only)")]),
   ("WORLD", "TEST WORLD (1)", [("m14", "14 · Learned traffic agents")]),
 ]),
 ("GATE", "THE RULE", [("gate", "SAFETY CHECKER — physics, NO ML\nno model can move the car on its own;\nonly the checker gives 'go'")]),
]
D3_edges = [
 ("d_idd", "m1", ""), ("d_sim", "m1", "renders"), ("d_seg", "m2", ""), ("d_sim", "m2", ""), ("d_3d", "m3", ""), ("d_3d", "m4", ""),
 ("d_sim", "m4", ""), ("d_ped", "m5", "gestures"), ("d_text", "m6", ""), ("d_gap", "m7", ""), ("d_seg", "m8", "IDD-AW weather"),
 ("d_gap", "m9", ""), ("d_traj", "m10", ""), ("d_sim", "m10", "counterfactual runs"), ("d_ped", "m11", "intent labels"),
 ("d_sim", "m12", "outcomes of moves"), ("d_sim", "m13", ""), ("d_traj", "m14", ""),
 ("m1", "gate", "detections"), ("m2", "gate", "free space"), ("m4", "gate", ""), ("m10", "gate", "occupied regions"),
 ("m12", "gate", "ranked moves (advice only)"), ("m5", "gate", "caution only"), ("m8", "gate", "sight distance"),
]
D3_core = ("m1", "m2", "m5", "m10", "m12")
D3_classes = [("safety", "fill:#ffd6d6,stroke:#b00000,stroke-width:3px", ["gate"]), ("gap", "fill:#eeeeee,stroke:#777,stroke-dasharray: 4 3", ["d_gap"])]

# ================================================================ D4 FIVE SCENARIOS
scen = [
 ("V", "1 · Unmarked village road", "tractor-trolley · bullock cart · cycle · cattle on verge · no edge lines · gravel",
  "IDs 11, 13–15, 38, 43, 49", "F1 village mix + F7 surface + F9 weather", "find safe edge, pass slow vehicle only with sight distance"),
 ("U", "2 · Unsignalled urban intersection", "cross traffic · turning autos · jaywalkers · police/pedestrian hand signals",
  "IDs 16, 20–22, 28, 53–61", "F4 junction + F2/F3", "negotiate gap, no deadlock, no forced entry"),
 ("H", "3 · Highway merge with slow vehicles", "slow truck · tractor on highway · wrong-way vehicle · service-road entry",
  "IDs 5, 6, 11, 52", "F5 highway + F4/F9", "verified gap despite speed difference"),
 ("M", "4 · Dense market", "2W seepage (0.9 m gaps) · auto pickup stops · vendors · crowd · bus hiding a person",
  "IDs 1–4, 9, 10, 25–27, 75, 76", "F2 market + F3 pedestrians + F9", "keep moving safely or declare BLOCKED"),
 ("C", "5 · Sudden cattle crossing", "cow dashes from verge · cow lying on road · herd",
  "IDs 31–34", "F6 animals + F1/F7", "detect, reserve its reachable zone, stop in time"),
]
D4_groups = [("PS", "5 REQUIRED PS SCENARIOS — each run × 10 seeds, pass = ≥9/10 complete + zero contacts", [])]
D4_edges = []
for k, t, actors, ids, fam, crit in scen:
    D4_groups[0][2].append((f"{k}g", t, [
        (f"{k}a", "Actors: " + actors), (f"{k}i", "P1 difficulties: " + ids),
        (f"{k}f", "Test family: " + fam), (f"{k}p", "Must show: " + crit)]))
    D4_edges += [(f"{k}a", f"{k}i", ""), (f"{k}i", f"{k}f", ""), (f"{k}f", f"{k}p", "")]
D4_groups.append(("OV", "APPLIED TO ALL 5", [("ov1", "Weather overlay: rain · fog · night (F9)"), ("ov2", "Fault injection: sensor dropout · delay (F10)"),
                                           ("ov3", "Metrics: replanning latency · path smoothness · completion rate")]))
for k, *_ in scen:
    D4_edges.append(("ov1", f"{k}a", ""))

# ================================================================ D5 BUILD PLAN (gantt)
D5_code = """gantt
title 10-week build plan (from 1 Oct 2026) — A = Aditya (brain, safety, evaluation) · S = Shourya (world, assets, perception)
dateFormat YYYY-MM-DD
axisFormat %d %b
section A · Brain & safety
W1 Fix S2/S3 crash + freeze            :a1, 2026-10-01, 7d
W2 10 Hz planner + safety checker       :a2, after a1, 7d
W3 Compiled code (MEX) + equal decisions :a3, after a2, 7d
W4 Control + gears + driver screen      :a4, after a3, 7d
W5 Motion predictor + belief + scorer   :a5, after a4, 7d
W6 Hand signals → belief (caution only) :a6, after a5, 7d
W7 SUMO reactive traffic + siren yield  :a7, after a6, 7d
W8 All tests + fault modes, DEMO FREEZE :crit, a8, after a7, 7d
W9 Final numbers + baselines            :a9, after a8, 7d
W10 Buffer · report · video             :a10, after a9, 7d
section S · World & perception
W1 CARLA source build + asset audit     :b1, 2026-10-01, 7d
W2 Custom cow + auto spawn in CARLA     :b2, after b1, 7d
W3 Indian asset pipeline + sensor setup :b3, after b2, 7d
W4 Camera → detector in the loop        :b4, after b3, 7d
W5 Render + REAL Indian video accuracy  :b5, after b4, 7d
W6 Village + junction scenes, gestures  :b6, after b5, 7d
W7 SUMO↔CARLA sync + 5 routes           :b7, after b6, 7d
W8 Weather + potholes (14DOF)           :b8, after b7, 7d
W9 Real-vs-sim check + film             :b9, after b8, 7d
W10 Fresh-machine replay + video        :b10, after b9, 7d
section Pass/fail gates
G1 S2 + dense S3 zero contact            :milestone, g1, 2026-10-07, 0d
G2 p99 ≤100 ms AND custom assets spawn   :milestone, g2, 2026-10-14, 0d
G5 Per-class accuracy on real + sim      :milestone, g5, 2026-11-04, 0d
G8 5 scenarios × 10 seeds ≥9/10, 0 contacts :milestone, g8, 2026-11-25, 0d
"""
D5_spec = """ROWS (two parallel tracks, one exit test per week):
Week | A · Aditya: brain, safety, evaluation | S · Shourya: world, assets, perception | Exit test
W1 1–7 Oct   | Fix S2 crash/freeze and dense S3 freeze | CARLA source build (165 GB, UE4.26, VS2019), asset audit | S2 + dense S3: zero contact, no false stall >10 s, 3 seeds each
W2 8–14 Oct  | Remove 88% hotspot; 8–16 moves; safety checker; BLOCKED state | Spawn 1 custom prop (cow) + 1 custom vehicle (auto) | p99 ≤100 ms over 1,000 ticks; 100 unsafe moves all vetoed; assets spawn (else declared stand-ins)
W3 15–21 Oct | Versioned message contract; planner+checker compiled to MEX | Indian asset pipeline; sensor calibration; bridge smoke test | 5-min S1 run in one model; MATLAB = MEX decisions
W4 22–28 Oct | Localisation, Stanley+PI control, gears, driver screen, fault path | Fix YOLOX zero-detections; camera+LiDAR+radar → tracks | 5 min sensor→track→certificate→steering/brake; injected loss → logged stop
W5 29 Oct–4 Nov | Motion predictor, belief, move scorer (yield model stays off) | Label renders; run REAL Indian frames + own dashcam clip | Per-class accuracy on sim AND real + the gap; ML can never bypass checker
W6 5–11 Nov  | Hand-signal → belief/right-of-way (caution only) | Village + junction CARLA scenes; walker raised-hand poses | All stop gestures slow/stop; zero 'go' gestures cause an uncertified move
W7 12–18 Nov | SUMO Client/Reader/Writer, reactive belief, siren yield, yield-rate sweep | Mirror SUMO actors into CARLA; 5 route files; audio events; cattle onset | 1,000 synced ticks; our move changes their move; siren-yield passes; 1 run per scenario
W8 19–25 Nov | Top-25 + 6 communication probes; fault modes; full-loop timing; DEMO FREEZE | F1–F10 mixes; rain/fog/night; 14DOF potholes; replay one mined failure | 5 scenarios × 10 seeds: ≥9/10 complete, 0 contacts; p50/p95/p99 published
W9 26 Nov–2 Dec | Frozen holdout, baselines, PS metrics, confidence intervals | Real-vs-sim recheck; film matched runs | All metrics by scenario; 299-seed bound only if all 299 clean
W10 3–9 Dec  | Fix blockers; report; 8-min script | Fresh-machine replay; final video | One command reproduces every run ID and metric
CUT ORDER if late: asset variety → rear/side cameras + driver watcher → audio detail → 14DOF breadth → auto failure mining → 299-run claim.
NEVER CUT: one Simulink model · 5 scenarios · camera+LiDAR+radar loop · safety checker · safe braking · honest timing · 3 PS metrics."""

# ================================================================ D6 PS COVERAGE
D6_groups = [
 ("PSR", "WHAT THE PS ASKS", [
   ("r1", "Pipeline in MATLAB + Simulink\nperception → prediction → planning → decision → vehicle motion"),
   ("r2", "Multi-sensor: camera · LiDAR · radar"), ("r3", "Identify autos · pushcarts · pedestrians · animals"),
   ("r4", "Predict short-term, non-lane, irregular motion"), ("r5", "Safe, collision-free path, replanned in real time"),
   ("r6", "Missing lane markings · informal merging\nsudden pedestrians · unexpected obstacles"),
   ("r7", "≥5 Indian scenarios (village, junction, highway merge, market, cattle)"),
   ("r8", "2 detailed RoadRunner scenes"), ("r9", "Metrics: replanning latency · path smoothness · completion rate"),
   ("r10", "Model · scenarios · results · report · video · closed-loop validation"),
 ]),
 ("OURS", "HOW WE MEET IT (part of our system)", [
   ("o1", "One Simulink ego stack, 13 parts, fixed message contract"), ("o2", "Cameras ×4 · LiDAR · radar ×3 · ultrasonic · GNSS/IMU"),
   ("o3", "YOLOX + road mask, Indian datasets (IDD, DriveIndia) + renders"), ("o4", "Top-K ego-conditioned predictor + cooperation belief\n+ conservative reachable zones"),
   ("o5", "Independent safety checker + 10 Hz gate + stale-plan brake"), ("o6", "Free-space / unknown map · group/cover merge modes\n· occlusion zones · BLOCKED state"),
   ("o7", "5 CARLA/SUMO scenarios × 10 seeds + F1–F10 families"), ("o8", "DEVIATION (disclosed): 2 detailed CARLA 0.9.15 scenes\n(no RoadRunner licence)"),
   ("o9", "Exact formulas: p50/p95/p99 + deadline misses · jerk + curvature · completion"),
   ("o10", "Run recorder · replay · report · matched-run video · reactive traffic"),
 ]),
 ("BEY", "BEYOND THE PS", [
   ("b1", "Hearing: siren / horn"), ("b2", "Hand-signal reading (caution only)"), ("b3", "Real Indian dashcam video test"),
   ("b4", "Failure mining → regression → frozen holdout"), ("b5", "Sensor-degradation curves (rain/fog/night)"),
   ("b6", "14DOF pothole ride tests"), ("b7", "Compiled planner (MEX) — path to car hardware"),
   ("b8", "Baselines on same seeds + confidence intervals"), ("b9", "Driver screen, takeover, minimal-risk stop"),
 ]),
]
D6_edges = [(f"r{i}", f"o{i}", "") for i in range(1, 11)] + [
 ("o3", "b3", ""), ("o2", "b1", ""), ("o3", "b2", ""), ("o10", "b4", ""), ("o2", "b5", ""), ("o1", "b6", ""),
 ("o5", "b7", ""), ("o9", "b8", ""), ("o5", "b9", "")]
D6_classes = [("dev", "fill:#fff0c2,stroke:#b8860b,stroke-width:2px", ["o8"])]
D6_extra = """<p class="note"><b>Honest status today (27 Sep 2026, 40 PS lines):</b> 1 meets · 22 partial · 15 not yet · 2 deviation (RoadRunner). Every line has a planned week and a test (see build plan). Source: P14-PS-COMPLIANCE.md.</p>"""

# ================================================================ D7 COMPETITORS + COST
D7_code = """pie showData
title Planned effort split — 20 builder-weeks (2 builders × 10 weeks)
"Brain + safety checker (A W1–W3, W6)" : 4
"Control + driver screen (A W4)" : 1
"Prediction + belief + scorer (A W5, W7)" : 2
"Testing, metrics, baselines (A W8–W10)" : 3
"CARLA world + Indian assets (S W1–W3, W6–W7)" : 5
"Perception ML + real-video test (S W4–W5, W9)" : 3
"Weather/potholes + final package (S W8, W10)" : 2
"""
D7_spec = """COMPETITOR TABLE  (✓ = verified public evidence · ✗ = verified absent · ? = not found · (P) = planned by us, not built yet)
Feature                                   | Ours     | The Syndicate (same PS) | ARAI scenario repo | WMG Safety Pool India | Swaayatt Robots | Minus Zero
Indian actors (cattle, autos, pushcarts)  | ✓ (P)    | ✗ stock Western CARLA   | ✓ Indian scenarios | ✓ crowdsourced         | ✓ real roads     | ✓ real roads
Hand-signal reading                       | ✓ (P)    | ?                       | ?                  | ?                      | ?                | ?
Reactive traffic (reacts to our car)      | ✓ (P)    | ?                       | ?                  | ✗ (tool can't model stop/restart) | n/a      | n/a
Independent safety checker (no ML)        | ✓ (P)    | ?                       | n/a (not a planner)| n/a                    | ?                | ? (claims "safety mechanisms")
Published measured results / metrics      | ✓ (P)    | ✗ (no numbers shown)    | ?                  | ?                      | ✗ (no papers)    | ✗ (blog only)
MATLAB/Simulink end-to-end (PS toolchain) | ✓ (P)    | ?                       | ?                  | ✗ (OpenSCENARIO export)| ✗                | ✗
Drives on real public roads               | ✗ (sim)  | ✗                       | test track         | ✗                      | ✓                | ✓ (Bengaluru, safety driver, ≤25 km/h)
Sources: P1 competitor check, P3 (Swaayatt sparse maps, Minus Zero May 2025 demo), idea-phase notes (Syndicate).

CASH COST (what we actually pay)
Item                                   | Cost          | Basis
MATLAB + Simulink + toolboxes (R2026a) | ₹0            | KIET campus licence
CARLA 0.9.15 · SUMO                    | ₹0            | open source
Indian datasets (IDD family, METEOR…)  | ₹0            | academic use; some need sign-up / agreement
Training compute                       | ₹0            | KIET DGX A100
Backup cloud A100 (if DGX busy)        | ~$0.43–1.09 per GPU-hour → 200 h ≈ $86–218 | getdeploying.com/gpus/nvidia-a100, thundercompute.com (Sep 2026)
Windows lab PC (8 GB GPU) for CARLA    | ₹0            | existing KIET lab
Real dashcam clip                      | ₹0            | phone camera
=> Real cost is builder time + compute hours, not money. The pie shows the planned effort split (a plan, not a measurement)."""

# ---------------------------------------------------------------- build all
if __name__ == "__main__":
    page("D1-FULL-SYSTEM", "D1 · Full system — end to end",
         "1 idea → 5 layers (SENSE · UNDERSTAND · DECIDE · ACT · PROVE) → 13 parts → components. Red = safety (only the checker can say 'go'). Dashed = test/comparison paths.",
         flowchart("LR", D1_groups, D1_edges, dashed=D1_dashed, classes=D1_classes), spec(D1_groups, D1_edges), size="A1 landscape")
    page("D2-ONE-DECISION", "D2 · One decision, step by step (every 100 ms)",
         "How the car decides once. Green = the car moves. Red = safety check / safe stop. Numbers in brackets = target time budget, not today's speed (today: 736 ms).",
         flowchart("TB", D2_groups, D2_edges, classes=D2_classes), spec(D2_groups, D2_edges), size="A2 portrait")
    page("D3-AI-STACK", "D3 · The 14-model AI stack (two tiers)",
         "Gold = 5-model prototype core (finale). White = full system (+9). Every model is advice only — the physics safety checker gives the only 'go'.",
         flowchart("LR", D3_groups, D3_edges, core=D3_core, classes=D3_classes), spec(D3_groups, D3_edges), size="A2 landscape")
    page("D4-FIVE-SCENARIOS", "D4 · The 5 required Indian scenarios",
         "Each scenario: who is on the road → which Indian difficulties it tests (P1 catalogue IDs) → test family → what the car must show.",
         flowchart("LR", D4_groups, D4_edges), spec(D4_groups, D4_edges), size="A2 landscape")
    page("D5-BUILD-PLAN", "D5 · 10-week build plan with pass/fail gates",
         "Two builders in parallel, merged into ONE Simulink model every week. Gates G1/G2/G5/G8 decide cuts.",
         D5_code, D5_spec, size="A2 landscape")
    page("D6-PS-COVERAGE", "D6 · What the PS asks → how we meet it → beyond the PS",
         "Left: PS requirements (official text). Middle: our part that answers it. Right: extras beyond the PS. Gold = the one disclosed deviation.",
         flowchart("LR", D6_groups, D6_edges, classes=D6_classes), spec(D6_groups, D6_edges), extra_html=D6_extra, size="A2 landscape")
    page("D7-COMPETITORS-AND-COST", "D7 · Competitor comparison + cost",
         "Pie = planned effort split. Tables = competitor ticks (verified only) and real cash cost.",
         D7_code, D7_spec, size="A3 landscape")
