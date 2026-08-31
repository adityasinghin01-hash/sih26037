---
trigger: glob
globs: ["**/*.m", "**/*.slx", "**/*.mlx"]
---

# MATLAB work

**Before writing a function, read `AGENTS.md` section 3** and name in your header comment which
contract struct you produce or consume. A function that invents its own struct shape is wrong.

- `lanespec` is lowercase. `laneSpec` does not exist. This has already cost the team once.
- Verify a function exists before using it. When unsure, say so rather than writing plausible code.
- **Never edit anything under `matlab/baseline/`.** That is a third-party planner used as an
  experimental control. Editing it invalidates the whole result.
- Report errors in full — the entire message and stack. A trimmed error costs a day.
