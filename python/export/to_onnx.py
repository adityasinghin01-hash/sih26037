"""Export both predictors to ONNX and report exactly what MATLAB will have to deal with.

Run this, then run derisk/check04_onnx_lstm.m in MATLAB. The opset that imports cleanly is the
one we train and ship, and that single number blocks the planner stream - send it immediately.
R2024b supports opsets 6-18; R2025a+ supports 6-20.

    python3 python/export/to_onnx.py                  # both models, untrained (shape check)
    python3 python/export/to_onnx.py --model <file>   # a trained checkpoint

THREE THINGS THIS SCRIPT REFUSES TO GUESS ABOUT
1. The opset actually written. torch >= 2.9 silently upconverts a requested opset below its
   implementation floor: ask for 9, 11 or 13 and you get a file stamped 18. Reporting the
   requested number would send the planner stream a number that is not true of the file.
   Measured 1 Sep 2026. This script reads the opset back out of the file it wrote.
2. Which operators MATLAB supports. importNetworkFromONNX converts a documented list into
   built-in layers; everything else becomes a custom layer, and an operator it cannot generate
   at all becomes a PLACEHOLDER FUNCTION A HUMAN MUST WRITE. So "exported OK" is not the same
   as "imports cleanly", and only MATLAB can settle the difference - that is check04's job.
   This script prints the operators outside the built-in list so check04 has a prediction to
   test rather than a surprise to debug.
3. Whether the file still computes what the model computes. onnxruntime is run against PyTorch
   on the same input and the outputs are compared. An export that succeeds and returns
   different numbers is the worst outcome available, because nothing errors.
"""
from __future__ import annotations

import argparse
import contextlib
import io
import logging
import sys
import warnings
from pathlib import Path

import numpy as np
import torch

# torch's exporter prints ~40 lines of progress and deprecation chatter per file. Six files
# buries the three lines that matter. Keep the real errors: only the exporter's own logging
# and warnings are silenced, and every failure is still printed by the [FAILED] branch.
warnings.filterwarnings("ignore")
logging.getLogger("torch.onnx").setLevel(logging.ERROR)


@contextlib.contextmanager
def _quiet():
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
        yield

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from model.yield_lstm import YieldNet, SEQ_LEN, FEATURE_DIM              # noqa: E402
from model.yield_attention import YieldAttentionNet, MAX_AGENTS          # noqa: E402

OUT = Path(__file__).resolve().parent

# Opsets worth writing. 17 is the lowest torch 2.13 will honour exactly; 18 is R2024b's
# ceiling; 20 is R2025a+'s ceiling. Anything lower is silently upconverted, so asking for it
# produces a duplicate file with a misleading name.
OPSETS = (17, 18, 20)

# ONNX operators importNetworkFromONNX converts into BUILT-IN MATLAB layers.
# Source: mathworks.com/help/deeplearning/ref/importnetworkfromonnx.html, read 1 Sep 2026.
# Anything outside this set becomes a custom layer - usually generated automatically, but
# sometimes a placeholder you must complete by hand.
MATLAB_BUILTIN = {
    "Add", "AveragePool", "BatchNormalization", "Concat", "Constant", "Conv", "ConvTranspose",
    "Div", "Sub", "Neg", "Dropout", "Elu", "Gelu", "Gemm", "GlobalAveragePool", "GlobalMaxPool",
    "GRU", "Identity", "InstanceNormalization", "LayerNormalization", "LeakyRelu", "LRN",
    "LSTM", "MatMul", "MaxPool", "Mul", "Relu", "PRelu", "Sigmoid", "Softmax", "Softplus",
    "Sum", "Tanh",
    # converted to custom ONNX-importer layers, which is still automatic:
    "Clip", "Flatten", "ImageScaler", "Reshape",
}

# These are the ones AGENTS.md calls settled: sparse message passing cannot import.
# Their presence is a hard failure, not a warning.
FORBIDDEN = {"Gather", "GatherND", "Scatter", "ScatterND", "ScatterElements"}


