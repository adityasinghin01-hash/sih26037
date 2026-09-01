# ReadThis — the World, start to finish

> ## This folder is not handed out.
>
> **Aditya builds the World himself** and briefs the world teammate on a call, not through this
> repository. Nothing in `README.md` or `TEAM.md` sends anyone here.
>
> It is kept because **`B-perception.md` is where the rules for producing `S1 TrackList` and
> `S9 DrivableSpace` are written down**, and the planner consumes both. If you are on another
> stream, you do not need this folder — treat `S1` and `S9` as arriving from Aditya.

Everything the car drives *on* and everything it *sees* is built here.

The scenarios and the sensing are one job, not two. Sensors attach to actors, so a scene appears
and the sensors go straight onto it — and what they see tells you immediately whether the scene
is right. **Build them in the same sessions.**

---

## What is in this folder

| File | What it is | When you open it |
|---|---|---|
| **`ReadThis.md`** | this file — the map of the folder | first, once |
| **`A-world.md`** | Stream A's task list: install, the roads, the junction, the galli, the ghat, the cow, the pedestrians | you are Stream A |
| **`B-perception.md`** | Stream B's task list: lidar, radar, tracking, the near-field ring, and `S1 TrackList` | you are Stream B |

Nothing else in the repository belongs to you. **Do not open `ml/`, `plan/`,
`matlab/+sih/+planner/`, `matlab/+sih/+prediction/` or the Simulink model.** If something in
there looks wrong, say so to a human — do not go and fix it.

## The one thing that connects you to the other half of the team

**`S1 TrackList`**, frozen in `AGENTS.md` section 3. Stream B produces it. The planner consumes it.
That single struct is the entire interface between Role 1 and Role 2, which is why the two halves
cannot break each other. Read section 3 before you write a line of code, and **never change it** —
five people build against it.

Stream B also produces **`S9 DrivableSpace`**.

## The commands you can use

| Command | What it does |
|---|---|
| `/state` | where the project is right now, and what is blocked |
| `/first-run` | runs the MATLAB that has never been executed. **Do this first on a new machine** |

There is no `/world` command yet, because there is no world code yet.

## Where this stream actually stands — 1 September 2026

**Not started.** `matlab/+sih/+scenario/` and `matlab/+sih/+perception/` do not exist yet. Both
task lists above are written and ready to follow; no code behind them has been written or run.

**And the blocker is the same one blocking everything else: MATLAB is not installed on any of our
three machines.** The parts of `A-world.md` you *can* do without MATLAB are the Meerut footage and
the OpenStreetMap exports. Start there.

## If you are stuck

| You want | Look at |
|---|---|
| **The frozen contract** | **`AGENTS.md` section 3** |
| Who does what, and what is blocked | `TEAM.md` |
| The project rules | `AGENTS.md` |
| The de-risk checks | `derisk/HOW-TO-RUN.md` |

**Send the whole error to Aditya — never a summary.** A trimmed error costs the team a day.
