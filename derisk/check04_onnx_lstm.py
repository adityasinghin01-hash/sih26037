# CHECK 4, PART A — build a toy LSTM and export it to ONNX.
# Run this in a terminal:  python3 check04_onnx_lstm.py
# Needs: pip install torch onnx
import torch, torch.nn as nn

FEATURES, HIDDEN, CLASSES, SEQ = 8, 32, 2, 20   # 2 classes = yield / no-yield

class YieldNet(nn.Module):
    def __init__(self):
        super().__init__()
        self.lstm = nn.LSTM(FEATURES, HIDDEN, batch_first=True)
        self.fc   = nn.Linear(HIDDEN, CLASSES)
    def forward(self, x):
        out, _ = self.lstm(x)
        return self.fc(out[:, -1, :])

model = YieldNet().eval()
dummy = torch.randn(1, SEQ, FEATURES)

for opset in (13, 11, 9):
    name = f"toy_lstm_opset{opset}.onnx"
    try:
        torch.onnx.export(model, dummy, name,
                          input_names=["sequence"], output_names=["yield_logits"],
                          opset_version=opset,
                          dynamic_axes={"sequence": {0: "batch"}})
        print(f"  [OK]      wrote {name}")
    except Exception as e:
        print(f"  [FAILED]  opset {opset}: {e}")

print("\nNow copy the .onnx files next to the MATLAB scripts and run check04_onnx_lstm.m")
