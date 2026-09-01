"""The yield/no-yield predictor.

An LSTM, not a GNN, and that is a hard constraint rather than a preference:
importNetworkFromONNX does not support Gather/Scatter, which message-passing GNNs depend on.
LSTM and GRU import cleanly. See AGENTS.md, settled decisions.

Input  : [B, 20, 31]  the sequence from AGENTS.md section 3 S2
Output : [B, 2]       logits -> softmax -> P(yield)
"""
from __future__ import annotations

import torch
import torch.nn as nn

FEATURE_DIM = 31
SEQ_LEN = 20
N_CLASSES = 2          # 0 = does not yield, 1 = yields


class YieldNet(nn.Module):
    def __init__(self, hidden: int = 64, layers: int = 1, dropout: float = 0.1) -> None:
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=FEATURE_DIM,
            hidden_size=hidden,
            num_layers=layers,
            batch_first=True,
            dropout=dropout if layers > 1 else 0.0,
        )
        self.head = nn.Sequential(
            nn.LayerNorm(hidden),
            nn.Dropout(dropout),
            nn.Linear(hidden, N_CLASSES),
        )
        # Input scaling lives INSIDE the model, so the ONNX file MATLAB imports takes raw
        # contract-S2 features and needs no MATLAB-side preprocessing to match. Buffers, not
        # parameters: they are saved in the checkpoint and exported as graph constants.
        self.register_buffer("feat_mean", torch.zeros(FEATURE_DIM))
        self.register_buffer("feat_std", torch.ones(FEATURE_DIM))

    def set_normaliser(self, mean, std) -> None:
        """Install per-feature scaling measured on the TRAINING clips only.

        Feature 10 (tau) and 11 (lateral time-to-cross) are clamped at +/-100 s while the box
        geometry features live in [0,1]. Unscaled, the two looming features carry ~400x the
        numeric range of everything else and the LSTM sees little but them.
        """
        self.feat_mean.copy_(torch.as_tensor(mean, dtype=torch.float32))
        self.feat_std.copy_(torch.as_tensor(std, dtype=torch.float32).clamp_min(1e-6))

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [B, T, 31] - raw contract features; normalisation happens inside the graph
        x = (x - self.feat_mean) / self.feat_std
        out, _ = self.lstm(x)
        # Take the last timestep WITHOUT integer indexing. `out[:, -1, :]` exports as ONNX
        # `Gather`, which importNetworkFromONNX has no built-in layer for; a slice followed by
        # `flatten` exports as Slice + Flatten instead. Measured, not assumed - see
        # to_onnx.py, which reports the operator list of every file it writes.
        last = torch.flatten(out[:, -1:, :], 1)
        return self.head(last)

    @torch.no_grad()
    def p_yield(self, x: torch.Tensor) -> torch.Tensor:
        return torch.softmax(self(x), dim=-1)[:, 1]


def count_params(model: nn.Module) -> int:
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


if __name__ == "__main__":
    m = YieldNet()
    x = torch.randn(4, SEQ_LEN, FEATURE_DIM)
    y = m(x)
    print(f"YieldNet  params={count_params(m):,}  in={tuple(x.shape)}  out={tuple(y.shape)}")
    print("P(yield) :", m.p_yield(x).tolist())
