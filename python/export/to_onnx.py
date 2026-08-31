"""Export both predictors to ONNX at several opsets, so MATLAB can say which one imports.

Run this, then run derisk/check04_onnx_lstm.m in MATLAB. The opset that imports cleanly is the
one we train and ship, and that single number blocks the planner stream - send it immediately.
R2024b supports opsets 6-18; R2025a+ supports 6-20.

    python3 python/export/to_onnx.py                  # both models, untrained (shape check)
    python3 python/export/to_onnx.py --model <file>   # a trained checkpoint

The attention model is checked for Gather/Scatter before it is written. Those operators do not
import into MATLAB, so an export containing them is a failure even though it succeeds here.
"""
from __future__ import annotations

import sys
from pathlib import Path

import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.yield_lstm import YieldNet, SEQ_LEN, FEATURE_DIM              # noqa: E402
from model.yield_attention import YieldAttentionNet, MAX_AGENTS          # noqa: E402

OUT = Path(__file__).resolve().parent
OPSETS = (13, 11, 9, 17)


FORBIDDEN = {"Gather", "GatherND", "Scatter", "ScatterND", "ScatterElements"}


def _check_ops(path) -> set[str]:
    """Return any operators in the graph that MATLAB cannot import."""
    try:
        import onnx
    except ImportError:
        return set()
    return {n.op_type for n in onnx.load(path).graph.node} & FORBIDDEN


def main() -> int:
    lstm = YieldNet().eval()
    attn = YieldAttentionNet().eval()
    seq1 = torch.randn(1, SEQ_LEN, FEATURE_DIM)
    seq2 = torch.randn(1, MAX_AGENTS, SEQ_LEN, FEATURE_DIM)
    adj2 = torch.zeros(1, MAX_AGENTS, MAX_AGENTS)

    jobs = [
        ("yield_lstm", lstm, (seq1,), ["sequence"],
         {"sequence": {0: "batch"}, "yield_logits": {0: "batch"}}),
        ("yield_gnn", attn, (seq2, adj2), ["sequence", "adjacency"],
         {"sequence": {0: "batch"}, "adjacency": {0: "batch"}, "yield_logits": {0: "batch"}}),
    ]

    ok: dict[str, list[int]] = {}
    for name, model, args, inputs, axes in jobs:
        ok[name] = []
        for opset in OPSETS:
            path = OUT / f"{name}_opset{opset}.onnx"
            try:
                torch.onnx.export(model, args, path.as_posix(),
                                  input_names=inputs, output_names=["yield_logits"],
                                  opset_version=opset, dynamic_axes=axes)
            except Exception as exc:                   # noqa: BLE001
                print(f"  [FAILED] {name} opset {opset}: {exc}")
                continue
            bad = _check_ops(path.as_posix())
            if bad:
                print(f"  [UNUSABLE] {path.name}: contains {sorted(bad)} - MATLAB cannot import")
                path.unlink(missing_ok=True)
                continue
            print(f"  [OK]     {path.name}")
            ok[name].append(opset)

    for name, opsets in ok.items():
        print(f"\n{name}: exported opsets {opsets or 'NONE'}")
    if not any(ok.values()):
        print("\nNothing exported. Report the full errors above.")
        return 1
    print("\nNext: run derisk/check04_onnx_lstm.m in MATLAB.")
    print("Send the working opset number to the planner stream immediately - it blocks them.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
