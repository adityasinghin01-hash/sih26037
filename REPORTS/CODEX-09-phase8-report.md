# CODEX 09 — Phase 8 zero-reaction diagnosis

## Finding

No `reactStep` trigger guard rejects every Demo 1 actor. The measured zero is caused earlier: `opts.Reactive` was parsed and written to `config.json`, but the pre-fix top-level call in `demo_play.m` was:

```matlab
D = loadRoute(route, opts.Cow);
```

That call did not pass `opts.Reactive`. The downstream route/track builders consequently used their default `reactive = false`, so the guarded call to `sc.reactStep` was never entered. This explains both observations at once: the printed reaction count stayed zero and the reactive output was byte-identical to the non-reactive output.

The recorded run supports this data-flow diagnosis. `results/demo1-cowblocking_20260917-043142/config.json` records `"Reactive": true`, proving the arguments block received the option. That does not prove the option reached `builtinTracks`; the missing argument at the route-loading boundary prevented exactly that.

## Guard arithmetic

The guard in `matlab/+sc/reactStep.m:95` is:

```matlab
if ahead <= 0 || ahead > reach || lateral > 2.0
    continue
end
```

I reconstructed the checked-in `sc.localRoads -> sc.routeFrom -> sc.path` geometry from `world/map/matlab_roads.csv` and `world/map/najibabad_metres.json`, then evaluated the same `actorSpec`, `activeActorsAt`, and `egoNominalXY` equations without MATLAB.

For the wrong-way motorcycle at `t = 20.00 s`:

- actor station: `610 - 9(20) = 430.000 m`
- nominal ego station: `25 + 12(20) = 265.000 m`
- actor XY: `(-141.915606655, 420.344533404) m`
- nominal ego XY: `(-263.541258690, 532.170713425) m`
- actor direction: `(-0.868738043578, 0.495271856298)`
- relative vector, ego minus actor: `(-121.625652035, 111.826180020) m`
- `ahead = dot(rel, dir) = 161.045190759205 m`
- `reach = 9(2.5) = 22.500000000000 m`
- `lateral = 36.909894394838 m`

At that instant, line 95 rejects it because `ahead > reach` (and also because `lateral > 2.0`). This is only an early, curved-road separation and does not explain a whole-run count of zero.

At `t = 27.00 s`, during the same motorcycle encounter:

- actor station: `610 - 9(27) = 367.000 m`
- nominal ego station: `25 + 12(27) = 349.000 m`
- actor XY: `(-189.910555742, 461.542652688) m`
- nominal ego XY: `(-201.969396022, 475.040592201) m`
- actor direction: `(-0.740835780680, 0.671686196125)`
- relative vector: `(-12.058840280, 13.497939514) m`
- `ahead = 18.000000000000 m`
- `reach = 22.500000000000 m`
- `lateral = 1.900000000000 m`

All three line-95 predicates are false: `ahead > 0`, `ahead <= reach`, and `lateral <= 2.0`. Class 5 has positive authority and its speed is 9 m/s, so the earlier class/authority and stopped-actor guards also pass. Therefore a zero count cannot be caused by any `reactStep` guard under the authored Demo 1 geometry.

## Minimal fix

The fix belongs in how `demo_play` calls its route/track builders, not in `reactStep` and not in `egoNominalXY`:

```matlab
D = loadRoute(route, opts.Cow, opts.Dense, opts.Reactive);
```

Propagate `dense` and `reactive` through `loadRoute` and `normaliseRoute` into `builtinRoute`/`builtinRouteS3`, then into `builtinTracks`/`builtinTracksS3`. The working tree now contains that propagation at `matlab/demo_play.m:185`, `:239-277`, `:293-295`, and `:353` (with the corresponding Demo 3 path at `:590-667`). No change to the reaction model is required.

This preserves the byte-identical disabled path: when `Reactive=false`, `builtinTracks` skips the `reactStep` call entirely, and `reactStep` itself still returns `A` untouched when disabled.

## Independence from planner state

The fix passes only the user-selected configuration flag through setup code. The reaction geometry still uses the time-based nominal route pose from `egoNominalXY`; it does not read the planner state, candidates, plan failures, collision predictions, or the ego's simulated pose. It therefore does not introduce planner-triggered rescue behavior.

Using the real ego pose would require moving reaction into the planner loop and would couple agent behavior to planner output. That is unnecessary for this defect and is intentionally not part of the fix.

## Verification status

MATLAB was not run, per the job constraint. Static checks establish that:

- the option is now forwarded from `opts.Reactive` to both Demo 1/2 and Demo 3 track builders;
- `Reactive=false` retains the pre-existing branch that bypasses reaction;
- the wrong-way motorcycle has at least one authored instant where every `reactStep` guard passes.

Claude should run the existing `testReactStep` suite and the original integration command. The post-fix MATLAB reaction count is `TODO(unverified)`; the required acceptance condition is greater than zero.
