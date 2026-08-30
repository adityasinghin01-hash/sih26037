# The pitch

Six minutes. Lead with the number, not the architecture.

---

## 1 · The problem (45 s)

> Every self-driving car has one safe default: when uncertain, stop.
>
> At an unsignalled Indian junction, nobody has priority. So the car is always uncertain.
> It stops, and it never goes.
>
> And this isn't our opinion. **India's own driving-decision dataset has 3,634 recorded
> decisions — and every single one is the car giving way. There is no recorded example of
> going first.** Even the data only knows how to be defensive.

## 2 · Why now (30 s)

> Since **1 April 2026**, MoRTH mandates a full ADAS suite on every new bus and truck in India.
> One of the five required standards is **lane departure warning** — a lane-based standard,
> on roads that often have no lanes.
>
> And the people who built METEOR measured it: **models that work on Waymo data fail on
> Indian data.**

## 3 · The idea (60 s)

> An Indian junction has no controller — so we deleted ours.
>
> We build on MathWorks' own OpenTrafficLab, which resolves junctions with a central
> TrafficController. A signal is a controller. **We remove the object.** Each vehicle decides
> its own role from geometry alone — no radio, no infrastructure, no shared map.
>
> The rulebook we use is **COLREGs**, from shipping. The sea has no lanes either. One vessel
> gives way; the other **holds course and speed**. Predictability is the safety mechanism.
>
> Waymo made its car assertive and drew an NHTSA investigation. A declared role is defensible.
> "We made it pushier" is not.

## 4 · Why a cow cannot be negotiated with by radio (30 s)

> Every competing junction method needs one of two things. GameOpt+ **assumes connected vehicles
> with V2I communication**. MathWorks' own intersection assist needs V2X.
>
> **A cow cannot join a radio network. Neither can an auto-rickshaw driver.**
>
> But a cow has a bearing and a course. That is all our method needs.

## 5 · The evidence (90 s) — the heart of it

> We do not show you one video. We show you three curves.
>
> - **Time-to-enter** — how long the car sits there
> - **Completion against traffic density** — where our planner separates from the baseline
> - **The perception-degradation curve** — how it holds up as sensing gets worse
>
> That third one nobody publishes. B-GAP admits it needs "very good sensing." GameOpt runs in a
> simulator with no sensors at all.
>
> And the car we beat is **MathWorks' own shipped planner, completely unmodified.** We picked
> their strongest one — it uses lidar like us, handles pedestrians and bicycles like us, targets
> an urban intersection like us. It fails for a structural reason: **it requires a reference path,
> and an unsignalled junction supplies none.** The coordinate system it reasons in does not
> physically exist there.
>
> We changed nothing about it. That's the difference between a result and a strawman.

## 6 · What we are honest about (45 s)

> **On the highway merge, lane-based methods beat us.** We do not claim that win. Our planner
> detects that the road has structure and switches mode. **Our planner knows when it isn't needed.**
>
> We didn't invent COLREGs, or velocity obstacles, or the LSTM. We took published methods, aimed
> them somewhere new, and built the first working implementation in the toolchain MathWorks asked
> for. We name every source on our own slides.

## 7 · The ask (30 s)

> This is **the missing test suite for ADAS on Indian roads** — released open, with a planner that
> proves it works.
>
> Not a self-driving car. India legally requires a driver in effective control. **A benchmark.**
> For ARAI and ICAT, who homologate every vehicle sold in India, and for the validation teams at
> Bosch, Continental, Tata Elxsi and KPIT.
>
> A judge can re-run our numbers in twelve minutes. They cannot re-run B-GAP.

---

## Questions we will be asked

| Question | Answer |
|---|---|
| "Where are the RoadRunner scenes?" | No licence. Built from real Meerut geometry via OpenStreetMap, exported as OpenDRIVE — they open in RoadRunner the day a licence arrives |
| "Didn't TwinX do this?" | They built the scenario generator. **Their output is our input.** Nothing in their pipeline decides anything |
| "Is the perception real?" | Lidar in the loop, because the cuboid environment gives point clouds not pixels. Camera trained on IDD, benchmarked offline. We report both, separately |
| "Where's your safety proof?" | The velocity obstacle's safety condition `h = λ − β ≥ 0` **is** a control barrier function. The planner is written in the filter's own variable |
| "Only two scenarios?" | Two perfect beats five rough. The other three are coverage, built after these are solid |

## Rules for whoever presents

- **Number first, architecture second.** Nobody remembers a block diagram.
- **Never say "this has never been done."** Say "no public work we could find."
- **Name our closest competitor before the judge does.**
- **If a number is not in `docs/CLAIM-LEDGER.md`, do not say it.**
