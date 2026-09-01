"""Feature builder — the 31-dimension vector defined in AGENTS.md section 3 S2.

The whole point: every quantity here is computable BOTH from a METEOR bounding-box track
(monocular dashcam, image plane) AND from a simulated lidar track projected through a
virtual camera with matching intrinsics. Nothing needs depth.

Do not lift METEOR into 3-D. Project the simulation down instead. Lifting needs monocular
depth, and 1 degree of camera pitch error is ~31% depth error at 30 m.
See research section 11.

The MATLAB twin of this file is matlab/+sih/+prediction/buildFeatureFrame.m.
python/tests/test_parity.py proves they agree. Keep it passing.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence
import numpy as np

FEATURE_DIM = 31
SEQ_LEN = 20          # 2.0 s at 10 Hz
N_CLASSES = 16
TAU_CLAMP = 100.0     # seconds; tau is unbounded as dh/dt -> 0
ADJACENCY_RADIUS_PX = 0.25   # normalised image distance counted as "interacting"


@dataclass(frozen=True)
class Box:
    """One detection in the image plane. Identical shape from METEOR XML or from
    projecting a 3-D track with monoCamera/vehicleToImage."""
    u_min: float
    v_min: float
    u_max: float
    v_max: float
    class_id: int          # AGENTS.md section 3 S5
    track_id: int
    t: float               # seconds


@dataclass(frozen=True)
class EgoState:
    speed: float          # m/s
    yaw_rate: float       # rad/s
    accel: float          # m/s^2
    cand_action: float    # AGENTS.md section 3 S6


def _safe_div(a: float, b: float, default: float = 0.0) -> float:
    return a / b if abs(b) > 1e-9 else default


def frame_features(
    boxes: Sequence[Box],
    prev: dict[int, Box] | None,
    ego: EgoState,
    img_w: int,
    img_h: int,
) -> tuple[np.ndarray, np.ndarray, list[int]]:
    """Build one FeatureFrame.

    Returns (data [N,31] float32, adjacency [N,N] float32, track_ids).
    Row order matches the input order, which must match TrackList order (S1 rule 1).
    """
    prev = prev or {}
    n = len(boxes)
    data = np.zeros((n, FEATURE_DIM), dtype=np.float32)
    ids: list[int] = []

    for i, b in enumerate(boxes):
        ids.append(b.track_id)
        w = (b.u_max - b.u_min) / img_w
        h = (b.v_max - b.v_min) / img_h
        u_c = ((b.u_min + b.u_max) / 2) / img_w
        v_c = ((b.v_min + b.v_max) / 2) / img_h
        v_bottom = b.v_max / img_h

        # rates, from the previous frame of the same track
        p = prev.get(b.track_id)
        if p is not None and (b.t - p.t) > 1e-6:
            dt = b.t - p.t
            pw = (p.u_max - p.u_min) / img_w
            ph = (p.v_max - p.v_min) / img_h
            pu = ((p.u_min + p.u_max) / 2) / img_w
            pv = ((p.v_min + p.v_max) / 2) / img_h
            du, dv, dh = (u_c - pu) / dt, (v_c - pv) / dt, (h - ph) / dt
            dw = (w - pw) / dt
        else:
            du = dv = dh = dw = 0.0

        # feature 10: looming. tau = h / (dh/dt) -> time to contact from 2-D expansion alone
        tau = _safe_div(h, dh, default=TAU_CLAMP)
        tau = float(np.clip(tau, -TAU_CLAMP, TAU_CLAMP))

        row = data[i]
        row[0], row[1] = u_c, v_c
        row[2] = v_bottom
        row[3], row[4] = w, h
        row[5] = float(np.log(max(w, 1e-6) / max(h, 1e-6)))
        row[6], row[7], row[8] = du, dv, dh
        row[9] = tau
        # feature 11: lateral time-to-cross. Seconds until this agent's centre reaches our own
        # path line (the image centre), from its current sideways drift. The lateral twin of
        # feature 10's looming, and like it, computable without any distance.
        #   positive  -> closing on our path, and how soon
        #   TAU_CLAMP -> drifting away, or not moving sideways
        # Plain du was used here before, which made this an exact copy of feature 7.
        lat_gap = u_c - 0.5
        lat_rate = -du if lat_gap >= 0 else du        # rate at which the gap shrinks
        row[10] = float(np.clip(_safe_div(abs(lat_gap), lat_rate, default=TAU_CLAMP),
                                -TAU_CLAMP, TAU_CLAMP))
        cid = b.class_id if 0 <= b.class_id < N_CLASSES else 0
        row[11 + cid] = 1.0     # 12..27 one-hot (0-indexed 11..26)
        row[27] = ego.speed
        row[28] = ego.yaw_rate
        row[29] = ego.accel
        row[30] = ego.cand_action
        _ = dw                  # kept for parity with the MATLAB builder; not a feature

    # adjacency: 1 where two agents are close enough in the image to be interacting.
    # The LSTM ignores this. It exists so the GNN swap is ~60 lines, not a rewrite.
    adj = np.zeros((n, n), dtype=np.float32)
    for i in range(n):
        for j in range(i + 1, n):
            d = float(np.hypot(data[i, 0] - data[j, 0], data[i, 1] - data[j, 1]))
            if d < ADJACENCY_RADIUS_PX:
                adj[i, j] = adj[j, i] = 1.0
    return data, adj, ids


def to_sequence(history: Sequence[np.ndarray], seq_len: int = SEQ_LEN) -> np.ndarray:
    """Stack per-frame rows for ONE agent into [T, 31], front-padded with the earliest
    frame when the track is younger than seq_len. Matches AGENTS.md section 3 S2."""
    if not history:
        return np.zeros((seq_len, FEATURE_DIM), dtype=np.float32)
    arr = np.stack(history[-seq_len:]).astype(np.float32)
    if arr.shape[0] < seq_len:
        pad = np.repeat(arr[:1], seq_len - arr.shape[0], axis=0)
        arr = np.concatenate([pad, arr], axis=0)
    return arr
