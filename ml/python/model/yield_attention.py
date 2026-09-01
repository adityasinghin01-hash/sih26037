"""Model 2 - the group version of the yield predictor.

Model 1 looks at each agent alone. This looks at all nearby agents together, because a scooter's
behaviour depends on the bus beside it, not only on the ego.

HARD CONSTRAINT: built from matrix multiply, softmax, addition and linear layers ONLY.
No Gather, no Scatter, no sparse message passing. MATLAB's importNetworkFromONNX does not
support those operators, so a message-passing version would train fine and then fail at the
final step. The adjacency matrix is applied as a MASK on dense attention, which imports.

Input  : sequence  [B, A, T, 31]     A agents, T timesteps
         adjacency [B, A, A]         1 where two agents interact
Output : yield_logits [B, A, 2]      one prediction per agent
"""
from __future__ import annotations

import torch
import torch.nn as nn

FEATURE_DIM = 31
SEQ_LEN = 20
MAX_AGENTS = 16
N_CLASSES = 2


class YieldAttentionNet(nn.Module):
    def __init__(self, hidden: int = 64, heads: int = 4, dropout: float = 0.1) -> None:
        super().__init__()
        self.hidden = hidden
        self.heads = heads
        self.dh = hidden // heads
        # shared per-agent sequence encoder - same family as model 1, so the comparison is fair
        self.encoder = nn.LSTM(FEATURE_DIM, hidden, batch_first=True)
        self.q = nn.Linear(hidden, hidden)
        self.k = nn.Linear(hidden, hidden)
        self.v = nn.Linear(hidden, hidden)
        self.proj = nn.Linear(hidden, hidden)
        self.norm1 = nn.LayerNorm(hidden)
        self.norm2 = nn.LayerNorm(hidden)
        self.ff = nn.Sequential(nn.Linear(hidden, hidden * 2), nn.GELU(),
                                nn.Linear(hidden * 2, hidden))
        self.drop = nn.Dropout(dropout)
        self.head = nn.Linear(hidden, N_CLASSES)
        # constants baked into the graph - see the note in forward()
        self.register_buffer("eye", torch.eye(MAX_AGENTS).unsqueeze(0))
        self.register_buffer("feat_mean", torch.zeros(FEATURE_DIM))
        self.register_buffer("feat_std", torch.ones(FEATURE_DIM))

    def set_normaliser(self, mean, std) -> None:
        """Install per-feature scaling measured on the TRAINING clips only. Same contract as
        YieldNet.set_normaliser, so the two models stay interchangeable at the S3 boundary."""
        self.feat_mean.copy_(torch.as_tensor(mean, dtype=torch.float32))
        self.feat_std.copy_(torch.as_tensor(std, dtype=torch.float32).clamp_min(1e-6))

    def forward(self, sequence: torch.Tensor, adjacency: torch.Tensor) -> torch.Tensor:
        # NOTE: every reshape below uses -1 and compile-time constants, never `sequence.shape`.
        # Reading a shape at runtime exports as ONNX Shape + Gather, and importNetworkFromONNX
        # has no built-in layer for Gather. A is fixed at export time anyway (AGENTS.md S2
        # file-formats note), so there is nothing to read.
        sequence = (sequence - self.feat_mean) / self.feat_std
        h, _ = self.encoder(sequence.reshape(-1, SEQ_LEN, FEATURE_DIM))
        # last timestep by slice + flatten, not integer index - same reason as model 1
        h = torch.flatten(h[:, -1:, :], 1).reshape(-1, MAX_AGENTS, self.hidden)   # [B, A, H]

        q = self.q(h).reshape(-1, MAX_AGENTS, self.heads, self.dh).transpose(1, 2)
        k = self.k(h).reshape(-1, MAX_AGENTS, self.heads, self.dh).transpose(1, 2)
        v = self.v(h).reshape(-1, MAX_AGENTS, self.heads, self.dh).transpose(1, 2)

        scores = torch.matmul(q, k.transpose(-2, -1)) / (self.dh ** 0.5)   # [B, heads, A, A]
        # Adjacency as an ARITHMETIC additive mask. An agent always attends to itself.
        # masked_fill exports as Not + Where; multiply-and-add exports as Mul + Add, both of
        # which MATLAB converts to built-in layers.
        keep = torch.clamp(adjacency + self.eye, 0.0, 1.0).unsqueeze(1)     # [B, 1, A, A]
        scores = scores * keep + (keep - 1.0) * 1e4
        attn = torch.softmax(scores, dim=-1)

        ctx = torch.matmul(attn, v).transpose(1, 2).reshape(-1, MAX_AGENTS, self.hidden)
        h = self.norm1(h + self.drop(self.proj(ctx)))
        h = self.norm2(h + self.drop(self.ff(h)))
        return self.head(h)                                                # [B, A, 2]

    @torch.no_grad()
    def p_yield(self, sequence: torch.Tensor, adjacency: torch.Tensor) -> torch.Tensor:
        return torch.softmax(self(sequence, adjacency), dim=-1)[..., 1]


def count_params(m: nn.Module) -> int:
    return sum(p.numel() for p in m.parameters() if p.requires_grad)


if __name__ == "__main__":
    net = YieldAttentionNet()
    x = torch.randn(2, MAX_AGENTS, SEQ_LEN, FEATURE_DIM)
    adj = (torch.rand(2, MAX_AGENTS, MAX_AGENTS) > 0.7).float()
    y = net(x, adj)
    print(f"YieldAttentionNet params={count_params(net):,}")
    print(f"  in  sequence={tuple(x.shape)} adjacency={tuple(adj.shape)}")
    print(f"  out {tuple(y.shape)}   expected (2, {MAX_AGENTS}, 2)")
    assert y.shape == (2, MAX_AGENTS, N_CLASSES)
    # prove no Gather/Scatter reaches the ONNX graph
    import io
    buf = io.BytesIO()
    torch.onnx.export(net, (x, adj), buf, opset_version=13,
                      input_names=["sequence", "adjacency"], output_names=["yield_logits"])
    import onnx
    ops = {n.op_type for n in onnx.load_from_string(buf.getvalue()).graph.node}
    bad = ops & {"Gather", "Scatter", "ScatterND", "ScatterElements", "GatherND"}
    print(f"  onnx ops: {len(ops)} distinct")
    print(f"  forbidden ops present: {sorted(bad) if bad else 'NONE - safe to import'}")
