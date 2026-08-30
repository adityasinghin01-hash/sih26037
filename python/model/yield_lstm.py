"""The yield/no-yield predictor.

An LSTM, not a GNN, and that is a hard constraint rather than a preference:
importNetworkFromONNX does not support Gather/Scatter, which message-passing GNNs depend on.
LSTM and GRU import cleanly. See AGENTS.md, settled decisions.

Input  : [B, 20, 31]  the sequence from docs/INTERFACES.md S2
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

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        # x: [B, T, 31]
        out, _ = self.lstm(x)
        return self.head(out[:, -1, :])       # last timestep only

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
