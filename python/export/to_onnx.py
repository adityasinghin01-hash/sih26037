"""Export YieldNet to ONNX at several opsets, so MATLAB can tell us which one imports.

Run this, then run matlab/tests/testOnnxImport.m. The opset that imports cleanly is the one
we train and ship. R2024b supports opsets 6-18; R2025a+ supports 6-20.
"""
from __future__ import annotations

import sys
from pathlib import Path

import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.yield_lstm import YieldNet, SEQ_LEN, FEATURE_DIM   # noqa: E402

OUT = Path(__file__).resolve().parent
OPSETS = (13, 11, 9, 17)


def main() -> int:
    model = YieldNet().eval()
    dummy = torch.randn(1, SEQ_LEN, FEATURE_DIM)
    ok = []
    for opset in OPSETS:
        path = OUT / f"yield_lstm_opset{opset}.onnx"
        try:
            torch.onnx.export(
                model, dummy, path.as_posix(),
                input_names=["sequence"], output_names=["yield_logits"],
                opset_version=opset,
                dynamic_axes={"sequence": {0: "batch"}, "yield_logits": {0: "batch"}},
            )
            print(f"  [OK]     {path.name}")
            ok.append(opset)
        except Exception as exc:                       # noqa: BLE001
            print(f"  [FAILED] opset {opset}: {exc}")
    if not ok:
        print("\nNo opset exported. Report the full errors above.")
        return 1
    print(f"\nExported opsets: {ok}")
    print("Next: run matlab/tests/testOnnxImport.m and report which ones MATLAB accepts.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
