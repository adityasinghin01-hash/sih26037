"""Parse METEOR frame annotations into the Box/EgoState objects features.py consumes.

Verified against the real data on 31 Aug 2026:
  - Every non-ego object carries an <attributes> block with Yield, Cutting, track_id.
  - <bndbox> also holds x-axis/y-axis/z-axis. Those are the EGO's ECEF position REPEATED on
    every object, not per-object positions. There is no per-agent 3-D. Never build any.
  - 1800 frames per clip = 30 Hz. Take every 3rd frame for the contract's 10 Hz.
  - "Pedestrain" is misspelt in the source data. Both spellings are mapped.
"""
from __future__ import annotations

import math
import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path

from .features import Box, EgoState

# S5 ClassID. Names are the strings that actually appear in METEOR.
CLASS_MAP: dict[str, int] = {
    "car": 1, "truck": 2, "bus": 3,
    "motorizedtricycle": 4,            # auto-rickshaw
    "motorbike": 5, "motorcycle": 5,
    "scooter": 6, "van": 7,
    "pedestrian": 8, "pedestrain": 8,  # misspelt in the source data
    "bicycle": 9, "cycle": 9,
    "cow": 10, "animal": 10, "dog": 11,
    "pushcart": 12, "cart": 13, "tractor": 14,
}
EGO_NAME = "egovehicle"


@dataclass(frozen=True)
class Frame:
    """One parsed frame."""
    index: int
    t: float                       # seconds from clip start
    boxes: list[Box]
    labels: dict[int, int]         # track_id -> 1 if Yield is True else 0
    ego_ecef: tuple[float, float, float] | None
    width: int
    height: int


def _attrs(obj: ET.Element) -> dict[str, str]:
    out: dict[str, str] = {}
    for a in obj.findall("./attributes/attribute"):
        name = (a.findtext("name") or "").strip()
        value = (a.findtext("value") or "").strip()
        if name:
            out[name] = value
    return out


def _f(el: ET.Element | None, tag: str, default: float = 0.0) -> float:
    if el is None:
        return default
    txt = el.findtext(tag)
    try:
        return float(txt) if txt not in (None, "") else default
    except ValueError:
        return default


def parse_frame(xml_text: str, index: int, fps: float = 30.0) -> Frame:
    """Parse one frame_NNNNNN.xml. Never raises on a malformed object; skips it."""
    root = ET.fromstring(xml_text)
    size = root.find("size")
    width = int(_f(size, "width", 1920.0))
    height = int(_f(size, "height", 1080.0))

    boxes: list[Box] = []
    labels: dict[int, int] = {}
    ego_ecef: tuple[float, float, float] | None = None
    t = index / fps

    for obj in root.findall("object"):
        name = (obj.findtext("name") or "").strip()
        bb = obj.find("bndbox")
        if bb is None:
            continue
        # The ECEF triple is the ego pose, repeated on every object. Read it once.
        if ego_ecef is None:
            x, y, z = _f(bb, "x-axis"), _f(bb, "y-axis"), _f(bb, "z-axis")
            if any(abs(v) > 1.0 for v in (x, y, z)):
                ego_ecef = (x, y, z)
        if name.lower() == EGO_NAME:
            continue

        a = _attrs(obj)
        try:
            track_id = int(float(a.get("track_id", "-1")))
        except ValueError:
            track_id = -1
        if track_id < 0:
            continue

        boxes.append(Box(
            u_min=_f(bb, "xmin"), v_min=_f(bb, "ymin"),
            u_max=_f(bb, "xmax"), v_max=_f(bb, "ymax"),
            class_id=CLASS_MAP.get(name.lower().replace(" ", ""), 0),
            track_id=track_id, t=t,
        ))
        labels[track_id] = 1 if a.get("Yield", "").strip().lower() == "true" else 0

    return Frame(index, t, boxes, labels, ego_ecef, width, height)


def ecef_to_speed(prev: tuple[float, float, float] | None,
                  cur: tuple[float, float, float] | None,
                  dt: float) -> float:
    """Ego speed in m/s from two ECEF positions. ECEF is metres, so this is a straight
    Euclidean distance over time. Returns 0.0 when either position is missing."""
    if prev is None or cur is None or dt <= 1e-9:
        return 0.0
    d = math.dist(prev, cur)
    return float(d / dt) if d < 100.0 else 0.0     # >100 m in one frame is a GPS jump


def ecef_to_yaw_rate(p0: tuple[float, float, float] | None,
                     p1: tuple[float, float, float] | None,
                     p2: tuple[float, float, float] | None,
                     dt: float) -> float:
    """Ego yaw rate in rad/s from three consecutive ECEF positions.

    The angle between two successive displacement vectors is how much the vehicle turned over
    that step. No geodetic conversion needed: the car moves in a locally horizontal plane, so
    the angle between the vectors is the heading change directly.

    Sign convention: positive is a left turn, taken from the cross product's projection onto
    the local up direction, which for ECEF is the position vector itself.
    """
    if p0 is None or p1 is None or p2 is None or dt <= 1e-9:
        return 0.0
    v1 = [p1[i] - p0[i] for i in range(3)]
    v2 = [p2[i] - p1[i] for i in range(3)]
    n1 = math.sqrt(sum(c * c for c in v1))
    n2 = math.sqrt(sum(c * c for c in v2))
    if n1 < 1e-3 or n2 < 1e-3:          # stationary; heading is undefined, not zero-turn
        return 0.0
    dot = max(-1.0, min(1.0, sum(v1[i] * v2[i] for i in range(3)) / (n1 * n2)))
    angle = math.acos(dot)
    cross = (v1[1] * v2[2] - v1[2] * v2[1],
             v1[2] * v2[0] - v1[0] * v2[2],
             v1[0] * v2[1] - v1[1] * v2[0])
    up = p1                              # ECEF position doubles as the local up vector
    sign = 1.0 if sum(cross[i] * up[i] for i in range(3)) >= 0 else -1.0
    rate = sign * angle / dt
    return float(rate) if abs(rate) < 3.0 else 0.0      # >3 rad/s is a GPS artefact


def action_from_accel(accel: float) -> float:
    """The S6 candidate action the ego actually took, inferred from its own acceleration.

    In METEOR we only observe what the driver did, never what they would have done otherwise.
    So during training feature 31 carries the ACTUAL action. At inference the planner supplies a
    hypothetical one. That gap is the known limitation of this model - see AGENTS.md.
    """
    if accel > 0.5:
        return 1.0        # commit
    if accel < -0.5:
        return -1.0       # give way
    return 0.0            # hold


_FRAME_RE = re.compile(r"(\d+)\.xml$", re.IGNORECASE)


def frame_index(path: str) -> int:
    m = _FRAME_RE.search(path)
    return int(m.group(1)) if m else -1


def clip_frames(clip_dir: Path) -> list[Path]:
    """Every frame file in a clip, sorted by frame number."""
    files = [p for p in clip_dir.rglob("*.xml")]
    return sorted(files, key=lambda p: frame_index(p.name))
