Implemented [densityPlannerRunS3.m](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/densityPlannerRunS3.m:1), ready for Claude’s MATLAB validation.

Approach chosen: a separate S3 runner. S3 differs substantially from S1 in actor generation, initial conditions, vehicle width, corridor logic, mirror folding, integration limits, and completion threshold. Generalizing the already-measured S1 runner without MATLAB regression testing was too risky.

Also updated [writeDemoResults.m](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/+sih/+metrics/writeDemoResults.m:60) so:

- Density actors are retained in `trajectories.csv` through an explicit ActorID→ClassID map.
- M6 uses 1.90 m normally and 1.70 m on `MirrorsFolded` samples.
- Existing callers without these optional fields retain their previous behavior.

Copied from existing runners/demo:

- `actorSpecS3`’s three rows verbatim.
- S3 tuning, initial state, integration limits, hazard-cap mechanism, completion threshold, start-speed calculation, and ramped corridor arithmetic.
- S1 density runner’s combined-track, logging, evidence, ID-offset, and result-writing structure.

Written fresh:

- Closed-form union of S3 negotiation and density actors.
- Correct velocities for positive-speed density actors.
- Row-unique density dimension tags and the class-ID evidence map.
- Squeeze invariant checks, fold logging, and full input capture in `config.json`.

Unverified assumptions:

- MATLAB accepts and executes the file.
- The full density union does not cause a D9/no-shared-trunk freeze.
- `sc.estimateDuration` remains sufficient if density actors add substantial waiting.
- The route completes and mirror folding occurs as intended.

The first line I expect to expose a behavioral problem is [densityPlannerRunS3.m:165](https://github.com/adityasinghin01-hash/sih26037/blob/main/matlab/densityPlannerRunS3.m:165), where the full combined TrackList first enters `sc.planSeat`.

Static verification passed: actor rows match, required S3 mechanisms are present, whitespace checks are clean, and forbidden paths are unchanged. An independent review found no remaining blocking static issues. MATLAB was not run, and no commit was created.