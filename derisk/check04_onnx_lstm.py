"""CHECK 4, PART A - superseded. Use the real exporter instead.

This used to build a toy LSTM and export it at opsets 13, 11 and 9. Both halves of that are
now known to be wrong:

  * A toy of nn.LSTM + nn.Linear imports easily and proves nothing about our real model, which
    also carries LayerNorm, normalisation constants, and a Slice + Flatten. Those are the parts
    that fail.
  * torch >= 2.9 SILENTLY UPCONVERTS opsets 9, 11 and 13 to 18, so the sweep produced three
    identical files under three misleading names. Stream D is blocked on that number.

Do this instead:

    python3 ml/python/export/to_onnx.py --model <checkpoint.pt>     # writes opsets 17, 18, 20
    # then, in MATLAB:
    check04_onnx_lstm
"""
import sys

print(__doc__)
sys.exit(1)
