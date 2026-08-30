# Pick a lane

Six workstreams. **Read them, pick one, put your name on it.** They are deliberately
independent — `docs/INTERFACES.md` is frozen, so you can build your piece without waiting on
anybody or asking anybody a question.

| Stream | What you own | Machine | Needs MATLAB? |
|---|---|---|---|
| **A · World** | Scenarios, real Meerut roads, junction geometry | Windows or Mac | Yes |
| **B · Perception** | Lidar, tracking, the detector | Windows | Yes |
| **C · Prediction** | METEOR pipeline, LSTM training on the DGX | Any + DGX | Only at the end |
| **D · Planner** | COLREGs negotiation, Stateflow chart | Windows | Yes |
| **E · Evidence** | Baseline arm, metrics, experiment runner | Windows | Yes |
| **F · Visual** | Blender, renders, demo video | Mac — **Aditya** | No |

## How this works

**The code is written for you.** Most modules already have working implementations or complete
skeletons with the interfaces wired. Your job is to **run it, verify it, report failures in full,
and do the parts a machine cannot** — training runs, dataset downloads, judging whether a render
looks right, deciding whether a scenario feels like a real Indian junction.

**When something breaks, send the whole error.** Never a summary. A trimmed stack trace costs a day.

## Using Antigravity

The repo has an `AGENTS.md` at the root. Antigravity reads it automatically — it carries the
stack, the conventions and the settled decisions, so the agent already knows the rules.

Two things to do before you start:
1. Open the repo root as your workspace, not a subfolder. `AGENTS.md` only loads from the root.
2. Read `docs/INTERFACES.md` yourself. Do not let an agent change it. If your agent proposes
   editing that file, the answer is no — five other people are building against it.

Point your agent at your own brief in this folder. Everything it needs is referenced from there.

## Before your first commit

**Read [`docs/WORKFLOW.md`](../docs/WORKFLOW.md).** It covers the things that are not in your brief:

- **One branch per stream** — `stream-a-world`, `stream-b-perception`, etc. **Never push to `main`**
- **Commit format** — `<task-id>: <what changed>`, e.g. `B3: TrackList emits SensorMask`
- **Run the tests before every push.** Do not push red and hope
- **Definition of done** — four conditions, and "it works on my machine" is not one of them
- **Handoffs** — who is waiting on you, and to tell them when you are unblocked
- **What to do when the contract is not enough** — you do not edit it, you ask

## Three rules that apply to everyone

**Never edit `matlab/baseline/`.** That is MathWorks' shipped planner, unmodified, and it is our
control arm. If we tune it to fail, a judge calls it a strawman and the whole result dies.

**Never invent a number.** If you have not run the thing that produces it, write
`TODO(unverified)`. This project's entire pitch is that its claims are checkable.

**Nothing ships with a bug already reproduced in the demo flow.** We lost a hackathon that way.