def inspect(path: str) -> tuple[int, list[str], set[str]]:
    """Return (opset actually in the file, ops outside MATLAB's built-in list, forbidden ops)."""
    import onnx
    m = onnx.load(path)
    opset = max((i.version for i in m.opset_import if i.domain in ("", "ai.onnx")), default=-1)
    ops = [n.op_type for n in m.graph.node]
    outside = sorted({o for o in ops if o not in MATLAB_BUILTIN})
    return opset, outside, {o for o in ops if o in FORBIDDEN}


def verify(path: str, model: torch.nn.Module, args: tuple, names: list[str]) -> str:
    """Run the written file through onnxruntime and compare with PyTorch. Returns a verdict."""
    try:
        import onnxruntime as ort
    except ImportError:
        return "not checked (onnxruntime missing)"
    try:
        sess = ort.InferenceSession(path, providers=["CPUExecutionProvider"])
        feed = {n: a.detach().numpy() for n, a in zip(names, args)}
        got = sess.run(None, feed)[0]
        with torch.no_grad():
            want = model(*args).numpy()
        if got.shape != want.shape:
            return f"SHAPE MISMATCH onnx={got.shape} torch={want.shape}"
        err = float(np.abs(got - want).max())
        return f"max abs diff {err:.2e}" + ("" if err < 1e-4 else "  <-- TOO LARGE")
    except Exception as exc:                                              # noqa: BLE001
        return f"RUNTIME FAILED {type(exc).__name__}: {exc}"


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--model", type=Path, default=None,
                    help="a trained .pt checkpoint; without it the nets are random "
                         "(fine for a shape and operator check, useless for accuracy)")
    args_cli = ap.parse_args()

    lstm = YieldNet().eval()
    attn = YieldAttentionNet().eval()
    if args_cli.model:
        ck = torch.load(args_cli.model, map_location="cpu", weights_only=False)
        target = attn if ck.get("model") == "attention" else lstm
        target.load_state_dict(ck["state_dict"])
        print(f"loaded {args_cli.model}  (model={ck.get('model')})")
    else:
        print("NOTE: exporting UNTRAINED weights. Shapes and operators are real; numbers are not.")

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
    notes: list[str] = []
    for name, model, margs, inputs, axes in jobs:
        ok[name] = []
        print(f"\n--- {name} ---")
        for opset in OPSETS:
            path = OUT / f"{name}_opset{opset}.onnx"
            try:
                with _quiet():
                    torch.onnx.export(model, margs, path.as_posix(),
                                      input_names=inputs, output_names=["yield_logits"],
                                      opset_version=opset, dynamic_axes=axes, dynamo=True)
            except Exception as exc:                                      # noqa: BLE001
                print(f"  [FAILED]   opset {opset}: {type(exc).__name__}: {exc}")
                continue

            actual, outside, bad = inspect(path.as_posix())
            if actual != opset:
                # rename so the filename never lies about its own contents
                path.unlink(missing_ok=True)
                print(f"  [SKIPPED]  requested {opset} but torch wrote {actual} - "
                      f"not written, it would duplicate opset{actual}")
                continue
            if bad:
                print(f"  [UNUSABLE] opset {actual}: contains {sorted(bad)} - "
                      f"AGENTS.md says these cannot import")
                path.unlink(missing_ok=True)
                continue

            print(f"  [OK]       {path.name}   opset in file = {actual}")
            print(f"             numerics vs PyTorch: {verify(path.as_posix(), model, margs, inputs)}")
            if outside:
                print(f"             {len(outside)} op(s) outside MATLAB's built-in list: {outside}")
                notes.append(f"{path.name}: {outside}")
            else:
                print("             every operator maps to a built-in MATLAB layer")
            ok[name].append(actual)

    print("\n" + "=" * 70)
    for name, opsets in ok.items():
        print(f"{name}: exported opsets {opsets or 'NONE'}")
    if not any(ok.values()):
        print("\nNothing exported. Report the full errors above.")
        return 1
    if notes:
        print("\nOperators outside the built-in list become CUSTOM layers on import. Most are")
        print("generated automatically; any that are not arrive as a placeholder function that")
        print("a human must complete. check04 in MATLAB is what settles which - run it and")
        print("report whether importNetworkFromONNX warns about placeholders.")
    print("\nNext: run derisk/check04_onnx_lstm.m in MATLAB.")
    print("Send the working opset number to the planner stream immediately - it blocks them.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
