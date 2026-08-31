"""Contract tests. These guard the shapes other people's code depends on.

    python3 python/tests/test_contract.py

No pytest needed. Exits non-zero on failure.
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from meteor.features import (FEATURE_DIM, N_CLASSES, SEQ_LEN, Box, EgoState,   # noqa: E402
                             frame_features, to_sequence)
from meteor.parse_xml import CLASS_MAP, parse_frame                            # noqa: E402

FAILED: list[str] = []


def check(name: str, cond: bool, detail: str = "") -> None:
    print(f"  {'PASS' if cond else 'FAIL'}  {name}{'  ' + detail if detail else ''}")
    if not cond:
        FAILED.append(name)


def main() -> int:
    print("S2 - the feature vector")
    boxes = [Box(100, 200, 300, 400, 1, 7, 0.0), Box(500, 220, 560, 300, 10, 9, 0.0)]
    ego = EgoState(8.0, 0.1, -0.5, 0.5)
    data, adj, ids = frame_features(boxes, None, ego, 1920, 1080)

    check("31 features exactly", data.shape[1] == FEATURE_DIM, f"got {data.shape[1]}")
    check("one row per agent", data.shape[0] == len(boxes))
    check("adjacency is N x N", adj.shape == (len(boxes), len(boxes)))
    check("track ids preserved in order", ids == [7, 9])
    check("float32", data.dtype == np.float32)
    check("no NaN or Inf", bool(np.isfinite(data).all()))

    print("\nfeature positions - these must never move")
    check("28-30 are the ego state",
          (data[0, 27], data[0, 28], data[0, 29]) == (8.0, 0.1, -0.5))
    check("31 is the candidate action", data[0, 30] == 0.5)
    onehot = data[0, 11:11 + N_CLASSES]
    check("12-27 are a 16-way one-hot", onehot.sum() == 1.0 and onehot[1] == 1.0)
    check("cow maps to ClassID 10", data[1, 11 + 10] == 1.0)

    print("\nfeature 11 is not a duplicate of feature 7")
    prev = {7: Box(90, 200, 290, 400, 1, 7, -0.1)}
    moved, _, _ = frame_features([boxes[0]], prev, ego, 1920, 1080)
    check("feature 7 and feature 11 differ",
          not np.isclose(moved[0, 6], moved[0, 10]),
          f"du={moved[0,6]:.4f} closure={moved[0,10]:.4f}")

    print("\nsequences")
    short = to_sequence([data[0]])
    check("front-padded to T", short.shape == (SEQ_LEN, FEATURE_DIM), f"got {short.shape}")
    check("padding repeats the earliest frame", bool(np.allclose(short[0], short[-1])))

    print("\nS5 - class map")
    check("auto-rickshaw is 4", CLASS_MAP["motorizedtricycle"] == 4)
    check("cow is 10", CLASS_MAP["cow"] == 10)
    check("the 'Pedestrain' misspelling is handled",
          CLASS_MAP["pedestrain"] == CLASS_MAP["pedestrian"] == 8)

    print("\nparser")
    xml = """<annotation><size><width>1920</width><height>1080</height></size>
      <object><name>EgoVehicle</name><bndbox><xmin>0</xmin><ymin>0</ymin><xmax>1</xmax>
        <ymax>1</ymax><x-axis>1235098.99</x-axis><y-axis>5958251.66</y-axis>
        <z-axis>1920118.26</z-axis></bndbox></object>
      <object><name>Car</name><bndbox><xmin>10</xmin><ymin>20</ymin><xmax>30</xmax><ymax>40</ymax>
        <x-axis>1235098.99</x-axis><y-axis>5958251.66</y-axis><z-axis>1920118.26</z-axis></bndbox>
        <attributes><attribute><name>Yield</name><value>True</value></attribute>
        <attribute><name>track_id</name><value>3</value></attribute></attributes></object>
      </annotation>"""
    fr = parse_frame(xml, 0)
    check("ego is excluded from the boxes", len(fr.boxes) == 1)
    check("yield label read", fr.labels.get(3) == 1)
    check("ego ECEF captured once", fr.ego_ecef is not None)
    check("image size read", (fr.width, fr.height) == (1920, 1080))

    print()
    if FAILED:
        print(f"{len(FAILED)} FAILED: {', '.join(FAILED)}")
        return 1
    print("all contract tests passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
