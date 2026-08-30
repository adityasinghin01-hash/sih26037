# Metrics — pre-registered

**Fixed 30 August 2026, before a single run.** That is the point: nobody can say we chose metrics
that flattered our results. **Do not add metrics. Do not change definitions.**

## The standard, and why it is not enough

The reference benchmark is the CARLA leaderboard:

```
Driving Score      = Route Completion x Infraction Penalty
Infraction Penalty = 1 / (1 + sum_j c_j * n_j)
```

| Infraction | Coefficient |
|---|---|
| Collision with a pedestrian | 1.00 |
| Collision with another vehicle | 0.70 |
| Collision with a static object | 0.60 |
| Running a red light | 0.40 |
| Scenario timeout | 0.40 |
| Failure to maintain minimum speed | up to 0.40 |
| Running a stop sign | 0.25 |

**We must correct ourselves on this in public.** We once said no standard metric punishes a frozen
car. It does — through "failure to maintain minimum speed" and the agent-blocked rule. But:

> Agent blocked — if an agent doesn't take any actions for **180 simulation seconds**.

**Three minutes.** A car stuck twenty seconds at an Indian junction has already failed, and CARLA
registers nothing. So the honest claim is not "no metric exists" — it is that **the standard
metric's resolution is about an order of magnitude too coarse for this problem.** Always use that
phrasing. It is stronger, and it is true.

## Ours

| ID | Metric | Exact definition |
|---|---|---|
| **M1** | **Time-to-enter** | Seconds from the ego first coming within 5 m of the junction entry line to its front axle crossing that line. **The headline number** |
| **M2** | **Completion vs density** | Fraction of runs reaching the goal within the time limit, swept across agents per 100 m² |
| **M3** | **Perception-degradation curve** | M2 re-measured under injected position error sigma, dropout rate, and false-positive rate — each swept independently |
| M4 | Weighted infractions | CARLA's own coefficients above, with **animals scored at the pedestrian weight of 1.00** |
| M5 | Minimum TTC | Smallest time-to-collision over the run, reported per agent class |
| M6 | Replanning latency | Wall-clock ms per planning cycle: mean, p95, max. *Demanded by the problem statement* |
| M7 | Path smoothness | Integral of squared lateral jerk over the path, plus peak lateral acceleration. *Demanded by the problem statement* |
| **M8** | **Yield ledger** | Every negotiation logged: predicted yield, actual yield, role assigned, outcome. Reported as precision and recall **in closed loop**, not on a held-out test set |
| M9 | Deadlock rate | Fraction of encounters where both parties stay below 0.5 m/s for more than 3 s |
| M10 | Role churn | Give-way ↔ stand-on flips per encounter. **Rule 8 forbids "a series of small alterations"** — high churn means we are violating the rulebook we claim to follow |

## Three rules

1. **M1, M2 and M3 are the result.** Everything else guards against winning the wrong way.
2. **M4 and M5 must not regress against the baseline.** A faster car that is less safe is a failed
   project, and we report it as one if that is what happens.
3. **One command regenerates every number.** An unreproducible number does not go on a slide.
