# PHASE 2 — MERGED RESULT (Claude + Perplexity + Consensus/lit-review)
**30 Aug 2026. Dataset question settled. The negotiation layer is buildable.**

## THE DECISIVE ANSWER: METEOR labels behaviour PER AGENT

Quoted from the ICRA 2023 paper: each clip has a **static XML** (video-level metadata) and a
**dynamic XML** (frame-level), and the dynamic file contains "bounding boxes, GPS coordinates,
and **agent behaviors**". The benchmark "uses bounding box annotations and their corresponding
behavior labels."

**Behaviour labels attach to individual surrounding agents, not to the ego vehicle.**
This is the opposite of IDD-X, and it is exactly what our design needs.

### The 17-label taxonomy, quoted
**Atypical interactions:** Overtaking (OT) - Overspeeding (OS) - **Yield (Y)** - **Cutting (C)** -
Lane change with markings LC(m) - Lane change without markings (LC) - Zigzagging (ZM)
**Traffic violations:** Running a traffic light (RB TL) - Wrong Lane (RB WL) - Wrong Turn (RB WT)
**Diverse scenarios:** intersections, roundabouts, traffic signals, left/right/U-turns

### The two labels that matter most, quoted verbatim
> **Yield (Y):** "A pedestrian, bicycle, or any slow-moving agent trying to cross the road in
> front of another agent. **If the latter slows down or stops, letting them cross the road**
> then such behavior is labeled as yield."

> **Cutting (C):** "When pedestrians, bicycles, or any slow-moving agents trying to cross the
> road **is interrupted by another agent**."

**Yield and Cutting are the two outcomes of a negotiation** — someone gave way, or someone did
not — labelled per agent, on Indian roads. This is the ground truth our negotiability layer
needs. Earlier searches concluded "no dataset annotates negotiation outcomes"; METEOR gets
closer than anything else found.

### METEOR facts
| Item | Value |
|---|---|
| Collected | **Hyderabad and outskirts**, radius 42-62 miles, rural + unstructured included |
| Rig | 2x Thinkware F800 dashcams on an MG Hector and a Maruti Ciaz |
| Camera | 2.3 MP, 140 deg FOV, 1920x1080 @ 30 fps, GPS synchronised to camera |
| Scale | 1,000+ one-minute clips, 2M+ frames, 13M+ boxes, **16 agent categories** |
| Annotations | boxes, class IDs, **ego GPS trajectories**, weather/time/density, urban/rural + lane markings, road network, ego actions (turns, accelerate, brake), rare behaviours, camera intrinsics |
| Audio | **none** |
| Size / access | **93.4 GB**, HuggingFace, no registration |

### METEOR's stated limitations - quoted, and they cost us work
> "we currently do not provide **trajectory information from a fixed reference frame**"
> "one would have to use **depth estimation techniques** to extract such trajectories"
> "our dataset does not contain **HD maps and pointcloud data**"

**Consequence:** METEOR gives image-plane boxes, not world-frame trajectories. Turning its
behaviour labels into usable per-agent reactivity requires a depth/projection step. Real work,
must be budgeted.

## DEAD LINKS AND DEAD ENDS
- **gamma.umd.edu/meteor is DEAD** (NoSuchBucket / 404). The HuggingFace mirror is the only
  live route. **Download it early — a mirror can disappear.**
- **TRAF (TraPHic dataset) is DEAD.** gamma.umd.edu/traphic/dataset returns 404. No mirror found.
- **HID does not exist as searchable.** Likely a misremembered name. Drop it.

## THE REVISED DATASET PLAN
| Dataset | Size | Licence | Why | Verdict |
|---|---|---|---|---|
| **IDD Lite** | 26.9 MB | research | test pipeline on a laptop today | **GET NOW** |
| **IDD Multimodal** | **~16 GB** (6.5+6.6+3.0) | research | **stereo 15fps + GPS 15Hz + 16-ch LiDAR + OBD** = real Indian ego speed, cheaply | **GET** |
| **DATS_2022** | small, >10k images | **CC BY 4.0** | **45 classes incl. dogs, goats, cattle, camel, horse AND animal-drawn carts**. Mendeley, DOI 10.17632/nfc34n8svj.2 | **GET — this is our animals data** |
| **IDD Detection** | 22.8 GB | research | 46k images, train the detector | **GET** |
| **METEOR** | 93.4 GB | CC BY-NC-SA (treat as non-commercial) | **the negotiation layer** | **GET, early** |
| IDD-X | 160 GB | CC BY-SA 4.0 | labels the wrong direction (ego-relative) | **SKIP** |
| IDD-3D | 236 GB | CC-BY-4.0 | too big for the value | **SKIP** |
| TRAF / HID | - | - | dead / not found | **SKIP** |

Roughly **135 GB** total, plus reassembly headroom for METEOR. Far better than the 400 GB
the original plan implied.

## AUDIO — THE GAP IS REAL AND NARROWER THAN HOPED
**No driving dataset anywhere contains audio.** Confirmed across all eight checked.

But horn audio work already exists, and we must name it ourselves:
- **"Vehicular Honk in Road Traffic Area"** (Durgapur, India) — IEEE DataPort, raw audio over
  ~124 km of road, partly labelled. GitHub: biswajitmaity17/DATASET
- **AClassiHonk** (Maity et al., arXiv 2401.00154) — multi-label honk classification on Indian
  road audio, ~15 h labelled, spectrogram CNN
- **HornBase** (Data in Brief 2024) — 1,080 one-second horn clips, CNN ~89% accuracy, not Indian
- **iNoise** Indian Noise Database; **Vaani Noise Event Dataset** (HuggingFace, has
  vehicle_traffic/horns)
- **YHonk**, Ahmedabad — 32 lakh honking events over 3 years with GPS, timestamp, duration.
  Media-reported, not publicly downloadable.

**So: honk detection is occupied. Horn audio datasets for India exist.**
**What was NOT found: any system that feeds horn audio into a driving planner.**
Sirens are used in AV perception; the horn as a negotiation signal inside the planner appears
open. State it as "no public system we could find," never "nobody has done it."

## WHAT THIS MEANS
1. The negotiation layer is **buildable** — METEOR's Yield/Cutting labels are the ground truth.
2. The animals scenario is **buildable and permissively licensed** — DATS_2022, CC BY 4.0.
3. Real Indian ego speed is **cheap** — IDD Multimodal, ~16 GB, GPS 15 Hz + OBD.
4. Audio remains the one place our own Meerut footage is unique — no driving dataset has sound.
5. Disk requirement drops from ~400 GB to ~135 GB plus headroom.
