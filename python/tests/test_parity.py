"""Parity fixture for the two feature builders.

    python3 python/tests/test_parity.py

python/meteor/features.py trains the model. matlab/+sih/+prediction/buildFeatureFrame.m feeds
it at inference. If the two disagree the network sees different numbers than it was trained on,
NOTHING ERRORS, and the symptom looks like a planner bug days later. AGENTS.md section 5 makes
them agreeing a hard requirement; this is the file that enforces it.

MATLAB cannot be called from here, so this works in two halves:
  1. This script builds cases that exercise every branch, records what Python produces, and
     writes python/tests/parity_fixture.json.
  2. matlab/tests/testFeatureParity.m reads that file, runs the MATLAB twin on the same
     inputs, and asserts agreement to 1e-6.

Run this whenever features.py changes, and commit the regenerated fixture with it. A fixture
that is older than features.py is proving nothing.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from meteor.features import Box, EgoState, frame_features                      # noqa: E402

FIXTURE = Path(__file__).resolve().parent / "parity_fixture.json"
TOL = 1e-6

FAILED: list[str] = []


def check(name: str, ok: bool, detail: str = "") -> None:
    print(f"  {'PASS' if ok else 'FAIL'}  {name}{('  ' + detail) if detail else ''}")
    if not ok:
        FAILED.append(name)


def b(u0, v0, u1, v1, cid, tid, t):
    return Box(u_min=u0, v_min=v0, u_max=u1, v_max=v1, class_id=cid, track_id=tid, t=t)


def case(name, boxes, prev, ego, w=1920, h=1080):
    prev_map = {p.track_id: p for p in prev}
    data, adj, ids = frame_features(boxes, prev_map, ego, w, h)
    return {
        "name": name,
        "img_w": w, "img_h": h,
        "ego": {"speed": ego.speed, "yaw_rate": ego.yaw_rate,
                "accel": ego.accel, "cand_action": ego.cand_action},
        "boxes": [dict(u_min=x.u_min, v_min=x.v_min, u_max=x.u_max, v_max=x.v_max,
                       class_id=x.class_id, track_id=x.track_id, t=x.t) for x in boxes],
        "prev": [dict(u_min=x.u_min, v_min=x.v_min, u_max=x.u_max, v_max=x.v_max,
                      class_id=x.class_id, track_id=x.track_id, t=x.t) for x in prev],
        "expected_data": np.asarray(data, dtype=float).tolist(),
        "expected_adj": np.asarray(adj, dtype=float).tolist(),
        "expected_ids": [int(i) for i in ids],
    }


def main() -> int:
    still = EgoState(speed=0.0, yaw_rate=0.0, accel=0.0, cand_action=0.0)
    moving = EgoState(speed=8.25, yaw_rate=-0.14, accel=1.5, cand_action=0.5)

    cases = []

    # 1. empty - S1 rule 3 says a consumer must not error on an empty list
    cases.append(case("empty", [], [], still))

    # 2. one box, no history: every rate is zero, so tau and the lateral feature must both
    #    fall to the +/-100 s clamp through the safe-divide default, not to zero or inf
    cases.append(case("no history", [b(800, 500, 900, 600, 1, 7, 1.0)], [], still))

    # 3. real rates, both features live
    cases.append(case("with history",
                      [b(800, 500, 900, 620, 1, 7, 1.0)],
                      [b(780, 490, 870, 590, 1, 7, 0.9)], moving))

    # 4. dead centre: lat_gap == 0 takes the >= 0 branch, so latRate = -du
    cases.append(case("dead centre",
                      [b(910, 500, 1010, 600, 5, 3, 2.0)],
                      [b(900, 495, 1000, 595, 5, 3, 1.9)], moving))

    # 5. ClassID outside 0..15 must fold to unknown, not raise and not write out of bounds
    cases.append(case("class out of range", [b(100, 400, 200, 500, 99, 11, 3.0)], [], still))
    cases.append(case("class negative", [b(100, 400, 200, 500, -4, 12, 3.0)], [], still))

    # 6. every S5 class in one frame, so all 16 one-hot positions are exercised
    cases.append(case("all classes",
                      [b(50 + 60 * c, 400, 100 + 60 * c, 500, c, 100 + c, 4.0)
                       for c in range(16)], [], moving))

    # 7. adjacency: a near pair and a far one in the same frame
    cases.append(case("adjacency mixed",
                      [b(800, 500, 900, 600, 1, 1, 5.0),
                       b(830, 520, 930, 620, 5, 2, 5.0),     # near  -> 1
                       b(60, 950, 160, 1050, 8, 3, 5.0)],    # far   -> 0
                      [], still))

    # 8. extreme aspect ratio - guards the max(w,1e-6) floor inside log(w/h)
    cases.append(case("extreme aspect",
                      [b(900, 500, 901, 1000, 9, 21, 6.0)], [], still))

    # 9. a track present now but absent from prev: rates must be zero, not carried over
    cases.append(case("new track beside an old one",
                      [b(800, 500, 900, 600, 1, 7, 7.0), b(400, 500, 500, 600, 2, 8, 7.0)],
                      [b(780, 490, 880, 590, 1, 7, 6.9)], moving))

    # 10. identical timestamps: (t - p.t) is not > 1e-6, so rates stay zero
    cases.append(case("zero dt",
                      [b(800, 500, 900, 600, 1, 7, 8.0)],
                      [b(700, 400, 800, 500, 1, 7, 8.0)], still))

    print("building parity fixture")
    for c in cases:
        d = np.array(c["expected_data"], dtype=float)
        n = len(c["boxes"])
        check(f"{c['name']}: shape [{n}, 31]", d.shape == (n, 31) if n else d.size == 0,
              str(d.shape))
        if n:
            check(f"{c['name']}: finite", bool(np.isfinite(d).all()))
            oh = d[:, 11:27]
            check(f"{c['name']}: exactly one class bit per row",
                  bool((oh.sum(axis=1) == 1).all()))
            check(f"{c['name']}: tau and lateral inside +/-100",
                  bool((np.abs(d[:, 9:11]) <= 100.0 + TOL).all()))

    FIXTURE.write_text(json.dumps({"tolerance": TOL, "cases": cases}, indent=1))
    print(f"\nwrote {FIXTURE}  ({len(cases)} cases)")
    if FAILED:
        print(f"\n{len(FAILED)} check(s) failed: {FAILED}")
        return 1
    print("Python side agrees with itself. Now run matlab/tests/testFeatureParity.m")
    print("in MATLAB - that is the half that can actually catch a divergence.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
